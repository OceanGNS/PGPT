import numpy as np
import gsw

#######################################
############# salinity.py #################
#######################################

def c2salinity(C, t, p):
    # Algorithm to compute salinity using GSW toolbox
    # TEOS Toolbox <https://www.teos-10.org/software.htm>
    p = 10 * p  ##  dBar
    C = 10 * C  ##  mS/cm
    SP = gsw.SP_from_C(C, t, p)
    return SP

#######################################
############# p2depth ##################
#######################################

def p2depth(p):
    # Algorithm from seawater library to compute depth from pressure
    # input is sea water pressure p in dbar (dbar = bar*10)
    #
    g = 9.81 # standard val of gravity, m/s^2
    a = -1.82e-15
    b =2.279e-10
    c = 2.2512e-5
    d = 9.72659
    depth = (p*(p*(p*(p*a+b)-c)+d))/g
    return depth


#######################################
############# dm2dd ####################
#######################################

def dm2d(x):
    # Convert Degree-Minute to Decimal Degree
    deg = np.trunc(x / 100)
    minute = x - 100 * deg
    decimal = minute / 60
    return deg + decimal


#######################################
########### rad2deg ####################
#######################################

def rad2deg(x):
    return x * 180 / np.pi

#######################################
####### Oxygen Compensation #############
#######################################

def O2freshtosal(O2fresh, T, S):
    #  Compensate the oxygen data from sci_oxy4_oxygen from "fresh" to "salty"
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


#######################################
############# Range Check ##############
#######################################
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




#######################################
############## Find Profiles ##############
#######################################

