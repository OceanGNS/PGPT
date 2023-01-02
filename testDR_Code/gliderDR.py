import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from functions import salinity,DM2D,rad2deg,O2freshtosal,range_check,correctDR

# Glider data set from Unit 334 collected in Placentia Bay in 2022
df = pd.read_csv('glider_334_data.csv')
#print(list(df.columns.values))

# convert from DDMM.MM to DD.DD
for col in ['lat', 'lon', 'gps_lat', 'gps_lon']:
    if(col in df.keys()):
        df[col] = DM2D(df[col])

# Run the dead reckoning correction code
df['lon_corrected'],df['lat_corrected'] = correctDR(df['lon'],df['lat'],df['time'],df['dr_state'],df['gps_lon'],df['gps_lat'])

fig, ax = plt.subplots()
ax.plot(df['lon_corrected'],df['lat_corrected'],'o',label='corrected')
ax.plot(df['lon'],df['lat'],'o',label='original')
ax.set(xlabel='longitude', ylabel='latitude',
       title='Algorithm for Deadreckoning Position Correction')
ax.grid()
ax.legend()
fig.savefig("DRtest.png")
plt.show()
