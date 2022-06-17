ipid=0
#util commands
settempaxe() { ncap2 -O -s 'temp[$temp]={-40.5,-37.5,-34.5,-31.5,-28.5,-25.5,-22.5,-19.5,-16.5,-13.5,-10.5,-7.5,-4.5,-1.5,1.5}' $1 $1 ; }


############  begin  ############

#get Years
source ./0_InfoInput.sh
#produces ../../download/$yyyymm.archive with file paths
generateArchiveFileDay() { 
		iyyyymm=$1
		dd=$2

		yyyy=${iyyyymm/-*/}
		mm=${iyyyymm/*-/}
		yymmmm_dir=$(echo $pathToClayWD/$yyyy/$mm)

                f=$yymmmm_dir/*$iyyyymm-${dd}T*Z?.hdf

                #ls $f > $pathToClay/${iyyyymm/-/_}/archive
                ls $f > $yymmmm_dir/arch.${yyyy}_${mm}_${dd}
 }


#interpolate files to grid
	for yyyymm in ${yyyymms[@]} ; do
		#while IFS= read line
		#do
		for dd in {01..31} ; do

			generateArchiveFileDay $yyyymm $dd
			file=$(ls $yymmmm_dir/arch.${yyyy}_${mm}_${dd} )
			ls $file

			echo python run.readHDF.pyHDF.py $file & pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)

			if [[ $ipid == 31 ]] ; then
				for eachPid in ${pids[*]}; do wait $eachPid; done ; ipid=0
				echo
			fi
		done

		#done <"$file"
	done


exit

#
#
#
#
# deprecated
#
#
#
#
#

VertCor=TbinMPC
var=CI2CT

#VertCor=TbinAll6K
VertCor=TbinAll
var=CC

#join files by month
	ipid=0
	for yyyymm in ${yyyymms[@]} ; do

		#for tt in {00..14} ; do
		for tt in {00..29} ; do

			mkdir -p out_year/${var}_$VertCor${tt}
			echo out_year/${var}_$VertCor${tt}
			ls out/$var/${var}_$VertCor${tt}/${var}_$VertCor${tt}_CAL_LID_L2_333m*$yyyymm*nc | wc -l
			#if still fails, check this, because at least one files has data in lon 0
			#try converting to nc before the ensmean
			cdo -O ensmean out/$var/${var}_$VertCor${tt}/${var}_$VertCor${tt}_CAL_LID_L2_333m*$yyyymm*nc \
				out_year/${var}_$VertCor${tt}/${var}_$VertCor${tt}_$yyyymm.nc & pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)
		done
		for eachPid in ${pids[*]}; do wait $eachPid; done ; ipid=0
	done


        for yyyymm in ${yyyymms[@]} ; do
		
		ncecat -O -u temp out_year/${var}_${VertCor}{00..29}/${var}_${VertCor}*_$yyyymm.nc out_year/${var}_$VertCor_$yyyymm.nc
		f=out_year/${var}_$VertCor_$yyyymm.nc
		ncatted -O -h -a history,global,d,, $f $f
		settempaxe $f
		mv $f{,.temp}
		cdo -f nc copy  $f{.temp,}
		echo $f
	done
