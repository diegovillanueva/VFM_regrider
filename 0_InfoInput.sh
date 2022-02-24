#utils

#make sure your files are in a structure /path/YYYY_MM/hdfFiles.hdf 

## you can use ts=${f/-??T??-??-????.hdf/} ; ts=${ts/*Prov-V?-??./} ; ts=${ts/-/_} ; echo $ts

#used for second paer of kevin
#CAL_LID_L2_PSCMask-Prov-V1-10:
#version=V1-10 #used for second paer of kevin
if [ $version == 'V1-10' ] ; then
    pathToClay=/vols/fs1/scratch/ortiz/PSC/CAL_LID_L2_PSCMask-Prov-$version
    yyyymms=(
    2019-10  
    2019-11  
    2019-12  
    2020-01  
    2020-02  
    2020-03  
    2020-04  
    )
fi

#version=V1-11 #used for second paer of kevin
#CAL_LID_L2_PSCMask-Prov-V1-11:
if [ $version == 'V1-11' ] ; then
    pathToClay=/vols/fs1/scratch/ortiz/PSC/CAL_LID_L2_PSCMask-Prov-$version
    yyyymms=(
    2021-04  
    2021-05  
    2021-06  
    2021-07  
    2021-08  
    2021-09  
    2021-10  
    2021-11  
    )
fi

