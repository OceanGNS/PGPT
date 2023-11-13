#!/usr/bin/env bash

scriptsDir=$1
missionDir=$2
metadataFile=$3

##  RAW DIRECTORY
if [[ ! -e ${missionDir}/raw ]]; then
    cat <<EOF
	The "raw" directory wasn\'t found!
	Please run the script in your mission directory with the "raw" directory present.
	See the README file for more information.
EOF
    exit 1
fi

##  METADATA FILE EXIST
if [[ ! -e ${missionDir}/${metadataFile} ]]; then
    cat <<EOF
	Metadata file "${metadataFile}" wasn\'t found in ${missionDir}!
EOF
    exit 1
fi

##  METADATA FILE VALIDATION
# python3 ${scriptsDir}/metaCheck.py ${missionDir}/${metadataFile}
if [[ $? -ne 0 ]]; then
    exit 1
fi

##  CACHE FILES EXIST
if [[ ! -e ${missionDir}/../cache ]]; then
    cat <<EOF
	"cache" directory wasn't found.
	See the README file for more information.
EOF
    exit 1
fi
