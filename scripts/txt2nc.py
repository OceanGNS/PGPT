import argparse
import os.path
import os
import csv
import glob
import numpy as np
import pandas as pd
import math
import multiprocessing
import sys


scriptsDir = os.path.dirname(os.path.realpath(__file__))
missionDir = os.path.abspath(os.path.join(os.getcwd(), os.pardir))
sys.path.insert(0, scriptsDir)

from gliderfuncs import p2depth, dm2d, deriveCTD, deriveO2, findProfiles, correctDeadReckoning
from data2attr import saveNetcdf
from quartod_qc import quartodQCchecks

# remove empty arrays and nanmean slice warnings
import warnings
warnings.simplefilter(action="ignore", category=pd.errors.PerformanceWarning)
warnings.simplefilter("ignore", category=RuntimeWarning)


def printF(*args, **kwargs):
    kwargs["flush"] = True
    return print(*args, **kwargs)


def readBDdata(filename, varFilter, ignore=False):
    """
    Reads *.bd data from a given file and filters the columns based on the provided filter.

    :param filename: str, path to the file containing .bd data
    :param varFilter: list, a list of column names to filter the data
    :param ignore: bool, if True, the variables in the filter will be ignored, else they will be used
    :return: pd.DataFrame, filtered data
    """
    try:
        data = pd.read_csv(filename, delimiter=' ',
                           skiprows=[*range(14), 15, 16])
        if varFilter is not None:
            if ignore:
                data = data.drop(columns=varFilter, errors='ignore')
            else:
                data = data.filter(varFilter, axis='columns')
        return data.rename(columns={'m_present_time': 'time', 'sci_m_present_time': 'time'})
    except Exception as e:
        # logging.error(f'Error reading {filename}: {str(e)}')
        return pd.DataFrame()  # Return an empty DataFrame in case of error


def readVarFilter(filterName):
    with open("%s/bin/%s" % (scriptsDir, filterName), 'r') as fid:
        return [row[0] for row in csv.reader(fid, delimiter=',')]


