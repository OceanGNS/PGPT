import sys
import glob
import xarray as xr
import pandas as pd
from gliderfuncs import correct_dead_reckoning, findProfiles
from data2attr import save_netcdf

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
	nc_path, processing_mode, gliders_db, metadata_source = sys.argv[1:5]
	nc_path = nc_path+'/nc/'
	
	# Load and process data
	files = sorted(glob.glob(nc_path + '*{}*.nc'.format(processing_mode)))
	data_list, glider_record_list = [], []
	
	# Collect all variable names from all files and all "glider_record" groups
	all_vars, all_glider_record_vars = set(), set()
	for f in files:
		try:
			tmpData = xr.open_dataset(f, engine='netcdf4', decode_times=False)
			all_vars.update(tmpData.data_vars)
			
			tmpGliderRecordData = xr.open_dataset(f, engine='netcdf4', group='glider_record', decode_times=False)
			all_glider_record_vars.update(tmpGliderRecordData.data_vars)
		except Exception as e:
			print('Ignore {}. Error: {}'.format(f, e))
	
	for f in files:
		try:
			tmpData = xr.open_dataset(f, engine='netcdf4', decode_times=False)
			tmpData = add_missing_variables(tmpData, all_vars)
			data_list.append(tmpData)
			
			tmpGliderRecordData = xr.open_dataset(f, engine='netcdf4', group='glider_record', decode_times=False)
			tmpGliderRecordData = add_missing_variables(tmpGliderRecordData, all_glider_record_vars)
			glider_record_list.append(tmpGliderRecordData)
			
			print('Processed {}'.format(f))
		except Exception as e:
			print('Ignore {}. Error: {}'.format(f, e))
	
	raw_data = xr.concat(glider_record_list, dim='time').sortby('time').to_dataframe().reset_index()
	data = xr.concat(data_list, dim='time').sortby('time').to_dataframe().reset_index()
		
	
	# Calculate profile index and correct lon/lat using the dead reckoning correction
	data = process_data(data, raw_data)
	
	# This needs to be done automatically based on the file attributes!!!
	filename = 'echo-trajectory_file.nc'
	
	# Set file encoder and data type
	source_info = {
		'gliders_db': gliders_db,
		'metadata_source': metadata_source,
		'encoder': 'glider_dac_3.0_conventions.yml',
		'processing_mode': processing_mode,
		'data_type': 'trajectory',
		'data_source': files,
		'filename': filename,
		'filepath': nc_path
	}
	
	# Save trajectory file
	save_netcdf(data, raw_data, source_info)

