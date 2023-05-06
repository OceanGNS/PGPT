import sys
import glob
import os.path
import xarray as xr
import pandas as pd
import numpy as np
from gliderfuncs import correct_dead_reckoning, findProfiles
from data2attr import save_netcdf
import multiprocessing
import dask.distributed as dd
from dask.diagnostics import ProgressBar


# Use distributed.Client instead of dask.distributed.Client
# Use local_cluster instead of LocalCluster
def create_client():
	from dask.distributed import Client, LocalCluster
	try:
		multiprocessing.get_start_method()
	except:
		multiprocessing.set_start_method('forkserver', force=True)
	# Specify the dashboard_address parameter in LocalCluster
	cluster = LocalCluster(processes=True, n_workers=1, threads_per_worker=1, dashboard_address=':0')
	return Client(cluster, set_as_default=True)

# to help with "padding" empty arrays if a glider [s/t/e/b]bd file got lost or corrupted.
def add_missing_variables(dataset, all_vars):
	for var in all_vars:
		if var not in dataset:
			dataset[var] = xr.DataArray(np.full_like(dataset['time'], np.nan), dims='time')
	return dataset

def process_data(data, raw_data):
	if 'x_dr_state' in raw_data.keys() and all(key in raw_data.keys() for key in ['m_gps_lon', 'm_gps_lat', 'm_lat', 'm_lon']):
		data['lon_qc'], data['lat_qc'] = correct_dead_reckoning(raw_data['m_lon'], raw_data['m_lat'], raw_data['time'], raw_data['x_dr_state'], raw_data['m_gps_lon'], raw_data['m_gps_lat'])
	
	if 'depth' in data.keys():
		data['profile_index'], data['profile_direction'] = findProfiles(data['time'], data['depth'], stall=20, shake=200)
	
	return data

if __name__ == '__main__':
	# Set up the multiprocessing context by calling create_client()
	client = create_client()
	
	# Take inputs from the bash script
	mission_dir, processing_mode, gliders_db, metadata_source = sys.argv[1:5]
	
	# Create attribute settings
	encoder_file = os.path.join(os.path.join(os.path.dirname(os.path.realpath(__file__)), './attributes/'), 'glider_dac_3.0_conventions.yml')
	
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
	print(source_info['filepath'] + '*{}*.nc'.format(processing_mode))
	files = sorted(glob.glob(source_info['filepath'] + '*{}*.nc'.format(processing_mode)))
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
			print('Ignore {}. Error: {}'.format(f, e))

	source_info['filename'] = tmpData.deployment_name.split('T')[0]+'-'+source_info['processing_mode']+'_trajectory_file.nc'

	# Use Dask to load and concatenate the NetCDF files
	# Modify this part of the code to include ProgressBar
	with ProgressBar():
		data = xr.open_mfdataset(files, engine='netcdf4', combine='by_coords', decode_times=False, parallel=True)
		data = add_missing_variables(data, all_vars)
		data = data.sortby('time').to_dataframe().reset_index()

	with ProgressBar():
		glider_data = xr.open_mfdataset(files, engine='netcdf4', group='glider_record', combine='by_coords', decode_times=False, parallel=True)
		glider_data = add_missing_variables(glider_data, all_glider_record_vars)
		glider_data = glider_data.sortby('time').to_dataframe().reset_index()

	# Calculate profile index and correct lon/lat using the dead reckoning correction
	data = process_data(data, glider_data)

	# Save trajectory file
	save_netcdf(data, glider_data, source_info)

	# Clean up any leaked semaphore objects
	#import resource
	#resource.setrlimit(resource.RLIMIT_NOFILE, (resource.getrlimit(resource.RLIMIT_NOFILE)[0], resource.getrlimit(resource.RLIMIT_NOFILE)[0]))