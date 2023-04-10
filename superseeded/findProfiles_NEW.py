def findProfiles(stamp, depth, **kwargs):
    import numpy as np
    
    # Assertions to check input arguments
    assert isinstance(stamp, np.ndarray), "stamp must be a numpy array"
    assert isinstance(depth, np.ndarray), "depth must be a numpy array"
    assert len(depth.shape) == 1, "depth must be a 1-dimensional array"
    assert len(stamp.shape) == 1, "stamp must be a 1-dimensional array"
    
    # Set default value of stamp if not provided
    if stamp is None:
        stamp = np.arange(1, len(depth)+1)
        
    # Set default values of optional arguments
    options_list = {
        "length": 0,
        "period": 0,
        "inversion": 0,
        "interrupt": 0,
        "stall": 0,
        "shake": 0,
    }
    options_list.update(kwargs)
    
    # Check if all optional arguments are provided
    valid_options = ["length", "period", "inversion", "interrupt", "stall", "shake"]
    for option in valid_options:
        assert option in options_list, f"{option} is not provided in kwargs"
    
    # Check if the length of stamp and depth is the same
    assert len(stamp) == len(depth), "stamp and depth must have the same length"
    
    # Flatten depth and stamp arrays
    depth = depth.flatten()
    stamp = stamp.flatten()
    
    # Get the indices of non-NaN values in depth and stamp arrays
    valid_index = np.flatnonzero(~np.isnan(depth) & ~np.isnan(stamp))
    
    # Define profile_index and profile_direction arrays
    profile_index = np.zeros_like(depth) - 0.5
    profile_direction = np.zeros_like(depth)

    # Initialize profile index and profile direction
    profile = 0
    direction = np.sign(np.diff(depth[valid_index[:2]]))
    
    # Loop over valid indices to identify profiles
    for i in range(2, len(valid_index)):
        # Compute the current direction
        current_direction = np.sign(depth[valid_index[i]] - depth[valid_index[i-1]])
        
        # Check if the direction has changed
		if current_direction != direction:
    		# Compute the duration and depth range of the previous segment
    		duration = stamp[valid_index[i-1]] - stamp[valid_index[i-2]]
    		depth_range = np.abs(depth[valid_index[i-1]] - depth[valid_index[i-2]])
    
    		# Check if the previous segment is a valid cast segment
    		if direction==np.sign(np.diff(depth)):
    
    # Add the direction of the last sample
    direction=np.append(direction,direction[-1])
    
    # Find segments
    is_segment_boundary=np.concatenate(([1],np.abs(np.diff(direction))>0,[1]))
    segment_start_index=np.nonzero(is_segment_boundary[:-1])[0]
    segment_end_index=np.nonzero(is_segment_boundary[1:])[0]-1
    
    # Exclude short segments
    segment_depth_range=depth[segment_end_index]-depth[segment_start_index]
    segment_duration=stamp[segment_end_index]-stamp[segment_start_index]
    
    exclude=np.logical_or(
        segment_depth_range<=options_list["stall"],
        segment_duration<=options_list["shake"],
    )
    is_segment_boundary[segment_start_index[exclude]]=False
    is_segment_boundary[segment_end_index[exclude]+1]=False
    
    # Find profiles
    profile_index=np.zeros_like(depth)
    profile_direction=np.zeros_like(depth)
    
    profile_count=0
    profile_depth_range=0
    profile_start_index=0
    last_profile_end_index=0
    last_profile_direction=0
    
    for segment_index in np.nonzero(is_segment_boundary[:-1])[0]:
        if is_segment_boundary[segment_index]:
            next_segment_index=segment_index+1
            
            if segment_index-last_profile_end_index==1:
                # The previous segment was a transition. Skip it
                profile_direction[segment_index]=last_profile_direction
                profile_index[segment_index]=profile_count-1
                
            elif segment_index-last_profile_end_index>1:
                # End of a profile
                profile_end_index=last_profile_end_index+np.argmax(depth[last_profile_end_index:segment_index])
                profile_depth_range=depth[profile_end_index]-depth[profile_start_index]
                
                if (
                    profile_count>0
                    and (
                        profile_depth_range<=options_list["length"]
                        or stamp[segment_index-1]-stamp[last_profile_end_index]>=options_list["interrupt"]
                        or np.abs(np.sum(np.diff(depth[last_profile_end_index:segment_index]))))>=options_list["inversion"]
                ):
                    # Invalidate the last profile if any condition is not met
                    profile_index[last_profile_end_index:segment_index]=profile_count-1
                    profile_direction[last_profile_end_index:segment_index]=last_profile_direction
                else:
                    # Finish the profile
                    profile_index[profile_start_index:profile_end_index+1]=profile_count
                    profile_direction[profile_start_index:profile_end_index+1]=last_profile_direction
                    profile_count+=1
                    
                last_profile_end_index=profile_end_index
                
            profile_start_index=segment_index
            last_profile_direction=direction[segment_index]
            
    # Finish the last profile
    profile_depth_range=depth[-1]-depth[profile_start_index]
    
	if (
    	profile_depth_range<=options_list["length"]
    	or stamp[-1]-stamp[last_profile_end_index]>=options_list["interrupt"]
    	or np.abs(np.sum(np.diff(depth[last_profile_end_index:]))))>=options_list["inversion"]
	):
        # Invalidate the last profile if any condition is not met
        profile_index[last_profile_end_index:]=profile_count-1
        profile_direction[last_profile_end_index:]=last_profile_direction
    else:
        # Finish the profile
        profile_index[profile_start_index:]=profile_count
        profile_direction[profile_start_index:]=last_profile_direction
        profile_count+=1
    
    # Return the results
    return profile_index, profile_direction
