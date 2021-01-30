from netCDF4 import Dataset
import matplotlib.ticker
import numpy as np
import utils

class netcdf_file:
   def __init__(s,
		fn='py_netcdf4.nc'):#filename
	s.fn=fn
        s.ds = Dataset(fn, 'w', format='NETCDF4')
	s.dim_names={}

   def set_dims(s, 
                x_arr, #dimension values
                xname,#dimension name
		x_description): #dim description like ["X", "temperature", "dgC"]
        s.dim_names[xname]=xname

        s.ds.createDimension(xname, len(x_arr))

        x = s.ds.createVariable         (xname, 'f4', (xname,))
        x[:] = x_arr
	
	s.set_dim_att(s.dim_names[xname], x_description)
   def set_dim_att(s,
		axename, #axe name like 'temperature' 'lat' 'lon' 
		description): # axe atribute list ['X' axis name, 'latitude' longname , 'degrees north' units]
        s.ds[axename].axis= description[0]
        s.ds[axename].long_name = description[1]
        s.ds[axename].units = description[2]
        s.ds[axename].standard_name = s.ds[axename].long_name

   def add_variable_1d(s,xname,vname='field'):
        field = s.ds.createVariable(vname, 'f8', (s.dim_names[xname],),fill_value=np.nan)
        field[:] = np.nan
   def add_variable_2d(s,dimnames,vname='field'):
        field = s.ds.createVariable(vname, 'f8', 
		(s.dim_names[dimnames[0]],s.dim_names[dimnames[1]],)
		,fill_value=np.nan)
        field[:] = np.nan
   def add_variable_3d(s,dimnames,vname='field'):
        field = s.ds.createVariable(vname, 'f8', 
		(s.dim_names[dimnames[0]],s.dim_names[dimnames[1]],s.dim_names[dimnames[2]],)
		,fill_value=np.nan)
        field[:] = np.nan
   def add_variable_4d(s,dimnames,vname='field'):
        field = s.ds.createVariable(vname, 'f8', 
		(s.dim_names[dimnames[0]],s.dim_names[dimnames[1]],s.dim_names[dimnames[2]],s.dim_names[dimnames[3]])
		,fill_value=np.nan)
        field[:] = np.nan

   def write_down(s):
        s.ds.close()
	print("cdo infon "+s.fn)

def writeVarToNetcdf(	outpdf='./test',
			dims_list=[np.array([0,1]),np.array([0,1]) ], 
			var=np.array([[0,1],[0,1]]),
			varname='test'):

		outfilenc=outpdf+'.nc'
		utils.ensure_dir(outfilenc)
		netcdffile=netcdf_file(outfilenc)

		if len(var.shape)==1 :
			dimnames=['temp']
			x_description=["X", "temperature", "dgC"]
			netcdffile.set_dims(dims_list[0],dimnames[0],x_description)	
			netcdffile.add_variable_1d(dimnames[0],vname=varname)
			netcdffile.ds[varname][:]=var

		elif len(var.shape)==2 :
			#print "writing 2d var"
			dimnames=['lat','lon']
			dim_description=[	["Y", "latitude", "degrees_north"]	,
						["X", "longitude", "degrees_east"]	]
			for idim,dimname in enumerate(dimnames):
				netcdffile.set_dims(dims_list[idim],dimname,dim_description[idim])	
			netcdffile.add_variable_2d(dimnames,vname=varname)
			#print 'shapes',dimnames,netcdffile.ds[varname].shape,var.shape
			netcdffile.ds[varname][:,:]=var

		elif len(var.shape)==3 :
			dimnames=['temp','lat','lon']
			dim_description=[	["Z", "temperature", "dgC"]	,
						["Y", "latitude", "degrees_north"]	,
						["X", "longitude", "degrees_east"]	]
			for idim,dimname in enumerate(dimnames):
				netcdffile.set_dims(dims_list[idim],dimname,dim_description[idim])	
			netcdffile.add_variable_3d(dimnames,vname=varname)
			print 'shapes',dimnames,netcdffile.ds[varname].shape,var.shape
			netcdffile.ds[varname][:,:,:]=var
		elif len(var.shape)==4 :
			dimnames=['temp','con','lat','lon']
			dim_description=[	
						["Z", "temperature", "dgC"]     	,
						["T", "constrain", ""]		,
						["Y", "latitude", "degrees_north"]	,
						["X", "longitude", "degrees_east"]	
					]
			for idim,dimname in enumerate(dimnames):
				netcdffile.set_dims(dims_list[idim],dimname,dim_description[idim])	
			netcdffile.add_variable_4d(dimnames,vname=varname)
			netcdffile.ds[varname][:,:,:,:]=var


		netcdffile.write_down()

