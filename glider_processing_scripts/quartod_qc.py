import numpy as np

def get_qc_options(variable_name):
	if variable_name == 'oxygen':
		qc_options = {
			'sensor_min': 0,
			'sensor_max': 500,
			'sensor_user_min': 50,
			'sensor_user_max': 500,
			'spike_thrshld_low': 4,
			'spike_thrshld_high': 8,
			'n_dev': 3,
			'time_dev': 25,
			'eps': 1e-6,
			'rep_cnt_fail': 5,
			'rep_cnt_suspect': 3
		}
	elif variable_name == 'salinity':
		qc_options = {
			'sensor_min': 2,
			'sensor_max': 40,
			'sensor_user_min': 10,
			'sensor_user_max': 37,
			'spike_thrshld_low': 0.3,
			'spike_thrshld_high': 0.9,
			'n_dev': 3,
			'time_dev': 25,
			'eps': 0.005,
			'rep_cnt_fail': 5,
			'rep_cnt_suspect': 3
		}
	elif variable_name == 'temperature':
		qc_options = {
			'sensor_min': -2,
			'sensor_max': 40,
			'sensor_user_min': -2,
			'sensor_user_max': 30,
			'spike_thrshld_low': 3,
			'spike_thrshld_high': 8,
			'n_dev': 3,
			'time_dev': 25,
			'eps': 0.05,
			'rep_cnt_fail': 5,
			'rep_cnt_suspect': 3
		}
	elif variable_name == 'pressure':
		qc_options = {
			'sensor_min': -2,
			'sensor_max': 1200,
			'sensor_user_min': -2,
			'sensor_user_max': 1200,
			'spike_thrshld_low': 3,
			'spike_thrshld_high': 8,
			'n_dev': 3,
			'time_dev': 25,
			'eps': 0.05,
			'rep_cnt_fail': 5,
			'rep_cnt_suspect': 3
		}
	else:
		raise ValueError(f"Unknown variable_name '{variable_name}'")
		
	return qc_options

def range_check_test(var, qc_flag, sensor_min=0, sensor_max=500, user_min=0, user_max=500):
	"""
	Perform a Range Check Test on the given data array.

	:param var: array-like, the data to test for range
	:param sensor_min: float, the minimum sensor value
	:param sensor_max: float, the maximum sensor value
	:param user_min: float, the user-selected minimum value
	:param user_max: float, the user-selected maximum value
	:return: array-like, the flags for each data point (1: Pass, 3: Suspect, 4: Fail)
	"""

	for i, value in enumerate(var):
		if value < sensor_min or value > sensor_max:
			qc_flag[i] = 4
		elif value < user_min or value > user_max:
			qc_flag[i] = 3

	return qc_flag


def spike_test(var, qc_flag, thrshld_low=4, thrshld_high=8):
	"""
	Perform a Spike Test on the given data array.

	:param var: array-like, the data to test for spikes
	:param thrshld_low: float, the low spike threshold
	:param thrshld_high: float, the high spike threshold
	:return: array-like, the flags for each data point (1: Pass, 3: Suspect, 4: Fail)
	"""
	# Calculate the spike reference values
	spk_ref = (var[:-2] + var[2:]) / 2

	# Calculate the spike magnitudes
	spike = np.abs(var[1:-1] - spk_ref)

	# Identify where spikes exceed the low and high thresholds
	suspect_spikes = (thrshld_low < spike) & (spike <= thrshld_high)
	fail_spikes = spike > thrshld_high

	# Update the qc_flag array
	qc_flag[1:-1][suspect_spikes] = 3
	qc_flag[1:-1][fail_spikes] = 4

	return qc_flag

