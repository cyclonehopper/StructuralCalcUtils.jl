abstract type DesignSections end

#===FUNCTIONS TO OPERATE ON DESIGNSECTIONS TYPE====#
export get_Ag
function get_Ag(s::DesignSections)
    return s.Ag
end

#Function to get correct βx depending on which flange is in compression
function fβx(tMu, IsBottomFlangeLarger, s::DesignSections)
    if IsBottomFlangeLarger == 0 #symmetrical
        βx = 0.0
    else
        if tMu > 0.0 # top compression
            if IsBottomFlangeLarger > 0
                βx = -(s.βx_raw) #-ve = additional plte is in bottom flange
            else
                βx = +(s.βx_raw) #-ve = additional plte is in bottom flange				
            end
        else #bottom compression
            if IsBottomFlangeLarger > 0
                βx = -(s.βx_raw) #-ve = additional plte is in bottom flange
            else
                βx = +(s.βx_raw) #-ve = additional plte is in bottom flange				
            end
        end
    end

    return βx
    # return  (sqrt(π^2 * E* Iyp / leb^2) * (sqrt(G*J + π^2 *E*Iw/leb^2 + βx^2*π^2/4 * E*Iyp/leb^2) + βx/2.0 * sqrt(π^2 * E* Iyp / leb^2))) / 1000.0^2
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

#===END OF DESIGN SECTION MODULES===#