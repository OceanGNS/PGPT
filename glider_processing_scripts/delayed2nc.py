import numpy as np
import pandas as pd
import sys
import os.path
from functions import c2salinity,stp2ct_density,p2depth,dm2d,rad2deg,O2freshtosal,range_check
from addAttrs import attr

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
data = data.interpolate(limit=20) # limit is arbitrary but it helps

##  CONVERT DM 2 D.D
for col in ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']:
    if(col in data.keys()):
        data[col] = dm2d(data[col])

##  CONVERT RADIAN 2 DEGREE
for col in ['c_fin', 'c_heading', 'c_pitch', 'm_fin',  'm_heading',  'm_pitch',  'm_roll']:
    if(col in data.keys()):
        data[col] = rad2deg(data[col])

## SET PRESSURE BAR TO DBAR
if('sci_water_pressure' in data.keys()):
    data['sci_water_pressure'] = data['sci_water_pressure']*10
        
## DO SOME BASIC RANGE CHECKING ON SENSORS
if('m_gps_lon' in data.keys() and 'm_gps_lat' in data.keys() and 'm_lon' in data.keys() and 'm_lat' in data.keys()):
    data['m_gps_lat'] = range_check(data['m_gps_lat'],-90,90)
    data['m_gps_lon'] = range_check(data['m_gps_lon'],-180,180)
    data['m_lon'] = range_check(data['m_lon'],-180,180)
    data['m_lat'] = range_check(data['m_lat'],-90,90)

if('sci_water_cond' in data.keys() and 'sci_water_temp' in data.keys() and 'sci_water_pressure' in data.keys()):
    data['sci_water_cond'] = range_check(data['sci_water_cond'],0.01,4)
    data['sci_water_temp'] = range_check(data['sci_water_temp'],-2,25)
    data['sci_water_pressure'] = range_check(data['sci_water_pressure'],-2,1200)

if('sci_oxy4_oxygen' in data.keys()):
    data['sci_oxy4_oxygen'] = range_check(data['sci_oxy4_oxygen'],5,500)

## CALCULATE DEPTH FROM CTD PRESSURE SENSOR ("sci_water_pressure")
if('sci_water_pressure' in data.keys()):
    data['sci_water_depth'] = p2depth(data['sci_water_pressure'])

##  CALCULATE SALINITY AND DENSITY
if('sci_water_cond' in data.keys() and 'sci_water_temp' in data.keys() and 'sci_water_pressure' in data.keys()):
    data['practical_salinity'],data['absolute_salinity'] = c2salinity(data['sci_water_cond'], data['sci_water_temp'], data['sci_water_pressure'],data['m_gps_lon'],data['m_gps_lat'])
    data['conservative_temperature'],data['sea_water_density']=stp2ct_density(data['absolute_salinity'],data['sci_water_temp'],data['sci_water_pressure'])

## COMPENSATE OXYGEN FOR SALINITY EFFECTS
nanChk = np.any(~np.isnan(data['sci_oxy4_oxygen']))
if('sci_oxy4_oxygen' in data.keys() and 'sci_water_temp' in data.keys() and 'practical_salinity' in data.keys() and nanChk):
    data['oxygen_concentration'] = O2freshtosal(data['sci_oxy4_oxygen'], data['sci_water_temp'], data['practical_salinity'])

raw_data = data
data = pd.DataFrame()

## VARIABLE NAMING FOR US IOOS GLIDERDAC 3.0
data['time'] = raw_data['time']
data['latitude'] = raw_data['m_gps_lat']
data['longitude'] = raw_data['m_gps_lon']
data['pressure'] = raw_data['sci_water_pressure']
data['depth'] = raw_data['sci_water_depth']
data['u'] = raw_data['m_final_water_vx']
data['v'] = raw_data['m_final_water_vy']

# data['profile_id'] = data['profile_index']
data['profile_time'] = data['time'] # midprofile
data['profile_lat'] = data['latitude'] # midprofile
data['profile_lon'] = data['longitude'] # midprofile
data['time_uv'] = data['time']
data['lat_uv'] = data['latitude']
data['lon_uv'] = data['longitude']

## CTD VARIABLES
data['conductivity'] = raw_data['sci_water_cond']
data['salinity'] = raw_data['practical_salinity']
data['density'] = raw_data['sea_water_density']
data['temperature'] = raw_data['sci_water_temp']

## OXYGEN SENSOR
data['oxygen_sensor_temperature'] = raw_data['sci_oxy4_temp']
data['oxygen_concentration'] = raw_data['oxygen_concentration']

print(data.keys())
# data['platform'] = 0

##  Convert & Save as netCDF
if(len(data)>0):
    nc = data.set_index(['time']).to_xarray()
    attr(fileName, nc, GLIDERS_DB, ATTRS,'GDAC_IOOS_ENCODER.yml', 'delayed')
    nc.to_netcdf('../nc/%s_delayed.nc' % (fileName))
