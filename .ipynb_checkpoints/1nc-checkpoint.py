import numpy as np
import pandas as pd
from glob import glob


files = glob('*.txt')

data = pd.DataFrame()
for f in files:
    try:
        tmpData = pd.read_csv(f,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
        if("m_present_time" in tmpData.keys()):
            tmpData = tmpData.rename(columns={"m_present_time":"timestamp"})
        if("sci_m_present_time" in tmpData.keys()):
            tmpData = tmpData.rename(columns={"sci_m_present_time":"timestamp"})
        data = pd.concat([data, tmpData], ignore_index=True, sort=True)
    except:
        print('Ignore %s' % f)

data = data.sort_values(by=['timestamp'])

##  Convert & Save as netCDF
if(len(data)>0):
    nc = data.set_index(['timestamp']).to_xarray()
    nc.to_netcdf('../nc/all.nc')
