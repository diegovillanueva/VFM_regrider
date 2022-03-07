#utils

#make sure your files are in a structure /path/YYYY_MM/hdfFiles.hdf 

## you can use ts=${f/-??T??-??-????.hdf/} ; ts=${ts/*Prov-V?-??./} ; ts=${ts/-/_} ; echo $ts

version=V1-10 #used for second paer of kevin

#used for second paer of kevin
#CAL_LID_L2_PSCMask-Prov-V1-10:
#version=V1-10 #used for second paer of kevin
if [ $version == 'V1-10' ] ; then
    pathToClay=/vols/fs1/scratch/ortiz/PSC/CAL_LID_L2_PSCMask-Prov-$version
    yyyymms=(
    2018-04
    2018-05
    2018-06
    2018-07
    2018-08
    2018-09
    2018-10
    2018-11
    2018-12
    2019-01
    2019-02
    2019-03
    2019-04
    2019-05
    2019-06
    2019-07
    2019-08
    2019-09
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
    2020-10
    2020-11
    2020-12
    2021-01
    2021-02
    2021-03
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

