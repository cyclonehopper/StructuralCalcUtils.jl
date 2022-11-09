


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
d1=254.0
bf1=254.0
tf1=14.2
tw1=8.6
rr1=14.0

s = IbeamPlusBottomIbeam(d, bf, tf, tw, rr, d1, bf1, tf1, tw1, rr1, fy, fu, "HR") 

#  test against results from strand7
@test abs(s.Ag - 31673.6)/31673.6 ≈ 0.01  atol = 0.01
@test abs(s.Izp - 5.26856e9)/5.26856e9 ≈ 0.01 atol = 0.01
@test abs(s.Zzp - 8.49226e6)/8.49226e6 ≈ 0.01 atol = 0.01
@test abs(s.Szp - 1.10731e7)/1.10731e7 ≈ 0.01 atol = 0.01
@test abs(s.J - 5.07956e6)/5.07956e6 ≈ 0.01 atol = 0.01
@test abs(s.Iw - 2.71318e13)/2.71318e13 ≈ 0.01 atol = 0.01
# @test s.λey_bending[10] == 45

# s = IbeamPlusBottomIbeam(d, bf, tf, tw, rr, d1, bf1, tf1, tw1, rr1, fy, fu, "HW") 
# @test s.λey_bending[10] == 35
