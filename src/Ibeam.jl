

export Ibeam
struct Ibeam <: DesignSections
    d::Float64
    bf::Float64
    tf::Float64
    tw::Float64
    rr::Float64
    fy::Float64
    fu::Float64
    stresscode::String
    geom::PyObject
    Ag::Float64
    Izp::Float64
    Iyp::Float64
    Szp::Float64
    Syp::Float64
    # Zzpt::Float64
    # Zzpb::Float64
    Zzp::Float64
    # Zypt::Float64
    # Zypb::Float64
    Zyp::Float64
    rzp::Float64
    ryp::Float64
    J::Float64
    Iw::Float64
    βx_raw::Float64
    b::Vector{Float64}
    t::Vector{Float64}
    λe::Vector{Float64}
    λey_axial::Vector{Float64}
    λep::Vector{Float64}
    λey_bending::Vector{Float64}

    # function DesignSections(d,bf,tf,tw,rr,d1,bf1,tf1,tw1,rr1,fy, Ag)
    #     new(d,bf,tf,tw,rr,d1,bf1,tf1,tw1,rr1,fy,Ag)
    # end
    function Ibeam(d, bf, tf, tw, rr, fy, fu, stresscode)
        # primitive_sections = pyimport("sectionproperties.pre.library.primitive_sections")
        steel_section = pyimport("sectionproperties.pre.library.steel_sections")
        AnalysisSection = pyimport("sectionproperties.analysis.section")

        isec1 = steel_section.i_section(d=d, b=bf, t_f=tf, t_w=tw, r=rr, n_r=4)
        # isec2 = steel_section.i_section(d=d1, b=bf1, t_f=tf1, t_w=tw1, r=rr1, n_r=4).shift_section((bf - bf1) / 2, -d1)
        geom = isec1
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
        Zzp = min(Zzpt, Zzpb)
        Zypt = section_analysis.get_zp()[3]
        Zypb = section_analysis.get_zp()[4]
        Zyp = min(Zypt, Zypb)
        rzp = sqrt(Izp / Ag)
        ryp = sqrt(Iyp / Ag)
        J = section_analysis.get_j()
        Iw = section_analysis.get_gamma()

        # The plus value relates to the top flange in compression and the minus value relates to the bottom flange in compression
        βx_raw = abs(section_analysis.get_beta_p()[1])
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
        bef = (bf - tw) / 2.0
        λef = (bef / tf) * sqrt(fy / 250.0)
        λeyf_axial = get_λey_axialcompression(isOne, stresscode)
        push!(λe, λef)
        push!(λe, λef)
        push!(λe, λef)
        push!(λe, λef)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)
        push!(λey_axial, λeyf_axial)
        push!(b, bef)
        push!(b, bef)
        push!(b, bef)
        push!(b, bef)
        push!(t, tf)
        push!(t, tf)
        push!(t, tf)
        push!(t, tf)

        # rolled web
        push!(λe, (d - 2.0 * tf) / tw * sqrt(fy / 250.0))
        push!(λey_axial, get_λey_axialcompression(isBoth, stresscode))

        push!(b, d - 2.0 * tf)
        push!(t, tw)

        # calculate element slenderness per table 5.2 (bending)
        λep = Float64[] #element slenderness
        λey_bending = Float64[] #limits, yield bending
        isUniformCompression = true

        # flange outstand 
        λepf_outstand = get_λep(isOne, stresscode, isUniformCompression)
        push!(λep, λepf_outstand) #HR
        push!(λep, λepf_outstand) #HR
        push!(λep, λepf_outstand) #HR
        push!(λep, λepf_outstand) #HR

        λeyf_one = get_λey_bending(isOne, stresscode, isUniformCompression)
        push!(λey_bending, λeyf_one) #HR
        push!(λey_bending, λeyf_one) #HR
        push!(λey_bending, λeyf_one) #HR
        push!(λey_bending, λeyf_one) #HR  

        # rolled web, main Ubeam
        push!(λep, get_λep(isBoth, stresscode, !isUniformCompression)) #HR
        push!(λey_bending, get_λey_bending(isBoth, stresscode, !isUniformCompression)) #HR

        new(d, bf, tf, tw, rr, fy, fu, stresscode, geom, Ag, Izp, Iyp, Szp, Syp, Zzp, Zyp,
            rzp, ryp, J, Iw, βx_raw, b, t, λe, λey_axial, λep, λey_bending)
    end
end