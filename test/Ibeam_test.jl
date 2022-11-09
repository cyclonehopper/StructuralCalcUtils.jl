

# test #2 to check the capacity of 1000WB215
@testset "capacity of 1000WB215" begin
    αb = 0.5
    fy = 300.0
    fu = 430.0

    d = 1000
    bf = 300
    tf = 20
    tw = 16
    rr = 0.0

    s = Ibeam(d, bf, tf, tw, rr, fy, fu, "HR")
    # @test s.Ag ≈ 27400.0 atol=1.0
    # @test s.Szp == 9570e3
    # @test s.Zzp == 8120e3
    # @test abs(s.J - 2890000.0) / 2890000.0 < 1/100
    # @test abs(s.Iw - 2.17e13) / 2.17e13 < 1/100

    lebtop = 1512.0
    lebbott = 2 * lebtop
    IsBottomFlangeLarger = 0
    αm = 1.0
    Nu = 343.36
    Muz = 1559.77
    Ze = fZe(s)
    Msz = fMs(s)
    Mo = fMo(s, Muz, IsBottomFlangeLarger, lebtop, lebbott)  #fMo(s::DesignSections, Muz, IsBottomFlangeLarger, lebtop, lebbott)
    Mbz = fMbz(Muz, Msz, lebtop, lebbott, IsBottomFlangeLarger, s, αm)
    kf = fkf(s)
    # kf = 0.74
    # @test kf ≈ 0.74 atol=0.01
    ϕNs = fϕNs(kf, s.Ag, s.fy)
    # @test ϕNs ≈ 5459.22 atol=10.0
    ly = 7700
    klry = ly / s.ryp
    @test klry ≈ 134.1 atol = 1
    αcy = fαc(klry, fy, αb, kf)
    @test αcy ≈ 0.36 atol = 0.01
    ϕNcy = fϕNc(αcy, ϕNs)
    @test ϕNcy ≈ 1942.10 atol = 10
    ϕMox = fϕMox(Nu, ϕNcy, 0.9 * Mbz)
    @test ϕMox ≈ 2117.29 atol = 10
    # @test abs(Ze - 9570e3) / 9570e3 < 1 / 100 #from SG model F4 midspan
    # @test 0.9 * Msz ≈ 2583.90 atol = 1
    # @test abs(0.9 * Mo - 34610.32)/34610.32 < 1/100.0
    # @test abs(0.9 * Mbz - 2572.02)/2572.02 < 1/100.0

    # 
end



