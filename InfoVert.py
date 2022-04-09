#vertical coordinate to use
temperatureName="Layer_Centroid_Temperature"
temperatureName="Layer_Top_Temperature"
heightName="Layer_Top_Altitude"

VertCoordinateType="TbinAll"

if VertCoordinateType=="TbinMPC":
	#MPC
	VertCoordinate=temperatureName
	VCoorDef="TbinMPC"
	VCoorLowest=-42
	VCoorHighest=3
	VCoorBinWidth=3

if VertCoordinateType=="TbinAll6K":
	#All Temp
	VertCoordinate=temperatureName
	VCoorDef="TbinAll6K"
	VCoorLowest=-60
	VCoorHighest=30
	VCoorBinWidth=6

if VertCoordinateType=="TbinAll":
	#All Temp
	VertCoordinate=temperatureName
	VCoorDef="TbinAll"
	VCoorLowest=-60
	VCoorHighest=30
	VCoorBinWidth=3

#debug
#VCoorLowest=-42
#VCoorHighest=-39

if VertCoordinateType=="HAer":
	#Height regimes
	VertCoordinate=heightName
	VCoorDef="HAer"
	VCoorLowest=00
	VCoorHighest=30
	VCoorBinWidth=10

if VertCoordinateType=="Treg":
	#Temp Regimes
	VertCoordinate=temperatureName
	VCoorDef="Treg"
	VCoorLowest=-80
	VCoorHighest=40
	VCoorBinWidth=40
