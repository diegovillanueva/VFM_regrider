#avoid error DISPLAY
import matplotlib as mpl
mpl.use('Agg')

import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import griddata

import sys
sys.path.append('/vols/fs1/work/ortiz/binPython/')
import netcdf

class interpolation():
 def __init__(s):
	s.ntest=1000
	s.interpolMethods=['nearest','cubic','linear']
	s.setInterpolMethodByIndex(0)

#tests begin
 def quickTest(s):
	s.ntest=1000
	s.setTestDataAndTestGrid()

	s.rebin()

	s.plot()
	s.saveToNetcdf()

 def testInterpolMethods(s):
	for index in [0,1,2]:
		s.setInterpolMethodByIndex(index)
		s.setTestDataAndTestGrid()

		s.interpolate()
		s.plot()

 def getData(s,x,y,var):
	# data coordinates and values
	s.x = x
	s.y = y
	s.var = var

 def getTestData(s):
	# data coordinates and values
	s.x = np.random.random(s.ntest)
	s.y = np.random.random(s.ntest)
	s.var = np.random.random(s.ntest)

 def setGrid(s,dlat,dlon,slat=-90,slon=-180):
	# target grid to interpolate to
	s.xGridDim = np.arange(slat,90,dlat)
	s.yGridDim = np.arange(slon,180,dlon)

	s.xGrid,s.yGrid = np.meshgrid(s.xGridDim,s.yGridDim)

 def setTestGrid(s):
	# target grid to interpolate to
	s.xGridDim = s.yGridDim = np.arange(0,1.01,0.01)
	s.xGrid,s.yGrid = np.meshgrid(s.xGridDim,s.yGridDim)
#tests end

 def setTestDataAndTestGrid(s):
		s.getTestData()
		s.setTestGrid()

 def setInterpolMethodByIndex(s,index):
	s.interpolMethod=s.interpolMethods[index]

 def rebin(s):
	#only this template works and has dimensions lat,lon , find out why!!!
	varTemplate=np.swapaxes(s.xGrid,0,1)
	s.varGrid = np.zeros_like(varTemplate).astype(float)
	s.varGridCount = np.zeros_like(varTemplate)


	#tuples as lat,lon !!!!critical!!!
	s.varContainedTuples=s.getMaskWhereVarContained()

	for vari,ituple in enumerate(s.varContainedTuples):
		if not (np.isnan(s.var[vari])):
			s.varGrid[ituple]+=s.var[vari]
			s.varGridCount[ituple]+=1
			#print s.x[vari],s.y[vari]

	valid=s.varGridCount!=0
	s.varGrid[valid]=s.varGrid[valid]/s.varGridCount[valid]
	#mask out if no count
	s.varGrid[s.varGridCount==0]=np.nan

 def nearest_neighbors(s,longArray, grid):
	return np.array([s.nearest_neighbor(grid,xi) for xi in longArray])

 def nearest_neighbor(s,array, value):
    idx = np.nanargmin(np.abs(array - value))
    return idx

 def getMaskWhereVarContained(s):
	tuples=zip(
		s.nearest_neighbors(s.x,s.xGridDim),
        	s.nearest_neighbors(s.y,s.yGridDim)
)
	#print np.shape(tuples)
	return tuples	


 def plot(s):
	fig = plt.figure()
	ax = fig.add_subplot(111)
	plt.contourf(s.xGrid,s.yGrid,s.varGrid,np.arange(0,1.01,0.01))
	#plt.plot(s.x,s.y,'k.')
	plt.savefig('interpolated.'+s.interpolMethod+'.png',dpi=100)
	plt.close(fig)

 def saveToNetcdf(s,fn="test",varname='test'):
	netcdf.writeVarToNetcdf(   	outpdf='./out/'+fn,
					dims_list=[s.xGridDim,s.yGridDim],
					var=s.varGrid,
					varname=varname)
#deprecated
 def interpolate(s):
	s.varGrid = griddata((s.x,s.y),s.var,(s.xGrid,s.yGrid),method=s.interpolMethod)

if __name__=='__main__':
	test=interpolation()
	#test.testInterpolMethods()
	test.quickTest()

def interpolate(data,lat,lon,fn="test",vn="varname"):
	interpol=interpolation()

	interpol.getData(lat,lon,data)
	interpol.setGrid(2,30,slat=-89,slon=-165)
	#interpol.setGrid(2,2,slat=-89,slon=-179)

	interpol.rebin()
	#interpol.interpolate()

	#interpol.plot()
	interpol.saveToNetcdf(fn=fn,varname=vn)
