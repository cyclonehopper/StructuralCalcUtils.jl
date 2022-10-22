### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# ╔═╡ 8a1a24de-5286-422d-9beb-5357f72556d8
using ODBC, DataFrames, XLSX, Query

# ╔═╡ 4d06b88a-5d4a-425f-9524-c85e5d8557e4
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 2400px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ 4b8407b8-16de-4bd3-b2ea-bf307a15eee4
md"""
DESIGN PARAMETERS
"""

# ╔═╡ d761b6ef-4f2e-4cf4-a095-2ac5322d8d95
isBucklingLength = true
#isBucklingLength = false

# ╔═╡ 569feb5e-28f1-4450-ad29-4a114b11147c
#memb = Int32(34) #design member
memb = Int32(86) #design member

# ╔═╡ 3a4ac77f-3689-46a0-92eb-93cda8122e19
	ky=1.0

# ╔═╡ 8535ab55-b5a0-4736-9986-0849e52e7671
kz=1.0

# ╔═╡ 7f2b353f-e36b-4a8c-a52f-83434c83fed6
fypl = 250.0

# ╔═╡ b6be4e06-2ade-4062-b5e7-184c3d89a0b5
	filename = raw"22131-ST-MOD-04 Truss_grids 2-6-10&11_As-built.MDB"


# ╔═╡ 2b0b6010-5b83-415d-bc5f-d6574dce7c74
	filepath = "D:\\JuliaRepo\\StructuralCalcUtils\\test\\.mdb\\"

# ╔═╡ caff658b-ca3b-45e0-87e3-704111a3fe44
begin
	filepathname = filepath *filename
	statement ="Driver={Microsoft Access Driver (*.mdb, *.accdb)}; Dbq="  * filepathname
	dbconn = ODBC.Connection(statement)		
end


# ╔═╡ f99ac100-5fcf-4f79-8e29-bea36b818349
md"""
Database/Dataframes queries
"""

# ╔═╡ 4102e85a-d5f5-4cf8-8ec1-4c4c00e72747
begin
	queryDesignMember = DBInterface.execute(dbconn, "SELECT * FROM `Steel Member Design`" )
	dfDesignMember = DataFrame(queryDesignMember) 

	membstring = 	dfDesignMember[dfDesignMember."Group" .== memb, Symbol("Member List")][1]	
	memblist32 = parse.(Int32, split(membstring, ","))
	memblist16 = parse.(Int16, split(membstring, ","))
	queryMembers = DBInterface.execute(dbconn, "SELECT * FROM Members");	
	dfMembers=filter(i -> i.Member in memblist32, DataFrame(queryMembers))

	querySecprops = DBInterface.execute(dbconn, "SELECT * FROM `Section Properties`");
	dfSecprop = DataFrame(querySecprops)

	queryBuklingLengths = DBInterface.execute(dbconn, "SELECT * FROM `Buckling Effective Lengths`" )	
	dfBucklingLengths = filter(i -> i.Memb in memblist16, DataFrame(queryBuklingLengths))
	#dfBucklingLengths = filter(i -> i.Memb .==memb, DataFrame(queryBuklingLengths))

	Lcomb_with_bcklingLength = dfBucklingLengths[: , Symbol("Load Case")]
	queryForces = DBInterface.execute(dbconn, "SELECT * FROM `Member Intermediate Forces and Moments`");
	dfForces = filter(i -> i.Member in memblist32 && i.Case in Lcomb_with_bcklingLength , DataFrame(queryForces))

	secnum= dfMembers[!, :"Section"][1]
	secname = dfSecprop[dfSecprop.Section .== secnum, :"Name"][1]
	
	#userdef lib import
	xlsfilename = raw"22131_userdefiend sections.xlsx"
	xlssheetname="22131"
	df = dropmissing(DataFrame(XLSX.readtable(filepath*xlsfilename,xlssheetname,"A:AO",first_row=3)), :Name);
	dfsection=df[(df.Name .== secname) ,:] 
	""
	l0 = 0.0
	for i in eachindex(memblist16)
		l0 = l0 + dfBucklingLengths[i,Symbol("Length (m)")] *1000.0
	end
	l0
	
end

# ╔═╡ b9e90e5e-f660-412f-ba66-f4e65b7c2153


