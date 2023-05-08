#!/usr/bin/env bash

# Set variables

glider="$1"
mission_dir="$2"
parent_dir=$3
scripts_dir="$4"
gliders_db="$5"
metadata_file="$6"
processing_mode="$7"

# Create directories
cd "${mission_dir}/"
rm -r txt nc 2>/dev/null
mkdir -p txt nc

# Set raw directory
raw_dir="${mission_dir}/raw"
cd "${raw_dir}/"

# Decompress files
decompress_files() {
  for f in *.?cd; do
    out="$(echo $f | sed 's/cd$/bd/')"
    echo "##  DECOMPRESSING $f TO ${out} ..."
    ${scripts_dir}/bin/compexp x "$f" ${out}
    # rm "$f"  ## Uncomment if you don't want to keep compressed files
    echo " ... done"
  done
}

# Rename files
rename_files() {
  echo "##  RENAMING DBD FILES ..."
  ${scripts_dir}/bin/rename_dbd_files *.*bd /
}

convert_binary_to_text() {
  # Check if cache directory exists
  if [[ ! -e ../cache ]]; then
    mkdir ../cache
  fi

  # Create symbolic link if it doesn't exist
  if [[ ! -L cache ]]; then
    ln -nsf ${mission_dir}/cache .
  fi

  # Check if files are present and then convert them to ascii *.txt files
  if [[ -n "$(ls ${glider}*bd)" ]]; then
    for f in ${glider}*bd; do
      if [[ ! -e ../txt/$f.txt ]]; then
        echo "bd2ascii $f"
        "${scripts_dir}/bin/bd2ascii" "$f" >"../txt/$f.txt"
        sed -i "s/ $//" "../txt/$f.txt" ## Remove empty space from the end of each line (pandas doesn't like them)
      fi
    done
  else
    echo "No files found matching pattern '${glider}*bd'"
  fi

  # Remove symbolic link
  rm cache
}

# Convert to NetCDF
convert_to_netcdf() {
  cd "${mission_dir}/txt"

  # Create *.nc profile files
  echo "##  asc2profile.py"
  python3 ${scripts_dir}/asc2profile.py ${glider} ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}

  # Create trajectory file
  echo "##  profile2traj.py"
  python3 ${scripts_dir}/profile2traj.py ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}
}

# Main function
main() {
  decompress_files
  rename_files
  convert_binary_to_text
  convert_to_netcdf
}

# Run main function
main
