import numpy as np
import gsw


## PSS-78 Algorithm to compute salinity
def salinity(C,t,p):

    p = 10*p  ##  dBar
    C = 10*C  ##  mS/cm
    SP = gsw.SP_from_C(C, t, p)
    
    # Define constants
    #a0 = 0.0080
    #a1 = -0.1692
    #a2 = 25.3851
    #a3 = 14.0941
    #a4 = -7.0261
    #a5 = 2.7081
    #b0 = 0.0005
    #b1 = -0.0056
    #b2 = -0.0066
    #b3 = -0.0375
    #b4 = 0.0636
    #b5 = -0.0144
    #c0 = 0.6766097
    #c1 = 2.00564e-2
    #c2 = 1.104259e-4
    #c3 = -6.9698e-7
    #c4 = 1.0031e-9
    #d1 = 3.426e-2
    #d2 = 4.464e-4
    #d3 = 4.215e-1
    #d4 = -3.107e-3
    #e1 = 2.070e-5
    #e2 = -6.370e-10
    #e3 = 3.989e-15
    #k = 0.0162
    
    #t68 = t*1.00024
    #ft68 = (t68 - 15)/(1 + k*(t68 - 15))
    #R = 0.023302418791070513*C
    #rt_lc = c0 + (c1 + (c2 + (c3 + c4*t68)*t68)*t68)*t68
    #Rp = 1 + (p*(e1 + e2*p + e3*p*p))/(1 + d1*t68 + d2*t68*t68 + (d3 + d4*t68)*R)
    #Rt = R/(Rp*rt_lc)
    #Rtx = np.sqrt(Rt)
    #SP = a0 + (a1 + (a2 + (a3 + (a4 + a5*Rtx)*Rtx)*Rtx)*Rtx)*Rtx + ft68*(b0 + (b1 + (b2 + (b3 + (b4 + b5*Rtx)*Rtx)*Rtx)*Rtx)*Rtx)
    return SP

##  Convert Degree-Minute to Decimal Degree
def DM2D(x):
    deg = np.trunc(x/100)
    minute = x - 100*deg
    decimal = minute/60
    return deg+decimal

##  Convert radian to degree
def rad2deg(x):
    return x*180/np.pi


##  Compensate the oxygen data from sci_oxy4_oxygen from "fresh" to "salty"
def O2freshtosal(O2fresh,T,S):

    #define constants
    a1 =-0.00624097
    a2 = 0.00693498
    a3 = 0.00690358
    a4 = 0.00429155
    a5 = 3.11680e-7

    # interpolate nans in oxygen index
    not_nan = ~np.isnan(O2fresh)
    xp = not_nan.ravel().nonzero()[0]
    fp = O2fresh[not_nan]
    x  = np.isnan(O2fresh).ravel().nonzero()[0]

    O2fresh[np.isnan(O2fresh)] = np.interp(x, xp, fp)
    
    sca_T = np.log((298.15 - T)/(273.15 + T))
    O2sal =  O2fresh*np.exp(S*(a1 - a2*sca_T -  a3*sca_T**2 - a4*sca_T**3) - a5*S**2)
    return O2sal


## Range Check
def range_check(var,var_min,var_max):

    var_check = var

    # get rid of outliers above var_max
    id = var>var_max
    var_check[id]=np.nan
    
    # get rid of outliers below var_min
    id = var<var_min
    var_check[id]=np.nan

    # get rid of value exactly "0"
    id = np.where(var_check==0)[0]
    var_check[id]=np.nan

    return var_check


## Long lat Correction
def correctDR(lon,lat,timestamp,x_dr_state,gps_lon,gps_lat):
# Correction for glider dead reckoned locations when underwater
# using the gps and drift at surface state (approximate currents)
# Inputs:
#     m_lon (NMEA format)
#     m_lat (NMEA format)
#     m_present_time (unix)
#     x_dr_state (glider dive state variable)
#     m_gps_lon (NMEA format)
#     m_gps_lat  (NMEA format)
#
# Output
#    corr_lon, corr_lat (corrected m_lon, m_lat in decimal degrees)



    i_si     = np.argwhere( np.diff (x_dr_state**2)!=0)
    i_start = np.argwhere(np.diff( x_dr_state[i_si]**2, n=2,axis=0 )==18)
    i_start = i_si[i_start[:,0]]
    i_start = i_start[:,0]
    
    # print(np.isnan(lon[i_start[1]]))
    for ki in range(len(i_start) ):
        while np.isnan(lon[i_start[ki] ] ) :
            i_start[ki] = i_start[ki] +1
  
    # gps location at surface
    # transition x_dr_state from 2->3
    i_end  = np.argwhere(np.diff(x_dr_state**2,n=1,axis=0)==5)
    i_end  = i_end[:,0]-1
    for ki in range(len(i_end)):
        while (np.isnan(lon[i_end[ki]]) and np.isnan(gps_lon[i_end[ki]] ) ) :
            i_end[ki] = i_end[ki] +1

    # DR location after surfacing
    # transition from 1->2
    i_mid = np.argwhere(np.diff(x_dr_state**2,n=1,axis=0)==3)
    i_mid = i_mid[:,0]
    for ki in range(len(i_mid)):
	    while np.isnan(lon[i_mid[ki]]):
		    i_mid[ki] = i_mid[ki] -1

    t_start = timestamp[i_start]
    lon_dif=lon[i_end] - lon[i_mid]
    lat_dif=lat[i_end] - lat[ i_mid]
    t_dif=timestamp[i_mid]-timestamp[i_start]
    vlonDD = lon_dif / t_dif
    vlatDD  = lat_dif / t_dif
    loncDD = lon[0, ]
    latcDD = lat[0, ]

    ap = 0
    for i in range(len(i_start)):
    	idtemp=np.arange(i_start[i],i_mid[i]+1)
    	a = i_start[i] + np.argwhere(~np.isnan(lon[idtemp]))
    	ap = np.vstack((ap, a))
    	ti = timestamp[a] - timestamp[a[0]]
    	loncDD = np.vstack((loncDD.reshape(-1,1)   ,(lon[a] +   ti*vlonDD[i]).reshape(-1,1)  ))
    	latcDD  = np.vstack((latcDD.reshape(-1,1)  ,(lat[a] + ti*vlatDD[i] ).reshape(-1,1)  ))
    
    # NEED TO USE PADDING OF NANS
    
    return loncDD,latcDD
    






