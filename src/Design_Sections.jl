abstract type DesignSections end

#===FUNCTIONS TO OPERATE ON DESIGNSECTIONS TYPE====#


export get_Ag
function get_Ag(s::DesignSections)
    return s.Ag
end


export get_λey_axialcompression
function get_λey_axialcompression(isOutstand::Bool, stresscode::String)
    if isOutstand
        if uppercase(stresscode) == "HR"
            return 16.0
        else #HW
            return 14.0
        end
    else
        if uppercase(stresscode) == "HR"
            return 45.0
        else #HW
            return 35.0
        end
    end
end

export get_λep
function get_λep(isOutstand::Bool, stresscode::String, isUniformCompression::Bool)
    if isOutstand #uniform compression or not
        if uppercase(stresscode) == "HR"
            return 9.0
        else #HW
            return 8.0
        end
    else #both
        if isUniformCompression
            return 30.0
        else
            return 82.0
        end
    end
end

export get_λey_bending
function get_λey_bending(isOutstand::Bool, stresscode::String, isUniformCompression::Bool)
    if isOutstand #uniform compression or not
        if isUniformCompression
            if uppercase(stresscode) == "HR"
                return 16.0
            else #HW
                return 14.0
            end
        else
            if uppercase(stresscode) == "HR"
                return 25.0
            else #HW
                return 22.0
            end
        end

    else
        if isUniformCompression
            if uppercase(stresscode) == "HR"
                return 45.0
            else #HW
                return 35.0
            end
        else
            return 115.0
        end
    end
end

# negative area
export fδArea
function fδArea(b::Float64, t::Float64, λe::Float64, λey::Float64)
    Δb = min(b, b * λey / λe) - b
    return Δb * t
end

# form factor
export fkf
function fkf(s::DesignSections)
    # vb, vt, vλe, vλey, Ag
    aneg = sum(fδArea.(s.b, s.t, s.λe, s.λey_axial))
    return 1.0 + aneg / s.Ag
end

# section axial capacity
export fϕNs
function fϕNs(kf::Float64, Ag::Float64, fy::Float64)
    # in kN
    return 0.9 * kf * Ag * fy / 1000.0
end

#slenderness factor αc
export fαc
function fαc(klr::Float64, fy::Float64, αb::Float64, kf::Float64)
    λn = klr * sqrt(kf) * sqrt(fy / 250.0)
    αa = 2100 * (λn - 13.5) / (λn^2 - 15.3 * λn + 2500.00)
    λ = λn + αa * αb
    η = 0.00326 * (λ - 13.5)
    ξ = ((λ / 90.0)^2 + 1 + η) / (2.0 * (λ / 90.0)^2)
    return ξ * (1.0 - sqrt(1.0 - (90.0 / (ξ * λ))^2))
end

# member axial capacity
export fϕNc
function fϕNc(αc::Float64, ϕNs::Float64)
    min(1.0, αc) * ϕNs
end

# effective section modulus
export fZe
function fZe(s::DesignSections)
    # fZe(λe, λep, λeyb, Szp, Zzp)
    # compact if rλ < 1.0
    rλ = s.λe ./ s.λep
    # non-compact if rλ_slender < 1.0
    rλ_slender = s.λe ./ s.λey_bending

    # compact section modulus
    Zc = min(s.Szp, 1.5 * s.Zzp)

    # critical slenderness
    iλmax = findmax(rλ)[2]

    if maximum(rλ) < 1.0
        # isCompact = true
        return Zc
    elseif maximum(rλ_slender) < 1.0
        # isCompact = false
        λs = s.λe[iλmax]
        λsy = s.λey_bending[iλmax]
        λsp = s.λep[iλmax]
        return s.Zzp + ((λsy - λs) / (λsy - λsp)) * (Zc - s.Zzp)
    else
        # "slender section"
        λs = s.λe[iλmax]
        λsy = s.λey_bending[iλmax]
        return s.Zzp * (λsy / λs)^2
    end
end

#region ======================== 8.3 - SECTION CAPACITY

# 8.3.2 - Uniaxial bending about major axis, tension of compresion
function fϕMrx(Nu::Float64, ϕMsx::Float64, ϕNs::Float64)
    return ϕMsx * (1.0 - abs(Nu) / ϕNs)
end

function fϕMry(Nu::Float64, ϕMsy::Float64, ϕNs::Float64)
    return ϕMsy * (1.0 - abs(Nu) / ϕNs)
