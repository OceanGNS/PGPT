import numpy as np
import pandas as pd
from datetime import datetime
import yaml

def read_yaml_file(file_path):
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

def update_attrs(nc, attrs, glider_info, now, duration):
    glider_name, deployment_datetime, deployment_id, glider_serial_id, platform_type, wmo_id = glider_info
    nc.attrs.update(attrs['global'], attrs['instrument_ctd'], {
        'processing_mode': processing_mode,
        'deployment_name': f'{glider_name}-{deployment_datetime}',
        'deployment_id': deployment_id,
        'instrument_id': glider_name,
        'glider_serial_id': glider_serial_id,
        'platform_type': platform_type,
        'wmo_id': wmo_id,
        'wmo_platform_code': wmo_id,
        'cdm_data_type': data_type,
        'geospatial_lat_min': lat_min,
        'geospatial_lat_max': lat_max,
        'geospatial_lon_min': lon_min,
        'geospatial_lon_max': lon_max,
        'geospatial_vertical_min': depth_min,
        'geospatial_vertical_max': depth_max,
        'time_coverage_start': start_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'time_coverage_end': end_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'id': f'{glider_name}-{deployment_datetime}',
        'profile_id': nc.attrs['id'],
        'title': f'Slocum Glider data from glider {deployment_id}',
        'source': f'Observational Slocum glider data from source dba file XXX-YYYY-XXX-X-X-dbd(XXXXXXX)',
        'time_coverage_duration': duration,
        'date_created': now,
        'date_issued': now,
        'date_modified': now,
    })

    for var, attr_dict in attrs['CFnamelist'].items():
        if var in nc:
            for key, value in attr_dict.items():
                if value.startswith('** COMMAND:'):
                    command = value.replace('** COMMAND:', '')
                    nc[var].attrs[key] = eval(command)
                else:
                    nc[var].attrs[key] = value
        else:
            print(f'{var} not present in the nc file')

    for var in nc.keys():
        nc[var].attrs.update({
            'standard_name': var,
            'long_name': var,
            'units': ' ',
            'comment': ' ',
            'observation_type': ' ',
            'accuracy': ' ',
            'platform': 'platform',
        })

    nc['platform'] = 0
    nc['platform'].attrs.update({
        "_FillValue": -999,
        "comment": f"{platform_type} {glider_serial_id}",
        "id": glider_name,
        "instrument": "instrument_ctd",
        "long_name": f"Memorial University {platform_type} {glider_name}",
        "type" : "platform",
        "wmo_id": wmo_id
    })

    nc['instrument_ctd'] = 0
    nc['instrument_ctd'].attrs.update(attrs['instrument_ctd'])

def compute_duration(start_time, end_time):
    duration_seconds = int((end_time - start_time).total_seconds())
    duration_days, remainder = divmod(duration_seconds, 86400)
    duration_hours, remainder = divmod(remainder, 3600)
    duration_minutes, duration_seconds = divmod(remainder, 60)
    duration_parts = []
	if duration_days > 0:
	    duration_parts.append(f"{duration_days}D")
	if duration_hours > 0 or duration_minutes > 0 or duration_seconds > 0:
	    duration_parts.append("T")
	    if duration_hours > 0:
	        duration_parts.append(f"{duration_hours}H")
	    if duration_minutes > 0:
	        duration_parts.append(f"{duration_minutes}M")
	    if duration_seconds > 0:
	        duration_parts.append(f"{duration_seconds}S")
	return "P" + "".join(duration_parts)

def attr(fileName, nc, GLIDERS_DB, ATTRS, ENCODER, processingMode):
	attrs = read_yaml_file(ATTRS) | read_yaml_file(ENCODER)
	now = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
	glider_name = fileName.split('-')[0]
	data_type = 'profile'
	lon_min, lon_max = np.nanmin(nc.variables['lon'][:]), np.nanmax(nc.variables['lon'][:])
	lat_min, lat_max = np.nanmin(nc.variables['lat'][:]), np.nanmax(nc.variables['lat'][:])
	depth_min, depth_max = np.nanmin(nc.variables['depth'][:]), np.nanmax(nc.variables['depth'][:])
	start_time = datetime.fromtimestamp(float(nc.variables['time'][:][0]))
	end_time = datetime.fromtimestamp(float(nc.variables['time'][:][-1]))
	duration = compute_duration(start_time, end_time)
	deployment_id = 33  # SHOULD CALCULATED AUTOMATICALLY
	glider_db = pd.read_csv(GLIDERS_DB)
	glider = glider_db.loc[glider_db['glider_name'] == glider_name]
	glider_serial_id, platform_type, wmo_id = glider['glider_serial'].to_numpy()[0], glider['glider_type'].to_numpy()[0], glider['WMO'].to_numpy()[0]
	
	glider_info = (glider_name, deployment_datetime, deployment_id, glider_serial_id, platform_type, wmo_id)
	
	update_attrs(nc, attrs, glider_info, now, duration)
