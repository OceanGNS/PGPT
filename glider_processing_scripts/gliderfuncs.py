import gsw
import numpy as np
import pandas as pd

import numpy as np

def interpolate_nans(x, time: np.ndarray = None, tgap: int = None):
	"""
	Fills not a number (nan's) in arrays

	Returns:
		Array with nan's filled.
	"""
	x = np.copy(x)
	not_nan = np.logical_not(np.isnan(x))

	# Check if there are any non-NaN values in the array
	if not np.any(not_nan):
		return x  # Return the input array if it contains only NaN values

	if time is not None:
		if not isinstance(time[0], np.datetime64):
			time = np.array(time, dtype='datetime64[s]')

	nan_indices = np.flatnonzero(np.isnan(x))

	for idx in nan_indices:
		if idx == 0 or idx == len(x) - 1:
			continue

		if time is not None:
			left_time_diff = abs((time[idx] - time[idx - 1]).astype('timedelta64[s]').astype(float))
			right_time_diff = abs((time[idx + 1] - time[idx]).astype('timedelta64[s]').astype(float))
		else:
			left_time_diff = 1
			right_time_diff = 1

		if tgap is not None and (left_time_diff > tgap or right_time_diff > tgap):
			continue

		x[idx] = np.interp(idx, np.flatnonzero(not_nan), x[not_nan])

	return x


def p2depth(p: np.ndarray, time: np.ndarray = None, interpolate: bool = True, tgap: int = 20):
	"""
	Calculate the depth in meters from the sea water pressure in dbar.

	Args:
		p: Sea water pressure in dbar.
		interpolate (bool): Whether to interpolate missing values (default=False).

	Returns:
		The depth in meters corresponding to the given pressure.
	"""
	
	# Convert input arrays to ndarrays if they are not already
	p = np.asarray(p)
	
	if time is not None:
		time = np.asarray(time)
	
	if interpolate:
		if time is not None:
			p = interpolate_nans(p, time, tgap=tgap)
		else:
			p = interpolate_nans(p, tgap=tgap)

	# Constants used in the depth calculation formula
	g = 9.81  # standard value of gravity, m/s^2
	a = -1.82e-15
	b = 2.279e-10
	c = 2.2512e-5
	d = 9.72659

	# Calculate the depth using the given pressure and the constants
	return (p * (p * (p* (p * a + b) - c) + d)) / g

def dm2d(x: np.ndarray):
	"""
	Converts degree-minute (NMEA stamp ddmm.mm) to decimal degree (dd.dd).
	
	Args:
		x (ndarray): Value in degree-minute format (e.g. 4453.44 for 44 degrees 53.44 minutes)
	
	Returns:
		x: Value in decimal degree format (e.g. 44.889 degrees)
	"""
	sign = np.sign(x)
	x = np.abs(x)
	return sign * (np.trunc(x / 100) + (x % 100) / 60)

def deriveCTD(c, t, p, lon, lat, time=None, interpolate=False, tgap=20):
	"""
	Calculate practical salinity and absolute salinity from conductivity, temperature, and pressure using the GSW library.
	
	Args:
		c: Conductivity in S/m.
		t: Temperature in degrees Celsius.
		p: Pressure in dbar.
		lon: Longitude in degrees east.
		lat: Latitude in degrees north.
		time: Optional time array (datetime64 or Unix timestamps).
		interpolate: Whether to interpolate missing values (default=False).
		tgap: Time gap for interpolation (default=20).
	
	Returns:
		practical salinity, absolute salinity, conservative temperature, density
	"""
	# Convert input arrays to ndarrays if they are not already
	c = np.asarray(c)
	t = np.asarray(t)
	p = np.asarray(p)
	lon = np.asarray(lon)
	lat = np.asarray(lat)
	
	if time is not None:
		time = np.asarray(time)
	
	if not (c.shape == t.shape == p.shape):
		raise ValueError("All input arrays must have the same shape.")
	
	if interpolate:
		if time is not None:
			p = interpolate_nans(p, time, tgap)
			t = interpolate_nans(t, time, tgap)
			c = interpolate_nans(c, time, tgap)
		else:
			p = interpolate_nans(p, tgap=tgap)
			t = interpolate_nans(t, tgap=tgap)
			c = interpolate_nans(c, tgap=tgap)

	# c *= 10
		
	# Compute practical salinity from conductivity
	SP = gsw.conversions.SP_from_C(c*10, t, p)
	
	# Compute absolute salinity
	SA = gsw.SA_from_SP(SP, p, np.nanmean(lon), np.nanmean(lat))
	
	# Compute conservative tempeature
	CT =gsw.CT_from_t(SA, t, p)
	
	# Compute density
	rho = gsw.rho(SA, CT, p)
	
	return SP, SA, CT, rho

