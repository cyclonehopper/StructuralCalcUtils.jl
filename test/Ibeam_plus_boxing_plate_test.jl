


# test design data
# klery = 104.58587511331348
# klerz = 40.82478476403052


# TEST #1
# d = 692.0
# bf = 250.0
# tf = 16.0
# tw = 10.0
# rr = 0.0
# dpl = d - tf
# tpl = 16.0
# s = IbeamPlusBoxingPlate(d, bf, tf, tw, rr, dpl, tpl, fy, fu, "HR", "both")
# @test abs(s.Ag - 36232)/36232 < 1/100 
# @test abs(s.Izp - 1.97748e9)/1.97748e9 < 1/100
# @test abs(s.Zzp - 5.71525e6)/5.71525e6 < 1/100
# @test abs(s.Szp - 7.44881e6)/7.44881e6 < 1/100
# @test abs(s.J - 1.10156e9)/1.10156e9 < 5/1000


# test #2 to check the capacity of 1000WB215
@testset "capacity of 1000WB215" begin
    αb = 1.0
    fy = 300.0
    fu = 430.0

    d = 1000
    bf = 300
    tf = 20
    tw = 16
    rr = 0.0
    dpl = 1e-6
    tpl = 1e-6
    s = IbeamPlusBoxingPlate(d, bf, tf, tw, rr, dpl, tpl, fy, fu, "HR", "both")
    @test s.Ag == 27400.0
    @test s.Szp == 9570e3
    @test s.Zzp == 8120e3
    @test abs(s.J - 2890000.0) / 2890000.0 < 1/100
    @test abs(s.Iw - 2.17e13) / 2.17e13 < 1/100

    letop = 1512.0
    lebott = 2 * letop
    αm = 1.0
    Mu = 1559.77
    Ze = fZe(s)
    Msz = fMs(s)
    @test Ze == 9570e3 #from SG model F4 midspan
    # fMbz(Mu, Msz, lebtop, lebbott, IsBottomFlangeLarger, s::DesignSections, αm)
end



