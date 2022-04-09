ipid=0

#var=TAB_532
#var=PSC




#from setdimN 100 alt file
setaltaxe121() { 
    ncpdq -O -a -alt,lat,lon $1 $1
    ncap2 -O -s 'alt[$alt]={000,001,002,003,004,005,006,007,008,009,010,011,012,013,014,015,016,017,018,019,020,021,022,023,024,025,026,027,028,029,030,031,032,033,034,035,036,037,038,039,040,041,042,043,044,045,046,047,048,049,050,051,052,053,054,055,056,057,058,059,060,061,062,063,064,065,066,067,068,069,070,071,072,073,074,075,076,077,078,079,080,081,082,083,084,085,086,087,088,089,090,091,092,093,094,095,096,097,098,099,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120}' $1 $1 ; 
    ncap2 -O -s "alt=alt/120.*(30.1-8.3)+8.3"  $1 $1
}
setdimN ()
{
    dimlen=$1
    d=($(seq 1 $dimlen));
    dim=$2
    file=$3
    arr=$(printf ",%s" "${d[@]}");
    #echo ${arr:1}
    ncap2 -O -s $dim'[$'$dim']={'${arr:1}'}' $file $file
}
settempaxe() { ncap2 -O -s 'temp[$temp]={-40.5,-37.5,-34.5,-31.5,-28.5,-25.5,-22.5,-19.5,-16.5,-13.5,-10.5,-7.5,-4.5,-1.5,1.5}' $1 $1 ; }


join_files(){
    for dd in {01..30} ; do 

        files_to_j=$psc_dir/${var}_${VertCoor}*/*${yyyy}?${mm}?${dd}*.nc
        joined_file_day=$joindir/ncecat.${yyyy}-${mm}-${dd}.nc
	dimn=$(ls -l $files_to_j | wc -l)
	dimn=${dimn// /}

        (
        ncecat -O -u lev $files_to_j $joined_file_day
        setdimN $dimn lev $joined_file_day
	ncecat -O -u time $joined_file_day $joined_file_day

	mv $joined_file_day{,.temp} ; cdo -O -setdate,${yyyy}-${mm}-${dd} $joined_file_day{.temp,} ; /bin/rm $joined_file_day.temp

        ) 2> /dev/null & pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)
    done

#wait
for eachPid in ${pids[*]}; do wait $eachPid; done
}



avg_files() {
    joined_files_days=out_joined/${var}/$yyyymm/ncecat.${yyyymm}-??.nc
    echo ${var}/$yyyymm
    ls $joined_files_days | wc -l
    cdo -O mergetime $joined_files_days ${joindir}.nc
echo cdo infon ${joindir}.nc
exit
}

loop_months() {
    #get  yyyymms and version

    for yyyymm in ${yyyymms[@]} ; do

        joindir=out_joined/${var}/$yyyymm
        mkdir -p $joindir

        yyyy=${yyyymm/-??/}
        mm=${yyyymm/????-/}

        join_files
        avg_files &
        pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)

        echo
    done

#wait
for eachPid in ${pids[*]}; do wait $eachPid; done

joined_files_months=out_joined/${var}/????-??.nc
cdo -O mergetime $joined_files_months out_joined/${var}.nc

echo cdo infon -yearmean -vertsum out_joined/${var}.nc
}

##################################################  start merging ##################################################

source ../VFM_regrider/0_InfoInput.sh #"V1-10" "V1-11" 

var=CC
var=CI2CT

psc_dir=./out/${var}/

VertCoor=Alt
VertCoor=Tbin

loop_months


##################################################  end merging ##################################################

exit



JoinTempvars(){

VertCor=TbinMPC
var=CI2CT

#join files by month
	ipid=0
	for yyyymm in ${yyyymms[@]} ; do

		for tt in {00..14} ; do

			mkdir -p out_year/${var}_$VertCor${tt}
			echo out_year/${var}_$VertCor${tt}
			ls out/$var/${var}_$VertCor${tt}/${var}_$VertCor${tt}_CAL_LID_L2_333m*$version*$yyyymm*nc | wc -l
			#if still fails, check this, because at least one files has data in lon 0
			#try converting to nc before the ensmean
			cdo -O ensmean out/$var/${var}_$VertCor${tt}/${var}_$VertCor${tt}_CAL_LID_L2_333m*$version*$yyyymm*nc \
				out_year/${var}_$VertCor${tt}/${var}_$VertCor${tt}_${version}_$yyyymm.nc & pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)
		done
		for eachPid in ${pids[*]}; do wait $eachPid; done ; ipid=0
	done

        for yyyymm in ${yyyymms[@]} ; do
		
		ncecat -O -u temp out_year/${var}_${VertCor}{00..14}/${var}_${VertCor}*_${version}_$yyyymm.nc out_year/${var}_$VertCor_${version}_$yyyymm.nc
		f=out_year/${var}_$VertCor_${version}_$yyyymm.nc
		ncatted -O -h -a history,global,d,, $f $f
		settempaxe $f
		mv $f{,.temp}
		cdo -f nc copy  $f{.temp,}
		echo $f
	done

}

