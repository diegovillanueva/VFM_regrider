# -*- coding: utf-8 -*-
#!/usr/local/bin/python
from pyhdf import SD
from readFlag import *
import grid
import numpy as np
np.set_printoptions(	threshold=sys.maxsize,
			formatter={'float': lambda x: "{0:2.0f}".format(x)})
import copy
import InfoFlags as settings

class varInfo():
 def __init__(s):
	#defaults for debug
	#s.fileName = "CAL_LID_L2_333mCLay-ValStage1-V3-40.2020-01-29T20-56-48ZN.hdf"
	#s.varName  = "Feature_Classification_Flags"
	s.fileName = "CAL_LID_L2_PSCMask-Prov-V1-11.2021-11-30T00-00-00ZN.hdf"
	s.varName  = "PSC_Feature_Mask"
	#get flags 6-7 and average them as: missing,1,0,1
	s.VFMflagStart=settings.VFMflagStart
	s.VFMflagFinish=settings.VFMflagFinish
	s.flagValues=settings.flagValues
	if True:
		s.sds_flagBegin=s.VFMflagStart-1
		s.sds_flagLength=s.VFMflagFinish-s.sds_flagBegin
	s.labels=['Unknown','Ice','Water','HO']
	#values to assign to each flag value (counting)

	#Alternative: include a second condition depending on flags (e.g., aerosol)
	s.CondFlag	=settings.CondFlag	
	s.CondFlagStart	=settings.CondFlagStart	
	s.CondFlagFinish=settings.CondFlagFinish
	if True:
		s.CondFlagBegin	=s.CondFlagStart-1
		s.CondFlagLength=s.CondFlagFinish-s.CondFlagBegin
	s.CondFlagValue	=settings.CondFlagValue	

class getFlag(varInfo):
 def __init__(s):
	varInfo.__init__(s)


	s.debugOffset=settings.debugOffset

	s.offset=100
	s.skip=1000
	 
 def getFileNameShort(s,debug=False):
	base=os.path.basename(s.fileName)
	fn=os.path.splitext(base)[0]
	#fn=base
	if debug:
		return "test"
	else:
		return fn

#This get VertCoordinate, height and flags(VFM) from the top cloudy pixel of caliop profile
 def getDataPSC(s):
    # open the hdf file
    s.hdf = SD.SD(s.fileName)
     
    s.data=s.getPixelVar(s.varName)
    print s.data.shape
    ##print s.debugOffset
    ##print s.data

    s.nrows = s.data.shape[1]
    print s.nrows
    
    #s.VertCoordinate=s.getTopPixelVar(settings.VertCoordinate)
    s.VertCoordinate=s.getVertVar(settings.VertCoordinate)
    s.VertCoordinate[np.where(s.VertCoordinate==-9999.0)]=np.nan
    #print s.VertCoordinate
    
    
    s.lat=s.getPixelVar("Latitude")
    s.lon=s.getPixelVar("Longitude")
    # Terminate access to the SD interface and close the file
    s.hdf.end()
    
    
 def setNrows(s):
	# get dataset dimensions
	s.nrows = len(s.data)  

	 
 def getVertVar(s,varName):
		# select and read the sds data, select top pixel
		s.sds = s.hdf.select(varName)
		data = s.sds.get()
		# Terminate access to the data set
		s.sds.endaccess()
		#get top pixel
		return data
	 
 def getTopPixelVar(s,varName):
		# select and read the sds data, select top pixel
		s.sds = s.hdf.select(varName)
		data = s.sds.get()
		# Terminate access to the data set
		s.sds.endaccess()
		#get top pixel
		return data[::s.debugOffset,0]

 def getPixelVar(s,varName):
    # select and read the sds data, select top pixel
    s.sds = s.hdf.select(varName)
    data = s.sds.get()
    # Terminate access to the data set
    s.sds.endaccess()
    #get top pixel
    if len(data.shape) == 1:
        return data[::s.debugOffset]
    else:
        return data[::s.debugOffset,:]

 #replace flag index(vfm) for flag value (user), given a condition
 def getLabelValueIf(s,byte):
	#if no conditions or condition fullfilled
	if s.CondFlag==False:
		return s.flagValues[s.getLabelIndex(byte)]
	elif int(get_bitflag_by_range(byte,s.CondFlagBegin,s.CondFlagLength))==int(s.CondFlagValue):
		return s.flagValues[s.getLabelIndex(byte)]
	else:
		return np.nan

 #replace flag index(vfm) for flag value (user)
 def getLabelIndex(s,byte):
	return get_bitflag_by_range(byte,s.sds_flagBegin,s.sds_flagLength)

 def getLabelValue(s,byte):
	return s.flagValues[s.getLabelIndex(byte)]

 def getValues(s):
    if s.VFMflagStart == -1 : #if a float
        s.values=s.data
    else: #if a flag
        s.values=np.array(map(s.getLabelValueIf, s.data))

 def getValuesPSC(s):
        s.values= (s.data>0).astype(float)

