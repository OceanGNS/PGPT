#!/usr/bin/env bash

# Set variables
glider="$1"
mission_dir="$2"
scripts_dir="$3"
gliders_db="$4"
metadata_file="$5"
processing_mode="$6"

# Create directories
cd "${mission_dir}/"
mkdir -p txt nc

# Set raw directory
raw_dir="${mission_dir}/raw"
cd "${raw_dir}/"

# Decompress files
decompress_files() {
  for f in *.?cd; do
    ${scripts_dir}/bin/compexp x "$f" "$(echo $f | sed 's/cd$/bd/')"
    # rm "$f"  ## Uncomment if you don't want to keep compressed files
  done
}

# Rename files
rename_files() {
  ${scripts_dir}/bin/rename_dbd_files *.*bd /
}

convert_binary_to_text() {
  # Check if cache directory exists
  if [[ ! -d ../cache ]]; then
    mkdir ../cache
  fi
  
  # Create symbolic link if it doesn't exist
  if [[ ! -L cache ]]; then
    ln -nsf ${mission_dir}/cache .
  fi
  
  for f in ${glider}*bd; do
    if [[ ! -e ../txt/$f.txt ]]; then
      echo "$f"
      "${scripts_dir}/bin/bd2ascii" "$f" > "../txt/$f.txt"
      sed -i "s/ $//" "../txt/$f.txt"  ## Remove empty space from the end of each line (pandas doesn't like them)
    fi
  done
  
  # Remove symbolic link
  rm cache
}

# Convert to NetCDF
convert_to_netcdf() {
  cd "${mission_dir}/txt"
  
  # Create *.nc profile files
  python3 ${scripts_dir}/asc2profile.py ${glider} ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}
  
  # Create trajectory file
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
