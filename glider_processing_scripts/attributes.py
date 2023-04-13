import numpy as np
import pandas as pd
from datetime import datetime
import math
import yaml


def attr(fileName, data, GLIDERS_DB, METADATA, ENCODER, PROCESSING_MODE, DATA_TYPE):
	"""
	Add global and variable attributes to an xarray Dataset containing glider data.
	
	Args:
	fileName (str): Name of the output NetCDF file.
	data (xr.Dataset): xarray Dataset containing the glider data.
	GLIDERS_DB (str): Path to the CSV file containing the glider database.
	METADATA (str): Path to the YAML file containing metadata attributes.
	ENCODER (str): Path to the YAML file containing IOOS encoder (variable naming rules).
	PROCESSING_MODE (str): Processing mode of the glider data (e.g., 'real-time', 'delayed').
	DATA_TYPE (str): Type of the glider data (e.g., 'profile', 'trajectory').
	
	Note:
	This function modifies the input xarray Dataset 'data' in-place.
	"""
	##  READ ATTRIBUTES AND VARIABLE NAMING RULES (ENCODER)
	with open(METADATA, 'r') as f:
		attrs = yaml.safe_load(f)
	with open(ENCODER,'r') as f:
		CFL= yaml.safe_load(f)
	# Merge dictionaries from master yaml and IOOS Decoder
	attrs = attrs | CFL
	
	#####################  AUTO CALCULATE  #####################
	##  FROM NC FILE
	now = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
	gliderName = fileName.split('-')[0]  ##  eg sunfish (all small letters)
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
	gliderDB = pd.read_csv(GLIDERS_DB)
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
	data.attrs['processing_mode'] = PROCESSING_MODE
	data.attrs['deployment_name'] = '%s-%s' % (gliderName, deploymentDateTime)
	data.attrs['deployment_id'] = deploymentID
	data.attrs['instrument_id'] = gliderName
	data.attrs['glider_serial_id'] = gliderSerialID
	data.attrs['platform_type'] = platformType
	data.attrs['wmo_id'] = WMOid
	data.attrs['wmo_platform_code'] = WMOid
	data.attrs['cdm_data_type'] = DATA_TYPE
	data.attrs['geospatial_lat_min'] = latMin
	data.attrs['geospatial_lat_max'] = latMax
	data.attrs['geospatial_lon_min'] = lonMin
	data.attrs['geospatial_lon_max'] = lonMax
	data.attrs['geospatial_vertical_min'] = depthMin
	data.attrs['geospatial_vertical_max'] = depthMax
	data.attrs['time_coverage_start'] = startTime.strftime('%Y-%m-%dT%H:%M:%SZ')
	data.attrs['time_coverage_end'] = endTime.strftime('%Y-%m-%dT%H:%M:%SZ')
	data.attrs['id'] = '%s-%s' % (gliderName, deploymentDateTime)
	data.attrs['profile_id'] = data.attrs['id']
	data.attrs['title'] = "Slocum Glider data from glider %s" % deploymentID
	data.attrs['source'] = "Observational Slocum glider data from source dba file XXX-YYYY-XXX-X-X-dbd(XXXXXXX)"
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
		if("standard_name" not in data[var].attrs.keys()):
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

def save_netcdf(fname,nc_path,data, raw_data, gliders_db, metadata_source, encoder, processing_mode, data_type):
	"""
	Save processed and raw glider data to a NetCDF file.
	
	Args:
	fname (str): Output filename.
	nc_path (str): Output directory path.
	data (pd.DataFrame): Processed glider data.
	raw_data (pd.DataFrame): Raw glider data.
	"""
	if not data.empty:
		output_fn=nc_path+fname
		data = data.set_index('time').to_xarray()
		attr(fname, data, gliders_db, metadata_source, encoder, processing_mode, data_type)
		data.to_netcdf(output_fn)
	if not raw_data.empty:
		raw_data = raw_data.set_index('time').to_xarray()
		raw_data.to_netcdf(output_fn, group="glider_record", mode="a")