# ╔═╡ 42c723ce-f6a7-44e5-93b1-1b1228b0112c
md"""
Design member list
"""

# ╔═╡ 5566ab3f-7698-4eb9-9085-bdbfbc8aa4bb
 
memblist16 
 


# ╔═╡ d5f167dc-cd0a-4dec-80fb-b279651c68e1
md"""
Design member physical length
"""

# ╔═╡ d8589658-f585-4a69-bf7f-6cb98a724f23
dfMembers

# ╔═╡ 03623d8b-efc3-4cb0-a9a5-e81cd0bd9b29
l0

# ╔═╡ a41aff43-3e16-4be9-a05e-276f715e0794
md"""
Section name / properties
"""

# ╔═╡ f64c3a86-a819-47e8-8908-098e20f0d2df
secnum

# ╔═╡ f6a17cbf-d588-4e8e-859d-34d774722045
secname 

# ╔═╡ 83a231a7-100f-474a-ab1b-7740102503d1
dfsection

# ╔═╡ 59b829e8-9813-4c7f-aa42-db7c77073a9c
begin 
	tf = dfsection[dfsection."Shape Type" .== "I or H Section" , Symbol("Tt")][1]
	tw = dfsection[dfsection."Shape Type" .== "I or H Section" , Symbol("Tw")][1]
	d = dfsection[dfsection."Shape Type" .== "I or H Section" , Symbol("D")][1]
	bf = dfsection[dfsection."Shape Type" .== "I or H Section" , Symbol("Bt")][1]
	tpl = dfsection[2, Symbol("Bt")]
	dpl = dfsection[2, Symbol("D")]
	tplf = dfsection[3, Symbol("D")]
	dplf = dfsection[3, Symbol("Bt")]	
	Ag = dfsection[!, Symbol("A")][1]
	Iyp = dfsection[!, Symbol("Iyp")][1]
	Syp = dfsection[!, Symbol("Syp")][1]

	Cz = dfsection[1, Symbol("Cz")][1]
	Zyp = Iyp / (bf + tpl)/2.0          #check
	Izp = dfsection[!, Symbol("Izp")][1]
	Szp = dfsection[!, Symbol("Szp")][1]
	Zzp = Izp / ((d)/2.0)                         #check  
	" "
end

# ╔═╡ 74987af5-d064-4cfe-acba-3187bfaad982
md"""
Design Forces
"""

# ╔═╡ c704bb77-2716-4331-af39-400ddd49b72d
Lcomb = dfForces[:, Symbol("Case")]

# ╔═╡ 9093d960-2f84-40da-9107-60882b0c1643
begin
	
	if isBucklingLength	
		lby = dfBucklingLengths[:, Symbol("Ly (m)")] * 1000.0 
		lbz = dfBucklingLengths[: , Symbol("Lz (m)")] * 1000.0
	
		#dfForces = filter(i -> i.Case in Lcomb_in_compression, DataFrame(queryForces))
		
		#dfForces = filter(i -> i.Member in memblist  & i.Case in Lcomb_in_compression , DataFrame(queryForces))
	
		#Lcomb = filter(i -> i in Lcomb_in_compression , dfForces[:, Symbol("Case")])
	else
		#dfForces = filter(i -> i.Member in memblist , DataFrame(queryForces))
	
		#Lcomb = dfForces[!, Symbol("Case")]
	
	end

end

# ╔═╡ 0aa2f72d-6c68-4a7f-a836-8c0aa1c1beaf
#Nu = dfForces[!, Symbol("Axial Force (kN)")] ;
Nu =  dfForces[!, Symbol("Axial Force (kN)")];

# ╔═╡ 5d2ef5c8-7aac-45dd-9636-b9922b4ec7ea
Muy = dfForces[!, Symbol("Y-Axis Moment (kNm)")] ;


# ╔═╡ cf721528-b339-4c6b-a8e4-deebebaa6805
Muz = dfForces[!, Symbol("Z-Axis Moment (kNm)")] ;


# ╔═╡ 2da1e548-f435-47d0-8145-7bedd956f752
LcombUnique = unique(Lcomb)

# ╔═╡ d27a5785-145e-486b-98f6-75b69462c379
md"""
MEMBER COMPRESION 
"""

