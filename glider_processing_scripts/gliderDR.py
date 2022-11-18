import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from functions import DM2D

df = pd.read_csv('glider_334_data.csv')
column_names = list(df.columns.values)

# print(column_names)

lon  = df.lon.to_numpy()
#print(df[['lat']])
# lon = df[['lat']]
lat   = df.lat.to_numpy()
timestamp = df.time.to_numpy()
x_dr_state = df.dr_state.to_numpy()
gps_lon = df.gps_lon.to_numpy()
gps_lat = df.gps_lat.to_numpy()

# print(np.argwhere(np.isnan(x_dr_state)))
# print(x_dr_state)

# interpolate all nan's in glider x_dr_state using "previous"
not_nan = ~np.isnan(x_dr_state)
xp = not_nan.ravel().nonzero()[0]
fp = x_dr_state[not_nan]
x  = np.isnan(x_dr_state).ravel().nonzero()[0]

## NEED TO BE CHANGED TO method = "previous" - might need pandas or scipy
# x_dr_state[np.isnan(x_dr_state)] = np.interp(x, xp, fp)

# dead reckoning dive location
# lat/lon index for transition of x_dr_state from 4->1
x_dr_state = x_dr_state
i_si     = np.argwhere( np.diff (x_dr_state**2)!=0)
i_start = np.argwhere(np.diff( x_dr_state[i_si]**2, n=2,axis=0 )==18)
i_start = i_si[i_start[:,0]]
# print(i_start)

# print(np.isnan(lon[i_start[1]]))
for ki in range(len(i_start) ):
    while np.isnan(lon[i_start[ki] ] ) :
       i_start[ki] = i_start[ki] +1
  
# print(i_start)
# gps location at surface
# transition x_dr_state from 2->3
 
i_end  = np.argwhere(np.diff(x_dr_state**2,n=1,axis=0)==5)
i_end  = i_end[:,0]
# print(i_end)
    
for ki in range(len(i_end)):
    while (np.isnan(lon[i_end[ki]]) and np.isnan(gps_lon[i_end[ki]] ) ) :
        i_end[ki] = i_end[ki] +1
            
# print(i_end)


# DR location after surfacing
# transition from 1->2


i_mid = np.argwhere(np.diff(x_dr_state**2,n=1,axis=0)==3)
i_mid = i_mid[:,0]
# print(i_mid)
for ki in range(len(i_mid)):
	while np.isnan(DM2D(lon[i_mid[ki]] ) ):
		# print(i_mid[ki])
		i_mid[ki] = i_mid[ki] -1

# print(i_mid)

t_start = timestamp[i_start]

lon_dif = DM2D(lon[i_end]) - DM2D(lon[i_mid])
lat_dif  = DM2D(lat[i_end]) - DM2D(lat[ i_mid])
t_dif    =  timestamp[i_mid] - timestamp[i_start]
    
vlonDD = lon_dif / t_dif
vlatDD  = lat_dif / t_dif
loncDD = DM2D(lon[0, ])
latcDD  = DM2D(lat[0, ])
ap = 1

# print(latcDD)

for i in range(len(i_start)):
	a = i_start[i] + np.argwhere(~np.isnan( lon[np.arange(i_start[i],i_mid[i])] ))-1
	ap = np.vstack((ap, a))
	ti = timestamp[a] - timestamp[a[0]]
	loncDD = np.vstack((loncDD.reshape(-1,1) ,(DM2D(lon[a]) + ti*vlonDD[i]).reshape(-1,1)  ))
	latcDD  = np.vstack((latcDD.reshape(-1,1)  ,(DM2D(lat[a] ) + ti*vlatDD[i] ).reshape(-1,1)  ))



lonDD = DM2D(lon[ap])
latDD  = DM2D(lat[ap])
gps_lonDD = DM2D(gps_lon[1:].reshape(-1,1))
gps_latDD  = DM2D(gps_lat[1:].reshape(-1,1))


fig, ax = plt.subplots()
ax.plot(loncDD,latcDD,'o')
ax.set(xlabel='longitude', ylabel='latitude',
       title='Algorithm for Deadreckoning Position Correction')
ax.grid()

fig.savefig("DRtest.png")
plt.show()