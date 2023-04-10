import numpy as np
import pandas as pd
import gsw

def c2salinity(conductivity: np.ndarray, temperature: np.ndarray, pressure: np.ndarray, longitude: np.ndarray, latitude: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
	"""
	Calculate practical salinity and absolute salinity from conductivity, temperature, and pressure using the GSW library.
	
	Args:
		conductivity: Conductivity in S/m.
		temperature: Temperature in degrees Celsius.
		pressure: Pressure in dbar.
		longitude: Longitude in degrees east.
		latitude: Latitude in degrees north.
	
	Returns:
		A tuple containing the practical salinity and absolute salinity arrays.
	"""
	if not (conductivity.shape == temperature.shape == pressure.shape == longitude.shape == latitude.shape):
		raise ValueError("All input arrays must have the same shape.")

	# Convert conductivity to microS/cm
	conductivity *= 10

	# Compute practical salinity from conductivity
	practical_salinity = gsw.C_from_SP(conductivity, temperature, pressure)

	# Compute absolute salinity and return both salinity arrays
	absolute_salinity = gsw.SA_from_SP(practical_salinity, pressure, longitude, latitude)
	return practical_salinity, absolute_salinity

def stp2ct_density(SA: np.ndarray, t: np.ndarray, p: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
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
	
	CT = gsw.CT_from_t(SA, t, p)
	rho = gsw.rho(SA, CT, p)
	return CT, rho

def p2depth(p: np.ndarray):
	"""
	Calculate the depth in meters from the sea water pressure in dbar.
	
	Args:
		p: Sea water pressure in dbar.
	
	Returns:
		The depth in meters corresponding to the given pressure.
	"""
	# Constants used in the depth calculation formula
	g: float = 9.81  # standard value of gravity, m/s^2
	a: float = -1.82e-15
	b: float = 2.279e-10
	c: float = 2.2512e-5
	d: float = 9.72659

	# Calculate the depth using the given pressure and the constants
	depth: np.ndarray = (p * (p * (p * a + b) - c) + d) / g

	return depth

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
		raise ValueError("stamp and depth must be numpy arrays.")
	
	# Set default parameter values
	options_list = { "length": 0, "period": 0, "inversion": 0, "interrupt": 0, "stall": 0, "shake": 0 }
	options_list.update(kwargs)
	
	# Flatten input arrays
	depth, stamp = depth.flatten(), stamp.flatten()
	
	# Compute vertical direction
	valid = np.isfinite(depth) & np.isfinite(stamp)
	sdy = np.sign(np.diff(depth[valid]))
	
	# Identify depth peaks
	depth_peak = np.diff(sdy, prepend=0, append=0) != 0
	depth_peak_index = np.flatnonzero(depth_peak)
	
	# Identify cast segments
	sgmt_frst, sgmt_last = stamp[depth_peak_index[:-1]], stamp[depth_peak_index[1:]]
	sgmt_strt, sgmt_fnsh = depth[depth_peak_index[:-1]], depth[depth_peak_index[1:]]
	sgmt_sinc, sgmt_vinc = sgmt_last - sgmt_frst, sgmt_fnsh - sgmt_strt
	cast_sgmt_valid = ~(np.abs(sgmt_vinc) <= options_list["stall"]) & ~(sgmt_sinc <= options_list["shake"])
	cast_sgmt_index = np.flatnonzero(cast_sgmt_valid)
	cast_sgmt_lapse = sgmt_frst[cast_sgmt_index[1:]] - sgmt_last[cast_sgmt_index[:-1]]
	cast_sgmt_space = -sgmt_vinc[cast_sgmt_index[:-1]] * (sgmt_strt[cast_sgmt_index[1:]] - sgmt_fnsh[cast_sgmt_index[:-1]])
	cast_sgmt_dirch = np.diff(np.sign(sgmt_vinc[cast_sgmt_index]))
	cast_sgmt_bound = ~((cast_sgmt_dirch == 0) & (cast_sgmt_lapse <= options_list["interrupt"]) & (cast_sgmt_space <= options_list["inversion"]))
	cast_head_index = depth_peak_index[cast_sgmt_index[1:][cast_sgmt_bound]]
	cast_tail_index = depth_peak_index[cast_sgmt_index[:-1][cast_sgmt_bound]] + 1
	
	# Identify valid casts
	cast_length = np.abs(depth[cast_tail_index] - depth[cast_head_index])
	cast_period = stamp[cast_tail_index] - stamp[cast_head_index]
	cast_valid = ~(cast_length <= options_list["length"]) & ~(cast_period <= options_list["period"])
	
	# Initialize output np arrays
	profile_index = 0.5 + np.cumsum(np.concatenate(([0], cast_valid[:-1] != cast_valid[1:], [0])))
	profile_direction = np.full_like(depth, np.nan)
	
	# Compute vertical direction for each profile
	for i in range(len(depth_peak_index) - 1):
		start, end = depth_peak_index[i], depth_peak_index[i+1]
		profile_direction[start:end] = sdy[i]
	
	return profile_index, profile_direction


def correct_dead_reckoning(glider_lon, glider_lat, glider_timestamp, dive_state, gps_lon, gps_lat) -> tuple[np.ndarray, np.ndarray]:
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
	dive_starts = np.argwhere(np.diff(dive_state**2) == 17)[:,0] + 1
	
	# Remove dive_starts with NaN values
	dive_starts = dive_starts[~np.isnan(glider_lon[dive_starts])]
	
	# Find the end of each dive
	dive_ends = np.argwhere(np.diff(dive_state**2, n=1) == 5)[:,0] + 1
	
	# Remove dive_ends with NaN values
	dive_ends = dive_ends[~(np.isnan(glider_lon[dive_ends]) & np.isnan(gps_lon[dive_ends]))]
	
	# Find the midpoint of each dive
	dive_mids = np.argwhere(np.diff(dive_state**2, n=1) == 3)[:,0]
	while np.isnan(glider_lon[dive_mids]):
		dive_mids -= 1
	
	# Calculate the velocity for longitude and latitude
	time_diff = glider_timestamp[dive_mids] - glider_timestamp[dive_starts]
	vlonDD = (glider_lon[dive_ends] - glider_lon[dive_mids]) / time_diff
	vlatDD = (glider_lat[dive_ends] - glider_lat[dive_mids]) / time_diff
	
	# Calculate the corrected latitude and longitude
	good_indices = np.concatenate([np.argwhere(~np.isnan(glider_lon[i:j+1])) + i for i, j in zip(dive_starts, dive_mids)])
	ti = glider_timestamp[good_indices] - glider_timestamp[good_indices[0]]
	loncDD = np.concatenate([(glider_lon[i] + ti * vlonDD[n]) for n, i in enumerate(dive_starts)])
	latcDD = np.concatenate([(glider_lat[i] + ti * vlatDD[n]) for n, i in enumerate(dive_starts)])
	
	# Initialize the output arrays and fill them with the corrected values
	corrected_lon = np.full_like(glider_lon, np.nan)
	corrected_lat = np.full_like(glider_lat, np.nan)
	corrected_lon[good_indices] = loncDD
	corrected_lat[good_indices] = latcDD
	
	return corrected_lon, corrected_lat