# ╔═╡ 5e679779-6bdb-413e-ad17-d43a66e70a36
md"""
Check element slenderness
"""

# ╔═╡ 5d143565-bfc9-489b-83f0-548a18bd1e2e
md"""
Flat element slenderness, λe
"""

# ╔═╡ 92fc91b4-8d6f-469b-a278-54092b2f6a70
begin
	#order of vector of slendernes
	#flange/both/HW - rolled section
	#web/both/HR - rolled I or H section
	#coverpl/both/HW - additional plate
	bf1 = (bf-tw)
	d1 = (d-2*tf)	
	vfy = fypl
	λe = [bf1/tf, d1/tw,d1/tpl ] .* vfy / 250.0

end	

# ╔═╡ 4daad385-e149-429c-b927-6fff6d037295
	# limits
	λey = [35.0,45.0,35.0]

# ╔═╡ 63fa26bd-e8bc-48de-b335-7004d14bdb7a
md"""
Nominal section axial compression capacity
"""

# ╔═╡ b37ef3f5-31c9-4357-9a26-abb64fa9a609
begin
	#check effective width, update area if element is slender
	function fδArea(b, t, λe, λey)
		Δb =b - min(b, b * λey / λe)
		return Δb * t
	end
	#functIon to calculate the portion of b that exceeds the slenderness limit
	#Flanges negative areas, if slender  
	afneg = 4.0 * fδArea(bf1,tf, λe[1], λey[1])
	awneg =  fδArea(d1,tw, λe[2], λey[2])
	aplneg = 2.0 * fδArea(d1,tpl, λe[3], λey[3])
	Ae = Ag -(afneg + awneg + aplneg)
	kf = Ae / Ag
	#assume no penetrations for now
	ϕNs = 0.9 * kf * Ag * fypl / 1000.0

end

# ╔═╡ 13fab070-b1ef-4687-98fd-0c11009738b8
md"""
MEMBER CAPACITY
"""

# ╔═╡ 2d613571-101a-4c98-a1b2-3bad223e96d0
begin 
	function fαc(klr, fy, αb)
		λn = klr * fy / 250.0		
		αa = 2100 * (λn -13.5) / (λn^2 -15.3*λn + 2500.00)
		λ = λn + αa * αb
		η = 0.00326*(λ -13.5)
		ξ = ((λ/90.0)^2 + 1 + η) / (2.0* (λ/90.0)^2)
		return ξ * (1.0 - sqrt(1.0 - (90.0/(ξ * λ))^2 ))
	end
end

# ╔═╡ 98ec4bbe-d04b-4289-bc68-1387b6672d19
ry = sqrt(Iyp / Ag)

# ╔═╡ 085ec544-1bd5-4101-b134-fafec9c3b32f
rz = sqrt(Izp / Ag)

# ╔═╡ 19b9e242-ce67-4bc6-b115-57cb97bdbef5
l0

# ╔═╡ 35e1e519-9691-4cdf-be87-abcf19d9f384
lby

# ╔═╡ a289b997-6762-4ec2-9d06-e0dcf0d7fee8
lbz

# ╔═╡ 9432fe7d-6516-4336-9519-0d1aeb7ceef7
if isBucklingLength  
	kler = max.(lby/ry, lbz/rz)
else 
	kler = max(ky * l0 / ry, kz * l0 / rz )
end

# ╔═╡ 81e714f5-162a-4e71-a07c-b7973069ee56
	αb = 0.0 # for a welded box, table 6.3.3(A)

# ╔═╡ 3c34f236-c5fd-45d1-9956-ed658e501132
	αc = fαc.(kler  , fypl, αb)

# ╔═╡ e8e99ddf-599d-460b-b650-930836f6943d
ϕNc = αc * ϕNs #in kN

# ╔═╡ d56b1995-6fe7-4ae4-a0ed-d56085c713d4
md"""
COMBINED ACTIONS - member subject to minor axis bending only + compression
"""

# ╔═╡ 5e89e9dc-007f-4fe9-823b-f52bf3959b8d
md"""
Section Slendernes, check compactness 
"""

# ╔═╡ 21799646-2cb8-4533-af02-3b65ba2606f6
λe

