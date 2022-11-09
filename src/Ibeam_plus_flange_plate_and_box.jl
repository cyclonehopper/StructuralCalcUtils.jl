

export IbeamPlusFlangePlateAndBox
struct IbeamPlusFlangePlateAndBox <: DesignSections
    d::Float64
    bf::Float64
    tf::Float64
    tw::Float64
    rr::Float64
    bf1::Float64
    tf1::Float64
    dpl::Float64
    tpl::Float64
    fy::Float64
    fu::Float64
    stresscode::String
    flangeplateLoc::String
    sideplateLoc::String
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
    function IbeamPlusFlangePlateAndBox(d, bf, tf, tw, rr, bf1, tf1, dpl, tpl, fy, fu, stresscode, flangeplateLoc, sideplateLoc)

        primitive_sections = pyimport("sectionproperties.pre.library.primitive_sections")
        steel_section = pyimport("sectionproperties.pre.library.steel_sections")
        AnalysisSection = pyimport("sectionproperties.analysis.section")


        isec1 = steel_section.i_section(d=d, b=bf, t_f=tf, t_w=tw, r=rr, n_r=4)
        pl_bottom_outside = primitive_sections.rectangular_section(bf1, tf1).shift_section((bf - bf1) / 2, -tf1)
        pl_top_outside = primitive_sections.rectangular_section(bf1, tf1).shift_section((bf - bf1) / 2, d)


        # The plus value relates to the top flange in compression and the minus value relates to the bottom flange in compression
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
        isBothEndsSupported = !isOne
        λef = (bf - tw) / (2 * tf) * sqrt(fy / 250.0)
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

        # rolled web
        push!(λe, (d - 2.0 * tf) / (tw) * sqrt(fy / 250.0))
        push!(λey_axial, get_λey_axialcompression(isBothEndsSupported, stresscode))
        push!(b, d - 2 * tf)
        push!(t, tw)



        # element slenderness limit per table 5.2 (bending)
        λep = Float64[] #element slenderness
        λey_bending = Float64[] #limits, yield bending
        uniformCompression = true

        # flange outstand 
        λepf = get_λep(isOne, stresscode, uniformCompression)
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR
        push!(λep, λepf) #HR
        λeyf = get_λey_bending(isOne, stresscode, uniformCompression)
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR
        push!(λey_bending, λeyf) #HR  

        # rolled web
        push!(λep, get_λep(isBothEndsSupported, stresscode, !uniformCompression)) #HR
        push!(λey_bending, get_λey_bending(isBothEndsSupported, stresscode, !uniformCompression)) #HR  

        istop = !isnothing(findfirst("TOP", uppercase(flangeplateLoc)))
        isbottom = !isnothing(findfirst("BOTT", uppercase(flangeplateLoc)))
        isTopAndBottom = !isnothing(findfirst("BOTH", uppercase(sideplateLoc)))
        if isTopAndBottom
            istop = true    
            isbottom = true
        end

        # if uppercase(plateLoc) == "TOP_OUTSIDE"
        geom = isec1
        if istop
            flatpl = pl_top_outside
            geom = geom | flatpl
            # flange plate slenderness, +PL section, assumed both ends restrained only 
            push!(b, bf1)
            push!(t, tf1)
            λef1 = bf1 / tf1 * sqrt(fy / 250.0)
            push!(λe, λef1)
            push!(λey_axial, get_λey_axialcompression(isBothEndsSupported, stresscode))
            push!(λep, get_λep(isBothEndsSupported, stresscode, uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothEndsSupported, stresscode, uniformCompression)) #HR
        end
        if isbottom
            flatpl = pl_bottom_outside
            geom = geom | flatpl
            # flange plate slenderness, +PL section, assumed both ends restrained only 
            push!(b, bf1)
            push!(t, tf1)
            λef1 = bf1 / tf1 * sqrt(fy / 250.0)
            push!(λe, λef1)
            push!(λey_axial, get_λey_axialcompression(isBothEndsSupported, stresscode))
            push!(λep, get_λep(isBothEndsSupported, stresscode, uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothEndsSupported, stresscode, uniformCompression)) #HR
        end

        # SIDE PLATE PORtION
        pl_left = primitive_sections.rectangular_section(tpl, dpl).shift_section(-tpl, tf / 2.0)
        pl_right = primitive_sections.rectangular_section(tpl, dpl).shift_section(bf, tf / 2.0)

        isRight = !isnothing(findfirst("RIGHT", uppercase(sideplateLoc)))
        isLeft = !isnothing(findfirst("LEFT", uppercase(sideplateLoc)))
        isRightAndLeft = !isnothing(findfirst("BOTH", uppercase(sideplateLoc)))
        if isRightAndLeft
            isRight = true
            isLeft = true
        end
        bew = (d - 2.0 * tf)
        # if uppercase(sideplateLoc) == "TOP"
        if (isRight)
            flatpl = pl_right
            geom = geom | flatpl

            # SIDE plate slenderness, +PL section, assumed both ends restrained only
            push!(b, bew)
            push!(t, tpl)
            push!(λe, bew / tpl * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothEndsSupported, stresscode))
            push!(λep, get_λep(isBothEndsSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothEndsSupported, stresscode, !uniformCompression)) #HR
        end

        if (isLeft)
            flatpl = pl_left
            geom = geom | flatpl
            # SIDE plate slenderness, +PL section, assumed both ends restrained only
            push!(b, bew)
            push!(t, tpl)
            push!(λe, bew / tpl * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothEndsSupported, stresscode))
            push!(λep, get_λep(isBothEndsSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothEndsSupported, stresscode, !uniformCompression)) #HR
        end


        # geom = isec1 | isec2
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

        new(d, bf, tf, tw, rr, bf1, tf1, dpl, tpl, fy, fu, stresscode, flangeplateLoc, sideplateLoc, geom, Ag, Izp, Iyp, Szp, Syp, Zzp, Zyp,
            rzp, ryp, J, Iw, βx_raw, b, t, λe, λey_axial, λep, λey_bending)
    end
end