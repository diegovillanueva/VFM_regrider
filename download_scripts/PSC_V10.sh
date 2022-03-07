#copy your links here

links=(
https://xfr139.larc.nasa.gov/803a6b73-45ca-4256-aeb1-9b25c5525123
)

#when ready you can move them here
down=(
)

#edit
pass="diego.villanueva@ug.uchile.cl"
downloadFolder="/vols/fs1/scratch/ortiz/PSC/"

today=$(date +'%d_%m_%YT%H')
for (( i=0 ; i < ${#links[@]} ; i++ )) ; do
	link=${links[$i]}
	wget -r -nc "$link"  --user anonymous --password $pass -P $downloadFolder -A "CAL_LID_L2_PSCMask*.hdf"  &> $downloadFolder/${today}.n$i.err & disown
done
