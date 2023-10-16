#!/usr/bin/env bash

usage() {
	echo "Usage: $(basename $0) [-g glider_name] [-d missionDirectory] [-m metadata.yml] [-p realtime|delayed]"
}

while getopts ":g:d:m:p:" opt; do
	case "${opt}" in
	g)
		glider=${OPTARG}
		echo "Glider name"
		;;

	d)
		missionDir=${OPTARG}
		echo 'Mission absolute path (where the "raw" directory is located).'
		;;

	m)
		metadataFile=${OPTARG}
		echo 'Metadata YAML absolute or relative path.'
		;;

	p)
		processingMode=${OPTARG}
		echo 'Processing mode.  Either "realtime" or "delayed".'
		;;

	h)
		usage
		exit 0
		;;

	:)
		echo -e "option requires an argument."
		usage
		exit 1
		;;

	?)
		echo -e "Invalid command option."
		usage
		exit 1
		;;

	*)
		usage
		exit 1
		;;
	esac
done

if [[ -z ${glider} ]] || [[ -z ${missionDir} ]] || [[ -z ${metadataFile} ]] || [[ -z ${processingMode} ]]; then
	usage
	exit 1
fi

# Set variables
# export glider="$1"
# export missionDir="$2"
# export scriptsDir="$3"
# export gliders_db="$4"
# export metadata_file="$5"
# export processing_mode="$6"

script=$(realpath $0)
export scriptsDir=$(dirname ${script})

######################################################
####  INITIAL CHECKS
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
if [[ ! -e ${metadataFile} ]]; then
	cat <<EOF
	Metadata file "${metadataFile}" wasn\'t found!
EOF
	exit 1
fi

##  METADATA FILE VALID

##  CACHE FILES EXIST
if [[ ! -e ${missionDir}/cache ]]; then
	cat <<EOF
	"cache" directory wasn't found.
	See the README file for more information.
EOF
	exit 1
fi

######################################################

##  PREPARE DIRECTORIES
mkdir -p ${missionDir}/{txt,nc}

##  DECOMPRESS & RENAME FILES
cd ${missionDir}/raw
n=$(ls *.?[cC][dD] | wc -l)
if [[ $n -eq 0 ]]; then
	echo "No compressed files found.  Moving on ..."
else
	echo "Decompressing files ..."
	ls *.?[cC][dD] | parallel "out=$(echo {} | sed 's/cd$/bd/') ; ${scriptsDir}/bin/compexp x {} ${out}"
	echo "Decompression done."
	# ls *.?[cC][dD] | while read f; do
	# 	out="$(echo $f | sed 's/cd$/bd/')"
	# 	# Check if decompressed file already exists
	# 	if [[ ! -e $out ]]; then
	# 		echo "##  DECOMPRESSING $f TO ${out}"
	# 		${scriptsDir}/bin/compexp x "$f" ${out}
	# 	fi
	# done
fi

echo "##  Renaming ?BD files ..."
${scriptsDir}/bin/rename_dbd_files *.*[bB][dD] /
echo "##  Renaming ?BD files done."

######################################################

##  BINARY -> TXT
function bd2asc {
	f=$1
	txt_path="../txt/$f.txt"
	if [[ ! -e $txt_path ]]; then
		echo "bd2ascii $f"
		"${scriptsDir}/bin/bd2ascii" "$f" >"$txt_path"
		sed -i "s/ $//" "$txt_path"
	fi
}
export -f bd2asc

cd ${missionDir}/raw
ln -sf ${missionDir}/cache .
ls ${glider}*bd 2>/dev/null | parallel 'bd2asc {}'
rm ${missionDir}/raw/cache

######################################################

cd ${missionDir}/txt

##  REMOVE EMPTY FILES
find . -empty -delete

##  CHECK IF THERE IS ANY NC FILE OLDER THAN A TXT FILE
newestTXTfile=$(ls -tr ${missionDir}/txt | tail -1 | xargs -I{} date -r {} +%s)
newestNCfile=$(ls -tr ${missionDir}/nc | tail -1 | xargs -I{} date -r {} +%s)
if [[ ${newestTXTfile} -gt ${newestNCfile} ]]; then
	python3 ${scriptsDir}/txt2nc.py --glider=${glider} --mode=${processingMode} --metadataFile=${metadataFile}
else
	echo "No new file to process.  Exiting now."
fi
find ${missionDir}/nc -empty -delete

# Ignore files with only 1 timestamp. They're likely to miss some variables. Next step doesn't like it.
# cd ${missionDir}/nc
# mkdir ${missionDir}/nc/ignored
# for f in *.nc; do
# 	i=$(ncdump $f | grep "time =" | head -1 | awk '{print $3}')
# 	if [[ $i -le 1 ]]; then mv -v $f ignored; fi
# done
# find . -type d -empty -delete

# echo "##  profile2traj.py"
# python3 ${scriptsDir}/profile2traj.py ${missionDir} ${processing_mode} ${gliders_db} ${metadata_file}

# rm -r ${missionDir}/nc/dask-worker-space
