#copy your links here

links=(
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
