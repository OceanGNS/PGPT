import numpy as np
import pandas as pd
import datetime
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
		missionMeta = yaml.load(f, Loader=yaml.BaseLoader)
	with open(source_info['encoder'], 'r') as f:
		cfl = yaml.load(f)
	# Merge dictionaries from master yaml and IOOS Decoder
	attrs = {**missionMeta, **cfl}

	#####################  AUTO CALCULATE  #####################
	##  FROM NC FILE
	now = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
	# gliderName = source_info['filename'].split('-')[0]  ##  eg sunfish (all small letters)
	lonMin = np.nanmin(data.variables['lon'][:])
	lonMax = np.nanmax(data.variables['lon'][:])
	latMin = np.nanmin(data.variables['lat'][:])
	latMax = np.nanmax(data.variables['lat'][:])
	depthMin = np.nanmin(data.variables['depth'][:])
	depthMax = np.nanmax(data.variables['depth'][:])
	startTime = datetime.datetime.fromtimestamp(float(data.variables['time'][:][0]))
	endTime = datetime.datetime.fromtimestamp(float(data.variables['time'][:][-1]))
	
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
	deploymentID = "33" # SHOULD BE CALCULATED AUTOMATICALLY
	
	##  FROM DATABASE
	# gliderDB = pd.read_csv(source_info['gliders_db'])
	# glider = gliderDB.loc[gliderDB['glider_name'] == attrs['glider']['name']]
	# gliderSerialID = gliderDB['glider_serial'].to_numpy()[0]
	# platformType = gliderDB['glider_type'].to_numpy()[0]
	# WMOid = gliderDB['WMO'].to_numpy()[0]
	
	#####################  ADD ATTRIBUTES  #####################
	##  USER INPUT
	for key in attrs['global'].keys():
		value = attrs['global'][key]
		# if(type(value) == datetime.datetime or type(value) == datetime.date):
			# data.attrs[key] = value.strftime('%FT%X')
		# else:
		data.attrs[key] = value
	
	##  CALCULATED
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
	data.attrs['deployment_name'] = '%s-%s' % (attrs['glider']['name'], data.attrs['deployment_date'])
	data.attrs['deployment_id'] = deploymentID
	data.attrs['instrument_id'] = attrs['glider']['name']
	data.attrs['glider_serial_id'] = attrs['glider']['serial']
	data.attrs['platform_type'] = attrs['glider']['type']
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
	data.attrs['id'] = '%s-%s' % (attrs['glider']['name'], data.attrs['deployment_date'])
	data.attrs['title'] = "%s data from glider %s" % (attrs['glider']['type'],deploymentID)
	data.attrs['time_coverage_duration'] = duration
	data.attrs['date_created'] = now
	data.attrs['date_issued'] = now
	data.attrs['date_modified'] = now
	data.attrs['Conventions'] = "CF-1.6"
	data.attrs['Metadata_Conventions'] = "CF-1.6, Unidata Dataset Discovery v1.0"
	data.attrs['format_version'] = "IOOS_Glider_NetCDF_v2.0.nc"
	data.attrs['history'] = "%s: Initial profile creation" % (now)
	data.attrs['keywords_vocabulary'] = "GCMD Science Keywords"
	data.attrs['metadata_link'] = "https://mungliders.com"
	data.attrs['naming_authority'] = "com.mungliders"
	data.attrs['publisher_name'] = "mungliders"
	data.attrs['sea_name'] = attrs['global']['region']
	data.attrs['references'] = "https://ioos.noaa.gov/wp-content/uploads/2015/10/Manual-for-QC-of-Glider-Data_05_09_16.pdf"
	data.attrs['standard_name_vocabulary'] = "CF Standard Name Table v27"
	
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
		"comment": attrs['glider']['comment'], # "%s %s" % (attrs['glider']['type'],attrs['glider']['seial']),
		"id": attrs['glider']['name'],
		"instrument": "instrument_ctd",
		"long_name": "Memorial University %s %s" % (attrs['glider']['type'],attrs['glider']['name']),
		"type" : "platform",
		"wmo_id":attrs['glider']['WMO']
	}
	data['platform'] = data['platform'].astype(np.int32) ##  To get rid of "LL" in netCDF

	# CTD
	data['instrument_ctd'] = 0
	for key in attrs['sensors']['CTD'].keys():
		value = attrs['sensors']['CTD'][key]
		data['instrument_ctd'].attrs[key] = value
	data['instrument_ctd'].attrs['_FillValue'] = -999
	if data['instrument_ctd'].dtype != 'int64':
		data['instrument_ctd'] = data['instrument_ctd'].astype(np.int32)
  	
	# Specific data types wanted by IOOS
	if any(np.isnan(data['profile_id'])):
		data['profile_id'] = data['profile_id'].fillna(-999)
		
	if data['profile_id'].dtype != 'int32':
		data['profile_id'] = data['profile_id'].astype(np.int32)
	
	##  Dimention needed by GDAC
	x = xr.Dataset({"trajectory": (("traj_strlen"), [1234])},
		coords={"traj_strlen": [1]})
	data = xr.combine_by_coords([data, x])
	data['trajectory'].attrs = {
		'cf_role': 'trajectory_id',
		'comment': "A trajectory is a single deployment of a glider and may span multiple data files.",
        "long_name": "Trajectory %s" % data.attrs['deployment_name']
	}
	data['traj_strlen'].attrs = {
        "long_name": "Trajectory String Length"
	}
	
	return data

def save_netcdf(data, raw_data, source_info):
	def check_variables(dataset):
		time_dim_size = dataset.dims['time']
		data_vars = {var_name: var_data for var_name, var_data in dataset.variables.items() if var_name != 'time'}
		reshaped_vars = {var_name: var_data if var_data.ndim == len(var_data.dims) else var_data.broadcast_like(dataset['time']).fillna(np.nan)
						 for var_name, var_data in data_vars.items()}
		return xr.Dataset(reshaped_vars, coords=dataset.coords)
	#
	if not data.empty:
		data = data.set_index('time').to_xarray()
		if(source_info['data_type'] == 'profile'):
			modified_data = data_attributes(data, source_info)
		else:
			modified_data = data
		modified_data.to_netcdf(source_info['filepath'] +'/nc/'+ source_info['filename'], mode='w')
	if not raw_data.empty:
		raw_data = raw_data.set_index('time').to_xarray()
		raw_data = check_variables(raw_data)
		raw_data.to_netcdf(source_info['filepath'] +'/nc/'+ source_info['filename'], group="glider_record", mode="a")