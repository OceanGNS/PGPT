##  Salinity calculate:
##  https://oceanobservatories.org/wp-content/uploads/2015/10/1341-00040_Data_Product_SPEC_PRACSAL_OOI.pdf

import numpy as np
import pandas as pd
import sys
import os.path
from functions import salinity,DM2D,rad2deg


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

##  CALCULATE SALINITY
if('sci_water_cond' in data.keys() and 'sci_water_temp' in data.keys() and 'sci_water_pressure' in data.keys()):
    data['salinity'] = salinity(data['sci_water_cond'], data['sci_water_temp'], data['sci_water_pressure'])

##  CONVERT DM 2 D.D
for col in ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']:
    if(col in data.keys()):
        data[col] = DM2D(data[col])

##  CONVERT RADIAN 2 DEGREE
for col in ['c_fin', 'c_heading', 'c_pitch', 'm_fin',  'm_heading',  'm_pitch','m_roll']:
    if(col in data.keys()):
        data[col] = rad2deg(data[col])


##  Convert & Save as netCDF
if(len(data)>0):
    nc = data.set_index(['timestamp']).to_xarray()
    nc.to_netcdf('../nc/%s_realtime.nc' % (fileName))