def rate_of_change_test(var, time, qc_flag, n_dev=3, tim_dev=25):
	"""
	Perform a Rate of Change Test on the given data array.

	:param var: array-like, the data to test for rate of change
	:param time: array-like, the time array corresponding to the data
	:param n_dev: int, the number of standard deviations for the threshold
	:param tim_dev: int, the period in hours over which the standard deviations are calculated
	:return: array-like, the flags for each data point (1: Pass, 3: Suspect)
	"""

	# Ensure the time array is a NumPy datetime64 object
	if not isinstance(time[0], np.datetime64):
		time = np.array(time, dtype='datetime64[ns]')

	# Compute the time differences
	time_diff = np.ediff1d(time).astype('timedelta64[s]').astype(float) / 3600
	valid_diff = time_diff > 0

	# Compute the rate of change
	rate_of_change = np.abs(np.diff(var)) / time_diff
	rate_of_change[~valid_diff] = 0

	# Compute the standard deviations and thresholds using a rolling window
	var_series = pd.Series(var)
	rolling_std = var_series.rolling(window=tim_dev).std(ddof=1)
	threshold = n_dev * rolling_std

	# Find where the rate of change exceeds the threshold
	exceed_threshold = rate_of_change > threshold[1:].to_numpy()

	# Update the qc_flag array
	qc_flag[1:][exceed_threshold] = 3

	return qc_flag


def flat_line_test(var, qc_flag, eps=1e-6, rep_cnt_fail=5, rep_cnt_suspect=3):
	"""
	Perform a Flat Line Test on the given data array.

	:param var: array-like, the data to test for flat line
	:param eps: float, the tolerance value to compare the data values
	:param rep_cnt_fail: int, number of repeated observations for a fail flag
	:param rep_cnt_suspect: int, number of repeated observations for a suspect flag
	:return: array-like, the flags for each data point (1: Pass, 3: Suspect, 4: Fail)
	"""
	# Compute the differences between adjacent elements and compare with eps
	abs_diff = np.abs(np.diff(var)) < eps

	# Identify runs of repeated values and compute their lengths
	runs = np.split(abs_diff, np.where(~abs_diff)[0] + 1)
	run_lengths = np.array([len(run) for run in runs if run[0]])

	# Identify the starting indices of suspect and fail runs
	suspect_start_indices = np.where(~abs_diff)[0][np.cumsum(run_lengths)[:-1]] - run_lengths + rep_cnt_suspect - 1
	fail_start_indices = np.where(~abs_diff)[0][np.cumsum(run_lengths)[:-1]] - run_lengths + rep_cnt_fail - 1

	# Update the qc_flag array
	qc_flag[suspect_start_indices] = 3
	qc_flag[fail_start_indices] = 4

	return qc_flag

	
def quartod_qc_checks(var, time, variable_name):
	"""
	Performs Quality Control Checks on data following US QUARTOD Protocol and Standards
	The function performs the following tests:
	1. Gross Range Test
	2. Spike Test
	3. Rate of Change Test
	4. Flat Line Test

	:param var: array-like, the data to test
	:param time: array-like, the time associated with the data
	:param variable_name: string, the name of the variable being tested
	:return: array-like, the flags for each data point (1: Pass, 2: Not tested, 3: Suspect, 4: Fail, 9: Missing Data)
	"""

	# create qc flag variable from var
	# set initially the flag to "one" which is "pass"
	var = np.asarray(var)
	qc_flag = np.ones_like(var, dtype=int)

	# Set missing data flag to 9
	qc_flag[np.isnan(var)] = 9

	# for different variables (e.g. salinity) there are different thresholds for the tests
	qc_options = get_qc_options(variable_name)

	# test 1 - range check
	qc_flag = range_check_test(var, qc_flag, qc_options['sensor_min'], qc_options['sensor_max'], qc_options['sensor_user_min'], qc_options['sensor_user_max'])
	print('done: test 1 - range check test for variable '+variable_name)

	# test 2 - spike test
	qc_flag = spike_test(var, qc_flag, qc_options['spike_thrshld_low'], qc_options['spike_thrshld_high'])
	print('done: test 2 - spike test for variable '+variable_name)

	# test 3 - rate of change test
	qc_flag = rate_of_change_test(var, time, qc_flag, qc_options['n_dev'], qc_options['time_dev'])
	print('done: test 3 - rate of change test for variable '+variable_name)

	# test 4 - flat line test
	qc_flag = flat_line_test(var, qc_flag, qc_options['eps'], qc_options['rep_cnt_fail'], qc_options['rep_cnt_suspect'])
	print('done: test 4 - flat line test for variable '+variable_name)

	return qc_flag