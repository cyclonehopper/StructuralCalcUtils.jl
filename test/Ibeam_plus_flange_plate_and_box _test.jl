# test design data
# klery = 104.58587511331348
# klerz = 40.82478476403052
αb = 1.0
fy = 300.0
fu = 430.0
# 700WB130
d = 700.0
bf = 250.0
tf = 20.0
tw = 10.0
rr = 0.0
bf1 = 280.0
tf1 = 10.0
dpl = d - tf
tpl = 10.0

s = IbeamPlusFlangePlateAndBox(d, bf, tf, tw, rr,bf1,tf1, dpl, tpl, fy, fu, "HW", "both", "both")

# test against SG model properties
@test s.Ag ≈ 35800 atol=10
@test abs(s.Izp - 2.625753e9)/2.625753e9 < 0.1/100
@test abs(s.Zzp - 7293760)/7293760 < 0.1/100
# @test abs(s.Szp - 7.44881e6)/7.44881e6 < 1/100
@test abs(s.J ) < 0.5/100
# @test abs(s.Iw - 3.73008e12)/3.73008e12 < 5/1000