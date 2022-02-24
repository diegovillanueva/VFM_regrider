#copy your links here
links=(
https://xfr139.larc.nasa.gov/7cbb6b8c-e7bd-4830-a99f-0ae624f0d5a3
)

#when ready you can move them here
down=(
https://xfr139.larc.nasa.gov/5c9e9f00-a584-4ba4-af6e-441649ad4420
https://xfr139.larc.nasa.gov/1c794bc3-8782-4a2b-97e6-f649a83b9266
https://xfr139.larc.nasa.gov/99dae459-e733-41e4-aa64-b67b99a6aba5
)

#edit
pass="your@email"
downloadFolder="yourDownloadPath"

today=$(date +'%d_%m_%YT%H')
for (( i=0 ; i < ${#links[@]} ; i++ )) ; do
	link=${links[$i]}
	wget -r -nc "$link"  --user anonymous --password $pass -P $downloadFolder -A "CAL_LID_L2_333mCLay*.hdf"  &> $downloadFolder/${today}.n$i.err & disown
done
