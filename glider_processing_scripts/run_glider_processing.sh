#!/usr/bin/env bash

# Set variables
export glider="$1"
export mission_dir="$2"
export scripts_dir="$3"
export gliders_db="$4"
export metadata_file="$5"
export processing_mode="$6"

# Check if raw directory exists
if [[ -d "${mission_dir}/raw" ]]; then
	# Prepare directories
	mkdir -p ${mission_dir}/{txt,nc}

	cd "${mission_dir}/raw"

	# Decompress and rename files
	ls *.?[cC][dD] | while read f; do
		out="$(echo $f | sed 's/cd$/bd/')"
		# Check if decompressed file already exists
		if [[ ! -e $out ]]; then
			echo "##  DECOMPRESSING $f TO ${out}"
			${scripts_dir}/bin/compexp x "$f" ${out}
		fi
	done

	echo "##  RENAMING DBD FILES ..."
	${scripts_dir}/bin/rename_dbd_files *.*[bB][dD] /

	# Create symbolic link to cache
	ln -sf ${mission_dir}/cache .

	# Convert binary files to text
	function dbd2asc {
		f=$1
		txt_path="../txt/$f.txt"
		if [[ ! -e $txt_path ]]; then
			echo "bd2ascii $f"
			"${scripts_dir}/bin/bd2ascii" "$f" >"$txt_path"
			sed -i "s/ $//" "$txt_path"
		fi
	}
	export -f dbd2asc

	cd "${mission_dir}/raw"
	ls ${glider}*bd 2>/dev/null | parallel 'dbd2asc {}'

	rm ${mission_dir}/raw/cache
fi

# Check if txt directory exists
if [[ -d "${mission_dir}/txt" ]]; then
	cd "${mission_dir}/txt"

	# REMOVE EMPTY FILES
	find . -empty -delete

	# Check if any files in nc directory have been modified in the last day
	if [[ -z $(find "${mission_dir}/nc" -mtime 0) ]]; then
		# Convert to NetCDF
		echo "##  asc2profile.py"
		python3 ${scripts_dir}/asc2profile.py ${glider} ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}
	fi

	# Ignore files with only 1 timestamp. They're likely to miss some variables. Next step doesn't like it.
	cd ${mission_dir}/nc
	mkdir ${mission_dir}/nc/ignored
	for f in *.nc; do
		i=$(ncdump $f | grep "time =" | head -1 | awk '{print $3}')
		if [[ $i -le 1 ]]; then mv -v $f ignored; fi
	done

	echo "##  profile2traj.py"
	python3 ${scripts_dir}/profile2traj.py ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}

	rm -r ${mission_dir}/nc/dask-worker-space
fi