def deriveO2(O2fresh: np.ndarray, t: np.ndarray, SP: np.ndarray, time: np.ndarray = None, interpolate: bool = True, tgap: int = 20):
	"""
	1. Compensate raw oxygen data from "fresh" to "salty" using temperature and salinity.
	
	Parameters:
		O2fresh (ndarray): Oxygen data in micro-mol / L at Salinity = 0 (provided from the sensor).
		t (ndarray): Temperature in degrees Celsius.
		SP (ndarray): Salinity in Practical Salinity Units (PSU).
	
	Returns:
		O2sal (ndarray): Oxygen data in micro-mol / L compensated for salinity effects.
	
	Raises:
		ValueError: If O2fresh is not a numpy array.
	
	"""
	# define constants
	a1 = -0.00624097
	a2 = 0.00693498
	a3 = 0.00690358
	a4 = 0.00429155
	a5 = 3.11680e-7
	
	# Convert input arrays to ndarrays if they are not already
	t = np.asarray(t)
	SP = np.asarray(SP)
	O2fresh = np.asarray(O2fresh)
	
	if time is not None:
		time = np.asarray(time)
	
	if np.any(~np.isnan(O2fresh)):
		# Interpolate nans in oxygen
		if interpolate:
			if time is not None:
				O2fresh = interpolate_nans(O2fresh, time, tgap=tgap)
			else:
				O2fresh = interpolate_nans(O2fresh, tgap=tgap)
		
		sca_T = np.log((298.15 - t) / (273.15 + t))
		O2sal = O2fresh * np.exp(SP * (a1 - a2 * sca_T - a3 * sca_T**2 - a4 * sca_T**3) - a5 * SP**2)
	else:
		O2sal = np.full_like(O2fresh, np.nan)

	return O2sal

