#!/usr/bin/env bash

# Set variables
glider="$1"
mission_dir="$2"
parent_dir="$3"
scripts_dir="$4"
gliders_db="$5"
metadata_file="$6"
processing_mode="$7"

# Create directories
cd "${mission_dir}/"
mkdir -p txt nc

# Set raw directory
raw_dir="${mission_dir}/raw"

# Decompress files
decompress_files() {
  for f in *.?cd; do
    ${scripts_dir}/compexp x "$f" "$(echo $f | sed 's/cd$/bd/')"
    # rm "$f"  ## Uncomment if you don't want to keep compressed files
  done
}

# Rename files
rename_files() {
  ${scripts_dir}/rename_dbd_files *.*bd /
}

convert_binary_to_text() {
  # Check if cache file exists
  if [[ ! -e ../cache ]]; then
    touch ../cache
  fi
  
  # Create symbolic link
  ln -sf ../cache .
  
  for f in ${glider}*bd; do
    if [[ ! -e ../txt/$f.txt ]]; then
      echo "$f"
      ${scripts_dir}/bd2ascii "$f" > ../txt/$f.txt
      sed -i 's/ $//' ../txt/$f.txt  ## Remove empty space from the end of each line (pandas doesn't like them)
    fi
  done
  
  # Remove symbolic link
  rm cache
}



# Convert to NetCDF
convert_to_netcdf() {
  cd "${mission_dir}/txt"
  ln -s ${scripts_dir}/functions.py
  ln -s ${scripts_dir}/addAttrs.py
  ln -s ${scripts_dir}/dbd_filter.csv
  ln -s ${scripts_dir}/GDAC_IOOS_ENCODER.yml
  
  for f in $(ls ${glider}*.[de]bd.txt | sed 's/\..bd\.txt//' | sort -u); do
    if [[ ! -e ../nc/$f.nc ]]; then
      python3 ${scripts_dir}/delayed2nc.py $f ${gliders_db} ${metadata_file}
    fi
  done
  
  rm dbd_filter.csv functions.py addAttrs.py GDAC_IOOS_ENCODER.yml
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