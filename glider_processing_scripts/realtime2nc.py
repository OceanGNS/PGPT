##  Salinity calculate:
##  https://oceanobservatories.org/wp-content/uploads/2015/10/1341-00040_Data_Product_SPEC_PRACSAL_OOI.pdf

import numpy as np
import pandas as pd
import sys
import os.path
from functions import c2salinity,stp2ct_density,p2depth,dm2d,rad2deg,O2freshtosal,range_check
from addAttrs import attr


fileName = sys.argv[1]

########  SBD
sbdFile = '%s.sbd.txt' % fileName
if(os.path.isfile(sbdFile)):
    sbdData = pd.read_csv(sbdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    sbdData = sbdData.rename(columns={"m_present_time":"timestamp"})
else:
    sbdData = pd.DataFrame()

########  TBD
tbdFile = '%s.tbd.txt' % fileName
if(os.path.isfile(tbdFile)):
    tbdData = pd.read_csv(tbdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    tbdData = tbdData.rename(columns={"sci_m_present_time":"timestamp"})
else:
    tbdData = pd.DataFrame()


## MERGE RECORDS
data = pd.concat([sbdData, tbdData], ignore_index=True, sort=True)
data = data.sort_values(by=['timestamp'])

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
    data['practical_salinity'],data['absolute_salinity'] = c2salinity(data['sci_water_cond'], data['sci_water_temp'], data['sci_water_pressure'],data['m_gps_lat'],data['m_gps_lon'])
    data['conservative_temperature'],data['density']=stp2ct_density(data['absolute_salinity'],data['sci_water_temp'],data['sci_water_pressure'])

## COMPENSATE OXYGEN FOR SALINITY EFFECTS
nanChk = np.any(~np.isnan(data['sci_oxy4_oxygen']))
if('sci_oxy4_oxygen' in data.keys() and 'sci_water_temp' in data.keys() and 'practical_salinity' in data.keys() and nanChk):
    data['oxygen_concentration'] = O2freshtosal(data['sci_oxy4_oxygen'], data['sci_water_temp'], data['practical_salinity'])


##  VARIABLE NAMING FOR US IOOS
data['time'] = data['timestamp']
data['latitude'] = data['m_gps_lat']
data['longitude'] = data['m_gps_lon']
data['pressure'] = data['sci_water_pressure']
data['depth'] = data['m_depth']
data['temperature'] = data['sci_water_temp']
data['conductivity'] = data['sci_water_cond']
data['eastward_sea_water_velocity'] = data['m_final_water_vx']
data['northward_sea_water_velocity'] = data['m_final_water_vy']


##  Convert & Save as netCDF
if(len(data)>0):
    nc = data.set_index(['timestamp']).to_xarray()
    nc.to_netcdf('../nc/%s_realtime.nc' % (fileName))
