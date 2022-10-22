#using ODBC, DataFrames, StructuralCalcUtils

filepath = "D:\\JuliaRepo\\StructuralCalcUtils\\test\\.mdb\\"
xlsxfilename = raw"22131_userdefiend sections.xlsx"
mdbfilename = raw"22131-ST-MOD-04 Truss_grids 2-6-10&11_As-built.MDB"

# @testset "StructuralCalcUtils.jl" begin

@test size(dfMembers(filepath * mdbfilename)) != 0
@test size(dfsection(filepath * mdbfilename)) != 0

# end