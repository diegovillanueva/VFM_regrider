source /vols/fs1/work/ortiz/.myfunctions.sh


var=PSC
var=TAB_532
var=PCR

year=2019
month=10
day=02

python run.readHDF.pyHDF.py /vols/fs1/scratch/ortiz/PSC/CAL_LID_L2_PSCMask-Prov-V1-10/${year}_${month}/CAL_LID_L2_PSCMask-Prov-V1-10.${year}-${month}-${day}T00-00-00ZN.hdf

ncecat -O -u lev ./out/${var}/${var}_Alt*/${var}_Alt*_CAL_LID_L2_PSCMask-Prov-V1-10.${year}-${month}-${day}T00-00-00ZN.nc trash/${var}_test.nc ; 

cdo infon trash/${var}_test.nc ;
