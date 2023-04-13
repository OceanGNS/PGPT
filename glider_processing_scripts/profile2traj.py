import sys
import glob
import xarray as xr
import pandas as pd
from functions import correct_dead_reckoning, findProfiles
from attributes import save_netcdf

def load_data(nc_path, processing_mode):
	files = sorted(glob.glob(nc_path + '*{}*.nc'.format(processing_mode)))
	data_list, glider_record_list = [], []
	
	for f in files:
		try:
			tmpData = xr.open_dataset(f, engine='netcdf4', decode_times=False)
			data_list.append(tmpData)
			tmpGliderRecordData = xr.open_dataset(f, engine='netcdf4', group='glider_record', decode_times=False)
			glider_record_list.append(tmpGliderRecordData)
			print('Processed {}'.format(f))
		except Exception as e:
			print('Ignore {}. Error: {}'.format(f, e))
	
	raw_data = xr.concat(glider_record_list, dim='time').sortby('time').to_dataframe().reset_index()
	data = xr.concat(data_list, dim='time').sortby('time').to_dataframe().reset_index()
	
	return data, raw_data

def process_data(data, raw_data):
	if 'x_dr_state' in raw_data.keys() and all(key in raw_data.keys() for key in ['m_gps_lon', 'm_gps_lat', 'm_lat', 'm_lon']):
		data['lon_qc'], data['lat_qc'] = correct_dead_reckoning(raw_data['m_lon'], raw_data['m_lat'], raw_data['time'], raw_data['x_dr_state'], raw_data['m_gps_lon'], raw_data['m_gps_lat'])
	
	if 'depth' in data.keys():
		data['profile_index'], data['profile_direction'] = findProfiles(data['time'], data['depth'], stall=20, shake=200)
	
	return data
if __name__ == '__main__':
	# Take inputs from the bash script
	nc_path, processing_mode, gliders_db, metadata_source = sys.argv[1:5]
	
	# Load and process data
	data, raw_data = load_data(nc_path, processing_mode)
	data = process_data(data, raw_data)
	
	# This needs to be done automatically based on the file attributes!!! 
	out_fname = 'echo-trajectory_file.nc'
	
	# Set file encoder and data type
	encoder, data_type = 'glider_dac_3.0_conventions.yml', 'trajectory'
	
	# Save trajectory file
	save_netcdf(out_fname, nc_path, data, raw_data, gliders_db, metadata_source, encoder, processing_mode, data_type)

