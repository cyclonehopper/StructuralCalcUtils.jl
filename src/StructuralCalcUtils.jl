module StructuralCalcUtils



# function greet()
#     "Hello! - StructuralCalcUtils"
# end

#===DESIGN SECTIONS MODULE=====#
using PyCall
pushfirst!(pyimport("sys")."path", "")

include("Design_Sections.jl")
include("Ibeam.jl")
include("Ibeam_plus_bottom_tee.jl")
include("Ibeam_plus_bottom_Ibeam.jl")
include("Ibeam_plus_flange_plate.jl")
include("Ibeam_plus_boxing_plate.jl")
include("Ibeam_plus_flange_plate_and_box.jl")
include("Channel_plus_boxing_plate.jl")


end # module StructuralCalcUtils
