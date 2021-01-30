#
Get download links from NASA
	-Go to https://search.earthdata.nasa.gov/
		-Search for 
			-CAL_LID_L2_333mCLay-ValStage1
				-V3-40 (Dec2016 to Nov2020)
				-V3-30 (2013 to 2017) 
				-V3-02 2011-2013: omitted
				-V3-01 2006-2011: omitted
				-V3-41 2020 onwards: omitted
			-CALIPSO Lidar Level 2 1/3 km Merged Layer, V4-20
				- Same version from 2007-2020 
				- better take this!

		-TIPS:
			-Set recurring and then get Januar-Februar and repeat for December
			-Filter granule id as: "CAL_LID_L2_333mMLay-Standard-V4-20.20*-01-*T*.hdf,CAL_LID_L2_333mMLay-Standard-V4-20.20*-02-*T*.hdf,CAL_LID_L2_333mMLay-Standard-V4-20.20*-12-*T*.hdf"
				- * is wildcard, and the comma is an additional search
	-Wait for mail with links (a couple of days)

Download
	- Use a download script: e.g., VFM_regrider/ClayDown.sh
	- wait for download to complete
	- organize downloads, e.g.: (find commands in VFM_regrider/utils.sh)

		orgDown() { for y in {2010..2020} ; do for m in 01 02 12 ; do mkdir -p ${y}_$m ; mv xfr139.larc.nasa.gov/*/CAL_LID_L2_333mCLay*${y}-$m*hdf ${y}_$m/ ; done ; done ; }
		scanDown() { for y in {2010..2020} ; do for m in 01 02 12 ; do echo ${y}_$m $(ls ${y}_$m | tail -n 1 | cut -c31-35) $(ls ${y}_$m | wc -l) ; done ; done ; }


Processing
	- Prepare environment: run as test: "python run.readHDF.pyHDF.py" 
	- Install libraries with : "python setup.py install --user"

- modify 0_InfoInput.sh: set your path and your files
- modigy InfoFlags.py: set the flags you want to get from the file and how to average them within a gridbox
- modify InfoVert.py: set Vertical coordinate you which and the bins to separate the profiles into
- run loop.filenames.sh to let the program call repeatedly to the python routines and merge all in "out" and "out_year" directories


