import numpy as np
# import pandas as pd

def getQCoptions(variableName):
	if variableName == 'oxygen_concentration':
		QCoptions = {
			'sensorMin': 0.1,
			'sensorMax': 500,
			'sensor_userMin': 0.1,
			'sensor_userMax': 450,
			'spike_thrshldLow': 4,
			'spike_thrshldHigh': 8,
			'nDev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 1e-6,
			'repCntFail': 5,
			'repCntSuspect': 3
		}
	elif variableName == 'salinity':
		QCoptions = {
			'sensorMin': 2,
			'sensorMax': 40,
			'sensor_userMin': 10,
			'sensor_userMax': 37,
			'spike_thrshldLow': 0.3,
			'spike_thrshldHigh': 0.9,
			'nDev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 1e-6,
			'repCntFail': 5,
			'repCntSuspect': 3
		}
	elif variableName == 'conductivity':
		QCoptions = {
			'sensorMin': 0,
			'sensorMax': 10,
			'sensor_userMin': 0.01,
			'sensor_userMax': 6,
			'spike_thrshldLow': 0.3,
			'spike_thrshldHigh': 0.9,
			'nDev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 1e-6,
			'repCntFail': 5,
			'repCntSuspect': 3
		}
	elif variableName == 'density':
		QCoptions = {
			'sensorMin': 999,
			'sensorMax': 1040,
			'sensor_userMin': 1015,
			'sensor_userMax': 1035,
			'spike_thrshldLow': 0.3,
			'spike_thrshldHigh': 0.9,
			'nDev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 1e-6,
			'repCntFail': 5,
			'repCntSuspect': 3
		}
	elif variableName == 'temperature':
		QCoptions = {
			'sensorMin': -2,
			'sensorMax': 40,
			'sensor_userMin': -1.89,
			'sensor_userMax': 30,
			'spike_thrshldLow': 0.5,
			'spike_thrshldHigh': 1.5,
			'nDev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 0.05,
			'repCntFail': 5,
			'repCntSuspect': 3
		}
	elif variableName == 'pressure':
		QCoptions = {
			'sensorMin': -2,
			'sensorMax': 1200,
			'sensor_userMin': -2,
			'sensor_userMax': 1200,
			'spike_thrshldLow': 4,
			'spike_thrshldHigh': 8,
			'nDev': 3,
			'time_dev': 300/3600,
			'min_wind_size': 10,
			'eps': 0.001,
			'repCntFail': 5,
			'repCntSuspect': 3
		}
	else:
		raise ValueError(f"Unknown variableName '{variableName}'")
		
	return QCoptions

def rangeCheckTest(var, QCflag, sensorMin=-2, sensorMax=1200, userMin=-2, userMax=1200):
	for i, value in enumerate(var):
		if np.isnan(value):
			continue
		if value < sensorMin or value > sensorMax:
			QCflag[i] = 4
		elif value < userMin or value > userMax:
			QCflag[i] = 3
	return QCflag

def spikeTest(var, QCflag, thrshldLow=4, thrshldHigh=8):
	var = np.asarray(var)
	nonNANindices = np.where(~np.isnan(var))[0]

	for i in nonNANindices[1:-1]:
		if np.isnan(var[i]):
			continue
		spkRef = (var[i - 1] + var[i + 1]) / 2
		spike = np.abs(var[i] - spkRef)
		if thrshldLow < spike <= thrshldHigh:
			QCflag[i] = 3
		elif spike > thrshldHigh:
			QCflag[i] = 4
	return QCflag


def rateOfChangeTest(var, time, QCflag, nDev=3, timDev=25, minWindowSize=3):
	if not isinstance(time[0], np.datetime64):
		time = np.array(time, dtype='datetime64[ns]')

	recentData = []
	for i in range(1, len(var)):
		if np.isnan(var[i]) or np.isnan(var[i - 1]):
			continue
		
		timeDiff = (time[i] - time[i - 1]).astype('timedelta64[s]').astype(float) / 3600
		if timeDiff <= 0:
			continue
		
		rateOfChange = np.abs(var[i] - var[i - 1]) / (timeDiff + 1e-8)
		recentData = [(t, v) for t, v in recentData if (time[i] - t).astype('timedelta64[h]').astype(float) < timDev]
		recentData.append((time[i - 1], var[i - 1]))

		if len(recentData) < minWindowSize:
			continue

		values = [v for t, v in recentData]
		ratesOfChange = np.diff(values) / np.diff([t.astype(float) for t, _ in recentData])  # Calculate rates of change
		meanRate = np.mean(ratesOfChange)
		sd = np.std(ratesOfChange, ddof=1)
		threshold = meanRate + nDev * sd

		if rateOfChange > threshold:
			QCflag[i] = 3

	return QCflag


def flatLineTest(var, QCflag, eps=1e-6, repCntFail=5, repCntSuspect=3):
	repeatCount = 0

	for i in range(1, len(var)):
		if np.isnan(var[i]) or np.isnan(var[i - 1]):
			repeatCount = 0
			continue
		if abs(var[i] - var[i - 1]) < eps:
			repeatCount += 1
		else:
			repeatCount = 0

		if not np.isclose(var[i], 0, atol=1e-8):
			if repeatCount >= repCntFail - 1:
				QCflag[i] = 4
			elif repeatCount >= repCntSuspect - 1:
				QCflag[i] = 3
	return QCflag


def quartodQCchecks(var, time, variableName, QCoptions=None):
	"""
	Performs Quality Control Checks on data following US QUARTOD Protocol and Standards
	The function performs the following tests:
	1. Gross Range Test
	2. Spike Test
	3. Rate of Change Test
	4. Flat Line Test

	:param var: array-like, the data to test
	:param time: array-like, the time associated with the data
	:param variableName: string, the name of the variable being tested
	:param QCoptions: dictionary, optional, custom options for the tests
	:return: array-like, the flags for each data point (1: Pass, 2: Not tested, 3: Suspect, 4: Fail, 9: Missing Data)
	"""

	# create qc flag variable from var
	# set initially the flag to "one" which is "pass"
	var = np.asarray(var)
	QCflag = np.ones_like(var, dtype=int)

	# Set missing data flag to 9 or data points that are exactly zero
	QCflag[np.isnan(var) | np.isclose(var, 0, atol=1e-8)] = 9

	# for different variables (e.g. salinity) there are different thresholds for the tests
	if QCoptions is None:
		QCoptions = getQCoptions(variableName)

	# test 1 - range check
	QCflag = rangeCheckTest(var, QCflag, QCoptions['sensorMin'], QCoptions['sensorMax'], QCoptions['sensor_userMin'], QCoptions['sensor_userMax'])
	#print('done: test 1 - range check test for variable '+variableName)

	# test 2 - spike test
	QCflag = spikeTest(var, QCflag, QCoptions['spike_thrshldLow'], QCoptions['spike_thrshldHigh'])
	#print('done: test 2 - spike test for variable '+variableName)

	# test 3 - rate of change test
	QCflag = rateOfChangeTest(var, time, QCflag, QCoptions['nDev'], QCoptions['time_dev'],QCoptions['min_wind_size'])
	#print('done: test 3 - rate of change test for variable '+variableName)

	# test 4 - flat line test
	QCflag = flatLineTest(var, QCflag, QCoptions['eps'], QCoptions['repCntFail'], QCoptions['repCntSuspect'])
	#print('done: test 4 - flat line test for variable '+variableName)

	return QCflag