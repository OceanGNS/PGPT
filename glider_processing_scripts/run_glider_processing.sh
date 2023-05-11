#!/usr/bin/env bash

# Set variables
glider="$1"
mission_dir="$2"
scripts_dir="$3"
gliders_db="$4"
metadata_file="$5"
processing_mode="$6"

# Check if raw directory exists
if [[ -d "${mission_dir}/raw" ]]; then
    # Prepare directories
    mkdir -p ${mission_dir}/{txt,nc,cache}

    cd "${mission_dir}/raw"

    # Decompress and rename files
    ls *.?cd | while read f; do
        out="$(echo $f | sed 's/cd$/bd/')"
        # Check if decompressed file already exists
        if [[ ! -e $out ]]; then
            echo "##  DECOMPRESSING $f TO ${out}"
            ${scripts_dir}/bin/compexp x "$f" ${out}
        fi
    done

    echo "##  RENAMING DBD FILES ..."
    ${scripts_dir}/bin/rename_dbd_files *.*bd /

    # Create symbolic link to cache
    ln -sf ${mission_dir}/cache .

    # Convert binary files to text
    ls ${glider}*bd 2>/dev/null | while read f; do
        txt_path="../txt/$f.txt"
        if [[ ! -e $txt_path ]]; then
            echo "bd2ascii $f"
            "${scripts_dir}/bin/bd2ascii" "$f" >"$txt_path"
            sed -i "s/ $//" "$txt_path"
        fi
    done

    rm ${mission_dir}/raw/cache
fi

# Check if txt directory exists
if [[ -d "${mission_dir}/txt" ]]; then
    cd "${mission_dir}/txt"

    # Check if any files in nc directory have been modified in the last day
    if [[ -z $(find "${mission_dir}/nc" -mtime 0) ]]; then
        # Convert to NetCDF
        echo "##  asc2profile.py"
        python3 ${scripts_dir}/asc2profile.py ${glider} ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}
    fi

    echo "##  profile2traj.py"
    python3 ${scripts_dir}/profile2traj.py ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}

    rm -r ${mission_dir}/txt/dask-worker-space
fi
