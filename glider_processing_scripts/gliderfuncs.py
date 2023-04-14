import numpy as np
import pandas as pd
import gsw
from typing import Tuple

def interpolate_nans(x: np.ndarray):
	"""
	Fills not a number (nan's) in arrays

	Returns:
		Array with nan's filled.
	"""
	x = np.copy(x)
	not_nan = np.logical_not(np.isnan(x))
	x[np.isnan(x)] = np.interp(np.flatnonzero(np.isnan(x)), np.flatnonzero(not_nan), x[not_nan])
	return x

def c2salinity(c: np.ndarray, t: np.ndarray, p: np.ndarray, lon: np.ndarray, lat: np.ndarray,interpolate: bool = True) -> tuple[np.ndarray, np.ndarray]:
	"""
	Calculate practical salinity and absolute salinity from conductivity, temperature, and pressure using the GSW library.
	
	Args:
		c: Conductivity in S/m.
		t: Temperature in degrees Celsius.
		p: Pressure in dbar.
		lon: Longitude in degrees east.
		lat: Latitude in degrees north.
	
	Returns:
		A tuple containing the practical salinity and absolute salinity arrays.
	"""
	if not (c.shape == t.shape == p.shape == lon.shape == lat.shape):
		raise ValueError("All input arrays must have the same shape.")

	# Convert conductivity to microS/cm
	c *= 10
	
	if interpolate:
		p = interpolate_nans(p)
		t = interpolate_nans(t)
		c = interpolate_nans(c)
		lon = interpolate_nans(lon)
		lat = interpolate_nans(lat)
	
	# Compute practical salinity from conductivity
	S = gsw.C_from_SP(c, t, p)

	# Compute absolute salinity and return both salinity arrays
	SA = gsw.SA_from_SP(S, p, lon, lat)
	return S, SA

def stp2ct_density(SA: np.ndarray, t: np.ndarray, p: np.ndarray, interpolate: bool = True) -> tuple[np.ndarray, np.ndarray]:
	"""
	Calculate conservative temperature and sea water density from salinity, temperature, and pressure using the GSW toolbox.
	
	Args:
		SA (np.ndarray): Absolute salinity.
		t (np.ndarray): Temperature in degrees Celsius.
		p (np.ndarray): Pressure in dbar.
	
	Returns:
		tuple: A tuple containing conservative temperature (CT) and sea water density (rho).
	
	"""
	if not (SA.shape == t.shape == p.shape):
		raise ValueError("All input arrays must have the same shape.")
		
	if interpolate:
		p = interpolate_nans(p)
		t = interpolate_nans(t)
		SA = interpolate_nans(SA)
	
	CT = gsw.CT_from_t(SA, t, p)
	rho = gsw.rho(SA, CT, p)
	return CT, rho

def p2depth(p: np.ndarray, interpolate: bool = True) -> np.ndarray:
	"""
	Calculate the depth in meters from the sea water pressure in dbar.
	
	Args:
		p: Sea water pressure in dbar.
		interpolate (bool): Whether to interpolate missing values (default=False).
	
	Returns:
		The depth in meters corresponding to the given pressure.
	"""
	if interpolate:
		p = interpolate_nans(p)
		
	# Constants used in the depth calculation formula
	g = 9.81  # standard value of gravity, m/s^2
	a = -1.82e-15
	b = 2.279e-10
	c = 2.2512e-5
	d = 9.72659

	# Calculate the depth using the given pressure and the constants
	return (p * (p * (p* (p * a + b) - c) + d)) / g

def dm2d(x):
	"""
	Converts degree-minute to decimal degree.
	
	Args:
		x (float): Value in degree-minute format (e.g. 12345 for 12 degrees 34.5 minutes)
	
	Returns:
		float: Value in decimal degree format (e.g. 12.575 degrees)
	"""
	return np.trunc(x / 100) + (x % 100) / 60

def O2freshtosal(O2fresh: np.ndarray, T: np.ndarray, S: np.ndarray) -> np.ndarray:
	"""
	Compensate oxygen data from "fresh" to "salty" using temperature and salinity.
	
	Parameters:
		O2fresh (ndarray): Oxygen data in "fresh" units.
		T (float): Temperature in degrees Celsius.
		S (float): Salinity in Practical Salinity Units (PSU).
	
	Returns:
		ndarray: Oxygen data in "salty" units.
	
	Raises:
		ValueError: If O2fresh is not a numpy array.
	
	"""
	# define constants
	a1 = -0.00624097
	a2 = 0.00693498
	a3 = 0.00690358
	a4 = 0.00429155
	a5 = 3.11680e-7
	
	if not (isinstance(O2fresh, np.ndarray) and isinstance(T, np.ndarray) and isinstance(S, np.ndarray)):
		raise ValueError("O2fresh, T and S must be a numpy array.")
	
	if np.any(~np.isnan(O2fresh)):
		# interpolate nans in oxygen index
		not_nan = ~np.isnan(O2fresh)
		xp = not_nan.ravel().nonzero()[0]
		fp = O2fresh[not_nan]
		x = np.isnan(O2fresh).ravel().nonzero()[0]
		O2fresh[np.isnan(O2fresh)] = np.interp(x, xp, fp)
		sca_T = np.log((298.15 - T) / (273.15 + T))
		O2sal = O2fresh * np.exp(S * (a1 - a2 * sca_T - a3 * sca_T**2 - a4 * sca_T**3) - a5 * S**2)
	else:
		O2sal = np.full_like(O2fresh, np.nan)

	return O2sal

def findProfiles(stamp: np.ndarray,depth: np.ndarray,**kwargs) -> tuple[np.ndarray, np.ndarray]:
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

	# Remove dive_starts with NaN values
	for ki in range(len(dive_starts)):
		while glider_lon[dive_starts[ki]] != glider_lon[dive_starts[ki]]:
			dive_starts[ki] = dive_starts[ki] + 1

	# Find the end of each dive
	dive_ends = np.argwhere(np.diff(dive_state**2, n=1) == 5)[:,0] + 1

	# Remove dive_ends with NaN values
	for ki in range(len(dive_ends)):
		while (glider_lon[dive_ends[ki]] != glider_lon[dive_ends[ki]]) and (gps_lon[dive_ends[ki]] != gps_lon[dive_ends[ki]]):
			dive_ends[ki] = dive_ends[ki] + 1

	# Find the midpoint of each dive
	dive_mids = np.argwhere(np.diff(dive_state**2, n=1) == 3)[:,0]
	for ki in range(len(dive_mids)):
		while glider_lon[dive_mids[ki]] != glider_lon[dive_mids[ki]]:
			dive_mids[ki] = dive_mids[ki] - 1

	# Calculate the velocity for longitude and latitude
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

		# This index is used to introduce "nan's" for padding to match array size to the original array
		ap = np.hstack((ap, a))

		ti = (glider_timestamp[a] - glider_timestamp[a[0]]).to_numpy()  # Changed this line
		loncDD = np.hstack((loncDD, (glider_lon[a].to_numpy() + ti * vlonDD[i])))
		latcDD = np.hstack((latcDD, (glider_lat[a].to_numpy() + ti * vlatDD[i])))

	# Initialize the output arrays and fill them with the corrected values
	corrected_lon = glider_lon * np.nan
	corrected_lat = glider_lat * np.nan
	corrected_lon.iloc[ap.astype(int)] = loncDD
	corrected_lat.iloc[ap.astype(int)] = latcDD

	return corrected_lon, corrected_lat