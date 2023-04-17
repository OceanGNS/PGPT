import argparse
import os.path
import csv
import numpy as np
import pandas as pd
from gliderfuncs import p2depth, dm2d, deriveCTD, deriveO2
from data2attr import save_netcdf
from quartod_qc import quartod_qc_checks

# remove empty arrays and nanmean slice warnings
import warnings
warnings.simplefilter(action="ignore", category=pd.errors.PerformanceWarning)
warnings.simplefilter("ignore", category=RuntimeWarning)

def read_bd_data(filename, var_filter):
	"""
	Reads *.bd data from a given file and filters the columns based on the provided filter.
	
	:param filename: str, path to the file containing .bd data
	:param var_filter: list, a list of column names to filter the data
	:return: pd.DataFrame, filtered data
	"""
	try:
		data = pd.read_csv(filename, delimiter=' ', skiprows=[*range(14), 15, 16])
		if var_filter is not None:
			data = data.filter(var_filter, axis='columns')
		return data.rename(columns={'m_present_time': 'time', 'sci_m_present_time': 'time'})
	except Exception as e:
		logging.error(f'Error reading {filename}: {str(e)}')
		return pd.DataFrame()  # Return an empty DataFrame in case of error

def read_var_filter():
	with open('dbd_filter.csv', 'r') as fid:
		return next(csv.reader(fid, delimiter=','))
	
