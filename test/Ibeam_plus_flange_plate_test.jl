


# test design data
# klery = 104.58587511331348
# klerz = 40.82478476403052
αb = 1.0
fy = 300.0
fu = 430.0

d = 900.0
bf=300.0
tf=20.0
tw=12.0
rr=0.0
d1=311.0
bf1=327.0
tf1=25.0

s = IbeamPlusFlangePlate(d, bf, tf, tw, rr, bf1, tf1, fy, fu, "HR") 
 
@test s.Ag ≈ 30495.00000000001 atol = 0.001
λe = s.λe
@test length(λe) == 6
λey_axial = s.λey_axial
@test length(λey_axial) == 6
λey_bending = s.λey_bending
@test length(λey_bending) == 6
λep = s.λep
@test length(λep) == 6



s2 = IbeamPlusFlangePlate(d, bf, tf, tw, rr, bf1, tf1, fy, fu, "HR", "TOP_AND_BOTTOM_outside") 
 
@test s2.Ag ≈ 38670.000000000015 atol = 0.001
λe = s2.λe
@test length(λe) == 7
λey_axial = s2.λey_axial
@test length(λey_axial) == 7
λey_bending = s2.λey_bending
@test length(λey_bending) == 7
λep = s2.λep
@test length(λep) == 7

@test λe[6] ≈ bf1/tf1* sqrt(fy / 250.0) atol = 0.0001
@test λe[7] ≈ bf1/tf1* sqrt(fy / 250.0) atol = 0.0001
@test λep[6] == 30.0
@test λep[7] == 30.0
@test λey_axial[6] == 45
@test λey_axial[7] == 45
@test λey_bending[6] == 45
@test λey_bending[7] == 45



# test #3 to check the capacity of 1000WB215
@testset "capacity of 700WB115 + 260*12fl bottom flange plate" begin
    αb = 0.5
    fy = 250.0
    fu = 430.0

    d = 692.0
    bf = 250.0
    tf = 16.0
    tw = 10.0
    rr = 0.0
    bf1 = 250.0
    tf1 = 12.0

    s3 = IbeamPlusFlangePlate(d, bf, tf, tw, rr, bf1, tf1, fy, fu, "HW", "bottom") 
    @test s3.Ag ≈ 17600.0 atol=176.0
    @test s3.Izp ≈ 1.46209e9 atol=1.46209e5
    @test s3.Iyp ≈ 5.734667e7 atol=5.734667e3
    @test s3.Szp ≈ 4624.0e3 atol=4624.0
    # @test s.Zzp == 8120e3
    @test s.J ≈ 2398.0e3 atol=1000
    # @test abs(s.Iw - 2.17e13) / 2.17e13 < 1/100

    lebtop = 1.4*1800.0
    lebbott = 2 * lebtop
    IsBottomFlangeLarger = 1
    αm = 0.5
    Nu = 229.441
    Muz = 663.941
    Ze = fZe(s)
    Msz = fMs(s)
    Mo = fMo(s, Muz, IsBottomFlangeLarger, lebtop, lebbott)  #fMo(s::DesignSections, Muz, IsBottomFlangeLarger, lebtop, lebbott)
    Mbz = fMbz(Muz, Msz, lebtop, lebbott, IsBottomFlangeLarger, s, αm)
    kf = fkf(s)
    # kf = 0.74
    # @test kf ≈ 0.74 atol=0.01
    ϕNs = fϕNs(kf, s.Ag, s.fy)
    # @test ϕNs ≈ 5459.22 atol=10.0
    ly = 7700.0
    klry = ly / s.ryp
    # @test klry ≈ 134.9 atol = 1.35 #chaeck 1% error
    αcy = fαc(klry, fy, αb, kf)
    # @test αcy ≈ 0.37 atol = 0.004
    ϕNcy = fϕNc(αcy, ϕNs)
    # @test ϕNcy ≈ 1212.74 atol = 12.2
    ϕMox = fϕMox(Nu, ϕNcy, 0.9 * Mbz)
    # @test ϕMox ≈ 765.43 atol = 7.7
    # @test abs(Ze - 9570e3) / 9570e3 < 1 / 100 #from SG model F4 midspan
    # @test 0.9 * Msz ≈ 2583.90 atol = 1
    # @test abs(0.9 * Mo - 34610.32)/34610.32 < 1/100.0
    # @test abs(0.9 * Mbz - 2572.02)/2572.02 < 1/100.0

    # 
end