def findProfiles(stamp,depth,**kwargs):
	depth = np.array(depth)
    stamp=np.array(stamp)
    
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
            
    #print(options_list)
    
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