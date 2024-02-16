import gsw
import numpy as np
import pandas as pd


def interpolateNANs(x, time: np.ndarray = None, tgap: int = None):
	"""
	Fills not a number (nan's) in arrays

	Returns:
		Array with nan's filled.
	"""
	x = np.copy(x)
	notNAN = np.logical_not(np.isnan(x))

	# Check if there are any non-NaN values in the array
	if not np.any(notNAN):
		return x  # Return the input array if it contains only NaN values

	if time is not None:
		if not isinstance(time[0], np.datetime64):
			time = np.array(time, dtype='datetime64[s]')

	NANindices = np.flatnonzero(np.isnan(x))

	for idx in NANindices:
		if idx == 0 or idx == len(x) - 1:
			continue

		if time is not None:
			leftTimeDiff = abs((time[idx] - time[idx - 1]).astype('timedelta64[s]').astype(float))
			rightTimeDiff = abs((time[idx + 1] - time[idx]).astype('timedelta64[s]').astype(float))
		else:
			leftTimeDiff = 1
			rightTimeDiff = 1

		if tgap is not None and (leftTimeDiff > tgap or rightTimeDiff > tgap):
			continue

		x[idx] = np.interp(idx, np.flatnonzero(notNAN), x[notNAN])

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
			p = interpolateNANs(p, time, tgap=tgap)
		else:
			p = interpolateNANs(p, tgap=tgap)

	# Constants used in the depth calculation formula
	g = 9.81  # standard value of gravity, m/s^2
	a = -1.82e-15
	b = 2.279e-10
	c = 2.2512e-5
	d = 9.72659

	# Calculate the depth using the given pressure and the constants
	return (p * (p * (p* (p * a + b) - c) + d)) / g

##T  NOT NEEDED ANYMORE.  DBDREADER PACKAGE TAKES CARE OF IT.
# def dm2d(x: np.ndarray):
# 	"""
# 	Converts degree-minute (NMEA stamp ddmm.mm) to decimal degree (dd.dd).
	
# 	Args:
# 		x (ndarray): Value in degree-minute format (e.g. 4453.44 for 44 degrees 53.44 minutes)
	
