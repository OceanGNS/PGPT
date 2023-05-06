import argparse
import os.path
import csv
import glob
import numpy as np
import pandas as pd
import math
from gliderfuncs import p2depth, dm2d, deriveCTD, deriveO2, findProfiles
from data2attr import save_netcdf
from quartod_qc import quartod_qc_checks


# remove empty arrays and nanmean slice warnings
import warnings
warnings.simplefilter(action="ignore", category=pd.errors.PerformanceWarning)
warnings.simplefilter("ignore", category=RuntimeWarning)

def printF(*args, **kwargs):
    kwargs["flush"] = True
    return print(*args, **kwargs)

def read_bd_data(filename, var_filter, ignore=False):
	"""
	Reads *.bd data from a given file and filters the columns based on the provided filter.
	
	:param filename: str, path to the file containing .bd data
	:param var_filter: list, a list of column names to filter the data
	:param ignore: bool, if True, the variables in the filter will be ignored, else they will be used
	:return: pd.DataFrame, filtered data
	"""
	try:
		data = pd.read_csv(filename, delimiter=' ', skiprows=[*range(14), 15, 16])
		if var_filter is not None:
			if ignore:
				data = data.drop(columns=var_filter, errors='ignore')
			else:
				data = data.filter(var_filter, axis='columns')
		return data.rename(columns={'m_present_time': 'time', 'sci_m_present_time': 'time'})
	except Exception as e:
		# logging.error(f'Error reading {filename}: {str(e)}')
		return pd.DataFrame()  # Return an empty DataFrame in case of error

def read_var_filter(filter_name):
	pwd_dir = os.path.dirname(os.path.realpath(__file__))
	filter_dir = os.path.join(pwd_dir, './bin/')
	filter_file = os.path.join(filter_dir, filter_name)
	
	with open(filter_file, 'r') as fid:
		return [row[0] for row in csv.reader(fid, delimiter=',')]

