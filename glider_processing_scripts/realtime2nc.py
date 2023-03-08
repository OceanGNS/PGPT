##  Salinity calculate:
##  https://oceanobservatories.org/wp-content/uploads/2015/10/1341-00040_Data_Product_SPEC_PRACSAL_OOI.pdf

import numpy as np
import pandas as pd
import sys
import os.path
from functions import c2salinity,p2depth,dm2d,rad2deg,O2freshtosal,range_check


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


data = pd.concat([sbdData, tbdData], ignore_index=True, sort=True)
data = data.sort_values(by=['timestamp'])

## DO SOME BASIC RANGE CHECKING SCIENCE SENSORS

if('sci_water_cond' in data.keys() and 'sci_water_temp' in data.keys() and 'sci_water_pressure' in data.keys()):
    data['sci_water_cond'] = range_check(data['sci_water_cond'],0.01,4)
    data['sci_water_temp'] = range_check(data['sci_water_temp'],-2,25)
    data['sci_water_pressure'] = range_check(data['sci_water_pressure'],-2,1200)

if('sci_oxy4_oxygen' in data.keys()):
    data['sci_oxy4_oxygen'] = range_check(data['sci_oxy4_oxygen'],50,500)


##  CALCULATE SALINITY
if('sci_water_cond' in data.keys() and 'sci_water_temp' in data.keys() and 'sci_water_pressure' in data.keys()):
    data['salinity'] = c2salinity(data['sci_water_cond'], data['sci_water_temp'], data['sci_water_pressure'])

## CALCULATE DEPTH FROM CTD PRESSURE SENSOR ("sci_water_pressure")
if('sci_water_pressure' in data.keys()):
    data['sci_water_depth'] = p2depth(data['sci_water_pressure']*10)

##  CONVERT DM 2 D.D
for col in ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']:
    if(col in data.keys()):
        data[col] = dm2d(data[col])

##  CONVERT RADIAN 2 DEGREE
for col in ['c_fin', 'c_heading', 'c_pitch', 'm_fin',  'm_heading',  'm_pitch','m_roll']:
    if(col in data.keys()):
        data[col] = rad2deg(data[col])

## COMPENSATE OXYGEN FOR SALINITY EFFECTS
nanChk = np.any(~np.isnan(data['sci_oxy4_oxygen']))
if('sci_oxy4_oxygen' in data.keys() and 'sci_water_temp' in data.keys() and 'salinity' in data.keys() and nanChk):
    data['oxygen_concentration'] = O2freshtosal(data['sci_oxy4_oxygen'], data['sci_water_temp'], data['salinity'])


##  Convert & Save as netCDF
if(len(data)>0):
    nc = data.set_index(['timestamp']).to_xarray()
    nc.to_netcdf('../nc/%s_realtime.nc' % (fileName))