def process_data(data, source_info):
	def update_columns(data, cols, func):
		data.update({col: func(data[col]) for col in cols if col in data.keys()})
	
	update_columns(data, ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], dm2d)
	update_columns(data, ['c_fin', 'c_heading', 'c_pitch', 'm_fin', 'm_heading', 'm_pitch', 'm_roll'], np.degrees)
	
	if 'sci_water_pressure' in data:
		data['sci_water_pressure'] *= 10
	
	if 'm_pressure' in data:
		data['m_pressure'] *= 10
	
	# Basic clipping of data
	if all(k in data for k in ['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']):
		data.update({k: np.clip(data[k], *r) for k, r in zip(['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], [(-90, 90), (-180, 180)] * 2)})

	if all(k in data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']):
		data.update({k: np.clip(data[k], *r) for k, r in zip(['sci_water_cond', 'sci_water_temp', 'sci_water_pressure'], [(0, 7), (-1.9, 40), (-1.9, 1200)])})
	
	if 'sci_oxy4_oxygen' in data:
		data['sci_oxy4_oxygen'] = np.clip(data['sci_oxy4_oxygen'], 0, 500)
	
	if 'sci_water_pressure' in data:
		data['sci_water_depth'] = p2depth(data['sci_water_pressure'],time=data['time'],interpolate=True, tgap=5)
	
	glider_data = data.copy()
	data = pd.DataFrame()
	
	# Store and rename variables in the "data" pd.dataframe
	data['time'], data['lat'], data['lon'] = glider_data['time'], glider_data['m_gps_lat'], glider_data['m_gps_lon']
	data['profile_time'], data['profile_lat'], data['profile_lon'] = data['time'].mean(), data['lat'].mean(), data['lon'].mean()
	data['u'], data['v'], data['time_uv'], data['lat_uv'], data['lon_uv'] = glider_data['m_final_water_vx'], glider_data['m_final_water_vy'], data['time'], data['lat'], data['lon']
	
	# derive CTD sensor data
	if all(k in glider_data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']):
		data['conductivity'],data['temperature'],data['depth'], data['pressure']=glider_data['sci_water_cond'],glider_data['sci_water_temp'],glider_data['sci_water_depth'],glider_data['sci_water_pressure']
		data['salinity'],data['absolute_salinity'],data['conservative_temperature'],data['density']=deriveCTD(data['conductivity'],data['temperature'],data['pressure'],data['lat'],data['lat'])
	
	# dervice oxygen sensor data
	if all(k in glider_data.keys() for k in ['sci_oxy4_oxygen', 'sci_water_temp', 'sci_water_pressure']):
		data['oxygen_concentration'] = deriveO2(glider_data['sci_oxy4_oxygen'], glider_data['sci_water_temp'], data['salinity'],time=data['time'],interpolate=True, tgap=20)
	
	if 'sci_oxy4_temp' in glider_data:
		data['oxygen_sensor_temperature'] = glider_data['sci_oxy4_temp']
	
	# optical sensors (if present)
	chlorophyll_list = ['sci_flbbrh_chlor_units', 'sci_flbbcd_chlor_units', 'sci_flbb_chlor_units', 'sci_flntu_chlor_units']
	for k in chlorophyll_list:
		if k in glider_data:
			data['chlorophyll_a'] = glider_data[k]
			break
	
	cdom_list = ['sci_fl3slo_cdom_unit', 'sci_fl3sloV2_cdom_units', 'sci_flbbcd_cdom_units', 'sci_fl2PeCdom_cdom_units']
	for k in cdom_list:
		if k in glider_data:
			data['cdom'] = glider_data[k]
			break
			
	# Quartod qc checks and with nans anywhere where the data is questionable for a rough qc
	qc_list = ['temperature', 'salinity','pressure','conductivity','density']
	for k in qc_list:
		if k in data:
			qc_variable = k + '_qc'
			data[qc_variable] = quartod_qc_checks(data[k].values, data['time'].values, k)
	
	# convert & save glider *.bd files to *.nc files
	name, ext = os.path.splitext(source_info['filename'])
	filename, bd_ext = os.path.splitext(name)
	source_info['filename'] = filename+'_delayed.nc'
	source_info['filepath'] = source_info['filepath']+'/nc/'
	save_netcdf(data, glider_data, source_info)
	
def main(source_info):
	# Validate command-line arguments
	file_types = ['dbd', 'sbd', 'tbd', 'ebd']
	filename = source_info['filename']
	name, ext = os.path.splitext(filename)
	name, ebd_ext = os.path.splitext(name)
	filename = name
	
	file_exists = any(os.path.isfile(f'{filename}.{file_type}.txt') for file_type in file_types)
	if not file_exists:
		raise FileNotFoundError(f'No matching file found for {filename} with extensions .dbd.txt, .sbd.txt, .tbd.txt, or .ebd.txt')
	
	var_filter = read_var_filter()
	if source_info['processing_mode'] == 'delayed':
		flight_data = read_bd_data(f'{filename}.dbd.txt', var_filter)
		science_data = read_bd_data(f'{filename}.ebd.txt', None)
	elif source_info['processing_mode'] == 'realtime':
		flight_data = read_bd_data(f'{filename}.sbd.txt', None)
		science_data = read_bd_data(f'{filename}.tbd.txt', None)
	else:
		raise ValueError("Invalid processing mode. Supported modes are 'delayed_mode' and 'realtime'.")
	
	# Merge records and sort by time
	data = pd.concat([df for df in [flight_data, science_data] if not df.empty], ignore_index=True, sort=True).sort_values(by=['time'])
	
	# Process and save data as netCDF
	process_data(data, source_info)

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('filename', help='name of the input file')
	parser.add_argument('filepath', help='path of the input file')
	parser.add_argument('processing_mode',help='processing mode')
	parser.add_argument('gliders_db', help='name of the glider database')
	parser.add_argument('metadata', help='name of the metadata file')
	arg_info = parser.parse_args()
	
	source_info = {
		'encoder': 'glider_dac_3.0_conventions.yml',
		'data_type': 'profile',
		'gliders_db': arg_info.gliders_db,
		'metadata_source': arg_info.metadata,
		'processing_mode': arg_info.processing_mode,
		'data_source': arg_info.filename,
		'filename': arg_info.filename,
		'filepath': arg_info.filepath
	}
	main(source_info)
	
