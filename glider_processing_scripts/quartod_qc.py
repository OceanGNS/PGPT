import numpy as np
import pandas as pd

def get_qc_options(variable_name):
	if variable_name == 'oxygen_concentration':
		qc_options = {
			'sensor_min': 0.1,
			'sensor_max': 500,
			'sensor_user_min': 0.1,
			'sensor_user_max': 450,
			'spike_thrshld_low': 4,
			'spike_thrshld_high': 8,
			'n_dev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
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
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 1e-6,
			'rep_cnt_fail': 5,
			'rep_cnt_suspect': 3
		}
	elif variable_name == 'temperature':
		qc_options = {
			'sensor_min': -2,
			'sensor_max': 40,
			'sensor_user_min': -1.89,
			'sensor_user_max': 30,
			'spike_thrshld_low': 0.5,
			'spike_thrshld_high': 1.5,
			'n_dev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
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
			'spike_thrshld_low': 4,
			'spike_thrshld_high': 8,
			'n_dev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 0.001,
			'rep_cnt_fail': 5,
			'rep_cnt_suspect': 3
		}
	else:
		raise ValueError(f"Unknown variable_name '{variable_name}'")
		
	return qc_options

def range_check_test(var, qc_flag, sensor_min=-2, sensor_max=1200, user_min=-2, user_max=1200):
	for i, value in enumerate(var):
		if np.isnan(value):
			continue
		if value < sensor_min or value > sensor_max:
			qc_flag[i] = 4
		elif value < user_min or value > user_max:
			qc_flag[i] = 3
	return qc_flag

def spike_test(var, qc_flag, thrshld_low=4, thrshld_high=8):
	var = np.asarray(var)
	non_nan_indices = np.where(~np.isnan(var))[0]

	for i in non_nan_indices[1:-1]:
		if np.isnan(var[i]):
			continue
		spk_ref = (var[i - 1] + var[i + 1]) / 2
		spike = np.abs(var[i] - spk_ref)
		if thrshld_low < spike <= thrshld_high:
			qc_flag[i] = 3
		elif spike > thrshld_high:
			qc_flag[i] = 4
	return qc_flag


def rate_of_change_test(var, time, qc_flag, n_dev=3, tim_dev=25, min_window_size=3):
	if not isinstance(time[0], np.datetime64):
		time = np.array(time, dtype='datetime64[ns]')

	recent_data = []
	for i in range(1, len(var)):
		if np.isnan(var[i]) or np.isnan(var[i - 1]):
			continue
		
		time_diff = (time[i] - time[i - 1]).astype('timedelta64[s]').astype(float) / 3600
		if time_diff <= 0:
			continue
		
		rate_of_change = np.abs(var[i] - var[i - 1]) / (time_diff + 1e-8)
		recent_data = [(t, v) for t, v in recent_data if (time[i] - t).astype('timedelta64[h]').astype(float) < tim_dev]
		recent_data.append((time[i - 1], var[i - 1]))

		if len(recent_data) < min_window_size:
			continue

		values = [v for t, v in recent_data]
		rates_of_change = np.diff(values) / np.diff([t.astype(float) for t, _ in recent_data])  # Calculate rates of change
		mean_rate = np.mean(rates_of_change)
		sd = np.std(rates_of_change, ddof=1)
		threshold = mean_rate + n_dev * sd

		if rate_of_change > threshold:
			qc_flag[i] = 3

	return qc_flag


def flat_line_test(var, qc_flag, eps=1e-6, rep_cnt_fail=5, rep_cnt_suspect=3):
	repeat_count = 0

	for i in range(1, len(var)):
		if np.isnan(var[i]) or np.isnan(var[i - 1]):
			repeat_count = 0
			continue
		if abs(var[i] - var[i - 1]) < eps:
			repeat_count += 1
		else:
			repeat_count = 0

		if not np.isclose(var[i], 0, atol=1e-8):
			if repeat_count >= rep_cnt_fail - 1:
				qc_flag[i] = 4
			elif repeat_count >= rep_cnt_suspect - 1:
				qc_flag[i] = 3
	return qc_flag


def quartod_qc_checks(var, time, variable_name, qc_options=None):
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
	:param qc_options: dictionary, optional, custom options for the tests
	:return: array-like, the flags for each data point (1: Pass, 2: Not tested, 3: Suspect, 4: Fail, 9: Missing Data)
	"""

	# create qc flag variable from var
	# set initially the flag to "one" which is "pass"
	var = np.asarray(var)
	qc_flag = np.ones_like(var, dtype=int)

	# Set missing data flag to 9 or data points that are exactly zero
	qc_flag[np.isnan(var) | np.isclose(var, 0, atol=1e-8)] = 9

	# for different variables (e.g. salinity) there are different thresholds for the tests
	if qc_options is None:
		qc_options = get_qc_options(variable_name)

	# test 1 - range check
	qc_flag = range_check_test(var, qc_flag, qc_options['sensor_min'], qc_options['sensor_max'], qc_options['sensor_user_min'], qc_options['sensor_user_max'])
	print('done: test 1 - range check test for variable '+variable_name)

	# test 2 - spike test
	qc_flag = spike_test(var, qc_flag, qc_options['spike_thrshld_low'], qc_options['spike_thrshld_high'])
	print('done: test 2 - spike test for variable '+variable_name)

	# test 3 - rate of change test
	qc_flag = rate_of_change_test(var, time, qc_flag, qc_options['n_dev'], qc_options['time_dev'],qc_options['min_wind_size'])
	print('done: test 3 - rate of change test for variable '+variable_name)

	# test 4 - flat line test
	qc_flag = flat_line_test(var, qc_flag, qc_options['eps'], qc_options['rep_cnt_fail'], qc_options['rep_cnt_suspect'])
	print('done: test 4 - flat line test for variable '+variable_name)

	return qc_flag