def processData(data, sourceInfo):
    # Transform certain columns applying a function to them like "rad2deg"
    def updateColumns(data, cols, func):
        data.update({col: func(data[col])
                    for col in cols if col in data.keys()})
    #
    def fillExactZeroWithNan(var):
        # Ensure the array is of a float dtype before assigning NaN
        # if np.issubdtype(var.dtype, np.integer):
        var = var.astype(float)
        var[np.isclose(var, 0, atol=1e-7)] = np.nan
        return var
    #
    def getColumnOrNan(df, columnName):
        if columnName in df.columns:
            return df[columnName]
        else:
            return np.full(len(df), np.nan)
    #
    # Get rid of "zero's" that are measurement or initialization artefacts from sensors.
    for col in data.columns:
        data[col] = fillExactZeroWithNan(data[col].values)
    #
    updateColumns(data, ['c_wpt_lat', 'c_wpt_lon',
                   'm_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], dm2d)
    updateColumns(data, ['c_fin', 'c_heading', 'c_pitch',
                   'm_fin', 'm_heading', 'm_pitch', 'm_roll'], np.degrees)
    #
    # Convert bar to dbar from glider pressure sensors (flight and science)
    columnsToUpdate = ['sci_water_pressure', 'm_pressure']
    for column in columnsToUpdate:
        if column in data:
            data[column] *= 10
    #
    # Basic clipping of data
    if np.all([k in data for k in ['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon']]):
        data.update({k: np.clip(data[k], *r) for k, r in zip(
            ['m_gps_lat', 'm_gps_lon', 'm_lat', 'm_lon'], [(-90, 90), (-180, 180)] * 2)})
    #
    if np.all([k in data for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure']]):
        data.update({k: np.clip(data[k], *r) for k, r in zip(['sci_water_cond',
                    'sci_water_temp', 'sci_water_pressure'], [(0, 7), (-1.9, 40), (-1.9, 1200)])})
    #
    if 'sci_oxy4_oxygen' in data:
        data['sci_oxy4_oxygen'] = np.clip(data['sci_oxy4_oxygen'], 0, 500)
    #
    if 'sci_water_pressure' in data:
        data['sci_water_depth'] = p2depth(
            data['sci_water_pressure'], time=data['time'], interpolate=True, tgap=5)
    #
    # Store and rename variables in the "data" pd.dataframe
    gliderData = data.copy()
    data = pd.DataFrame()
    #
    # Copy/duplicate certain names to the data frame from the gliderData frame but fill with nan if not existing
    nameList = {
        'time': 'time',
        'lat': 'm_gps_lat',
        'lon': 'm_gps_lon',
        'u': 'm_final_water_vx',
        'v': 'm_final_water_vy',
        'time_uv': 'time',
        'lat_uv': 'm_gps_lat',
        'lon_uv': 'm_gps_lon'
    }
    #
    for newCol, oldCol in nameList.items():
        data[newCol] = getColumnOrNan(gliderData, oldCol)
    #
    # derive CTD sensor data
    if (np.all([k in gliderData for k in ['sci_water_cond', 'sci_water_temp', 'sci_water_pressure', 'sci_water_depth']])):
        data['conductivity'], data['temperature'], data['depth'], data['pressure'] = gliderData[
            'sci_water_cond'], gliderData['sci_water_temp'], gliderData['sci_water_depth'], gliderData['sci_water_pressure']
        data['salinity'], data['absolute_salinity'], data['conservative_temperature'], data['density'] = deriveCTD(
            data['conductivity'], data['temperature'], data['pressure'], data['lon'], data['lat'])
    else:
        return
    #
    ##  FOR GDAC 3.0
    data['lat_qc'] = data['lat']*0
    data['lon_qc'] = data['lon']*0
    data['depth_qc'] = data['depth']*0
    #
    # derive oxygen sensor data
    if np.all([k in gliderData.keys() for k in ['sci_oxy4_oxygen', 'sci_water_temp', 'sci_water_pressure']]):
        data['oxygen_concentration'] = deriveO2(
            gliderData['sci_oxy4_oxygen'], gliderData['sci_water_temp'], data['salinity'], time=data['time'], interpolate=True, tgap=20)
    #
    if 'sci_oxy4_temp' in gliderData:
        data['oxygen_sensor_temperature'] = gliderData['sci_oxy4_temp']
    #
    # optical sensors (if present)
    chlorophyllList = ['sci_flbbrh_chlor_units', 'sci_flbbcd_chlor_units',
                        'sci_flbb_chlor_units', 'sci_flntu_chlor_units']
    for k in chlorophyllList:
        if k in gliderData:
            data['chlorophyll_a'] = gliderData[k]
            break
    #
    cdomList = ['sci_fl3slo_cdom_unit', 'sci_fl3sloV2_cdom_units',
                 'sci_flbbcd_cdom_units', 'sci_fl2PeCdom_cdom_units']
    for k in cdomList:
        if k in gliderData:
            data['cdom'] = gliderData[k]
            break
    #
    # Quartod qc checks and with nans anywhere where the data is questionable for a rough qc
    qcList = ['temperature', 'salinity',
               'pressure', 'conductivity', 'density']
    for k in qcList:
        if k in data:
            QCvariable = k + '_qc'
            data[QCvariable] = quartodQCchecks(
                data[k].values, data['time'].values, k)
    #
    # Create profile id, profile_time, profile_lon and profile_lat variable
    data = data.assign(profile_time=np.nan, profile_lat=np.nan,
                       profile_lon=np.nan, profile_id=np.nan)
    prof_idx, prof_dir = findProfiles(
        data['time'], data['depth'], stall=20, shake=200)
    uidx = np.unique(prof_idx)
    for k in uidx:
        if k == math.floor(k):
            idx = prof_idx == k
            idx = prof_idx == k
            data.loc[idx, 'profile_time'] = data.loc[idx, 'time'].mean()
            data.loc[idx, 'profile_lat'] = data.loc[idx, 'lat'].mean()
            data.loc[idx, 'profile_lon'] = data.loc[idx, 'lon'].mean()
            data.loc[idx, 'profile_id'] = prof_idx[idx] + \
                sourceInfo['fileNumber']
    #
    # convert & save glider *.bd files to *.nc files
    name, ext = os.path.splitext(sourceInfo['filename'])
    filename, bd_ext = os.path.splitext(name)
    sourceInfo['filename'] = "%s_%s.nc" % (
        filename, sourceInfo['processingMode'])
    #
    saveNetcdf(data, gliderData, sourceInfo)
    return data, gliderData


def main(sourceInfo):
    # Validate command-line arguments
    fileTypes = ['dbd', 'sbd', 'tbd', 'ebd']
    filename = sourceInfo['filename']
    name, ext = os.path.splitext(filename)
    name, ebd_ext = os.path.splitext(name)
    filename = name
    #
    fileExists = any(os.path.isfile(
        f'{filename}.{file_type}.txt') for file_type in fileTypes)
    if not fileExists:
        raise FileNotFoundError(
            f'No matching file found for {filename} with extensions .dbd.txt, .sbd.txt, .tbd.txt, or .ebd.txt')
    #
    if sourceInfo['processingMode'] == 'delayed':
        flightVarFilter = readVarFilter('dbd_filter.csv')
        scienceVarFilter = readVarFilter('ebd_filter.csv')
        flightData = readBDdata(f'{filename}.dbd.txt', flightVarFilter)
        scienceData = readBDdata(
            f'{filename}.ebd.txt', scienceVarFilter, ignore=True)
    elif sourceInfo['processingMode'] == 'realtime':
        flightData = readBDdata(f'{filename}.sbd.txt', None)
        scienceData = readBDdata(f'{filename}.tbd.txt', None)
    else:
        raise ValueError(
            "Invalid processing mode. Supported modes are 'delayed_mode' and 'realtime'.")
    #
    # Merge records and sort by time
    data = pd.concat([df for df in [flightData, scienceData]],
                     ignore_index=True, sort=True).sort_values(by=['time'])
    if (data.empty):
        return
    #
    # Check if the time values are monotonically increasing
    timeDiff = np.diff(data['time'].values)
    if not np.all(timeDiff > 0):
        print("Warning: Time values are not monotonically increasing. Correcting the time values.")
        # Correct the time values to make them monotonically increasing
        correction = np.where(timeDiff <= 0, -timeDiff + 1.005828380584717e-05, 0)
        correctedTime = data['time'].values.copy()
        correctedTime[1:] += np.cumsum(correction)
        data['time'] = correctedTime
    #
    # Process and save data as netCDF
    return processData(data, sourceInfo)


#######################################################################


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--glider', help='glider name')
    parser.add_argument('--mode', help='Processing mode (realtime | delayed)')
    parser.add_argument('--metadataFile', help='Metadata file path')
    args = parser.parse_args()

    glider = args.glider
    processingMode = args.mode
    metadataFile = args.metadataFile

    encoderFile = "%s/attributes/glider_dac_3.0_conventions.yml" % scriptsDir

    files = sorted(glob.glob(f'{glider}*.[dt]bd.txt'))
    fileNumber = 1
    sourceInfos = []
    for f in files:
        ncFilename = "nc/%s.nc" % os.path.splitext(f)[0]
        if not os.path.exists(ncFilename):
            sourceInfos.append({
                'encoder': encoderFile,
                'dataType': 'profile',
                'metadataFile': "%s/%s" % (missionDir, metadataFile),
                'processingMode': processingMode,
                'dataSource': f,
                'filename': f,
                'missionDir': missionDir,
                'fileNumber': fileNumber
            })
        #
        fileNumber += 1
    #
    with multiprocessing.Pool(1) as p:
        all = p.map(main, sourceInfos)
    #
    # TRAJECTORY
    allData = pd.concat([df[0] for df in all if df != None],
                        ignore_index=True, sort=True).sort_values(by=['time']).reset_index()
    allGliderData = pd.concat([df[1] for df in all if df != None],
                              ignore_index=True, sort=True).sort_values(by=['time']).reset_index()
    #
    if 'x_dr_state' in allGliderData.keys() and np.all([key in allGliderData.keys() for key in ['m_gps_lon', 'm_gps_lat', 'm_lat', 'm_lon']]):
        allData['lon_qc'], allData['lat_qc'] = correctDeadReckoning(
            allGliderData['m_lon'], allGliderData['m_lat'], allGliderData['time'], allGliderData['x_dr_state'], allGliderData['m_gps_lon'], allGliderData['m_gps_lat'])
    else:
        allData['lon_qc'], allData['lat_qc'] = allGliderData['m_lon'], allGliderData['m_lat']
    #
    if 'depth' in allData.keys():
        allData['profile_index'], allData['profile_direction'] = findProfiles(
            allData['time'], allData['depth'], stall=20, shake=200)
        allData['depth_qc'] = allData['depth']
    #
    sourceInfo = {
        'metadataFile': "%s/%s" % (missionDir, metadataFile),
        'encoder': encoderFile,
        'processingMode': processingMode,
        'dataType': 'trajectory',
        'dataSource': '',
        'filename': "%s_%s_trajectory.nc" % (glider, processingMode),
        'missionDir': missionDir
    }
    saveNetcdf(allData, allGliderData, sourceInfo)
