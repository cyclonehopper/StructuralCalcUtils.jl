

using ODBC, DataFrames, XLSX, Query
export dfDesignMember, memblist16, dfMembers, dfsection, dfSecprop, dfBucklingLengths, Lcomb_with_bucklingLength, dfForcescCompression, dfForcesTension,
    secnum, secname

function getMemberDesignData(
    dbconn::ODBC.Connection

)
queryDesignMember = DBInterface.execute(dbconn, "SELECT * FROM `Steel Member Design`" )
dfDesignMember = DataFrame(queryDesignMember) 

membstring = 	dfDesignMember[dfDesignMember."Group" .== memb, Symbol("Member List")][1]	
memblist32 = parse.(Int32, split(membstring, ","))
memblist16 = parse.(Int16, split(membstring, ","))
queryMembers = DBInterface.execute(dbconn, "SELECT * FROM Members");	
dfMembers = filter(i -> i.Member in memblist32, DataFrame(queryMembers))

querySecprops = DBInterface.execute(dbconn, "SELECT * FROM `Section Properties`");
dfSecprop = DataFrame(querySecprops)

queryBuklingLengths = DBInterface.execute(dbconn, "SELECT * FROM `Buckling Effective Lengths`" )	
dfBucklingLengths = filter(i -> i.Memb in memblist16, DataFrame(queryBuklingLengths))
#dfBucklingLengths = filter(i -> i.Memb .==memb, DataFrame(queryBuklingLengths))

Lcomb_with_bucklingLength = dfBucklingLengths[: , Symbol("Load Case")]
queryForces = DBInterface.execute(dbconn, "SELECT * FROM `Member Intermediate Forces and Moments`");
dfForcescCompression = filter(i -> i.Member in memblist32 && i.Case in Lcomb_with_bcklingLength , DataFrame(queryForces))
dfForcesTension = filter(i -> i.Member in memblist32 && !(i.Case in Lcomb_with_bcklingLength) , DataFrame(queryForces))

secnum= dfMembers[!, :"Section"][1]
secname = dfSecprop[dfSecprop.Section .== secnum, :"Name"][1]

#userdef lib import
xlsfilepathname = raw"\22131_userdefiend sections.xlsx"
xlssheetname="22131"
df = dropmissing(DataFrame(XLSX.readtable(xlsfilepathname,xlssheetname,"A:AO",first_row=3)), :Name);
dfsection = df[(df.Name .== secname) ,:] 

end
 