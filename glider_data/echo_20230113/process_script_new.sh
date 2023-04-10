#!/bin/bash

# Set variables
glider="echo"
mission_dir="$PWD/delayed"
parent_dir=$(builtin cd "$mission_dir/../../../"; pwd)
scripts_dir="$parent_dir/glider_processing_scripts"
gliders_db="$parent_dir/glider_reference_information/glider_serial-numbers_and_sensor-serial-numbers.csv"
metadata_file="$PWD/master.yml"

# Create directories
cd "${mission_dir}/"
mkdir -p txt nc

# Set raw directory
raw_dir="${mission_dir}/raw"
cd "$raw_dir"

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

# Convert binary to text
convert_binary_to_text() {
  ln -s ../cache .
  for f in ${glider}*bd; do
    if [[ ! -e ../txt/$f.txt ]]; then
      echo "$f"
      ${scripts_dir}/bd2ascii "$f" > ../txt/$f.txt
      sed -i 's/ $//' ../txt/$f.txt  ## Remove empty space from the end of each line (pandas doesn't like them)
    fi
  done
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
      python3 ${scripts_dir}/NEW_delayed2nc.py $f ${gliders_db} ${metadata_file}
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