def findProfiles(stamp,depth,**kwargs):
    # Code is a modified version from MATLAB code provided inside SOCIB toolbox
    #  <http://www.socib.es>
    #
    # findProfiles  Identify individual profiles and compute vertical direction from depth sequence.
    #
    #  Syntax:
    #   profile_index, profile_direction = findProfiles(stamp, depth,**kwargs)
    #    identify upcast and downcast profiles in depth (or pressure) vector DEPTH,
    #    with optional timestamps in vector STAMP, and computes a vector of profile
    #    indices PROFILE_INDEX and a vector of vertical direction PROFILE_DIRECTION.
    #    STAMP, DEPTH, PROFILE_DIRECTION and PROFILE_INDEX are the same length N,
    #    and if STAMP is not specified, it is assumed to be the sample index [1:N].
    #    PROFILE_DIRECTION entries may be 1 (down), 0 (flat), -1 (up).
    #    PROFILE_INDEX entries associate each sample with the number of the profile
    #    it belongs to. Samples in the middle of a profile are flagged with a whole
    #    number, starting at 1 and increased by 1 every time a new cast is detected,
    #    while samples between profiles are flagged with an offset of 0.5.
    #    See note on identification algorithm below.
    #
    #    **kwargs with field names as option keys and field values as option values:
    #      STALL: maximum range of a stalled segment (in the same units as DEPTH).
    #        Only intervals of constant vertical direction spanning a depth range
    #        not less than the given value are considered valid cast segments.
    #        Shorter intervals are considered stalled segments inside or between
    #        casts.
    #        Default value: 0 (all segments are valid cast segments)
    #      SHAKE: maximum duration of a shake segment (in the same units as STAMP).
    #        Only intervals of constant vertical direction with duration
    #        not less than the given value are considered valid cast segments.
    #        Briefer intervals are considered shake segments inside or between
    #        casts.
    #        Default value: 0 (all segments are valid cast segments)
    #      INVERSION: maximum depth inversion between cast segments of a profile.
    #        Consecutive valid cast segments with the same direction are joined
    #        together in the same profile if the range of the introduced depth
    #        inversion, if any, is less than the given value.
    #        Default value: 0 (never join cast segments)
    #      INTERRUPT: maximum time separation between cast segments of a profile.
    #        Consecutive valid cast segments with the same direction are joined
    #        together in the same profile if the duration of the lapse (sequence of
    #        stalled segments or shakes between them) is less than the given value.
    #        When STAMP is not specified, the duration will be the number of samples
    #        between them.
    #        Default value: 0 (never join cast segments)
    #      LENGTH: minimum length of a profile.
    #        A sequence of joined cast segments will be considered a valid profile
    #        only if the total spanned depth is greater or equal than the given.
    #        value.
    #        Default value: 0 (all profiles are valid)
    #      PERIOD: minimum duration of a profile.
    #        A sequence of joined cast segments will be considered a valid profile
    #        only if the total duration is greater or equal than the given value.
    #        Default value: 0 (all profiles are valid)
    #
    #  Notes:
    #    Profiles are identified as sequences of cast segments with the same
    #    vertical direction, allowing for stalled or shake segments in between.
    #    Vertical segments are intervals of constant vertical direction,
    #    and are delimited by the changes of vertical direction computed
    #    as the sign of forward differences of the depth sequence.
    #    A segment is considered stalled if it is to short in depth,
    #    or a shake if it is to short in time. Otherwise it is a cast segment.
    #    Consecutive cast segments with the same direction are joined together
    #    if the introduced depth inversion and the lapse between the segments
    #    are not significant according to the specified thresholds.
    #
    #    Invalid samples (NaN) in input are ignored. In output, they are marked as
    #    belonging to the previous profile, and with the direction of the previous
    #    sample.
    
    # CODE BEGINS
    
    # check ensure shape of input vectors
    #N = np.size(depth)
    #depth.shape = (N,)
    #stamp.shape = (N,)
    
    # define optional parameters
    options_list = {
        "length": 0,
        "period": 0,
        "inversion": 0,
        "interrupt": 0,
        "stall": 0,
        "shake": 0,
    }
    for i in options_list:
        if i in kwargs:
            options_list[i]=kwargs[i]
            
    print(options_list)
    
    depth= depth.flatten()
    stamp= stamp.flatten()

    # LOGIC BEGINS

    valid_index  = np.argwhere(np.logical_not(np.logical_or(np.isnan(depth),np.isnan(stamp)))).flatten()
    valid_index  = valid_index.astype(int)
    sdy = np.sign( np.diff( depth[valid_index],n=1,axis=0))
    depth_peak =  np.ones(np.size(valid_index), dtype=bool)
    depth_peak[1:len(depth_peak)-1,] = np.diff(sdy,n=1,axis=0) !=0
    depth_peak_index = valid_index[depth_peak]
    sgmt_frst = stamp[depth_peak_index[0:len(depth_peak_index)-1,]]
    sgmt_last = stamp[depth_peak_index[1:,]]
    sgmt_strt = depth[depth_peak_index[0:len(depth_peak_index)-1,]]
    sgmt_fnsh = depth[depth_peak_index[1:,]]
    sgmt_sinc = sgmt_last - sgmt_frst
    sgmt_vinc = sgmt_fnsh - sgmt_strt
    sgmt_vdir = np.sign(sgmt_vinc)

    #print(sgmt_vdir,sgmt_vinc,sgmt_sinc,sgmt_fnsh)

    cast_sgmt_valid = np.logical_not(np.logical_or(np.abs(sgmt_vinc) <= options_list["stall"],sgmt_sinc <= options_list["shake"]))
    cast_sgmt_index = np.argwhere(cast_sgmt_valid).flatten()
    cast_sgmt_lapse = sgmt_frst[cast_sgmt_index[1:]] - sgmt_last[cast_sgmt_index[0:len(cast_sgmt_index)-1]]
    cast_sgmt_space = -np.abs(sgmt_vdir[cast_sgmt_index[0:len(cast_sgmt_index)-1]] * (sgmt_strt[cast_sgmt_index[1:]] - sgmt_fnsh[cast_sgmt_index[0:len(cast_sgmt_index)-1]] ))
    cast_sgmt_dirch = np.diff(sgmt_vdir[cast_sgmt_index],n=1,axis=0)
    cast_sgmt_bound = np.logical_not((cast_sgmt_dirch[:,] == 0) & (cast_sgmt_lapse[:,] <= options_list["interrupt"]) & (cast_sgmt_space <= options_list["inversion"]))
    cast_sgmt_head_valid = np.ones(np.size(cast_sgmt_index), dtype=bool)
    cast_sgmt_tail_valid = np.ones(np.size(cast_sgmt_index), dtype=bool)
    cast_sgmt_head_valid[1:,] = cast_sgmt_bound
    cast_sgmt_tail_valid[0:len(cast_sgmt_tail_valid)-1,] = cast_sgmt_bound

    cast_head_index = depth_peak_index[cast_sgmt_index[cast_sgmt_head_valid]]
    cast_tail_index = depth_peak_index[cast_sgmt_index[cast_sgmt_tail_valid] + 1]
    cast_length = np.abs(depth[cast_tail_index] - depth[cast_head_index])
    cast_period = stamp[cast_tail_index] - stamp[cast_head_index];

    cast_valid = np.logical_not(np.logical_or(cast_length <= options_list["length"],cast_period <= options_list["period"]))
    cast_head = np.zeros(np.size(depth))
    cast_tail = np.zeros(np.size(depth))
    cast_head[cast_head_index[cast_valid] + 1] = 0.5
    cast_tail[cast_tail_index[cast_valid]] = 0.5

    # initialize output np arrays
    profile_index = 0.5 + np.cumsum(cast_head + cast_tail)
    profile_direction = np.empty((len(depth,)))
    profile_direction[:]= np.nan

    for i in range(len(valid_index)-1):
        i_start = valid_index[i]
        i_end = valid_index[i+1]
        #print(i,i_start,i_end)
        profile_direction[i_start:i_end]=sdy[i]
          
    return profile_index, profile_direction
    
#######################################
########## Long lat Correction #############
#######################################

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

    #T Fill nan's with previous value
    x_dr_state = x_dr_state.fillna(method='ffill')

    i_si = np.argwhere(np.diff(x_dr_state**2) != 0)
    i_start = np.argwhere(
        np.diff(x_dr_state[i_si[:, 0]]**2, n=2, axis=0) == 18)
    i_start = i_si[i_start[:, 0]]
    i_start = i_start[:, 0]

    # print(np.isnan(lon[i_start[1]]))
    for ki in range(len(i_start)):
        while np.isnan(lon[i_start[ki]]):
            i_start[ki] = i_start[ki] + 1

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
    t_dif = timestamp[i_mid].to_numpy() - timestamp[i_start].to_numpy()
    
    #Why time difference between mid and start? - Taimaz I changed it back to original code as this change broke the results
    #t_dif = timestamp[i_end].to_numpy() - timestamp[i_mid].to_numpy()
    
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
        
        #T What is "ap" used for?
        # it is the index of changed values based on the original array.
        # This index can be used to introduce "nan's" for padding to match array size to original array
        # print(a.size)
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