# ╔═╡ 2190ef78-058e-433f-b00e-70ee0ecf48e0
λep = [30.0,30.0,30.0]  #refer Table 5.2

# ╔═╡ 4acaadc5-9ed2-456a-a2ca-813a3e38e29d
rλ = λe ./ λep

# ╔═╡ 7be47e10-aab0-4358-83db-429a76bd9819
	Zcy = min(Syp, 1.5*Zyp)  #compact Ze


# ╔═╡ c0f9baee-42b3-4724-9eb3-ffe866f8d441
md"""
Effective section modulus, Zey
"""

# ╔═╡ e5d431cd-7c6f-498f-9550-f251fa34854a
if maximum(rλ) < 1.0
	isCompact = true
	Zey = Zcy
else
	iλmax = findmax(rλ)[2]
	isCompact = false
	λs = λe[iλmax]
	λsp = λep[iλmax]
	λsy = λey[iλmax]	
	Zey = Zyp + ((λsy-λs)/(λsy - λsp)) * (Zcy - Zyp)
end

# ╔═╡ ec841995-b1e4-4116-b9c2-0c971fc7f2bc
ϕMsy =0.9 * fypl * Zey / 1.0e6

# ╔═╡ 14220020-82f2-4137-b064-1310aae87846
#function to calculate interaction ratio for compression + minor axis bending
begin
	rcy = Float64[]	
	if	isBucklingLength
		for i in eachindex(Nu)
			if (Nu[i] > 0.0)
				fiNc = ϕNc[indexin(Lcomb[i],LcombUnique)][1] #get the correct axial capacity
	 			push!(rcy, Float64(Muy[i]) / ϕMsy + Float64(Nu[i]) / fiNc)	
			else
				push!(rcy, -1.0)
			end
		end	
	else
		for i in eachindex(Nu)
			if (Nu[i] > 0.0)
				fiNc = ϕNc #get the correct axial capacity
	 			push!(rcy, Float64(Muy[i]) / ϕMsy + Float64(Nu[i]) / fiNc)	
			else
				push!(rcy, -1.0)
			end	
		end	
	end
end

# ╔═╡ 807d7a87-8251-4f21-adb5-3b5cc755fa71
md"""
Design ratio/Case/Memb/Station
"""

# ╔═╡ 035d061f-0eec-48d3-b104-11fa7e1c149e
rcy

# ╔═╡ de03da7d-1dc6-460c-9939-a130236629a3
icrit = findmax(rcy)

# ╔═╡ 467db43b-b251-44fd-94e7-6e4ce354345e
dfForces[icrit[2], :]

# ╔═╡ 1f87aa52-6fbe-4f71-8bbe-1688ce051683
begin
	if isBucklingLength
		kler[indexin(Lcomb[icrit[2]],LcombUnique)][1]
		αc[indexin(Lcomb[icrit[2]],LcombUnique)][1]
		ϕNc[indexin(Lcomb[icrit[2]],LcombUnique)][1]
	end
end

# ╔═╡ fd6f2280-a0e8-4c77-b112-591af9c673aa


# ╔═╡ d492ba8c-21ea-4aad-88c1-480094a25019