#This functions take all data and set missing values when VertCoordinate is outside a range
 def sortDataIntoTempBin(s,top=0,bot=-3):
    #print "from "+str(top)+" to "+str(bot)	
    #print np.nanmean(s.values[np.where( (bot<s.VertCoordinate) & (s.VertCoordinate<top) )])	
    temp=copy.copy(s.values).astype(float)
    if any(s.VertCoordinate == np.nan) :
     temp=np.nan
    else:
     #print s.VertCoordinate
     #print bot,top
     temp[np.where( (bot>s.VertCoordinate) | (s.VertCoordinate>top) )]=np.nan
    #return s.values[np.where( (bot<s.VertCoordinate) & (s.VertCoordinate<top) )]
    return temp


 def SortTbins(s,lowest=-42,highest=3,width=3):
	Tbins=[]
	for bot in range(lowest,highest,width):
		top=bot+width
		Tbins.append(s.sortDataIntoTempBin(top=top,bot=bot))
	return Tbins

# Test functions
 def TestsortTemp(s):
	s.sortDataIntoTempBin()
	s.sortDataIntoTempBin(top=-39,bot=-42)
 def testSortTbins(s,lowest=-42,highest=3,width=3):
	for bot in range(lowest,highest,width):
		top=bot+width
		print str(bot) + " to " + str(top)
 def testValues(s):
	print s.values
	print np.nanmean(s.values)
	print np.nanmin(s.values)
	print np.nanmax(s.values)
 def testTemperature(s):
	print np.nanmean(s.VertCoordinate)
	print np.nanmin(s.VertCoordinate)
	print np.nanmax(s.VertCoordinate)
 def testNrows(s):
	print s.data.shape 
 def testLabels(s):
	for i in range(s.offset,s.nrows,s.skip):
		istr=get_bitflag_by_range(s.data[i],s.sds_flagBegin,s.sds_flagLength)
		if istr == 2:
			print '{:2.0f}'.format(s.VertCoordinate[i])
			print s.labels[istr]
			print

import sys
import os
if __name__=="__main__" :
    flag=getFlag()
    
    #set debug if only one argument (python run)
    debug=(len(sys.argv) == 1)
    if not debug :
    	flag.fileName=sys.argv[1]
    
    print flag.getFileNameShort()
    
    flag.getDataPSC()
    flag.getValuesPSC()
    #print flag.values

#Get values at VertCoordinate bins (mixed-phase)
    for ti in range(flag.values.shape[1]):
        tbinValues=flag.values[:,ti]
        #print tbinValues
    
    	fn=settings.VFMflagDef+"/"+	settings.VFMflagDef+"_"+settings.VCoorDef+"%03d"%ti+"/"+\
    					settings.VFMflagDef+"_"+settings.VCoorDef+"%03d"%ti+"_"+flag.getFileNameShort(debug)
    	grid.interpolate(tbinValues,flag.lat,flag.lon,fn=fn,vn=settings.VFMflagDef)
    
    
    
#	flag.testTemperature()
#	flag.testNrows()
#	flag.testLabels()
#	flag.testValues()
#	flag.TestsortTemp()
#	flag.testSortTbins()


