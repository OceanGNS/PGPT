import numpy as np
import pandas as pd
from datetime import datetime
import math
import yaml
import netCDF4 as nc4
import os
import xarray as xr

def data_attributes(data, source_info):
	"""
	Add global and variable attributes to an xarray Dataset containing glider data.
	
	Args:
	data (xr.Dataset): xarray Dataset containing the glider data.
	source_info (pd.DataFrame): Information about the Dataset and processing mode
	
	Note:
	This function modifies the input xarray Dataset 'data' in-place.
	"""
	data = data.copy()
	
	##  READ ATTRIBUTES AND VARIABLE NAMING RULES (ENCODER)
	with open(source_info['metadata_source'], 'r') as f:
		attrs = yaml.safe_load(f)
	with open(source_info['encoder'], 'r') as f:
		cfl= yaml.safe_load(f)
	# Merge dictionaries from master yaml and IOOS Decoder
	attrs = {**attrs, **cfl}
	
	#####################  AUTO CALCULATE  #####################
	##  FROM NC FILE
	now = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
	gliderName = source_info['filename'].split('-')[0]  ##  eg sunfish (all small letters)
	lonMin = np.nanmin(data.variables['lon'][:])
	lonMax = np.nanmax(data.variables['lon'][:])
	latMin = np.nanmin(data.variables['lat'][:])
	latMax = np.nanmax(data.variables['lat'][:])
	depthMin = np.nanmin(data.variables['depth'][:])
	depthMax = np.nanmax(data.variables['depth'][:])
	startTime = datetime.fromtimestamp(float(data.variables['time'][:][0]))
	endTime = datetime.fromtimestamp(float(data.variables['time'][:][-1]))
	
	# DURATION
	durationDays = math.floor((endTime-startTime).seconds / (24*3600))
	durationHours = math.floor(((endTime-startTime).seconds - 24*3600*durationDays)/3600)
	durationMinutes = math.floor(((endTime-startTime).seconds - 24*3600*durationDays - 3600*durationHours)/60)
	durationSeconds = (endTime-startTime).seconds - 24*3600*durationDays - 3600*durationHours - 60*durationMinutes
	duration = "PT"
	if(durationDays>0):
		duration += "%dD" % durationDays
	if(durationHours>0):
		duration += "%dH" % durationHours
	if(durationMinutes>0):
		duration += "%dM" % durationMinutes
	duration += "%dS" % durationSeconds
	
	##  FROM PREVIOUS DEPLOYMENTS
	deploymentID = 33 # SHOULD CALCULATED AUTOMATICALLY
	
	##  FROM DATABASE
	gliderDB = pd.read_csv(source_info['gliders_db'])
	glider = gliderDB.loc[gliderDB['glider_name'] == gliderName]
	gliderSerialID = gliderDB['glider_serial'].to_numpy()[0]
	platformType = gliderDB['glider_type'].to_numpy()[0]
	WMOid = gliderDB['WMO'].to_numpy()[0]
	
	#####################  ADD ATTRIBUTES  #####################
	##  USER INPUT
	for key in attrs['global'].keys():
		data.attrs[key] = attrs['global'][key]
	
	##  CALCULATED
	deploymentDateTime = attrs['global']['deployment_datetime']  ##  SHOULD BE CALCULATED AUTOMATICALLY
	data.attrs['processing_mode'] = source_info['processing_mode']
	data.attrs['cdm_data_type'] = source_info['data_type']
	
	if any('/' in file or '\\' in file for file in source_info['data_source']):
		# Use os.path.basename() to get only the file names
		file_names = [os.path.basename(file) for file in source_info['data_source']]
		data.attrs['source'] = ', '.join(file_names)
	else:
		data.attrs['source'] = source_info['data_source']
	
	processing_levels = {
		('realtime', 'profile'): 'Realtime raw Slocum glider profile data converted from the native data file format. No quality control provided.',
		('realtime', 'trajectory'): 'Realtime raw Slocum glider trajectory data converted and concatenated from the native data file format. No quality control provided.',
		('delayed', 'profile'): 'Delayed mode Slocum glider profile data converted from the native format. Limited and provisional quality control provided.',
		('delayed', 'trajectory'): 'Delayed mode Slocum glider trajectory data converted and concatenated from the complete data set. Limited and provisional quality control provided.',
	}
	processing_key = (source_info['processing_mode'], source_info['data_type'])
	data.attrs['processing_level'] = processing_levels.get(processing_key, 'Unknown processing level')
	data.attrs['deployment_name'] = '%s-%s' % (gliderName, deploymentDateTime)
	data.attrs['deployment_id'] = deploymentID
	data.attrs['instrument_id'] = attrs['glider']['name']
	data.attrs['glider_serial_id'] = attrs['glider']['serial']
	data.attrs['platform_type'] = platformType
	data.attrs['wmo_id'] = attrs['glider']['WMO']
	data.attrs['wmo_platform_code'] = attrs['glider']['WMO']
	data.attrs['geospatial_lat_min'] = latMin
	data.attrs['geospatial_lat_max'] = latMax
	data.attrs['geospatial_lon_min'] = lonMin
	data.attrs['geospatial_lon_max'] = lonMax
	data.attrs['geospatial_vertical_min'] = depthMin
	data.attrs['geospatial_vertical_max'] = depthMax
	data.attrs['time_coverage_start'] = startTime.strftime('%Y-%m-%dT%H:%M:%SZ')
	data.attrs['time_coverage_end'] = endTime.strftime('%Y-%m-%dT%H:%M:%SZ')
	data.attrs['id'] = '%s-%s' % (gliderName, deploymentDateTime)
	data.attrs['title'] = "Slocum Glider data from glider %s" % deploymentID
	data.attrs['time_coverage_duration'] = duration
	data.attrs['date_created'] = now
	data.attrs['date_issued'] = now
	data.attrs['date_modified'] = now
	
	
	#####################  ADD VARIABLE ATTRIBUTES FROM THE CF NAMELIST #####################
	for var in attrs['CFnamelist'].keys():
		if(var in data):
			for key in attrs['CFnamelist'][var].keys():
				if(attrs['CFnamelist'][var][key].startswith('** COMMAND:')):
					command = attrs['CFnamelist'][var][key].replace('** COMMAND:','')
					data[var].attrs[key] = eval(command)
				else:
					data[var].attrs[key] = attrs['CFnamelist'][var][key]
		else:
			print('%s not present in the data file' % var)
	##  Fill the rest of variables attributes with fillers
	for var in data.keys():
		if("long_name" not in data[var].attrs.keys()):
			data[var].attrs['standard_name'] = var
			data[var].attrs['long_name'] = var
			data[var].attrs['units'] = ' '
			data[var].attrs['comment'] = ' '
			data[var].attrs['observation_type'] = ' '
			data[var].attrs['accuracy'] = ' '
			data[var].attrs['platform'] = 'platform'

	data['platform'] = 0
	data['platform'].attrs = {
		"_FillValue": -999,
		"comment": "%s %s" % (platformType,gliderSerialID),
		"id": gliderName,
		"instrument": "instrument_ctd",
		"long_name": "Memorial University %s %s" % (platformType,gliderName),
		"type" : "platform",
		"wmo_id":WMOid
	}

	data['instrument_ctd'] = 0
	data['instrument_ctd'].attrs = attrs['instrument_ctd']
	
	# Specific data types wanted by IOOS
	if any(np.isnan(data['profile_id'])):
		data['profile_id'] = data['profile_id'].fillna(-999)
		
	if data['profile_id'].dtype != 'int32':
		data['profile_id'] = data['profile_id'].astype(np.int32)
	
	# return data with attributes
	return data

def save_netcdf(data, raw_data, output_fn):
	print(output_fn)
	def check_variables(dataset):
		time_dim_size = dataset.dims['time']
		data_vars = {var_name: var_data for var_name, var_data in dataset.variables.items() if var_name != 'time'}
		reshaped_vars = {var_name: var_data if var_data.ndim == len(var_data.dims) else var_data.broadcast_like(dataset['time']).fillna(np.nan)
						 for var_name, var_data in data_vars.items()}
		return xr.Dataset(reshaped_vars, coords=dataset.coords)
	#
	print('HI')
	if not data.empty:
		data = data.set_index('time').to_xarray()
		modified_data = data # data_attributes(data, source_info)
		modified_data.to_netcdf(output_fn)
	if not raw_data.empty:
		raw_data = raw_data.set_index('time').to_xarray()
		print(raw_data)
		raw_data = check_variables(raw_data)
		raw_data.to_netcdf(output_fn, group="glider_record", mode="a")