end

#endregion



# nominal section bending capacity

export fMsx
function fMsx(s::DesignSections)
    Ze = fZe(s)
    return Ze * s.fy / (1000.0^2)
end
export fϕMsx
function fϕMsx(s::DesignSections)
    Ze = fZe(s)
    return 0.9 * fMsx(s)
end
# calculate interaction ratio
# COMBINED ACTIONS - cl. 8.4.2.2 - Member subject to in-plane major axis bending + compression
export fϕMi
function fϕMi(Nu::Float64, ϕMs::Float64, ϕNc::Float64)
    return ϕMs * (1.0 - Nu / ϕNc)
end

export fr_ix
function fr_ix(Nu::Float64, Mux::Float64, ϕNcx::Float64, ϕMsx::Float64)
    if (Nu > 0.0)
        return abs(Mux) / ϕMsx + Nu / ϕNcx
    else
        return -1.0 # to keep the proper index when searhing later of critical load case
    end
end

#Function to get correct βx depending on which flange is in compression
export fβx
# 1=yes, 0=symmetrical, -1=no
# tMu = +ve=> top flange compresion per SG model
function fβx(tMu::Float64, IsBottomFlangeLarger::Int64, s::DesignSections)
    if IsBottomFlangeLarger != 0 #symmetrical
        if tMu > 0.0 # top compression
            if IsBottomFlangeLarger > 0
                βx = -(s.βx_raw) # shoulde be neg β
            else
                βx = (s.βx_raw) #-ve = additional plte is in bottom flange				
            end
        elseif tMu < 0.0 #bottom compression
            if IsBottomFlangeLarger > 0
                βx = (s.βx_raw) #-ve = additional plte is in bottom flange
            else
                βx = -(s.βx_raw) #-ve = additional plte is in bottom flange				
            end
        else
            βx = 0.0
        end
    else
        βx = 0.0
    end

    return βx
    # return  (sqrt(π^2 * E* Iyp / leb^2) * (sqrt(G*J + π^2 *E*Iw/leb^2 + βx^2*π^2/4 * E*Iyp/leb^2) + βx/2.0 * sqrt(π^2 * E* Iyp / leb^2))) / 1000.0^2
end

#Function to get correct βx and Mo, depending on which flange is in compression
export fMo
function fMo(s::DesignSections, Mux::Float64, IsBottomFlangeLarger::Int64, lebtop::Float64, lebbott::Float64)
    βx = fβx(Mux, IsBottomFlangeLarger, s) #get sign of βx
    J = s.J
    Iw = s.Iw
    Iyp = s.Iyp
    # shear modulus of steel
    G = 80.0e3
    # Youngs modulus
    E = 200.0e3

    if Mux > 0.0 # top flange compresion per SG sign convention
        return (sqrt(π^2 * E * Iyp / lebtop^2) * (sqrt(G * J + π^2 * E * Iw / lebtop^2 + βx^2 * π^2 / 4 * E * Iyp / lebtop^2) + βx / 2.0 * sqrt(π^2 * E * Iyp / lebtop^2))) / 1000.0^2
    else
        return (sqrt(π^2 * E * Iyp / lebbott^2) * (sqrt(G * J + π^2 * E * Iw / lebbott^2 + βx^2 * π^2 / 4 * E * Iyp / lebbott^2) + βx / 2.0 * sqrt(π^2 * E * Iyp / lebbott^2))) / 1000.0^2
    end
end

# αs = 0.6*(sqrt((Msz / Mo)^2 + 3.0) - Msz/Mo) #slenderness factor
export fαs
function fαs(Mo::Float64, Msx::Float64)
    return 0.6 * (sqrt((Msx / Mo)^2 + 3.0) - Msx / Mo)
end
function fαs(Mo::Float64, s::DesignSections)
    Msx = fMsx(s)
    return 0.6 * (sqrt((Msx / Mo)^2 + 3.0) - Msx / Mo)
end

# Mbz = min(1.0, αs * αm) * Msz  #nominal bending capacity
# call as
# fMbz.(Muz, Msz, lebtop, lebbott, IsBottomFlangeLarger, Ref(s), αm) , the Ref() keyword is required 
# to make the s variable a scalar
export fMbx
function fMbx(Mu::Float64, Msx::Float64, lebtop::Float64, lebbott::Float64, IsBottomFlangeLarger::Int64, s::DesignSections, αm::Float64)
    Mo = fMo(s, Mu, IsBottomFlangeLarger, lebtop, lebbott)
    αs = fαs(Mo, Msx)
    return min(1.0, αs * αm) * Msx
