# @testset "StructuralCalcUtils.jl" begin

#     # v = StructuralCalcUtils.foo(10,5)
#     # @test v[1] == 10
#     # @test v[2] == 5
#     # @test eltype(v) == Int
# end


s = IbeamPlusBottomTee(602.0, 228.0,14.8,10.6, 14.0, 471.125, 228.0, 14.8,10.6,14.0,250.0, "HR") #610UB + tee made of 610UB
@test s.tf == 14.8
# @test abs(s.Ag - 21321.683939999995) <= 1e-6
@test s.Ag ≈ 21321.683940000003 atol=0.01
@test get_Ag(s) ≈ 21321.683940000003 atol=0.01

isOutstand=true 
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
 

s.geom