# 	Returns:
# 		x: Value in decimal degree format (e.g. 44.889 degrees)
# 	"""
# 	sign = np.sign(x)
# 	x = np.abs(x)
# 	return sign * (np.trunc(x / 100) + (x % 100) / 60)

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
			p = interpolateNANs(p, time, tgap)
			t = interpolateNANs(t, time, tgap)
			c = interpolateNANs(c, time, tgap)
		else:
			p = interpolateNANs(p, tgap=tgap)
			t = interpolateNANs(t, tgap=tgap)
			c = interpolateNANs(c, tgap=tgap)

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
				O2fresh = interpolateNANs(O2fresh, time, tgap=tgap)
			else:
				O2fresh = interpolateNANs(O2fresh, tgap=tgap)
		
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
	optionsList = { "length": 0, "period": 0, "inversion": 0, "interrupt": 0, "stall": 0, "shake": 0}
	optionsList.update(kwargs)
	
	validIndex = np.argwhere(np.logical_not(np.isnan(depth)) & np.logical_not(np.isnan(stamp))).flatten()
	validIndex = validIndex.astype(int)
	
	sdy = np.sign(np.diff(depth[validIndex], n=1, axis=0))
	depthPeak = np.ones(np.size(validIndex), dtype=bool)
	depthPeak[1:len(depthPeak) - 1,] = np.diff(sdy, n=1, axis=0) != 0
	depthPeakIndex = validIndex[depthPeak]
	sgmtFrst = stamp[depthPeakIndex[0:len(depthPeakIndex) - 1,]]
	sgmtLast = stamp[depthPeakIndex[1:,]]
	sgmtStrt = depth[depthPeakIndex[0:len(depthPeakIndex) - 1,]]
	sgmtFnsh = depth[depthPeakIndex[1:,]]
	sgmtSinc = sgmtLast - sgmtFrst
	sgmtVinc = sgmtFnsh - sgmtStrt
	sgmtVdir = np.sign(sgmtVinc)

	castSgmtValid = np.logical_not(np.logical_or(np.abs(sgmtVinc) <= optionsList["stall"], sgmtSinc <= optionsList["shake"]))
	castSgmtIndex = np.argwhere(castSgmtValid).flatten()
	castSgmtLapse = sgmtFrst[castSgmtIndex[1:]] - sgmtLast[castSgmtIndex[0:len(castSgmtIndex) - 1]]
	castSgmtSpace = -np.abs(sgmtVdir[castSgmtIndex[0:len(castSgmtIndex) - 1]] * (sgmtStrt[castSgmtIndex[1:]] - sgmtFnsh[castSgmtIndex[0:len(castSgmtIndex) - 1]]))
	castSgmtDirch = np.diff(sgmtVdir[castSgmtIndex], n=1, axis=0)
	castSgmtBound = np.logical_not((castSgmtDirch[:,] == 0) & (castSgmtLapse[:,] <= optionsList["interrupt"]) & (castSgmtSpace <= optionsList["inversion"]))
	castSgmtHeadValid = np.ones(np.size(castSgmtIndex), dtype=bool)
	castSgmtTailValid = np.ones(np.size(castSgmtIndex), dtype=bool)
	castSgmtHeadValid[1:,] = castSgmtBound
	castSgmtTailValid[0:len(castSgmtTailValid) - 1,] = castSgmtBound

	castHeadIndex = depthPeakIndex[castSgmtIndex[castSgmtHeadValid]]
	castTailIndex = depthPeakIndex[castSgmtIndex[castSgmtTailValid] + 1]
	castLength = np.abs(depth[castTailIndex] - depth[castHeadIndex])
	castPeriod = stamp[castTailIndex] - stamp[castHeadIndex]
	castValid = np.logical_not(np.logical_or(castLength <= optionsList["length"], castPeriod <= optionsList["period"]))
	castHead = np.zeros(np.size(depth))
	castTail = np.zeros(np.size(depth))
	castHead[castHeadIndex[castValid] + 1] = 0.5
	castTail[castTailIndex[castValid]] = 0.5

	profileIndex = 0.5 + np.cumsum(castHead + castTail)
	profileDirection = np.empty((len(depth,)))
	profileDirection[:] = np.nan

	for i in range(len(validIndex) - 1):
		iStart = validIndex[i]
		iEnd = validIndex[i + 1]
		profileDirection[iStart:iEnd] = sdy[i]

	return profileIndex, profileDirection

