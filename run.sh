#!/usr/bin/env bash

usage() {
	echo "Usage: $(basename $0) -g glider_name -d mission_directory -m metadata_file_name -p mode(realtime|delayed) [-t CGDACusername]"
}

while getopts ":g:d:m:p:t::" opt; do
	case "${opt}" in
	g)
		glider=${OPTARG}
		;;

	d)
		missionDir=${OPTARG}
		;;

	m)
		metadataFile=${OPTARG}
		;;

	p)
		processingMode=${OPTARG}
		;;

	t)
		CGDAC_username=${OPTARG}
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

script=$(realpath $0)
export scriptsDir=$(dirname ${script})/scripts

######################################################
####  INITIAL CHECKS
bash ${scriptsDir}/check.sh ${scriptsDir} ${missionDir} ${metadataFile} ${processingMode}
if [[ $? -ne 0 ]]; then
	exit 1
fi

######################################################

##  PREPARE DIRECTORIES
# mkdir -p ${missionDir}/{txt,nc}
mkdir -p ${missionDir}/${processingMode}/nc

##  DECOMPRESS & RENAME FILES
cd ${missionDir}/${processingMode}/raw
n=$(ls *.?[cC][dD] | wc -l)
if [[ $n -eq 0 ]]; then
	echo "No compressed files found.  Moving on ..."
else
	echo "Decompressing files ..."
	ls *.?[cC][dD] | parallel "out=$(echo {} | sed 's/cd$/bd/') ; ${scriptsDir}/bin/compexp x {} ${out}"
	echo "Decompression done."
fi

echo "##  Renaming ?BD files ..."
${scriptsDir}/bin/rename_dbd_files *.*[bB][dD] /
echo "##  Renaming ?BD files done."

######################################################

##  LOWERCASE CACHE FILES (NEEDED BY "dbdreader")
cd ${missionDir}/cache
for f in $(find .); do
	ln -s "$f" "$(echo $f | tr '[A-Z]' '[a-z]')"
done

######################################################

cd ${missionDir}/${processingMode}/raw

##  CHECK IF THERE IS ANY NC FILE OLDER THAN A TXT FILE
newestRAWfile=$(ls -tr ${missionDir}/${processingMode}/raw | tail -1 | xargs -I{} date -r {} +%s)
newestNCfile=$(ls -tr ${missionDir}/${processingMode}/nc | tail -1 | xargs -I{} date -r {} +%s)

if [[ ${newestRAWfile} -gt ${newestNCfile} ]]; then
	python3 ${scriptsDir}/bd2nc.py --glider=${glider} --mode=${processingMode} --metadataFile=${metadataFile}
	# python3 ${scriptsDir}/bd2nc_oldMissions.py --glider=${glider} --mode=${processingMode} --metadataFile=${metadataFile}
else
	echo "No new file to process.  Exiting now."
fi
find ${missionDir}/${processingMode}/nc -empty -delete

##  UPLOAD NC FILES TO CGDAC
# CREATE A NEW DEPLOYMENT
if [[ ! -z ${CGDAC_username} ]]; then
	if [[ ${processingMode} == 'delayed' ]]; then delayedModeBool=true; fi
	deplymentDate=$(grep deployment_date ${metadataFile} | awk '{print $2}' | cut -dT -f1 | sed 's/-//g')T0000

	curl -X 'POST' \
		"https://cgdac.ca/api/deployment/?username=${CGDAC_username}&deployment_name=${glider}&deployment_date=${deplymentDate}&delayed_mode=${delayedModeBool}" \
		-H 'accept: application/json' \
		-H "X-API-KEY: ${token}" \
		-d ''

	deploymentName="${glider}-${deplymentDate}"
	if [[ ${processingMode} == 'delayed' ]]; then deploymentName="${deploymentName}-delayed"; fi

	for f in *.nc; do
		curl -X 'POST' \
			"https://cgdac.ca/api/deployment_file/?username=${CGDAC_username}&deployment_name=${deploymentDate}" \
			-H 'accept: application/json' \
			-H "X-API-KEY: ${token}" \
			-H 'Content-Type: multipart/form-data' \
			-F "file=@${f};type=application/x-netcdf"
	done
fi
