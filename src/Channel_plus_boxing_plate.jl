

export ChannelPlusBoxingPlate
struct ChannelPlusBoxingPlate <: DesignSections
    d::Float64
    bf::Float64
    tf::Float64
    tw::Float64
    rr::Float64
    dpl::Float64
    tpl::Float64
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

    # function DesignSections(d,bf,tf,tw,rr,d1,bf1,tf1,fy,plateLoc="BOTTOM_OUTSIDE")
    # plateLoc="TOP_OUTSIDE"
    # plateLoc="TOP_AND_BOTTOM_OUTSIDE"
    #     
    # end
    function ChannelPlusBoxingPlate(d, bf, tf, tw, rr, dpl, tpl, fy, fu, stresscode)

        primitive_sections = pyimport("sectionproperties.pre.library.primitive_sections")
        steel_section = pyimport("sectionproperties.pre.library.steel_sections")
        AnalysisSection = pyimport("sectionproperties.analysis.section")


        C_sec1 = steel_section.channel_section(d=d, b=bf, t_f=tf, t_w=tw, r=rr, n_r=4)
        pl_right = primitive_sections.rectangular_section(tpl, dpl).shift_section(bf, (d - dpl )/ 2.0)

        # The plus value relates to the top flange in compression and the minus value relates to the bottom flange in compression
        # b = Float64[] #element length
        # t = Float64[] #element thickness     
        # λe = Float64[] #element slenderness
        # λey_axial = Float64[] #limits, yield compression    
        # λep = Float64[] #element slenderness
        # λey_bending = Float64[] #limits, yield bending    

        # calculate element slenderness per table 6.2.4 (axial compression)        
        # rolled flanges, i-beam, outstand 
        isOne = true
        isBothEndsSupported = !isOne
        uniformCompression = true

        
        bef = (bf - tw)
        bew = (d - 2.0 * tf)
        λef = bef / tf * sqrt(fy / 250.0)
        λew = bew / (tw) * sqrt(fy / 250.0)
        λewpl = bew / (tpl) * sqrt(fy / 250.0)

        # element slenderness
        b = [bef, bef, bew, bew]
        t = [tf, tf, tw, tpl]
        λe = [λef, λef, λew, λewpl]

        # push!(λe, λef)
        # push!(λe, λef)
        # push!(λe, λew)
        # push!(λe, λewpl)

        # limits, axial
        λeyf_axial = get_λey_axialcompression(isBothEndsSupported, stresscode)
        λeyw_axial = get_λey_axialcompression(isBothEndsSupported, stresscode)
        λepf = get_λep(isBothEndsSupported, stresscode, uniformCompression)
        λepw = get_λep(isBothEndsSupported, stresscode, !uniformCompression)
        λepwpl = get_λep(isBothEndsSupported, stresscode, !uniformCompression)
        λeyf = get_λey_bending(isBothEndsSupported, stresscode, uniformCompression)
        λeyw = get_λey_bending(isBothEndsSupported, stresscode, !uniformCompression)
        λeywpl = get_λey_bending(isBothEndsSupported, stresscode, !uniformCompression)

        λey_axial = [λeyf_axial, λeyf_axial, λeyw_axial, λeyw_axial]
        # push!(λey_axial, λeyf_axial)
        # push!(λey_axial, λeyf_axial)
        # push!(λey_axial, λeyw_axial)
        # push!(λey_axial, λeyw_axial)

        # limits per table 5.2 (bending)
        λep = [λepf, λepf, λepw, λepwpl]
        # push!(λep, λepf) #HR
        # push!(λep, λepf) #HR
        # push!(λep, λepw) #HR
        # push!(λep, λepwpl) #HR

        λey_bending = [λeyf, λeyf, λeyw, λeywpl]
        # push!(λey_bending, λeyf) #HR
        # push!(λey_bending, λeyf) #HR  
        # push!(λey_bending, λeyw) #HR  
        # push!(λey_bending, λeywpl) #HR  

        geom = C_sec1 | pl_right
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
        βx_raw = abs(section_analysis.get_beta_p()[1])

        new(d, bf, tf, tw, rr, dpl, tpl, fy, fu, stresscode, geom, Ag, Izp, Iyp, Szp, Syp, Zzp, Zyp,
            rzp, ryp, J, Iw, βx_raw, b, t, λe, λey_axial, λep, λey_bending)
    end
end