def correctDeadReckoning(gliderLon, gliderLat, gliderTimestamp, diveState, gpsLon, gpsLat):
	"""
	Corrects glider dead reckoned locations when underwater
	using the gps and drift at surface state (approximate currents)

	Parameters:
		gliderLon (pd.Series): glider longitude
		gliderLat (pd.Series): glider latitude
		gliderTimestamp (pd.Series): glider timestamp
		diveState (pd.Series): glider dive state variable
		gpsLon (pd.Series): gps longitude
		gpsLat (pd.Series): gps latitude

	Returns:
		correctedLon (pd.Series): corrected glider longitude
		correctedLat (pd.Series): corrected glider latitude
	"""
	if not (isinstance(gliderLon, pd.Series) and isinstance(gliderLat, pd.Series) and isinstance(gliderTimestamp, pd.Series) and isinstance(diveState, pd.Series) and isinstance(gpsLon, pd.Series) and isinstance(gpsLat, pd.Series)):
		raise ValueError("lon,lat inputs must be pandas series.")
	#
	# Fill NaN values with previous value
	diveState = diveState.ffill()
	#
	# Find the start of each dive
	diveStarts = np.argwhere(np.diff(diveState**2) != 0).flatten()
	diveStarts = diveStarts[np.argwhere(np.diff(diveState[diveStarts]**2, n=2, axis=0) == 18).flatten()]
	# diveStarts = np.argwhere(np.diff(diveState) < 0).flatten()
	#
	# Remove diveStarts with NaN values
	for ki in range(len(diveStarts)):
		while gliderLon[diveStarts[ki]] != gliderLon[diveStarts[ki]]:
			diveStarts[ki] = diveStarts[ki] + 1
	#
	# Find the end of each dive (diveState 2 -> 3 or 2 -> 4)
	diveEnds = np.argwhere(np.logical_or(np.diff(diveState**2, n=1) == 5, np.diff(diveState**2, n=1) == 12))[:,0]+1
	# diff = np.diff(diveState**2, n=1)
	# diff_12 = diff==3  ##T diveState change from 1 to 2
	# diff_13 = diff==8  ##T diveState change from 1 to 3
	# diff_14 = diff==15  ##T diveState change from 1 to 4
	# diveEnds = np.argwhere(diff_12+diff_13+diff_14).flatten()
	#
	# Remove diveEnds with NaN values
	for ki in range(len(diveEnds)):
		while (gliderLon[diveEnds[ki]] != gliderLon[diveEnds[ki]]) and (gpsLon[diveEnds[ki]] != gpsLon[diveEnds[ki]]):
			diveEnds[ki] = diveEnds[ki] + 1
	#
	# Find the midpoint of each dive
	diveMids = np.argwhere(np.diff(diveState**2, n=1) == 3)[:,0]  #T Doesn't always work.  There are cases with diveState going 1 > 4 > 1.
	#
	for ki in range(len(diveMids)):
		while gliderLon[diveMids[ki]] != gliderLon[diveMids[ki]]:
			diveMids[ki] = diveMids[ki] - 1
	#
	print(diveStarts.shape, diveMids.shape, diveEnds.shape)
	# Calculate the velocity for longitude and latitude
	# print(diveStarts,diveStarts.shape)
	# print(diveMids,diveMids.shape)
	# print(diveEnds,diveEnds.shape)
	timeDiff = gliderTimestamp[diveMids].to_numpy() - gliderTimestamp[diveStarts].to_numpy()
	vlonDD = (gliderLon[diveEnds].to_numpy() - gliderLon[diveMids].to_numpy()) / timeDiff
	vlatDD = (gliderLat[diveEnds].to_numpy() - gliderLat[diveMids].to_numpy()) / timeDiff
	#
	# Calculate the corrected latitude and longitude
	loncDD = np.array(())
	latcDD = np.array(())
	ap = np.array(())
	#
	for i in range(len(diveStarts)):
		idtemp = np.arange(diveStarts[i], diveMids[i] + 1)
		a = (diveStarts[i] + np.argwhere((~gliderLon[idtemp].isna()).to_numpy())).flatten()
		#
		# This index is used to introduce "nan's" for padding to match array size to the original array
		ap = np.hstack((ap, a))
		if(len(a)==0):
			continue
		ti = (gliderTimestamp[a] - gliderTimestamp[a[0]]).to_numpy()  # Changed this line
		loncDD = np.hstack((loncDD, (gliderLon[a].to_numpy() + ti * vlonDD[i])))
		latcDD = np.hstack((latcDD, (gliderLat[a].to_numpy() + ti * vlatDD[i])))
	#
	# Initialize the output arrays and fill them with the corrected values
	correctedLon = gliderLon * np.nan
	correctedLat = gliderLat * np.nan
	correctedLon.iloc[ap.astype(int)] = loncDD
	correctedLat.iloc[ap.astype(int)] = latcDD
	#
	return correctedLon, correctedLat


def ignoreBadLatLon(data):
    filtered_columns = data.filter(regex='lat')
    filtered_columns = filtered_columns.replace(0, np.nan)
    filtered_columns = filtered_columns.replace(90, np.nan)
    filtered_columns = filtered_columns.replace(-90, np.nan)
    data[filtered_columns.columns] = filtered_columns.replace(0, np.nan)
    #
    filtered_columns = data.filter(regex='lon')
    filtered_columns = filtered_columns.replace(0, np.nan)
    filtered_columns = filtered_columns.replace(180, np.nan)
    filtered_columns = filtered_columns.replace(-180, np.nan)
    data[filtered_columns.columns] = filtered_columns.replace(0, np.nan)
    #
    return data