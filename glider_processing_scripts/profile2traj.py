import sys
import glob
import os.path
import xarray as xr
import pandas as pd
import numpy as np
from gliderfuncs import correct_dead_reckoning, findProfiles
from data2attr import save_netcdf

def printF(*args, **kwargs):
    kwargs["flush"] = True
    return print(*args, **kwargs)

# to help with "padding" empty arrays if a glider [s/t/e/b]bd file got lost or corrupted.
def add_missing_variables(dataset, all_vars):
	for var in all_vars:
		if var not in dataset:
			dataset[var] = xr.DataArray(np.nan, dims='time')
	return dataset


def process_data(data, raw_data):
	if 'x_dr_state' in raw_data.keys() and all(key in raw_data.keys() for key in ['m_gps_lon', 'm_gps_lat', 'm_lat', 'm_lon']):
		data['lon_qc'], data['lat_qc'] = correct_dead_reckoning(raw_data['m_lon'], raw_data['m_lat'], raw_data['time'], raw_data['x_dr_state'], raw_data['m_gps_lon'], raw_data['m_gps_lat'])
	
	if 'depth' in data.keys():
		data['profile_index'], data['profile_direction'] = findProfiles(data['time'], data['depth'], stall=20, shake=200)
	
	return data
	
if __name__ == '__main__':
	# Take inputs from the bash script
	mission_dir, processing_mode, gliders_db, metadata_source = sys.argv[1:5]
	
	# Create attribute settings
	encoder_file = os.path.join(os.path.join(os.path.dirname(os.path.realpath(__file__)), './attributes/') , 'glider_dac_3.0_conventions.yml')
	
	# Set file encoder and data type
	source_info = {
		'gliders_db': gliders_db,
		'metadata_source': metadata_source,
		'encoder': encoder_file,
		'processing_mode': processing_mode,
		'data_type': 'trajectory',
		'data_source': '',
		'filename': '',
		'filepath': mission_dir+'/nc/'
	}
	
	# Load and process data
	printF(source_info['filepath'] + '*{}*.nc'.format(processing_mode))
	files = sorted(glob.glob(source_info['filepath'] + '*{}*.nc'.format(processing_mode)))
	data_list, glider_record_list = [], []
	source_info['data_source'] = files
	
	# Collect all variable names from all files and all "glider_record" groups
	all_vars, all_glider_record_vars = set(), set()
	for f in files:
		try:
			tmpData = xr.open_dataset(f, engine='netcdf4', decode_times=False)
			all_vars.update(tmpData.data_vars)
			tmpGliderRecordData = xr.open_dataset(f, engine='netcdf4', group='glider_record', decode_times=False)
			all_glider_record_vars.update(tmpGliderRecordData.data_vars)
		except Exception as e:
			printF('Ignore {}. Error: {}'.format(f, e))
	
	source_info['filename'] = tmpData.deployment_name.split('T')[0]+'-'+source_info['processing_mode']+'_trajectory_file.nc'
	
	
	for f in files:
		try:
			tmpData = xr.open_dataset(f, engine='netcdf4', decode_times=False)
			tmpData = add_missing_variables(tmpData, all_vars)
			data_list.append(tmpData)
			
			tmpGliderRecordData = xr.open_dataset(f, engine='netcdf4', group='glider_record', decode_times=False)
			tmpGliderRecordData = add_missing_variables(tmpGliderRecordData, all_glider_record_vars)
			glider_record_list.append(tmpGliderRecordData)
			
			printF('Processed {}'.format(f))
		except Exception as e:
			printF('Ignore {}. Error: {}'.format(f, e))
		
	raw_data = xr.concat(glider_record_list, dim='time').sortby('time').to_dataframe().reset_index()
	data = xr.concat(data_list, dim='time').sortby('time').to_dataframe().reset_index()
	
		

	# Calculate profile index and correct lon/lat using the dead reckoning correction
	data = process_data(data, raw_data)
		
	# Save trajectory file
	save_netcdf(data, raw_data, source_info)

