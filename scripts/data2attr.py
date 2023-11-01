import numpy as np
# import pandas as pd
import datetime
import math
import yaml
# import netCDF4 as nc4
import os
import xarray as xr

def dataAttributes(data, sourceInfo):
	"""
	Add global and variable attributes to an xarray Dataset containing glider data.
	
	Args:
	data (xr.Dataset): xarray Dataset containing the glider data.
	sourceInfo (pd.DataFrame): Information about the Dataset and processing mode
	
	Note:
	This function modifies the input xarray Dataset 'data' in-place.
	"""
	data = data.copy()
	#
	##  READ ATTRIBUTES AND VARIABLE NAMING RULES (ENCODER)
	with open(sourceInfo['metadataFile'], 'r') as f:
		missionMeta = yaml.load(f, Loader=yaml.BaseLoader)
	with open(sourceInfo['encoder'], 'r') as f:
		cfl = yaml.load(f)
	# Merge dictionaries from master yaml and IOOS Decoder
	attrs = {**missionMeta, **cfl}
	#
	#####################  AUTO CALCULATE  #####################
	##  FROM NC FILE
	now = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
	# gliderName = sourceInfo['filename'].split('-')[0]  ##  eg sunfish (all small letters)
	lonMin = np.nanmin(data.variables['lon'][:])
	lonMax = np.nanmax(data.variables['lon'][:])
	latMin = np.nanmin(data.variables['lat'][:])
	latMax = np.nanmax(data.variables['lat'][:])
	depthMin = np.nanmin(data.variables['depth'][:])
	depthMax = np.nanmax(data.variables['depth'][:])
	startTime = datetime.datetime.fromtimestamp(float(data.variables['time'][:][0]))
	endTime = datetime.datetime.fromtimestamp(float(data.variables['time'][:][-1]))
	#
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
	#
	#####################  ADD ATTRIBUTES  #####################
	##  USER INPUT
	for key in attrs['global'].keys():
		value = attrs['global'][key]
		# if(type(value) == datetime.datetime or type(value) == datetime.date):
			# data.attrs[key] = value.strftime('%FT%X')
		# else:
		data.attrs[key] = value
	#
	##  CALCULATED
	data.attrs['processingMode'] = sourceInfo['processingMode']
	data.attrs['cdm_dataType'] = sourceInfo['dataType']
	#
	if any('/' in file or '\\' in file for file in sourceInfo['dataSource']):
		# Use os.path.basename() to get only the file names
		file_names = [os.path.basename(file) for file in sourceInfo['dataSource']]
		data.attrs['source'] = ', '.join(file_names)
	else:
		data.attrs['source'] = sourceInfo['dataSource']
	#
	processing_levels = {
		('realtime', 'profile'): 'Realtime raw Slocum glider profile data converted from the native data file format. No quality control provided.',
		('realtime', 'trajectory'): 'Realtime raw Slocum glider trajectory data converted and concatenated from the native data file format. No quality control provided.',
		('delayed', 'profile'): 'Delayed mode Slocum glider profile data converted from the native format. Limited and provisional quality control provided.',
		('delayed', 'trajectory'): 'Delayed mode Slocum glider trajectory data converted and concatenated from the complete data set. Limited and provisional quality control provided.',
	}
	processing_key = (sourceInfo['processingMode'], sourceInfo['dataType'])
	# data.attrs['processing_level'] = processing_levels.get(processing_key, 'Unknown processing level')
	# data.attrs['deployment_name'] = '%s-%s' % (attrs['glider']['name'], data.attrs['deployment_date'])
	# data.attrs['instrument_id'] = attrs['glider']['name']
	# data.attrs['glider_serial_id'] = attrs['glider']['serial']
	# data.attrs['platform_type'] = attrs['glider']['type']
	# data.attrs['wmo_id'] = attrs['glider']['WMO']
	# data.attrs['wmo_platform_code'] = attrs['glider']['WMO']
	# data.attrs['geospatial_lat_min'] = latMin
	# data.attrs['geospatial_lat_max'] = latMax
	# data.attrs['geospatial_lon_min'] = lonMin
	# data.attrs['geospatial_lon_max'] = lonMax
	# data.attrs['geospatial_vertical_min'] = depthMin
	# data.attrs['geospatial_vertical_max'] = depthMax
	# data.attrs['time_coverage_start'] = startTime.strftime('%Y-%m-%dT%H:%M:%SZ')
	# data.attrs['time_coverage_end'] = endTime.strftime('%Y-%m-%dT%H:%M:%SZ')
	# data.attrs['id'] = '%s-%s' % (attrs['glider']['name'], data.attrs['deployment_date'])
	# data.attrs['title'] = "%s data from glider %s" % (attrs['glider']['type'],attrs['global']['deployment_id'])
	# data.attrs['time_coverage_duration'] = duration
	# data.attrs['date_created'] = now
	# data.attrs['date_issued'] = now
	# data.attrs['date_modified'] = now
	# data.attrs['Conventions'] = "CF-1.6"
	# data.attrs['Metadata_Conventions'] = "CF-1.6, Unidata Dataset Discovery v1.0"
	# data.attrs['format_version'] = "IOOS_Glider_NetCDF_v2.0.nc"
	# data.attrs['history'] = "%s: Initial profile creation" % (now)
	# data.attrs['keywords_vocabulary'] = "GCMD Science Keywords"
	# data.attrs['metadata_link'] = "https://mungliders.com"
	# data.attrs['naming_authority'] = "com.mungliders"
	# data.attrs['publisher_name'] = "mungliders"
	# data.attrs['sea_name'] = attrs['global']['region']
	# data.attrs['references'] = "https://ioos.noaa.gov/wp-content/uploads/2015/10/Manual-for-QC-of-Glider-Data_05_09_16.pdf"
	# data.attrs['standard_name_vocabulary'] = "CF Standard Name Table v27"
	#
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
	#
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
	#
	# CTD
	data['instrument_ctd'] = 0
	for key in attrs['sensors']['CTD'].keys():
		value = attrs['sensors']['CTD'][key]
		data['instrument_ctd'].attrs[key] = value
	data['instrument_ctd'].attrs['_FillValue'] = -999
	if data['instrument_ctd'].dtype != 'int64':
		data['instrument_ctd'] = data['instrument_ctd'].astype(np.int32)
  	#
	# Specific data types wanted by IOOS
	if any(np.isnan(data['profile_id'])):
		data['profile_id'] = data['profile_id'].fillna(-999)
	#	
	if data['profile_id'].dtype != 'int32':
		data['profile_id'] = data['profile_id'].astype(np.int32)
	#
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
	#
	return data

