

export IbeamPlusBoxingPlate
struct IbeamPlusBoxingPlate <: DesignSections
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
    plateLoc::String
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

    # function DesignSections(d,bf,tf,tw,rr,d1,bf1,tf1,fy,plateLoc="")
    # plateLoc="TOP" = on the + side of major principal axis
    # plateLoc="BOTT" = on the - side of major axis     
    # plateLoc="BOth" = on the + & - side of major axis     
    # end
    function IbeamPlusBoxingPlate(d, bf, tf, tw, rr, dpl, tpl, fy, fu, stresscode="HW", plateLoc="both")

        primitive_sections = pyimport("sectionproperties.pre.library.primitive_sections")
        steel_section = pyimport("sectionproperties.pre.library.steel_sections")
        AnalysisSection = pyimport("sectionproperties.analysis.section")


        isec1 = steel_section.i_section(d=d, b=bf, t_f=tf, t_w=tw, r=rr, n_r=4)
        pl_left = primitive_sections.rectangular_section(tpl, dpl).shift_section(-tpl, tf / 2.0)
        pl_right = primitive_sections.rectangular_section(tpl, dpl).shift_section(bf, tf / 2.0)


        # The plus value relates to the top flange in compression and the minus value relates to the bottom flange in compression
        b = Float64[] #element length
        t = Float64[] #element thickness     
        λe = Float64[] #element slenderness
        λey_axial = Float64[] #limits, yield compression         
        λep = Float64[] #element slenderness
        λey_bending = Float64[] #limits, yield bending
        uniformCompression = true

        # λsy = Float64[] #section slenderness, yield
        # λsp = Float64[] #section slenderness. plastic
        # λep = Float64[] #element slenderness limit, plastic
        bef = (bf - tw) / 2.0
        λef = (bef / tf) * sqrt(fy / 250.0)
        bew = (d - 2.0 * tf)

        isOutstand = true
        isBothSupported = !isOutstand

        # λef_both = (bf - tw) / (2 * tf) * sqrt(fy / 250.0)
        λeyf_axial_one = get_λey_axialcompression(isOutstand, stresscode)
        λeyf_axial_both = get_λey_axialcompression(isBothSupported, stresscode)
        λepf_outstand = get_λep(isOutstand, stresscode, uniformCompression)
        λepf_both = get_λep(isBothSupported, stresscode, uniformCompression)
        λeyf_bending_one = get_λey_bending(isOutstand, stresscode, uniformCompression)
        λeyf_bending_both = get_λey_bending(isBothSupported, stresscode, uniformCompression)


        isRight = !isnothing(findfirst("RIGHT", uppercase(plateLoc)))
        isLeft = !isnothing(findfirst("LEFT", uppercase(plateLoc)))
        isLeftandright = !isnothing(findfirst("BOTH", uppercase(plateLoc)))
        if isLeftandright
            isRight = true
            isLeft = true
        end

        geom = isec1
        # FOR ADDITIONAL SIDE PLATES
        if (isLeft & isRight)
            geom = geom | pl_left | pl_right
            # rolled section slenderness
            push!(b, bef)
            push!(b, bef)
            push!(b, bef)
            push!(b, bef)
            push!(t, tf)
            push!(t, tf)
            push!(t, tf)
            push!(t, tf)
            push!(λe, λef)
            push!(λe, λef)
            push!(λe, λef)
            push!(λe, λef)
            push!(λey_axial, λeyf_axial_both) # 4*both
            push!(λey_axial, λeyf_axial_both)
            push!(λey_axial, λeyf_axial_both)
            push!(λey_axial, λeyf_axial_both)
            push!(λep, λepf_both) #HR 1*one
            push!(λep, λepf_both) #HR
            push!(λep, λepf_both) #2*both
            push!(λep, λepf_both) #HR
            push!(λey_bending, λeyf_bending_both) #HR
            push!(λey_bending, λeyf_bending_both) #HR
            push!(λey_bending, λeyf_bending_both) #HR
            push!(λey_bending, λeyf_bending_both) #HR        
            # rolled web 
            push!(b, bew)
            push!(t, tw)       
            push!(λe, bew / tw * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR
            # SIDE plate slenderness, +PL section, assumed both ends restrained only
            push!(b, bew)
            push!(b, bew)
            push!(t, tpl)
            push!(t, tpl)
            push!(λe, bew / tpl * sqrt(fy / 250.0))
            push!(λe, bew / tpl * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR


        elseif (isLeft)
            geom = geom | pl_left

            # rolled section slenderness
            
            push!(b, bef)
            push!(b, bef)
            push!(b, bef)
            push!(b, bef)
            push!(t, tf)
            push!(t, tf)
            push!(t, tf)
            push!(t, tf)
            push!(λe, λef)
            push!(λe, λef)
            push!(λe, λef)
            push!(λe, λef)
            push!(λey_axial, λeyf_axial_one) # 4*both
            push!(λey_axial, λeyf_axial_one)
            push!(λey_axial, λeyf_axial_both)
            push!(λey_axial, λeyf_axial_both)
            push!(λep, λepf_outstand) #HR 1*one
            push!(λep, λepf_outstand) #HR
            push!(λep, λepf_both) #2*both
            push!(λep, λepf_both) #HR
            push!(λey_bending, λeyf_bending_one) #HR
            push!(λey_bending, λeyf_bending_one) #HR
            push!(λey_bending, λeyf_bending_both) #HR
            push!(λey_bending, λeyf_bending_both) #HR        
            # rolled web 
            push!(b, bew)
            push!(t, tw)       
            push!(λe, bew / tw * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR

            # SIDE plate slenderness, +PL section, assumed both ends restrained only
            push!(b, bew)
            push!(t, tpl)push!(λe, bew / tpl * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR

        elseif (isRight)
            geom = geom | pl_right

            # rolled section slenderness
            
            push!(b, bef)
            push!(b, bef)
            push!(b, bef)
            push!(b, bef)
            push!(t, tf)
            push!(t, tf)
            push!(t, tf)
            push!(t, tf)
            push!(λe, λef)
            push!(λe, λef)
            push!(λe, λef)
            push!(λe, λef)
            push!(λey_axial, λeyf_axial_one) # 4*both
            push!(λey_axial, λeyf_axial_one)
            push!(λey_axial, λeyf_axial_both)
            push!(λey_axial, λeyf_axial_both)
            push!(λep, λepf_outstand) #HR 1*one
            push!(λep, λepf_outstand) #HR
            push!(λep, λepf_both) #2*both
            push!(λep, λepf_both) #HR
            push!(λey_bending, λeyf_bending_one) #HR
            push!(λey_bending, λeyf_bending_one) #HR
            push!(λey_bending, λeyf_bending_both) #HR
            push!(λey_bending, λeyf_bending_both) #HR        
            # rolled web
            push!(b, bew)
            push!(t, tw)        
            push!(λe, bew / tw * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR

            # SIDE plate slenderness, +PL section, assumed both ends restrained only
            push!(b, bew)
            push!(t, tpl)
            push!(λe, bew / tpl * sqrt(fy / 250.0))
            push!(λey_axial, get_λey_axialcompression(isBothSupported, stresscode))
            push!(λep, get_λep(isBothSupported, stresscode, !uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBothSupported, stresscode, !uniformCompression)) #HR

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

        new(d, bf, tf, tw, rr, dpl, tpl, fy, fu, stresscode, plateLoc, geom, Ag, Izp, Iyp, Szp, Syp, Zzp, Zyp,
            rzp, ryp, J, Iw, βx_raw, b, t, λe, λey_axial, λep, λey_bending)
    end
end