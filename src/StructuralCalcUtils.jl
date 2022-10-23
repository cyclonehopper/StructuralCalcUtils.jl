module StructuralCalcUtils



function greet()
    "Hello! - StructuralCalcUtils"
end

#===DESIGN SECTIONS MODULE=====#
using PyCall
pushfirst!(pyimport("sys")."path", "")

include("Design_Sections.jl")
include("Ibeam_plus_bottom_tee.jl")


end # module StructuralCalcUtils
