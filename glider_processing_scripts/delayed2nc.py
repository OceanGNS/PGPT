import numpy as np
import pandas as pd
import sys
import os.path
from functions import c2salinity,stp2ct_density,p2depth,dm2d,O2freshtosal
from addAttrs import attr


## REMOVE ANNOYING WARNINGS FOR EMPTY ARRAYS
import warnings
warnings.simplefilter(action="ignore", category=pd.errors.PerformanceWarning)
#warnings.filterwarnings(action='ignore', message='All-NaN slice encountered')
warnings.simplefilter("ignore", category=RuntimeWarning)



fileName = sys.argv[1]
GLIDERS_DB = sys.argv[2]
ATTRS = sys.argv[3]

########  DBD
dbdFile = '%s.dbd.txt' % fileName

import csv
fid=open('dbd_filter.csv', 'r')
var_filter = list(csv.reader(fid, delimiter=","))[0]
fid.close()

if(os.path.isfile(dbdFile)):
    dbdData = pd.read_csv(dbdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    dbdData = dbdData.filter(var_filter, axis='columns')
    dbdData = dbdData.rename(columns={"m_present_time":"time"})
else:
    dbdData = pd.DataFrame()

########  EBD
ebdFile = '%s.ebd.txt' % fileName
if(os.path.isfile(ebdFile)):
    ebdData = pd.read_csv(ebdFile, delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    ebdData = ebdData.rename(columns={"sci_m_present_time":"time"})
else:
    ebdData = pd.DataFrame()

## MERGE RECORDS
data = pd.concat([dbdData, ebdData], ignore_index=True, sort=True)
data = data.sort_values(by=['time'])

## INTERPOLATION OF DATA TO REDUCE GAPS
#data = data.interpolate(limit=20) # limit is arbitrary but it helps

##  CONVERT DM 2 D.D
for col in ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']:
    if(col in data.keys()):
        data[col] = dm2d(data[col])

##  CONVERT RADIAN 2 DEGREE
for col in ['c_fin', 'c_heading', 'c_pitch', 'm_fin',  'm_heading',  'm_pitch',  'm_roll']:
    if(col in data.keys()):
        data[col] = np.degrees(data[col])

## SET PRESSURE BAR TO DBAR
if('sci_water_pressure' in data.keys()):
    data['sci_water_pressure'] = data['sci_water_pressure']*10

def update_columns(data, cols, func):
		data.update({col: func(data[col]) for col in cols if col in data.keys()})

## DO SOME BASIC RANGE CHECKING ON SENSORS
if all(k in data for k in ['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']):
	data.update({k: np.clip(data[k], *r) for k, r in zip(['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], [(-90, 90), (-180, 180)] * 2)})

if all(k in data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']):
	data.update({k: np.clip(data[k], *r) for k, r in zip(['sci_water_cond', 'sci_water_temp', 'sci_water_pressure'], [(0.01, 4), (-2, 25), (-2, 1200)])})

if 'sci_oxy4_oxygen' in data:
	data['sci_oxy4_oxygen'] = np.clip(data['sci_oxy4_oxygen'], 5, 500)

## CALCULATE DEPTH FROM CTD PRESSURE SENSOR ("sci_water_pressure")
if('sci_water_pressure' in data.keys()):
    data['sci_water_depth'] = p2depth(data['sci_water_pressure'])

##  CALCULATE SALINITY AND DENSITY
if('sci_water_cond' in data.keys() and 'sci_water_temp' in data.keys() and 'sci_water_pressure' in data.keys()):
    data['practical_salinity'],data['absolute_salinity'] = c2salinity(data['sci_water_cond'], data['sci_water_temp'], data['sci_water_pressure'],data['m_gps_lon'],data['m_gps_lat'])
    data['conservative_temperature'],data['sea_water_density']=stp2ct_density(data['absolute_salinity'],data['sci_water_temp'],data['sci_water_pressure'])

## COMPENSATE OXYGEN FOR SALINITY EFFECTS
if('sci_oxy4_oxygen' in data.keys() and 'sci_water_temp' in data.keys() and 'practical_salinity' in data.keys()):
    data['oxygen_concentration'] = O2freshtosal(data['sci_oxy4_oxygen'].to_numpy(), data['sci_water_temp'].to_numpy(), data['practical_salinity'].to_numpy())


## VARIABLE NAMING FOR US IOOS GLIDERDAC 3.0
glider_data = data # new data frame for the raw variables
data = []
data = pd.DataFrame() # reset

# basic info
data['time'] = glider_data['time']
data['lat'] = glider_data['m_gps_lat']
data['lon'] = glider_data['m_gps_lon']

 # profile has to be midprofile - so take average
data['profile_time'] = np.nanmean(data['time'])
data['profile_lat'] = np.nanmean(data['lat'])
data['profile_lon'] = np.nanmean(data['lon'])

# U, V variables are copies
data['u'] = glider_data['m_final_water_vx']
data['v'] = glider_data['m_final_water_vy']
data['time_uv'] = data['time']
data['lat_uv'] = data['lat']
data['lon_uv'] = data['lon']

## CTD VARIABLES
data['pressure'] = glider_data['sci_water_pressure']
data['depth'] = glider_data['sci_water_depth']
data['conductivity'] = glider_data['sci_water_cond']
data['salinity'] = glider_data['practical_salinity']
data['density'] = glider_data['sea_water_density']
data['temperature'] = glider_data['sci_water_temp']

## OXYGEN SENSOR
if('oxygen_concentration' in glider_data.keys() and 'sci_water_temp' in glider_data.keys()):
    data['oxygen_sensor_temperature'] = glider_data['sci_oxy4_temp']
    data['oxygen_concentration'] = glider_data['oxygen_concentration']

##  Convert & Save as netCDF
# Preserve original data in additional group
if(len(data)>0):
    nc = data.set_index(['time']).to_xarray()
    attr(fileName, nc, GLIDERS_DB, ATTRS,'GDAC_IOOS_ENCODER.yml', 'delayed')
    nc.to_netcdf('../nc/%s_delayed.nc' % (fileName))
    gliderData = glider_data.set_index(['time']).to_xarray()
    gliderData.to_netcdf('../nc/%s_delayed.nc' % (fileName), group="glider_record",mode="a")
