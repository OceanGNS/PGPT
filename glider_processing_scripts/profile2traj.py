import os
import sys
import glob
import xarray as xr
import pandas as pd
import numpy as np
import math

from gliderfuncs import correct_dead_reckoning, findProfiles
from data2attr import save_netcdf

import multiprocessing
import dask.distributed as dd

import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="multiprocessing.resource_tracker")
warnings.filterwarnings("ignore", category=UserWarning, module="distributed.worker")

import logging
logging.getLogger("distributed").setLevel(logging.ERROR)


# Use distributed.Client instead of dask.distributed.Client
# Use local_cluster instead of LocalCluster
def create_client():
	from dask.distributed import Client, LocalCluster
	#
	try:
		multiprocessing.get_start_method()
	except:
		multiprocessing.set_start_method("forkserver", force=True)
	#
	cluster = LocalCluster(
		processes=True,
		n_workers=multiprocessing.cpu_count(),
		threads_per_worker=2,
		dashboard_address=":0",
		memory_limit='4GB' # Set memory limit per worker here
	)
	client = Client(cluster, set_as_default=True)
	#
	# Print Dask cluster configuration/settings
	scheduler_info = client.scheduler_info()
	print("Dask Cluster Configuration:")
	print(f"  Number of Workers: {len(scheduler_info['workers'])}")
	print(f"  Threads per Worker: {next(iter(scheduler_info['workers'].values()))['nthreads']}")
	print(f"  Memory Limit per Worker: {next(iter(scheduler_info['workers'].values()))['memory_limit']}")
	print(f"  Dashboard Address: {client.cluster.dashboard_link}")
	#
	return client

# to help with "padding" empty arrays if a glider [s/t/e/b]bd file got lost or corrupted.
#T  Not working, as "all_vars" is empty.
def add_missing_variables(dataset, all_vars):
	for var in all_vars:
		if var not in dataset:
			dataset[var] = xr.DataArray(np.full_like(dataset['time'], np.nan), dims='time')
	return dataset

def process_data(data, raw_data):
	if 'x_dr_state' in raw_data.keys() and all(key in raw_data.keys() for key in ['m_gps_lon', 'm_gps_lat', 'm_lat', 'm_lon']):
		data['lon_qc'], data['lat_qc'] = correct_dead_reckoning(raw_data['m_lon'], raw_data['m_lat'], raw_data['time'], raw_data['x_dr_state'], raw_data['m_gps_lon'], raw_data['m_gps_lat'])
	#
	if 'depth' in data.keys():
		data['profile_index'], data['profile_direction'] = findProfiles(data['time'], data['depth'], stall=20, shake=200)
	#
	return data

def read_in_chunks(files, chunk_size=256):
	for i in range(0, len(files), chunk_size):
		yield files[i:i + chunk_size]

if __name__ == '__main__':
	client = create_client()
	mission_dir, processing_mode, gliders_db, metadata_source = sys.argv[1:5]
	encoder_file = os.path.join(os.path.join(os.path.dirname(os.path.realpath(__file__)), './attributes/'), 'glider_dac_3.0_conventions.yml')
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
	#
	files = sorted(glob.glob(source_info['filepath'] + '*{}*.nc'.format(processing_mode)))
	source_info['data_source'] = files
	#
	all_vars, all_glider_record_vars = set(), set() #T  This is empty, and remains empty throught the whole process!
	first_file = True
	#
	# file_chunks = read_in_chunks(files)
	data_list, glider_data_list = [], []
	chunk_size = 256
	file_chunks = [files[i*chunk_size:(i+1)*chunk_size] for i in range(math.ceil(len(files)/chunk_size))]
	for chunk_files in file_chunks:
		#with xr.open_mfdataset(chunk_files, engine='netcdf4', combine='by_coords', decode_times=False, parallel=True).load() as data_chunk:
		with xr.open_mfdataset(chunk_files, engine='netcdf4', combine='nested', concat_dim='time', decode_times=False, parallel=True).load() as data_chunk:
			# data_chunk = add_missing_variables(data_chunk, all_vars)  #T  This line doesn't do anything.
			data_chunk = data_chunk.sortby('time').to_dataframe().reset_index()
			data_list.append(data_chunk)
		#
		#with xr.open_mfdataset(chunk_files, engine='netcdf4', group='glider_record', combine='by_coords', decode_times=False, parallel=True).load() as glider_data_chunk:
		with xr.open_mfdataset(chunk_files, engine='netcdf4', group='glider_record', combine='nested',concat_dim='time', decode_times=False, parallel=True).load() as glider_data_chunk:
			# glider_data_chunk = add_missing_variables(glider_data_chunk, all_glider_record_vars)  #T  This line doesn't do anything.
			glider_data_chunk = glider_data_chunk.sortby('time').to_dataframe().reset_index()
			glider_data_list.append(glider_data_chunk)
		#
		if first_file:
			with xr.open_dataset(chunk_files[0], engine='netcdf4', decode_times=False) as first_file_data:
				source_info['filename'] = first_file_data.deployment_name.split('T')[0]+'-'+source_info['processing_mode']+'_trajectory_file.nc'
				first_file = False
				#
				# Delete the trajectory file if it already exists
				output_file = os.path.join(source_info['filepath'], source_info['filename'])
				if os.path.exists(output_file):
					print(output_file)
					os.remove(output_file)
	#
	data = pd.concat(data_list).reset_index()  #T  reset_index here
	glider_data = pd.concat(glider_data_list).reset_index()  #T  reset_index here
	#
	data = process_data(data, glider_data)
	#
	save_netcdf(data, glider_data, source_info)
	#
	# Clean up any leaked semaphore objects
	client.close()
	client.shutdown()