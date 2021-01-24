                orgDown() { for y in {2010..2020} ; do for m in 01 02 12 ; do mkdir -p ${y}_$m ; mv xfr139.larc.nasa.gov/*/CAL_LID_L2_333mCLay*${y}-$m*hdf ${y}_$m/ ; done ; done ; }
                scanDown() { for y in {2010..2020} ; do for m in 01 02 12 ; do echo ${y}_$m $(ls ${y}_$m | tail -n 1 | cut -c31-35) $(ls ${y}_$m | wc -l) ; done ; done ; }
