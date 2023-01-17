import numpy as np
import pandas as pd
import sys
import os.path
from functions import salinity,DM2D,rad2deg,O2freshtosal,range_check

fileName = sys.argv[1]

########  DBD
dbdFile = '%s.dbd.txt' % fileName
filter = ["m_present_time","m_present_secs_into_mission","m_water_depth","m_de_oil_vol","c_de_oil_vol","m_water_vx","m_water_vy","m_depth","m_depth_rate","m_pitch","c_pitch","m_speed","m_ballast_pumped","c_ballast_pumped","m_battpos","c_battpos","m_heading","c_heading","m_fin","c_fin","m_roll","m_vacuum","m_battery","m_leak","m_altitude","m_raw_altitude","m_raw_altitude_rejected","m_altimeter_voltage","m_altitude_rate","m_altimeter_status","m_lat","m_lon","c_wpt_lon","c_wpt_lat","m_gps_lon","m_gps_lat","m_initial_water_vx","m_initial_water_vy","m_final_water_vx","m_final_water_vy","m_gps_speed","m_gps_heading","m_gps_mag_var","m_gps_x_lmc","m_gps_y_lmc","m_dr_x_postfix_drift","m_dr_y_postfix_drift","m_dr_x_actual_err","m_dr_y_actual_err","m_dr_postfix_time","x_dr_state","m_dr_time","m_gps_on","c_gps_on","m_water_delta_vx","m_water_delta_vy","m_depth_state","cc_depth_state_mode","x_fin_deadband","x_battpos_deadband","x_ballast_pumped_deadband","u_angle_of_attack","m_coulomb_amphr ","m_coulomb_amphr_raw","m_coulomb_amphr_total","m_coulomb_current","m_coulomb_current_raw","u_flbbcd_chlor_cwo","u_flbbcd_bb_cwo","u_flbbcd_cdom_cwo","u_flbbcd_chlor_sf","u_flbbcd_bb_sf","u_flbbcd_cdom_sf"]

if(os.path.isfile(dbdFile)):
    dbdData = pd.read_csv(dbdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    dbdData = dbdData.filter(filter, axis='columns')
    dbdData = dbdData.rename(columns={"m_present_time":"timestamp"})
else:
    dbdData = pd.DataFrame()

########  EBD
ebdFile = '%s.ebd.txt' % fileName
if(os.path.isfile(ebdFile)):
    ebdData = pd.read_csv(ebdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    ebdData = ebdData.rename(columns={"sci_m_present_time":"timestamp"})
else:
    ebdData = pd.DataFrame()


data = pd.concat([dbdData, ebdData], ignore_index=True, sort=True)
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
    data['salinity'] = salinity(data['sci_water_cond'], data['sci_water_temp'], data['sci_water_pressure'])
    
##  CONVERT DM 2 D.D
for col in ['c_wpt_lat', 'c_wpt_lon', 'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']:
    if(col in data.keys()):
        data[col] = DM2D(data[col])

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
    nc.to_netcdf('../nc/%s_delayed.nc' % (fileName))
