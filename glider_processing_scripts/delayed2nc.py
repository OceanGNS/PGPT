import numpy as np
import pandas as pd
import sys
import os.path
from functions import c2salinity,stp2ct_density,p2depth,dm2d,rad2deg,O2freshtosal,range_check
from addAttrs import attr

from warnings import simplefilter
simplefilter(action="ignore", category=pd.errors.PerformanceWarning)

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
if('sci_oxy4_oxygen' in data.keys() and 'sci_water_temp' in data.keys() and 'practical_salinity' in data.keys()):
    data['oxygen_concentration'] = O2freshtosal(data['sci_oxy4_oxygen'], data['sci_water_temp'], data['practical_salinity'])


## VARIABLE NAMING FOR US IOOS GLIDERDAC 3.0
glider_data = data # new data frame for the raw variables
data = []
data = pd.DataFrame() # reset

data['time'] = glider_data['time']
data['lat'] = glider_data['m_gps_lat']
data['lon'] = glider_data['m_gps_lon']
data['pressure'] = glider_data['sci_water_pressure']
data['depth'] = glider_data['sci_water_depth']
data['u'] = glider_data['m_final_water_vx']
data['v'] = glider_data['m_final_water_vy']

data['profile_time'] = data['time'] # midprofile
data['profile_lat'] = data['lat'] # midprofile
data['profile_lon'] = data['lon'] # midprofile
data['time_uv'] = data['time']
data['lat_uv'] = data['lat']
data['lon_uv'] = data['lon']

## CTD VARIABLES
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
