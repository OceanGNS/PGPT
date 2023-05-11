#!/usr/bin/env bash

# Set variables

export glider="$1"
export mission_dir="$2"
export scripts_dir="$3"
export gliders_db="$4"
export metadata_file="$5"
export processing_mode="$6"

# Decompress files
decompress_files() {
  f=$1
  out="$(echo $f | sed 's/cd$/bd/')"
  echo "##  DECOMPRESSING $f TO ${out}"
  ${scripts_dir}/bin/compexp x "$f" ${out}
  # rm "$f"  ## Uncomment if you don't want to keep compressed files
}
export -f decompress_files

# Rename files
rename_files() {
  echo "##  RENAMING DBD FILES ..."
  ${scripts_dir}/bin/rename_dbd_files *.*bd /
}

convert_binary_to_text() {
  f=$1
  if [[ ! -e ../txt/$f.txt ]]; then
    echo "bd2ascii $f"
    "${scripts_dir}/bin/bd2ascii" "$f" >"../txt/$f.txt"
    sed -i "s/ $//" "../txt/$f.txt" ## Remove empty space from the end of each line (pandas doesn't like them)
  fi
}
export -f convert_binary_to_text

# Convert to NetCDF
convert_to_netcdf() {
  # Create *.nc profile files
  echo "##  asc2profile.py"
  python3 ${scripts_dir}/asc2profile.py ${glider} ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}

  # Create trajectory file
  echo "##  profile2traj.py"
  python3 ${scripts_dir}/profile2traj.py ${mission_dir} ${processing_mode} ${gliders_db} ${metadata_file}

  rm -r ${mission_dir}/txt/dask-worker-space
}

# Main function
main() {
  # Create directories
  cd ${mission_dir}
  rm -r txt nc 2>/dev/null
  mkdir -p txt nc

  ##  DECOMPRESS RAW FILES
  cd "${mission_dir}/raw"
  ls *.?cd | parallel "decompress_files {}"

  ##  RENAME RAW FILES
  cd "${mission_dir}/raw"
  rename_files

  ## Check if cache directory exists
  if [[ ! -e ../cache ]]; then
    mkdir ../cache
  fi

  ## Create symbolic link if it doesn't exist
  if [[ ! -L cache ]]; then
    ln -nsf ${mission_dir}/cache .
  fi
  cd ${mission_dir}/raw
  ln -s ${mission_dir}/cache . 2>/dev/null

  ## Check if files are present and then convert them to ascii *.txt files
  if [[ -n "$(ls ${glider}*bd)" ]]; then
    ls ${glider}*bd | parallel "convert_binary_to_text {}"
  else
    echo "No files found matching pattern '${glider}*bd'"
  fi
  rm ${mission_dir}/raw/cache

  # ASCII -> NC
  cd "${mission_dir}/txt"
  convert_to_netcdf
}

# Run main function
main
