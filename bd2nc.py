import numpy as np
import pandas as pd
import sys
import os.path


fileName = sys.argv[1]

sbdFile = '%s.txt' % fileName
if(os.path.isfile(sbdFile)):
    sbdData = pd.read_csv(sbdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    sbdData = sbdData.rename(columns={"m_present_time":"timestamp"})
else:
    sbdData = pd.DataFrame()

tbdFile = '%s.txt' % fileName
if(os.path.isfile(tbdFile)):
    tbdData = pd.read_csv(tbdFile,delimiter=' ',skiprows=np.append(np.arange(14),[15,16]))
    tbdData = tbdData.rename(columns={"sci_m_present_time":"timestamp"})
else:
    tbdData = pd.DataFrame()


data = pd.concat([sbdData, tbdData], ignore_index=True, sort=True)
data = data.sort_values(by=['timestamp'])

##  Convert & Save as netCDF
if(len(data)>0):
    nc = data.set_index(['timestamp']).to_xarray()
    nc.to_netcdf('../nc/%s.nc' % (fileName))
