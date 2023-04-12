import sys
import glob
import xarray as xr
import pandas as pd
import numpy as np

# Read custom functions
from functions import correct_dead_reckoning, findProfiles

nc_path = '/Users/research/Documents/GitHub/gliderProcessing/glider_data/echo_20230113/delayed/nc/'

# Read *nc files
files = sorted(glob.glob(nc_path + '*.nc'.format('nc')))
data_list = []
glider_record_list = []

for f in files:
    try:
        tmpData = xr.open_dataset(f, engine='netcdf4')
        data_list.append(tmpData)
        tmpGliderRecordData = xr.open_dataset(f, engine='netcdf4', group='glider_record')
        glider_record_list.append(tmpGliderRecordData)
        print('Processed {}'.format(f))
    except Exception as e:
        print('Ignore {}. Error: {}'.format(f, e))

raw_data = xr.concat(glider_record_list, dim='time').sortby('time')
data = xr.concat(data_list, dim='time').sortby('time')

# Convert xarray datasets to pandas dataframes
raw_data = raw_data.to_dataframe().reset_index()
data = data.to_dataframe().reset_index()

# Correct longitude and latitude dead-reckoning positions
if( 'x_dr_state' in raw_data.keys() and 'm_gps_lon' in raw_data.keys() and 'm_gps_lat' in raw_data.keys() and 'm_lat' in raw_data.keys() and 'm_lon' in raw_data.keys()):
    data['lon_qc'],data['lat_qc'] = correct_dead_reckoning(raw_data['m_lon'],raw_data['m_lat'],raw_data['time'],raw_data['x_dr_state'],raw_data['m_gps_lon'],raw_data['m_gps_lat'])

# Compute profile index and direction
if('depth' in data.keys()):
    data['profile_index'],data['profile_direction']=findProfiles(data['time'],data['depth'],stall=20,shake=200)

