import argparse
import os.path
import csv
import numpy as np
import pandas as pd
from functions import c2salinity, stp2ct_density, p2depth, dm2d, O2freshtosal
from addAttrs import attr

## REMOVE ANNOYING WARNINGS FOR EMPTY ARRAYS
import warnings
warnings.simplefilter(action="ignore", category=pd.errors.PerformanceWarning)
#warnings.filterwarnings(action='ignore', message='All-NaN slice encountered')
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
	
def process_and_save_data(data, filename, gliders_db, attrs):
	def update_columns(data, cols, func):
		data.update({col: func(data[col]) for col in cols if col in data.keys()})
	
	update_columns(data, ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], dm2d)
	update_columns(data, ['c_fin', 'c_heading', 'c_pitch', 'm_fin', 'm_heading', 'm_pitch', 'm_roll'], np.degrees)
	
	if 'sci_water_pressure' in data:
		data['sci_water_pressure'] *= 10
	
	if all(k in data for k in ['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']):
		data.update({k: np.clip(data[k], *r) for k, r in zip(['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], [(-90, 90), (-180, 180)] * 2)})

	if all(k in data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']):
		data.update({k: np.clip(data[k], *r) for k, r in zip(['sci_water_cond', 'sci_water_temp', 'sci_water_pressure'], [(0.01, 4), (-2, 25), (-2, 1200)])})
	
	if 'sci_oxy4_oxygen' in data:
		data['sci_oxy4_oxygen'] = np.clip(data['sci_oxy4_oxygen'], 5, 500)
	
	if 'sci_water_pressure' in data:
		data['sci_water_depth'] = p2depth(data['sci_water_pressure'])
	
	glider_data = data.copy()
	data = pd.DataFrame()
	data['time'], data['lat'], data['lon'] = glider_data['time'], glider_data['m_gps_lat'], glider_data['m_gps_lon']
	data['profile_time'], data['profile_lat'], data['profile_lon'] = data['time'].mean(), data['lat'].mean(), data['lon'].mean()
	data['u'], data['v'], data['time_uv'], data['lat_uv'], data['lon_uv'] = glider_data['m_final_water_vx'], glider_data['m_final_water_vy'], data['time'], data['lat'], data['lon']
	
	if all(k in glider_data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']):
		data['salinity'], data['absolute_salinity'] = c2salinity(glider_data['sci_water_cond'].to_numpy(), glider_data['sci_water_temp'].to_numpy(), glider_data['sci_water_pressure'].to_numpy(), glider_data['m_gps_lon'].to_numpy(), glider_data['m_gps_lat'].to_numpy())
		data['conservative_temperature'], data['density'] = stp2ct_density(data['absolute_salinity'].to_numpy(), glider_data['sci_water_temp'].to_numpy(), glider_data['sci_water_pressure'].to_numpy())
		data['conductivity'], data['temperature'], data['depth'], data['pressure'] = glider_data['sci_water_cond'], glider_data['sci_water_temp'], glider_data['sci_water_depth'], glider_data['sci_water_pressure']
	
	if all(k in glider_data.keys() for k in ['sci_oxy4_oxygen', 'sci_water_temp', 'sci_water_pressure']):
		data['oxygen_concentration'] = O2freshtosal(glider_data['sci_oxy4_oxygen'].to_numpy(), glider_data['sci_water_temp'].to_numpy(), data['salinity'].to_numpy())
	
	if 'sci_oxy4_temp' in glider_data:
		data['oxygen_sensor_temperature'] = glider_data['sci_oxy4_temp']
	
	# convert & save glider *.bd files to *.nc files
	save_netcdf(data, glider_data, filename, gliders_db, attrs)

def save_netcdf(data, glider_data, filename, gliders_db, attrs):
	if not data.empty:
		nc = data.set_index('time').to_xarray()
		attr(filename, nc, gliders_db, attrs, 'GDAC_IOOS_ENCODER.yml', 'delayed')
		output_path = f'../nc/{filename}_delayed.nc'
		nc.to_netcdf(output_path)
		glider_data_nc = glider_data.set_index('time').to_xarray()
		glider_data_nc.to_netcdf(output_path, group="glider_record", mode="a")
	
def main(args):

	
	# Validate command-line arguments
	if not os.path.isfile(f'{args.filename}.dbd.txt'):
		raise FileNotFoundError(f'{file_arg} does not exist')
	
	var_filter = read_var_filter()
	dbd_data = read_bd_data(f'{args.filename}.dbd.txt', var_filter)
	ebd_data = read_bd_data(f'{args.filename}.ebd.txt', None)
	
	# Merge records and sort by time
	data = pd.concat([dbd_data, ebd_data], ignore_index=True, sort=True).sort_values(by=['time'])
	
	# Process and save data as netCDF
	process_and_save_data(data, args.filename, args.gliders_db, args.attrs)


if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('filename', help='name of the input file')
	parser.add_argument('gliders_db', help='name of the GLIDERS database')
	parser.add_argument('attrs', help='name of the attributes file')
	args = parser.parse_args()
	main(args)