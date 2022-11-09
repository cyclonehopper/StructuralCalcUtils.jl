# @testset "StructuralCalcUtils.jl" begin

#     # v = StructuralCalcUtils.foo(10,5)
#     # @test v[1] == 10
#     # @test v[2] == 5
#     # @test eltype(v) == Int
# end

isOutstand = true
isBoth = false

@test get_λey_axialcompression(true, "HR") == 16.0
@test get_λey_axialcompression(true, "HW") == 14.0
@test get_λey_axialcompression(false, "HR") == 45.0
@test get_λey_axialcompression(false, "HW") == 35.0

# outstand
isUniformCompression = true
@test get_λep(isOutstand, "HR", isUniformCompression) == 9.0
@test get_λep(isOutstand, "HW", isUniformCompression) == 8.0
@test get_λep(isOutstand, "HR", false) == 9.0
@test get_λep(isOutstand, "HW", false) == 8.0

@test get_λey_bending(isOutstand, "HR", isUniformCompression) == 16.0
@test get_λey_bending(isOutstand, "Hw", isUniformCompression) == 14.0
@test get_λey_bending(isOutstand, "HR", false) == 25.0
@test get_λey_bending(isOutstand, "Hw", false) == 22.0

# both
@test get_λep(isBoth, "HR", isUniformCompression) == 30.0
@test get_λep(isBoth, "Hw", isUniformCompression) == 30.0
@test get_λep(isBoth, "", false) == 82.0

@test get_λey_bending(isBoth, "HR", isUniformCompression) == 45.0
@test get_λey_bending(isBoth, "HW", isUniformCompression) == 35.0
@test get_λey_bending(isBoth, "", false) == 115.0

# test design data
klery = 104.58587511331348
klerz = 40.82478476403052
αb = 1.0
fy = 300.0
fu = 430.0

s = IbeamPlusBottomTee(602.0, 228.0, 14.8, 10.6, 14.0, 471.125, 228.0, 14.8, 10.6, 14.0, fy, fu, "HW") #610UB + tee made of 610UB
@test s.tf == 14.8
# @test abs(s.Ag - 21321.683939999995) <= 1e-6
@test s.Ag ≈ 21321.683940000003 atol = 0.01
# @test s.Izp ≈ 2.955704166325263e9 atol=1.0
# @test s.λe[1] ≈ 8.813513513513513 atol=0.01 
@test s.λey_axial[1] ≈ 14.0 atol = 0.01

kf = fkf(s)
@test kf ≈ 0.8253152802955954 atol = 0.01

αcy = fαc(klery, fy, αb, kf)
@test αcy ≈ 0.41919012373916215 atol = 0.001
αcz = fαc(klerz, fy, αb, kf)
@test αcz ≈ 0.8263351992043866 atol = 0.001

ϕNs = fϕNs(kf, s.Ag, fy)
ϕNcy = fϕNc(αcy, ϕNs)
ϕNcz = fϕNc(αcz, ϕNs)
@test ϕNcy ≈ 1991.664649228856 atol = 0.01

Ze = fZe(s)
@test Ze ≈ 6.596220695306765e6 atol = 5.0

Msz = fMs(Ze, fy)
@test 0.9 * Msz ≈ 1780.9795877328268 atol = 0.1

Nu = 43.7791 #+ve = compression
Muz = -157.3
r_ix = fr_ix(Nu, Muz, ϕNcz, 0.9 * Msz)
@test r_ix ≈ 0.09947286188926262 atol = 0.00001

IsBottomFlangeLarger = 1 #1=yes, 0=symmetrical, -1=no
@test fβx(-1, IsBottomFlangeLarger, s) > 0.0
@test fβx(1, IsBottomFlangeLarger, s) < 0.0
@test fβx(0, IsBottomFlangeLarger, s) == 0.0
@test fβx(-1, -IsBottomFlangeLarger, s) < 0.0
@test fβx(1, -IsBottomFlangeLarger, s) > 0.0
@test fβx(0, -IsBottomFlangeLarger, s) == 0.0
@test fβx(-1, 0, s) == 0.0
@test fβx(1, 0, s) == 0.0
@test fβx(0, 0, s) == 0.0

lebtop = 1500.0
lebbott = 19.0e3
Mo = fMo(s, Muz, IsBottomFlangeLarger, lebtop, lebbott)
@test Mo ≈ 194.42917576699918 atol = 0.1

αm = 1.0
Mbz = fMbz(Muz, Msz, lebtop, lebbott, IsBottomFlangeLarger, s, αm)
@test Mbz ≈ 173.67863226605854 atol = 0.1

ϕMbz = 0.9 * Mbz
r_ox = fr_ox(Nu, ϕNcy, Muz, ϕMbz)
@test r_ox ≈ 1.0286366923848462 atol = 0.01

# TENSION CASES
kt = 1.0
ϕNt = fϕNt(kt, s)
@test ϕNt ≈ 6396.505182000001 atol = 0.1

Nut = -17.8894
ϕMsz = 0.9 * Msz
Muz = -59.4713
r_ixt = fr_ixt(Nut, ϕNt, Muz, ϕMsz)
@test r_ixt ≈ 0.036976575544865026 atol = 0.001

r_oxt = fr_oxt(Nut, ϕNt, Muz, Msz, lebtop, lebbott, IsBottomFlangeLarger, s, αm)
@test r_oxt ≈ 0.3776714270331448 atol = 0.001