def findProfiles(stamp: np.ndarray,depth: np.ndarray,**kwargs):
	"""
	Identify individual profiles and compute vertical direction from depth sequence.
	
	Args:
		stamp (np.ndarray): A 1D array of timestamps.
		depth (np.ndarray): A 1D array of depths.
		**kwargs (optional): Optional arguments including:
			- length (int): Minimum length of a profile (default=0).
			- period (float): Minimum duration of a profile (default=0).
			- inversion (float): Maximum depth inversion between cast segments of a profile (default=0).
			- interrupt (float): Maximum time separation between cast segments of a profile (default=0).
			- stall (float): Maximum range of a stalled segment (default=0).
			- shake (float): Maximum duration of a shake segment (default=0).
	
	Returns:
		profile_index (np.ndarray): A 1D array of profile indices.
		profile_direction (np.ndarray): A 1D array of vertical directions.
	"""
	if not (isinstance(stamp, np.ndarray) and isinstance(depth, np.ndarray)):
		stamp = stamp.to_numpy()
		depth = depth.to_numpy()
	
	# Flatten input arrays
	depth, stamp = depth.flatten(), stamp.flatten()
	
	# Check if the stamp is a datetime object and convert to elapsed seconds if necessary
	if np.issubdtype(stamp.dtype, np.datetime64):
		stamp = (stamp - stamp[0]).astype('timedelta64[s]').astype(float)
	
	# Set default parameter values (did not set type np.timedelta64(0, 'ns') )
	options_list = { "length": 0, "period": 0, "inversion": 0, "interrupt": 0, "stall": 0, "shake": 0}
	options_list.update(kwargs)
	
	valid_index = np.argwhere(np.logical_not(np.isnan(depth)) & np.logical_not(np.isnan(stamp))).flatten()
	valid_index = valid_index.astype(int)
	
	sdy = np.sign(np.diff(depth[valid_index], n=1, axis=0))
	depth_peak = np.ones(np.size(valid_index), dtype=bool)
	depth_peak[1:len(depth_peak) - 1,] = np.diff(sdy, n=1, axis=0) != 0
	depth_peak_index = valid_index[depth_peak]
	sgmt_frst = stamp[depth_peak_index[0:len(depth_peak_index) - 1,]]
	sgmt_last = stamp[depth_peak_index[1:,]]
	sgmt_strt = depth[depth_peak_index[0:len(depth_peak_index) - 1,]]
	sgmt_fnsh = depth[depth_peak_index[1:,]]
	sgmt_sinc = sgmt_last - sgmt_frst
	sgmt_vinc = sgmt_fnsh - sgmt_strt
	sgmt_vdir = np.sign(sgmt_vinc)

	cast_sgmt_valid = np.logical_not(np.logical_or(np.abs(sgmt_vinc) <= options_list["stall"], sgmt_sinc <= options_list["shake"]))
	cast_sgmt_index = np.argwhere(cast_sgmt_valid).flatten()
	cast_sgmt_lapse = sgmt_frst[cast_sgmt_index[1:]] - sgmt_last[cast_sgmt_index[0:len(cast_sgmt_index) - 1]]
	cast_sgmt_space = -np.abs(sgmt_vdir[cast_sgmt_index[0:len(cast_sgmt_index) - 1]] * (sgmt_strt[cast_sgmt_index[1:]] - sgmt_fnsh[cast_sgmt_index[0:len(cast_sgmt_index) - 1]]))
	cast_sgmt_dirch = np.diff(sgmt_vdir[cast_sgmt_index], n=1, axis=0)
	cast_sgmt_bound = np.logical_not((cast_sgmt_dirch[:,] == 0) & (cast_sgmt_lapse[:,] <= options_list["interrupt"]) & (cast_sgmt_space <= options_list["inversion"]))
	cast_sgmt_head_valid = np.ones(np.size(cast_sgmt_index), dtype=bool)
	cast_sgmt_tail_valid = np.ones(np.size(cast_sgmt_index), dtype=bool)
	cast_sgmt_head_valid[1:,] = cast_sgmt_bound
	cast_sgmt_tail_valid[0:len(cast_sgmt_tail_valid) - 1,] = cast_sgmt_bound

	cast_head_index = depth_peak_index[cast_sgmt_index[cast_sgmt_head_valid]]
	cast_tail_index = depth_peak_index[cast_sgmt_index[cast_sgmt_tail_valid] + 1]
	cast_length = np.abs(depth[cast_tail_index] - depth[cast_head_index])
	cast_period = stamp[cast_tail_index] - stamp[cast_head_index]
	cast_valid = np.logical_not(np.logical_or(cast_length <= options_list["length"], cast_period <= options_list["period"]))
	cast_head = np.zeros(np.size(depth))
	cast_tail = np.zeros(np.size(depth))
	cast_head[cast_head_index[cast_valid] + 1] = 0.5
	cast_tail[cast_tail_index[cast_valid]] = 0.5

	profile_index = 0.5 + np.cumsum(cast_head + cast_tail)
	profile_direction = np.empty((len(depth,)))
	profile_direction[:] = np.nan

	for i in range(len(valid_index) - 1):
		i_start = valid_index[i]
		i_end = valid_index[i + 1]
		profile_direction[i_start:i_end] = sdy[i]

	return profile_index, profile_direction

