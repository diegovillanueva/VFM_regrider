#util commands
settempaxe() { ncap2 -O -s 'temp[$temp]={-40.5,-37.5,-34.5,-31.5,-28.5,-25.5,-22.5,-19.5,-16.5,-13.5,-10.5,-7.5,-4.5,-1.5,1.5}' $1 $1 ; }
settempaxe31() { ncap2 -O -s 'temp[$temp]={-88.5,-85.5,-82.5,-79.5,-76.5,-73.5,-70.5,-67.5,-64.5,-61.5,-58.5,-55.5,-52.5,-49.5,-46.5,-43.5,-40.5,-37.5,-34.5,-31.5,-28.5,-25.5,-22.5,-19.5,-16.5,-13.5,-10.5,-7.5,-4.5,-1.5,1.5}' $1 $1 ; }


############  begin  ############

#get Years
source ./0_InfoInput.sh
#produces ../../download/$yyyymm.archive with file paths
generateArchiveFileNC() { 
		#/2007/2007_01_02/DARNI_PRO_L2_v1.10_20070102031350.nc
		iyyyymm=$1
                f=$pathToClay/*/${iyyyymm/-/_}*/*${iyyyymm/-/}*nc
                ls $f > $pathToClay/archive_$iyyyymm
 }
generateArchiveFileHDF() { 
		iyyyymm=$1
                f=$pathToClay/${iyyyymm/-/_}/*$version*$iyyyymm*hdf
                ls $f > $pathToClay/${iyyyymm/-/_}/archive
 }


InterpolateFilesToGrid() {
#interpolate files to grid
	for yyyymm in ${yyyymms[@]} ; do
		generateArchiveFileNC $yyyymm
		file=$(ls $pathToClay/archive_$iyyyymm)
		ls $file

		tstart=$(date)
		ipid=0
		while IFS= read line
		do

			#echo python run.readHDF.pyHDF.py $line ; ipid=$(expr $ipid + 1)
			python run.readHDF.pyHDF.py $line & pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)

			if [[ $ipid == 40 ]] ; then
				for eachPid in ${pids[*]}; do wait $eachPid; done ; ipid=0
				echo from $tstart to $(date)
			fi

		done <"$file"
	done
}


JoinFilesByMonth() {
#join files by month
	ipid=0
	for yyyymm in ${yyyymms[@]} ; do
		yyyymm=${yyyymm/-/}

		#for tt in {00..14} ; do
		for tt in {00..30} ; do

			mkdir -p out_year/${var}_$VertCor${tt}
			echo out_year/${var}_$VertCor${tt}
			echo $yyyymm
			ls out/$var/${var}_$VertCor${tt}/${var}_$VertCor${tt}$identifier*$yyyymm*nc | wc -l
			echo
			cdo -O ensmean out/$var/${var}_$VertCor${tt}/${var}_$VertCor${tt}$identifier*$yyyymm*nc \
				out_year/${var}_$VertCor${tt}/${var}_$VertCor${tt}_${version}_$yyyymm.nc & pids[${ipid}]=$! ; ipid=$(expr $ipid + 1)
		done
		for eachPid in ${pids[*]}; do wait $eachPid; done ; ipid=0
	done
}

JoinLevels() {
	#jointLevs
        for yyyymm in ${yyyymms[@]} ; do
		yyyymm=${yyyymm/-/}
		#ncecat -O -u temp out_year/${var}_${VertCor}{00..14}/${var}_${VertCor}*_${version}_$yyyymm.nc out_year/${var}_$VertCor_${version}_$yyyymm.nc
		ncecat -O -u temp out_year/${var}_${VertCor}{00..30}/${var}_${VertCor}*_${version}_$yyyymm.nc out_year/${var}_$VertCor_${version}_$yyyymm.nc
		f=out_year/${var}_$VertCor_${version}_$yyyymm.nc
		ncatted -O -h -a history,global,d,, $f $f
		#settempaxe $f
		settempaxe31 $f
		mv $f{,.temp}
		cdo -f nc copy  $f{.temp,}
		settempaxe31 $f
		echo $f
	done
}

VertCor=TbinMPC
VertCor=TbinMPC_K
var=CI2CT
identifier=_CAL_LID_L2_333m*$version
identifier=*DARNI*

#InterpolateFilesToGrid
JoinFilesByMonth
JoinLevels