# ╔═╡ 913af5df-5508-4a75-956e-0b3c52458c50
DBInterface.close!(dbconn)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
ODBC = "be6f12e9-ca4f-5eb2-a339-a4f995cc0291"
Query = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[compat]
DataFrames = "~1.3.5"
ODBC = "~1.1.1"
Query = "~1.0.0"
XLSX = "~0.8.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "846b1663afa51a97e56262014eadbda8e843e28d"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "dc4405cee4b2fe9e1108caec2d760b7ea758eca2"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.5"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "5856d3031cdb1f3b2b6340dfdc66b6d9a149a374"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.2.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DBInterface]]
git-tree-sha1 = "9b0dc525a052b9269ccc5f7f04d5b3639c65bca5"
uuid = "a10d1c49-ce27-4219-8d33-6db1a4562965"
version = "2.5.0"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "6bce52b2060598d8caaed807ec6d6da2a1de949e"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.5"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DecFP]]
deps = ["DecFP_jll", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "a8269e0a6af8c9d9ae95d15dcfa5628285980cbb"
uuid = "55939f99-70c6-5e9b-8bb0-5071ed7d61fd"
version = "1.3.1"

[[deps.DecFP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e9a8da19f847bbfed4076071f6fef8665a30d9e5"
uuid = "47200ebd-12ce-5be5-abb7-8e082af23329"
version = "2.0.3+1"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "5158c2b41018c5f7eb1470d558127ac274eca0c9"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterableTables]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Requires", "TableTraits", "TableTraitsUtils"]
git-tree-sha1 = "70300b876b2cebde43ebc0df42bc8c94a144e1b4"
uuid = "1c8ee90f-4401-5389-894e-7a04a3dc0f4d"
version = "1.0.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "94d9c52ca447e23eac0c0f074effbcd38830deb5"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.18"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.ODBC]]
deps = ["DBInterface", "Dates", "DecFP", "Libdl", "Printf", "Random", "Scratch", "Tables", "UUIDs", "Unicode", "iODBC_jll", "unixODBC_jll"]
git-tree-sha1 = "3b08cf0104565f85662b58622977275343e601c1"
uuid = "be6f12e9-ca4f-5eb2-a339-a4f995cc0291"
version = "1.1.1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "3d5bf43e3e8b412656404ed9466f1dcbf7c50269"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.4.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Query]]
deps = ["DataValues", "IterableTables", "MacroTools", "QueryOperators", "Statistics"]
git-tree-sha1 = "a66aa7ca6f5c29f0e303ccef5c8bd55067df9bbe"
uuid = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
version = "1.0.0"