def process_data(data, source_info):

	# Transform certain columns applying a function to them like "rad2deg"
	def update_columns(data, cols, func):
		data.update({col: func(data[col]) for col in cols if col in data.keys()})

	def fill_exact_zero_with_nan(var):
		# Ensure the array is of a float dtype before assigning NaN
		if np.issubdtype(var.dtype, np.integer):
			var = var.astype(float)
		var[np.isclose(var, 0, atol=1e-7)] = np.nan
		return var
		
	def get_column_or_nan(df, column_name):
		if column_name in df.columns:
			return df[column_name]
		else:
			return np.full(len(df), np.nan)
	
	# Get rid of "zero's" that are measurement or initialization artefacts from sensors.
	for col in data.columns:
		data[col] = fill_exact_zero_with_nan(data[col].values)
	
	update_columns(data, ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], dm2d)
	update_columns(data, ['c_fin', 'c_heading', 'c_pitch', 'm_fin', 'm_heading', 'm_pitch', 'm_roll'], np.degrees)
	
	# Convert bar to dbar from glider pressure sensors (flight and science)
	columns_to_update = ['sci_water_pressure', 'm_pressure']
	for column in columns_to_update:
		if column in data:
			data[column] *= 10
	
	# Basic clipping of data
	if all(k in data for k in ['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']):
		data.update({k: np.clip(data[k], *r) for k, r in zip(['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], [(-90, 90), (-180, 180)] * 2)})

	if all(k in data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']):
		data.update({k: np.clip(data[k], *r) for k, r in zip(['sci_water_cond', 'sci_water_temp', 'sci_water_pressure'], [(0, 7), (-1.9, 40), (-1.9, 1200)])})
	
	if 'sci_oxy4_oxygen' in data:
		data['sci_oxy4_oxygen'] = np.clip(data['sci_oxy4_oxygen'], 0, 500)
	
	if 'sci_water_pressure' in data:
		data['sci_water_depth'] = p2depth(data['sci_water_pressure'],time=data['time'],interpolate=True, tgap=5)
	
	# Store and rename variables in the "data" pd.dataframe
	glider_data = data.copy()
	data = pd.DataFrame()
	
	# Copy/duplicate certain names to the data frame from the glider_data frame but fill with nan if not existing
	name_list = {
		'time': 'time',
		'lat': 'm_gps_lat',
		'lon': 'm_gps_lon',
		'u': 'm_final_water_vx',
		'v': 'm_final_water_vy',
		'time_uv': 'time',
		'lat_uv': 'm_gps_lat',
		'lon_uv': 'm_gps_lon'
	}
	
	for new_col, old_col in name_list.items():
		data[new_col] = get_column_or_nan(glider_data, old_col)
	
	# derive CTD sensor data
	if(all(k in glider_data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure', 'sci_water_depth'])):
		data['conductivity'],data['temperature'],data['depth'], data['pressure']=glider_data['sci_water_cond'],glider_data['sci_water_temp'],glider_data['sci_water_depth'],glider_data['sci_water_pressure']
		data['salinity'],data['absolute_salinity'],data['conservative_temperature'],data['density']=deriveCTD(data['conductivity'],data['temperature'],data['pressure'],data['lon'],data['lat'])
	else:
		return
	
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
	
	# Create profile id, profile_time, profile_lon and profile_lat variable
	data = data.assign(profile_time=np.nan, profile_lat=np.nan, profile_lon=np.nan, profile_id=np.nan)
	prof_idx, prof_dir = findProfiles(data['time'], data['depth'], stall=20, shake=200)
	uidx = np.unique(prof_idx)
	for k in uidx:
		if k == math.floor(k):
			idx = prof_idx == k
			idx = prof_idx == k
			data.loc[idx, 'profile_time'] = data.loc[idx, 'time'].mean()
			data.loc[idx, 'profile_lat'] = data.loc[idx, 'lat'].mean()
			data.loc[idx, 'profile_lon'] = data.loc[idx, 'lon'].mean()
			data.loc[idx, 'profile_id'] = prof_idx[idx]+source_info['file_number']

	# convert & save glider *.bd files to *.nc files
	name, ext = os.path.splitext(source_info['filename'])
	filename, bd_ext = os.path.splitext(name)
	source_info['filename'] = "%s_%s.nc" % (filename,source_info['processing_mode'])
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
	
	if source_info['processing_mode'] == 'delayed':
		flight_var_filter = read_var_filter('dbd_filter.csv')
		science_var_filter = read_var_filter('ebd_filter.csv')
		flight_data = read_bd_data(f'{filename}.dbd.txt', flight_var_filter)
		science_data = read_bd_data(f'{filename}.ebd.txt', science_var_filter, ignore=True)
	elif source_info['processing_mode'] == 'realtime':
		flight_data = read_bd_data(f'{filename}.sbd.txt', None)
		science_data = read_bd_data(f'{filename}.tbd.txt', None)
	else:
		raise ValueError("Invalid processing mode. Supported modes are 'delayed_mode' and 'realtime'.")

	
	# Merge records and sort by time
	data = pd.concat([df for df in [flight_data, science_data] if not df.empty], ignore_index=True, sort=True).sort_values(by=['time'])
	
	# Check if the time values are monotonically increasing
	time_diff = np.diff(data['time'].values)
	if not np.all(time_diff > 0):
		print("Warning: Time values are not monotonically increasing. Correcting the time values.")
		
		# Correct the time values to make them monotonically increasing
		correction = np.where(time_diff <= 0, -time_diff + 1e-6, 0)
		corrected_time = data['time'].values.copy()
		corrected_time[1:] += np.cumsum(correction)
		data['time'] = corrected_time

	# Process and save data as netCDF
	process_data(data, source_info)
	
if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('glider', help='glider name')
	parser.add_argument('mission_dir', help='path of the input files')
	parser.add_argument('processing_mode', help='processing mode')
	parser.add_argument('gliders_db', help='name of the glider database')
	parser.add_argument('metadata_file', help='name of the metadata file')
	args = parser.parse_args()
	
	pwd_dir = os.path.dirname(os.path.realpath(__file__))
	encoder_dir = os.path.join(pwd_dir, './attributes/')
	encoder_file = os.path.join(encoder_dir , 'glider_dac_3.0_conventions.yml')

	file_list = sorted(glob.glob(f'{args.glider}*.[ds]bd.txt'))
	nc_directory = os.path.join(args.mission_dir, 'nc')
	file_number = 1
	for f in file_list:
		printF("asc2profile %s" % f)
		nc_filename = os.path.join(nc_directory, f"{os.path.splitext(f)[0]}.nc")
		if not os.path.exists(nc_filename):
			source_info = {
				'encoder': encoder_file,
				'data_type': 'profile',
				'gliders_db': args.gliders_db,
				'metadata_source': args.metadata_file,
				'processing_mode': args.processing_mode,
				'data_source': f,
				'filename': f,
				'filepath': args.mission_dir,
				'file_number': file_number
			}
			main(source_info)
			file_number = file_number + 1
