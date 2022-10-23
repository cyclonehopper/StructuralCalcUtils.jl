

export IbeamPlusBottomTee
mutable struct IbeamPlusBottomTee <: DesignSections
    d::Float64
    bf::Float64
    tf::Float64
    tw::Float64
    rr::Float64
    d1::Float64
    bf1::Float64
    tf1::Float64
    tw1::Float64
    rr1::Float64
    fy::Float64
    stresscode::String
    geom::PyObject
    Ag::Float64
    Izp::Float64
    Iyp::Float64
    Szp::Float64
    Syp::Float64
    Zzpt::Float64
    Zzpb::Float64
    Zypt::Float64
    Zypb::Float64
    J::Float64
    Iw::Float64
    βx::Float64
    b::Vector{Float64}
    t::Vector{Float64}
    λe::Vector{Float64}
    λey_axial::Vector{Float64}
    λep::Vector{Float64}
    λey_bending::Vector{Float64}
 
    # function DesignSections(d,bf,tf,tw,rr,d1,bf1,tf1,tw1,rr1,fy, Ag)
    #     new(d,bf,tf,tw,rr,d1,bf1,tf1,tw1,rr1,fy,Ag)
    # end
    function IbeamPlusBottomTee(d, bf, tf, tw, rr, d1, bf1, tf1, tw1, rr1, fy, stresscode)
        # primitive_sections = pyimport("sectionproperties.pre.library.primitive_sections")
        steel_section = pyimport("sectionproperties.pre.library.steel_sections")
        AnalysisSection = pyimport("sectionproperties.analysis.section")

        isec1 = steel_section.i_section(d=d, b=bf, t_f=tf, t_w=tw, r=rr, n_r=4)
        teesec1 = steel_section.tee_section(d=d1, b=bf1, t_f=tf1, t_w=tw1, r=rr1, n_r=4).mirror_section(axis="x", mirror_point=[0.0, 0.0])#.shift_section(0.0, -tf/2)
        geom = isec1 | teesec1
        geom.create_mesh(mesh_sizes=tw^2)
        section_analysis = AnalysisSection.Section(geom)
        section_analysis.calculate_geometric_properties()
        section_analysis.calculate_warping_properties()
        section_analysis.calculate_plastic_properties()

        Ag = section_analysis.get_area()
        Izp = section_analysis.get_ip()[1]
        Iyp = section_analysis.get_ip()[2]
        Szp = section_analysis.get_sp()[1]
        Syp = section_analysis.get_sp()[2]
        Zzpt = section_analysis.get_zp()[1]
        Zzpb = section_analysis.get_zp()[2]
        Zypt = section_analysis.get_zp()[3]
        Zypb = section_analysis.get_zp()[4]
        J = section_analysis.get_j()
        Iw = section_analysis.get_gamma()
        βx_raw = abs(section_analysis.get_beta()[1])

        b = Float64[] #element length
        t = Float64[] #element thickness     
        λe = Float64[] #element slenderness
        λey_axial = Float64[] #limits, yield compression        
        # λsy = Float64[] #section slenderness, yield
        # λsp = Float64[] #section slenderness. plastic
        # λep = Float64[] #element slenderness limit, plastic

        # calculate element slenderness per table 6.2.4 (axial compression)
        # rolled flanges, i-beam, outstand 
        isOne = true
        isBoth = !isOne
        λef = (bf - tw) / (2 * tf) * fy / 250.0
        λeyf_axial = get_λey_axialcompression(isOne, stresscode)
        push!(λe, λef)
        push!(λe, λef)
        push!(λe, λef)
        push!(λe, λef)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)

        push!(b, bf - tw)
        push!(b, bf - tw)
        push!(b, bf - tw)
        push!(b, bf - tw)
        push!(t, tf)
        push!(t, tf)
        push!(t, tf)
        push!(t, tf)

        # flange outstand slenderness, Tee section
        push!(λe, (bf1 - tw1) / (2 * tf1) * fy / 250.0)
        push!(λe, (bf1 - tw1) / (2 * tf1) * fy / 250.0)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)

        push!(b, bf1 - tw1)
        push!(b, bf1 - tw1)
        push!(t, tf1)
        push!(t, tf1)


        # rolled web
        push!(λe, (d - 2.0 * tf) / (tw) * fy / 250.0)
        push!(λey_axial, get_λey_axialcompression(false, stresscode))

        push!(b, d - 2 * tf)
        push!(t, tw)

        #rolled web, Tee section
        push!(λe, (d1 - 2.0 * tf1) / (tw1) * fy / 250.0)
        push!(λey_axial, get_λey_axialcompression(isBoth, stresscode))

        push!(b, d1 - tf1)
        push!(t, tw1)


        # calculate element slenderness per table 5.2 (bending)
        λep = Float64[] #element slenderness
        λey_bending = Float64[] #limits, yield bending

        # flange outstand 
        λepf = get_λep(isOne, stresscode, true)
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR

        λeyf = get_λey_bending(isOne, stresscode, true)
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR

        # flange outstand, Tee section
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR


        # rolled web
        push!(λep, get_λep(isBoth, stresscode, false)) #HR
        push!(λey_bending, get_λey_bending(false, stresscode, false)) #HR

        # rolled web, Tee 
        push!(λep, get_λep(isBoth, stresscode, false)) #HR
        push!(λey_bending, get_λey_bending(false, stresscode, false)) #HR


        new(d, bf, tf, tw, rr, d1, bf1, tf1, tw1, rr1, fy, stresscode, geom, Ag, Izp, Iyp, Szp, Syp, Zzpt, Zzpb, Zypt, Zypb,
            J, Iw, βx_raw, b, t, λe, λey_axial, λep, λey_bending)
    end
end