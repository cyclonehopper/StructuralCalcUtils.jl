using ODBC

filepath = "D:\\JuliaRepo\\StructuralCalcUtils\\test\\.mdb\\"
xlsxfilename = raw"22131_userdefiend sections.xlsx"
mdbfilename = raw"22131-ST-MOD-04 Truss_grids 2-6-10&11_As-built.MDB"
begin
	mdbfilepathname = filepath *mdbfilename
	statement ="Driver={Microsoft Access Driver (*.mdb, *.accdb)}; Dbq="  * mdbfilepathname
	dbconn = ODBC.Connection(statement)		
end