end
export fϕMbx
function fϕMbx(Mu::Float64, Msx::Float64, lebtop::Float64, lebbott::Float64, IsBottomFlangeLarger::Int64, s::DesignSections, αm::Float64)
    return 0.9 * fMbx(Mu, Msx, lebtop, lebbott, IsBottomFlangeLarger, s, αm)
end

# COMBINED ACTIONS - cl. 8.4.4 - Member subject to  major axis bending  and may buckle laterally

export fr_ox
function fr_ox(Nu::Float64, ϕNcy::Float64, Mux::Float64, ϕMbx::Float64)
    if (Nu > 0.0) #compresion only
        return abs(Mux) / ϕMbx + Nu / ϕNcy
    else
        return -1.0 #just to maintain indexing/order
    end
end

export fϕMox
# clause 8.4.4.1 - Member in compression
function fϕMox(Nu::Float64, ϕNcy::Float64, ϕMbx::Float64)
    if (Nu > 0.0) #compression only
        return ϕMbx * (1.0 - Nu / ϕNcy)
    else
        return -1.0 #just to maintain indexing/order
    end
end

export fϕMoxt
# clause 8.4.4.2 - member in tension
function fϕMoxt(Nu::Float64, ϕNt::Float64, ϕMbx::Float64)
    if (Nu > 0.0) #compression only
        return ϕMbx * (1.0 - Nu / ϕNt)
    else
        return -1.0 #just to maintain indexing/order
    end
end


# COMBINED ACTIONS - Cl 8.4.2.3=>refer 8.3.2 - Uniaxial Bending about major axis + tension
export fϕNt
function fϕNt(kt::Float64, s::DesignSections)
    An = s.Ag #ignore holes
    return 0.9 * min(0.85 * kt * An * s.fu, s.Ag * s.fy) / 1000.0 #nominal tension capacity, kN
end

# interaction ratio
export fr_ixt
function fr_ixt(Nut::Float64, ϕNt::Float64, Mux::Float64, ϕMsx::Float64)
    if (Nut < 0.0) #check tension cases only; -ve = tension in sg model
        return abs(Mux) / ϕMsx - Nut / ϕNt
    else
        return -1.0
    end
end

# COMBINED ACTIONS - Cl 8.4.4.2 - Uniaxial Bending about major axis that may buckle alterally + tension
# interaction ratio
export fr_oxt
function fr_oxt(Nut::Float64, ϕNt::Float64, Mux::Float64, ϕMbx::Float64)
    if (Nut < 0.0) #check tension cases only 
        # Mbz = fMbz(Muz, Msz, lebtop, lebbott, IsBottomFlangeLarger, s, αm)
        return abs(Mux) / ϕMbx - (Nut / ϕNt)
    else
        return -1.0
    end

end

# 8.4.5 - BIAXIAL Bending
# 8.4.5.1 - COMPRESSION MEMBERS
export fr_cxiy
function fr_cxiy(Nu::Float64, Mux::Float64, Muy::Float64, ϕNcx::Float64, ϕNcy::Float64, ϕMsx::Float64, ϕMbx::Float64, ϕMsy::Float64)
    ϕMix = ϕMsx * (1.0 - Nu / ϕNcx)
    ϕMiy = ϕMsy * (1.0 - Nu / ϕNcy)
    ϕMox = fϕMox(Nu, ϕNcy, ϕMbx)
    ϕMcx = min(ϕMix, ϕMox)
    return (Mux / ϕMcx)^1.4 + (Muy / ϕMiy)^1.40
end

# 8.4.5.2 - TENSION MEMBERS

export fr_txry
function fr_txry(Nu::Float64, Mux::Float64, Muy::Float64, ϕNt::Float64, ϕMsy::Float64, ϕMsx::Float64m, ϕMbx::Float64)
    ϕMry = fϕMry(Nu, ϕMsy, ϕNt)
    ϕMrx = fϕMry(Nu, ϕMsx, ϕNt)
    ϕMoxt = fϕMoxt(Nu, ϕNt, ϕMbx)
    ϕMtx = min(ϕMrx, ϕMoxt)
    return (Mux / ϕMtx)^1.4 + (Muy / ϕMry)^1.40
end












#===END OF DESIGN SECTION MODULES===#