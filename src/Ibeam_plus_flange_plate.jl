

export IbeamPlusFlangePlate
struct IbeamPlusFlangePlate <: DesignSections
    d::Float64
    bf::Float64
    tf::Float64
    tw::Float64
    rr::Float64
    bf1::Float64
    tf1::Float64
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

    # function DesignSections(d,bf,tf,tw,rr,d1,bf1,tf1,fy,plateLoc="BOTTOM_OUTSIDE")
    # plateLoc="TOP_OUTSIDE"
    # plateLoc="TOP_AND_BOTTOM_OUTSIDE"
    #     
    # end
    function IbeamPlusFlangePlate(d, bf, tf, tw, rr, bf1, tf1, fy, fu, stresscode, plateLoc="bott")

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
        isBoth = !isOne
        bef = (bf - tw) / 2.0
        λef = bef / tf * sqrt(fy / 250.0)
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
        push!(λe, (d - 2.0 * tf) / (tw) * sqrt(fy / 250.0))
        push!(λey_axial, get_λey_axialcompression(isBoth, stresscode))
        push!(b, d - 2 * tf)
        push!(t, tw)

        # flange plate slenderness, +PL section, assumed both ends restrained only
        λef1 = bf1 / tf1 * sqrt(fy / 250.0)
        push!(λe, λef1)
        push!(λey_axial, get_λey_axialcompression(isBoth, stresscode))
        push!(b, bf1)
        push!(t, tf1)

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
        push!(λep, get_λep(isBoth, stresscode, !uniformCompression)) #HR
        push!(λey_bending, get_λey_bending(isBoth, stresscode, !uniformCompression)) #HR

        # flange pl, +additional PL section, both ends
        push!(λep, get_λep(isBoth, stresscode, uniformCompression)) #HR
        push!(λey_bending, get_λey_bending(isBoth, stresscode, uniformCompression)) #HR

        istop = !isnothing(findfirst("TOP", uppercase(plateLoc)))
        isbottom = !isnothing(findfirst("BOTT", uppercase(plateLoc)))

        # if uppercase(plateLoc) == "TOP_OUTSIDE"
        if (istop & (!isbottom))
            flatpl = pl_top_outside
            geom = isec1 | flatpl
        elseif (istop & isbottom)
            flatpl = pl_bottom_outside
            geom = isec1 | pl_bottom_outside | pl_top_outside

            # flange plate slenderness, +PL section, assumed both ends restrained only
            push!(λe, λef1)
            push!(λey_axial, get_λey_axialcompression(isBoth, stresscode))
            push!(b, bf1)
            push!(t, tf1)

            # flange pl, +additional PL section, both ends
            push!(λep, get_λep(isBoth, stresscode, uniformCompression)) #HR
            push!(λey_bending, get_λey_bending(isBoth, stresscode, uniformCompression)) #HR

        else #BOTTOM DEFAULT
            flatpl = pl_bottom_outside
            geom = isec1 | flatpl
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

        new(d, bf, tf, tw, rr, bf1, tf1, fy, fu, stresscode, plateLoc, geom, Ag, Izp, Iyp, Szp, Syp, Zzp, Zyp,
            rzp, ryp, J, Iw, βx_raw, b, t, λe, λey_axial, λep, λey_bending)
    end
end