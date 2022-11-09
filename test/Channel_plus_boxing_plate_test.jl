


# test design data
# klery = 104.58587511331348
# klerz = 40.82478476403052
@testset "capacity of 203*76C" begin
αb = 1.0
fy = 250.0
fu = 430.0

d = 203.2
bf=76.2
tf=11.2
tw=7.1
rr=12.2
dpl = 220.0
tpl = 10.0

s = ChannelPlusBoxingPlate(d, bf, tf, tw, rr, dpl, tpl, fy, fu, "HW") 

#  test against results from strand7
@test s.Ag ≈ 5254.442 atol = 50
# @test abs(s.Izp - 5.26856e9)/5.26856e9 ≈ 0.01 atol = 0.01
# @test abs(s.Zzp - 8.49226e6)/8.49226e6 ≈ 0.01 atol = 0.01
# @test abs(s.Szp - 1.10731e7)/1.10731e7 ≈ 0.01 atol = 0.01
# @test abs(s.J - 5.07956e6)/5.07956e6 ≈ 0.01 atol = 0.01
# @test abs(s.Iw - 2.71318e13)/2.71318e13 ≈ 0.01 atol = 0.01

@test s.λe[1] ≈ (bf-tw)/tf *sqrt(fy/250.0) atol = 0.01
@test s.λe[2] ≈ (bf-tw)/tf *sqrt(fy/250.0) atol = 0.01
@test s.λe[3] ≈ (d-2*tf)/tw *sqrt(fy/250.0) atol = 0.01
@test s.λe[4] ≈ (d-2*tf)/tpl *sqrt(fy/250.0) atol = 0.01

@test s.λey_axial[1] ≈ 35 atol = 0.01
@test s.λey_axial[2] ≈ 35 atol = 0.01
@test s.λey_axial[3] ≈ 35 atol = 0.01
@test s.λey_axial[4] ≈ 35 atol = 0.01

@test s.λey_bending[1] ≈ 35 atol = 0.01
@test s.λey_bending[2] ≈ 35 atol = 0.01
@test s.λey_bending[3] ≈ 115 atol = 0.01
@test s.λey_bending[4] ≈ 115 atol = 0.01

@test s.λep[1] ≈ 30.0 atol = 0.01
@test s.λep[2] ≈ 30.0 atol = 0.01
@test s.λep[3] ≈ 82.0 atol = 0.01
@test s.λep[4] ≈ 82.0 atol = 0.01

# @test s.λey_bending[10] == 45

end