def saveNetcdf(data, rawData, sourceInfo):
	def checkVariables(dataset):
		time_dim_size = dataset.dims['time']
		dataVars = {varName: varData for varName, varData in dataset.variables.items() if varName != 'time'}
		reshapedVars = {varName: varData if varData.ndim == len(varData.dims) else varData.broadcast_like(dataset['time']).fillna(np.nan)
						 for varName, varData in dataVars.items()}
		return xr.Dataset(reshapedVars, coords=dataset.coords)
	#
	comp = dict(zlib=True, complevel=5)
	if not data.empty:
		data = data.set_index('time').to_xarray()
		# if(sourceInfo['dataType'] == 'profile'):
		modifiedData = dataAttributes(data, sourceInfo)
		# else:
		# 	modifiedData = data
		encoding = {var: comp for var in modifiedData.data_vars}
		modifiedData.to_netcdf(sourceInfo['missionDir'] +'/nc/'+ sourceInfo['filename'], mode='w', encoding=encoding)
	if not rawData.empty:
		rawData = rawData.set_index('time').to_xarray()
		rawData = checkVariables(rawData)
		encoding = {var: comp for var in rawData.data_vars}
		rawData.to_netcdf(sourceInfo['missionDir'] +'/nc/'+ sourceInfo['filename'], group="glider_record", mode="a", encoding=encoding)