[[deps.QueryOperators]]
deps = ["DataStructures", "DataValues", "IteratorInterfaceExtensions", "TableShowUtils"]
git-tree-sha1 = "911c64c204e7ecabfd1872eb93c49b4e7c701f02"
uuid = "2aef5ad7-51ca-5a8f-8e88-e75cf067b44b"
version = "0.9.3"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableShowUtils]]
deps = ["DataValues", "Dates", "JSON", "Markdown", "Test"]
git-tree-sha1 = "14c54e1e96431fb87f0d2f5983f090f1b9d06457"
uuid = "5e66a065-1f0a-5976-b372-e0b8c017ca10"
version = "0.2.5"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.TableTraitsUtils]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Missings", "TableTraits"]
git-tree-sha1 = "78fecfe140d7abb480b53a44f3f85b6aa373c293"
uuid = "382cd787-c1b6-5bf2-a167-d5b971a19bda"
version = "1.0.2"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.XLSX]]
deps = ["Artifacts", "Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "ccd1adf7d0b22f762e1058a8d73677e7bd2a7274"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.8.4"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "58443b63fb7e465a8a7210828c91c08b92132dff"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.14+0"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "ef4f23ffde3ee95114b461dc667ea4e6906874b2"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.10.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.iODBC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "785395fb370d696d98da91eddedbdde18d43b0e3"
uuid = "80337aba-e645-5151-a517-44b13a626b79"
version = "3.52.15+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.unixODBC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg"]
git-tree-sha1 = "228f4299344710cf865b3659c51242ecd238c004"
uuid = "1841a5aa-d9e2-579c-8226-32ed2af93ab1"
version = "2.3.9+0"
"""

# ╔═╡ Cell order:
# ╟─4d06b88a-5d4a-425f-9524-c85e5d8557e4
# ╠═8a1a24de-5286-422d-9beb-5357f72556d8
# ╟─4b8407b8-16de-4bd3-b2ea-bf307a15eee4
# ╠═d761b6ef-4f2e-4cf4-a095-2ac5322d8d95
# ╠═569feb5e-28f1-4450-ad29-4a114b11147c
# ╠═3a4ac77f-3689-46a0-92eb-93cda8122e19
# ╠═8535ab55-b5a0-4736-9986-0849e52e7671
# ╠═7f2b353f-e36b-4a8c-a52f-83434c83fed6
# ╠═b6be4e06-2ade-4062-b5e7-184c3d89a0b5
# ╠═2b0b6010-5b83-415d-bc5f-d6574dce7c74
# ╠═caff658b-ca3b-45e0-87e3-704111a3fe44
# ╟─f99ac100-5fcf-4f79-8e29-bea36b818349
# ╠═4102e85a-d5f5-4cf8-8ec1-4c4c00e72747
# ╠═b9e90e5e-f660-412f-ba66-f4e65b7c2153
# ╟─42c723ce-f6a7-44e5-93b1-1b1228b0112c
# ╠═5566ab3f-7698-4eb9-9085-bdbfbc8aa4bb
# ╟─d5f167dc-cd0a-4dec-80fb-b279651c68e1
# ╠═d8589658-f585-4a69-bf7f-6cb98a724f23
# ╠═03623d8b-efc3-4cb0-a9a5-e81cd0bd9b29
# ╟─a41aff43-3e16-4be9-a05e-276f715e0794
# ╠═f64c3a86-a819-47e8-8908-098e20f0d2df
# ╠═f6a17cbf-d588-4e8e-859d-34d774722045
# ╠═83a231a7-100f-474a-ab1b-7740102503d1
# ╠═59b829e8-9813-4c7f-aa42-db7c77073a9c
# ╟─74987af5-d064-4cfe-acba-3187bfaad982
# ╠═c704bb77-2716-4331-af39-400ddd49b72d
# ╠═9093d960-2f84-40da-9107-60882b0c1643
# ╠═0aa2f72d-6c68-4a7f-a836-8c0aa1c1beaf
# ╠═5d2ef5c8-7aac-45dd-9636-b9922b4ec7ea
# ╠═cf721528-b339-4c6b-a8e4-deebebaa6805
# ╠═2da1e548-f435-47d0-8145-7bedd956f752
# ╟─d27a5785-145e-486b-98f6-75b69462c379
# ╟─5e679779-6bdb-413e-ad17-d43a66e70a36
# ╟─5d143565-bfc9-489b-83f0-548a18bd1e2e
# ╠═92fc91b4-8d6f-469b-a278-54092b2f6a70
# ╠═4daad385-e149-429c-b927-6fff6d037295
# ╟─63fa26bd-e8bc-48de-b335-7004d14bdb7a
# ╟─b37ef3f5-31c9-4357-9a26-abb64fa9a609
# ╟─13fab070-b1ef-4687-98fd-0c11009738b8
# ╠═2d613571-101a-4c98-a1b2-3bad223e96d0
# ╟─98ec4bbe-d04b-4289-bc68-1387b6672d19
# ╟─085ec544-1bd5-4101-b134-fafec9c3b32f
# ╠═19b9e242-ce67-4bc6-b115-57cb97bdbef5
# ╠═35e1e519-9691-4cdf-be87-abcf19d9f384
# ╠═a289b997-6762-4ec2-9d06-e0dcf0d7fee8
# ╠═9432fe7d-6516-4336-9519-0d1aeb7ceef7
# ╠═81e714f5-162a-4e71-a07c-b7973069ee56
# ╠═3c34f236-c5fd-45d1-9956-ed658e501132
# ╠═e8e99ddf-599d-460b-b650-930836f6943d
# ╟─d56b1995-6fe7-4ae4-a0ed-d56085c713d4
# ╟─5e89e9dc-007f-4fe9-823b-f52bf3959b8d
# ╠═21799646-2cb8-4533-af02-3b65ba2606f6
# ╠═2190ef78-058e-433f-b00e-70ee0ecf48e0
# ╠═4acaadc5-9ed2-456a-a2ca-813a3e38e29d
# ╟─7be47e10-aab0-4358-83db-429a76bd9819
# ╟─c0f9baee-42b3-4724-9eb3-ffe866f8d441
# ╟─e5d431cd-7c6f-498f-9550-f251fa34854a
# ╠═ec841995-b1e4-4116-b9c2-0c971fc7f2bc
# ╠═14220020-82f2-4137-b064-1310aae87846
# ╟─807d7a87-8251-4f21-adb5-3b5cc755fa71
# ╠═035d061f-0eec-48d3-b104-11fa7e1c149e
# ╠═de03da7d-1dc6-460c-9939-a130236629a3
# ╠═467db43b-b251-44fd-94e7-6e4ce354345e
# ╠═1f87aa52-6fbe-4f71-8bbe-1688ce051683
# ╠═fd6f2280-a0e8-4c77-b112-591af9c673aa
# ╠═d492ba8c-21ea-4aad-88c1-480094a25019
# ╠═913af5df-5508-4a75-956e-0b3c52458c50
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