def correct_dead_reckoning(glider_lon, glider_lat, glider_timestamp, dive_state, gps_lon, gps_lat):
	"""
	Corrects glider dead reckoned locations when underwater
	using the gps and drift at surface state (approximate currents)

	Parameters:
		glider_lon (pd.Series): glider longitude
		glider_lat (pd.Series): glider latitude
		glider_timestamp (pd.Series): glider timestamp
		dive_state (pd.Series): glider dive state variable
		gps_lon (pd.Series): gps longitude
		gps_lat (pd.Series): gps latitude

	Returns:
		corrected_lon (pd.Series): corrected glider longitude
		corrected_lat (pd.Series): corrected glider latitude
	"""
	if not (isinstance(glider_lon, pd.Series) and isinstance(glider_lat, pd.Series) and isinstance(glider_timestamp, pd.Series) and isinstance(dive_state, pd.Series) and isinstance(gps_lon, pd.Series) and isinstance(gps_lat, pd.Series)):
		raise ValueError("lon,lat inputs must be pandas series.")

	# Fill NaN values with previous value
	dive_state = dive_state.ffill()

	# Find the start of each dive
	dive_starts = np.argwhere(np.diff(dive_state**2) != 0).flatten()
	dive_starts = dive_starts[np.argwhere(np.diff(dive_state[dive_starts]**2, n=2, axis=0) == 18).flatten()]
	# dive_starts = np.argwhere(np.diff(dive_state) < 0).flatten()
 
	# Remove dive_starts with NaN values
	for ki in range(len(dive_starts)):
		while glider_lon[dive_starts[ki]] != glider_lon[dive_starts[ki]]:
			dive_starts[ki] = dive_starts[ki] + 1

	# Find the end of each dive (dive_state 2 > 3)
	dive_ends = np.argwhere(np.diff(dive_state**2, n=1) == 5)[:,0] + 1 # 
	# diff = np.diff(dive_state**2, n=1)
	# diff_12 = diff==3  ##T dive_state change from 1 to 2
	# diff_13 = diff==8  ##T dive_state change from 1 to 3
	# diff_14 = diff==15  ##T dive_state change from 1 to 4
	# dive_ends = np.argwhere(diff_12+diff_13+diff_14).flatten()

	# Remove dive_ends with NaN values
	for ki in range(len(dive_ends)):
		while (glider_lon[dive_ends[ki]] != glider_lon[dive_ends[ki]]) and (gps_lon[dive_ends[ki]] != gps_lon[dive_ends[ki]]):
			dive_ends[ki] = dive_ends[ki] + 1

	# Find the midpoint of each dive
	dive_mids = np.argwhere(np.diff(dive_state**2, n=1) == 3)[:,0]  #T Doesn't always work.  There are cases with dive_state going 1 > 4 > 1.

	for ki in range(len(dive_mids)):
		while glider_lon[dive_mids[ki]] != glider_lon[dive_mids[ki]]:
			dive_mids[ki] = dive_mids[ki] - 1

	print(dive_starts.shape,dive_mids.shape,dive_ends.shape)
	# Calculate the velocity for longitude and latitude
	# print(dive_starts,dive_starts.shape)
	# print(dive_mids,dive_mids.shape)
	# print(dive_ends,dive_ends.shape)
	time_diff = glider_timestamp[dive_mids].to_numpy() - glider_timestamp[dive_starts].to_numpy()
	vlonDD = (glider_lon[dive_ends].to_numpy() - glider_lon[dive_mids].to_numpy()) / time_diff
	vlatDD = (glider_lat[dive_ends].to_numpy() - glider_lat[dive_mids].to_numpy()) / time_diff

	# Calculate the corrected latitude and longitude
	loncDD = np.array(())
	latcDD = np.array(())
	ap = np.array(())
	
	for i in range(len(dive_starts)):
		idtemp = np.arange(dive_starts[i], dive_mids[i] + 1)
		a = (dive_starts[i] + np.argwhere((~glider_lon[idtemp].isna()).to_numpy())).flatten()
		#
		# This index is used to introduce "nan's" for padding to match array size to the original array
		ap = np.hstack((ap, a))
		if(len(a)==0):
			continue
		ti = (glider_timestamp[a] - glider_timestamp[a[0]]).to_numpy()  # Changed this line
		loncDD = np.hstack((loncDD, (glider_lon[a].to_numpy() + ti * vlonDD[i])))
		latcDD = np.hstack((latcDD, (glider_lat[a].to_numpy() + ti * vlatDD[i])))

	# Initialize the output arrays and fill them with the corrected values
	corrected_lon = glider_lon * np.nan
	corrected_lat = glider_lat * np.nan
	corrected_lon.iloc[ap.astype(int)] = loncDD
	corrected_lat.iloc[ap.astype(int)] = latcDD

	return corrected_lon, corrected_lat