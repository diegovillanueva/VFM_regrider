# -*- coding: utf-8 -*-
#!/usr/local/bin/python
#import sys
#sys.path.append('/work/bb1114/b380602/PAPER_godzilla/VFM_regrider/pyhdf-0.9.0')
#sys.path.append('/work/bb1114/b380602/PAPER_godzilla/VFM_regrider/pyhdf-0.9.0/build')
#import os
from pyhdf import SD

from readFlag import *
import grid
import numpy as np
np.set_printoptions(	threshold=sys.maxsize,
			formatter={'float': lambda x: "{0:2.0f}".format(x)} )
import copy
import InfoFlags as settings

class varInfo():
 def __init__(s):
	#defaults for debug
	s.fileName = "test_CAL_LID_L2_333mCLay-V3-40.hdf"
	s.varName  = "Feature_Classification_Flags"
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

	#for tests
	s.offset=100
	s.skip=1000
	 
 def getFileNameShort(s,debug=False):
	base=os.path.basename(s.fileName)
	#fn=os.path.splitext(base)[0]
	fn=base
	if debug:
		return "test"
	else:
		return fn

 def getData(s):

	archiveFile = open(s.fileName,'r')

	for ifile,singleFileName in enumerate(archiveFile):
		print ifile,singleFileName
		if ifile==0:
			s.lon,s.lat,s.VertCoordinate,s.data=s.getXYZdata(singleFileName)
		else: 
			templon,templat,tempVertCoordinate,tempdata=s.getXYZdata(singleFileName)
			s.lon=np.concatenate((s.lon,templon))
			s.lat=np.concatenate((s.lat,templat))
			s.VertCoordinate=np.concatenate((s.VertCoordinate,tempVertCoordinate))
			s.data=np.concatenate((s.data,tempdata))
			print(s.data.size)
			

#This get VertCoordinate, height and flags(VFM) from the top cloudy pixel of caliop profile
 def getXYZdata(s,fileName):
	# open the hdf file
	#print os.path.exists(fileName.rstrip())
	s.hdf = SD.SD(fileName.rstrip())
	 
	locdata=s.getFeaturesAs1D(s.varName)
	#s.setNrows()

	locVertCoordinate=s.getFeaturesAs1D(settings.VertCoordinate)
	locVertCoordinate[np.where(locVertCoordinate==-9999.0)]=np.nan


	loclat=s.getFeaturesAs1D("Latitude")
	loclon=s.getFeaturesAs1D("Longitude")
	# Terminate access to the SD interface and close the file
	s.hdf.end()
	return loclon,loclat,locVertCoordinate,locdata


# def setNrows(s):
#	# get dataset dimensions
#	s.nrows = len(s.data)  

	 
	 
 def getFeaturesAs1D(s,varName):
		# select and read the sds data, select top pixel
		s.sds = s.hdf.select(varName)
		data = s.sds.get()
		# Terminate access to the data set
		s.sds.endaccess()
		#get top feature: for VFM vertCoor is 5 (features) and 0 is the topmost feature
		return data[::s.debugOffset,0]
		#get all features for VFM (5) and flatten array
		#return data[::s.debugOffset,:].flatten(order='C')
		#get top cloud feature: for VFM vertCoor is 5 (features) and 0 is the topmost feature
		#to implement:

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
	s.values=np.array(map(s.getLabelValueIf, s.data))


#This functions take all data and set missing values when VertCoordinate is outside a range
 def sortDataIntoTempBin(s,top=0,bot=-3):
	#print "from "+str(top)+" to "+str(bot)	
	#print np.nanmean(s.values[np.where( (bot<s.VertCoordinate) & (s.VertCoordinate<top) )])	
	temp=copy.copy(s.values)
	#temp[ np.where( (bot>=s.VertCoordinate) | (s.VertCoordinate>=top) | np.isnan(s.VertCoordinate) )]=np.nan
	temp[ np.where( (s.VertCoordinate<=bot) | (top<=s.VertCoordinate) )]=np.nan #put nan outside temprange
	#temp[ np.where( np.isnan(s.VertCoordinate) )]=np.nan #this hapens auto
	#temp[ np.where( s.values == 0 ) ]=0 # this happens autom
	#print s.values,bot,top,s.VertCoordinate,temp
	#exit()
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
	for i in range(s.offset,len(s.data),s.skip):
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

	flag.getData()
	flag.getValues()



#Get values at VertCoordinate bins (mixed-phase)
	binValues=flag.SortTbins(lowest=settings.VCoorLowest,highest=settings.VCoorHighest,width=settings.VCoorBinWidth)
	for ti,tbinValues in enumerate(binValues):
		print 'validPoints at'+settings.VertCoordinate+str(settings.VCoorLowest+settings.VCoorBinWidth*(ti+0.5))
		print np.count_nonzero(~np.isnan(tbinValues))

		fn=settings.VFMflagDef+"/"+	settings.VFMflagDef+"_"+settings.VCoorDef+"%02d"%ti+"/"+\
						settings.VFMflagDef+"_"+settings.VCoorDef+"%02d"%ti+"_"+flag.getFileNameShort(debug)
		grid.interpolate(tbinValues,flag.lat,flag.lon,fn=fn,vn=settings.VFMflagDef,gridCT=settings.gridCountThreshold)

	

#	flag.testTemperature()
#	flag.testNrows()
#	flag.testLabels()
#	flag.testValues()
#	flag.TestsortTemp()
#	flag.testSortTbins()


