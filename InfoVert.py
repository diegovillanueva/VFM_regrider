#vertical coordinate to use
temperatureName="Layer_Top_Temperature"
temperatureName="ta"
heightName="Layer_Top_Altitude"

VertCoordinateType="TbinMPC_K"
lat="lat"
lon="lon"

if VertCoordinateType=="TbinMPC_K":
	#MPC
	VertCoordinate=temperatureName
	VCoorDef="TbinMPC_K"
	VCoorLowest=-90+273
	VCoorHighest=3+273
	VCoorBinWidth=3

if VertCoordinateType=="TbinAll":
	#All Temp
	VertCoordinate=temperatureName
	VCoorDef="TbinAll"
	VCoorLowest=-60
	VCoorHighest=30
	VCoorBinWidth=3

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

#VCoorNbins=$((($((VCoorHighest))-$((VCoorLowest)))/$VCoorBinWidth))
