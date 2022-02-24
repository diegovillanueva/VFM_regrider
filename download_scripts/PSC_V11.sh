#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (diego.villanueva): " username
    username=${username:-diego.villanueva}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/11/CAL_LID_L2_PSCMask-Prov-V1-11.2021-11-30T00-00-00ZN.hdf"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/11/CAL_LID_L2_PSCMask-Prov-V1-11.2021-11-30T00-00-00ZN.hdf -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/11/CAL_LID_L2_PSCMask-Prov-V1-11.2021-11-30T00-00-00ZN.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"
        downloadFolder="/vols/fs1/scratch/ortiz/PSC/V11/"
        pass="diego.villanueva@ug.uchile.cl"

        wget -P $downloadFolder --password $pass --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-01T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-02T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-03T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-04T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-05T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-06T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-07T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-08T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-09T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-10T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-11T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-12T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-13T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-14T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-15T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-16T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-19T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-20T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-21T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-22T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-23T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-24T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-25T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-26T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-27T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-28T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-29T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-30T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/10/CAL_LID_L2_PSCMask-Prov-V1-11.2020-10-31T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-01T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-02T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-03T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-04T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-05T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-06T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-07T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-08T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-09T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-10T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-11T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-12T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-13T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-14T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-15T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-16T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-17T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-18T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-19T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-20T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-21T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-22T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-23T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-24T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-25T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-26T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-27T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-28T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-29T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/11/CAL_LID_L2_PSCMask-Prov-V1-11.2020-11-30T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-01T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-02T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-03T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-04T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-05T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-06T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-07T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-08T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-09T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-10T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-11T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-12T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-13T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-14T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-15T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-16T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-17T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-18T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-19T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-20T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-21T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-22T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-23T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-24T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-25T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-26T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-27T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-28T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-29T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-30T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2020/12/CAL_LID_L2_PSCMask-Prov-V1-11.2020-12-31T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-01T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-02T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-03T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-04T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-05T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-06T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-07T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-08T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-09T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-10T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-11T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-12T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-13T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-14T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-15T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-16T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-17T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-18T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-19T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-20T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-21T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-22T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-23T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-24T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-25T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-26T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-27T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-28T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-29T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-30T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/01/CAL_LID_L2_PSCMask-Prov-V1-11.2021-01-31T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-01T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-02T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-03T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-04T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-05T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-06T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-07T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-08T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-09T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-10T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-11T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-12T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-13T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-14T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-15T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-16T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-17T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-18T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-19T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-20T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-21T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-22T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-23T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-24T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-25T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-26T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-27T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/02/CAL_LID_L2_PSCMask-Prov-V1-11.2021-02-28T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-01T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-02T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-03T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-04T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-05T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-06T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-07T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-08T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-09T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-10T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-11T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-12T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-13T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-14T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-15T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-16T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-20T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-22T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-23T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-24T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-25T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-26T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-27T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-28T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-29T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-30T00-00-00ZN.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L2_PSCMask-Prov-V1-11/2021/03/CAL_LID_L2_PSCMask-Prov-V1-11.2021-03-31T00-00-00ZN.hdf
EDSCEOF
