#!/usr/bin/env bash


glider="echo"

# Specify processing mode
# this should be used to pick between delayed and realtime mode.
processing_mode="delayed"

# Set path variables
mission_dir="$PWD/${processing_mode}"
parent_dir=$(builtin cd "$mission_dir/../../../"; pwd)
scripts_dir="$parent_dir/glider_processing_scripts"
gliders_db="$parent_dir/glider_reference_information/glider_serial-numbers_and_sensor-serial-numbers.csv"
metadata_file="$PWD/metadata.yml"

# Run the processing toolbox
source ${scripts_dir}/run_glider_processing.sh "$glider" "$mission_dir" "$parent_dir" "$scripts_dir" "$gliders_db" "$metadata_file" "$processing_mode"