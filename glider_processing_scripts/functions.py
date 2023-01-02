import numpy as np
import gsw


## PSS-78 Algorithm to compute salinity
def salinity(C, t, p):
    p = 10 * p  ##  dBar
    C = 10 * C  ##  mS/cm
    SP = gsw.SP_from_C(C, t, p)
    return SP


##  Convert Degree-Minute to Decimal Degree
def DM2D(x):
    deg = np.trunc(x / 100)
    minute = x - 100 * deg
    decimal = minute / 60
    return deg + decimal


##  Convert radian to degree
def rad2deg(x):
    return x * 180 / np.pi


##  Compensate the oxygen data from sci_oxy4_oxygen from "fresh" to "salty"
def O2freshtosal(O2fresh, T, S):

    #define constants
    a1 = -0.00624097
    a2 = 0.00693498
    a3 = 0.00690358
    a4 = 0.00429155
    a5 = 3.11680e-7

    # interpolate nans in oxygen index
    not_nan = ~np.isnan(O2fresh)
    xp = not_nan.ravel().nonzero()[0]
    fp = O2fresh[not_nan]
    x = np.isnan(O2fresh).ravel().nonzero()[0]

    O2fresh[np.isnan(O2fresh)] = np.interp(x, xp, fp)

    sca_T = np.log((298.15 - T) / (273.15 + T))
    O2sal = O2fresh * np.exp(S * (a1 - a2 * sca_T - a3 * sca_T**2 - a4 * sca_T**3) - a5 * S**2)
    return O2sal


## Range Check
def range_check(var, var_min, var_max):

    var_check = var

    # get rid of outliers above var_max
    id = var > var_max
    var_check[id] = np.nan

    # get rid of outliers below var_min
    id = var < var_min
    var_check[id] = np.nan

    # get rid of value exactly "0"
    id = np.where(var_check == 0)[0]
    var_check[id] = np.nan

    return var_check


## Long lat Correction
def correctDR(lon, lat, timestamp, x_dr_state, gps_lon, gps_lat):
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
    # HAS LOGICAL ERROR IN THE CODE! ITS NOT CLEAR WHAT THE ISSUE IS

    i_si = np.argwhere(np.diff(x_dr_state**2) != 0)
    i_start = np.argwhere(
        np.diff(x_dr_state[i_si[:, 0]]**2, n=2, axis=0) == 18)
    i_start = i_si[i_start[:, 0]]
    i_start = i_start[:, 0]

    # print(np.isnan(lon[i_start[1]]))
    for ki in range(len(i_start)):
        while np.isnan(lon[i_start[ki]]):
            i_start[ki] = i_start[ki] + 1

    #T Fill nan's with previous value
    x_dr_state = x_dr_state.fillna(method='ffill')
    
    # gps location at surface
    # transition x_dr_state from 2->3
    i_end = np.argwhere(np.diff(x_dr_state**2, n=1, axis=0) == 5)
    i_end = i_end[:, 0] + 1
    for ki in range(len(i_end)):
        while (np.isnan(lon[i_end[ki]]) and np.isnan(gps_lon[i_end[ki]])):
            i_end[ki] = i_end[ki] + 1

    # DR location after surfacing
    # transition from 1->2
    i_mid = np.argwhere(np.diff(x_dr_state**2, n=1, axis=0) == 3)
    i_mid = i_mid[:, 0]
    for ki in range(len(i_mid)):
        while np.isnan(lon[i_mid[ki]]):
            i_mid[ki] = i_mid[ki] - 1

    # t_start = timestamp[i_start]
    lon_dif = lon[i_end].to_numpy() - lon[i_mid].to_numpy()
    lat_dif = lat[i_end].to_numpy() - lat[i_mid].to_numpy()
    
    #Why time difference between mid and start?
    t_dif = timestamp[i_end].to_numpy() - timestamp[i_mid].to_numpy()
    # Taimaz, we may need to change it back to original code as this change broke the results in the example :(
    #t_dif = timestamp[i_mid].to_numpy() - timestamp[i_start].to_numpy()
    
    vlonDD = lon_dif / t_dif
    vlatDD = lat_dif / t_dif

    # we need to initialize loncDD and latcDD
    loncDD = np.array(())
    latcDD = np.array(())

    # ap is the index for the "good" positions used for later padding of values
    ap = np.array(())
    
    for i in range(len(i_start)):
        
        #T Again, why i_start and i_mid, rather than i_mid and i_end?  Below we're using
        #T vlonDD & vlatDD, which are calculated based on i_end & i-mid.
        #T I think there should be 2 loops.  One to cover i_start:i_mid, and on for the
        #T i_mid:i_end interval.
        idtemp = np.arange(i_start[i], i_mid[i] + 1)
        a = (i_start[i] + np.argwhere((~np.isnan(lon[idtemp])).to_numpy())).flatten()

        # This index is used to introduce "nan's" for padding to match array size to original array
        ap = np.hstack((ap, a))
        
        ti = timestamp[a] - timestamp[a[0]]
        loncDD = np.hstack(
            (loncDD, (lon[a] + ti * vlonDD[i]).to_numpy()))
        latcDD = np.hstack(
            (latcDD, (lat[a] + ti * vlatDD[i]).to_numpy()))

    # use ap to pad vectors to original input size of lon,lat
    loncDDs = lon*np.nan
    latcDDs = lon*np.nan

    loncDDs[ap]=loncDD
    latcDDs[ap]=latcDD
    return loncDDs,latcDDs
