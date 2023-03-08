import numpy as np
import pandas as pd
from datetime import datetime
import math
import yaml


def attr(fileName, nc, GLIDERS_DB, ATTRS, processingMode):
    ##  READ GLIDERS DATABASE
    gliders = pd.read_csv(GLIDERS_DB)
    ##  READ ATTRIBUTES
    with open(ATTRS, 'r') as f:
        attrs = yaml.safe_load(f)

    now = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')

    #####################  AUTO CALCULATE  #####################
    ##  FROM NC FILE
    gliderName = fileName.split('-')[0]  ##  eg sunfish (all small letters)
    dataType = 'profile'
    lonMin = np.nanmin(nc.variables['m_lon'][:])
    lonMax = np.nanmax(nc.variables['m_lon'][:])
    latMin = np.nanmin(nc.variables['m_lat'][:])
    latMax = np.nanmax(nc.variables['m_lat'][:])
    depthMin = np.nanmin(nc.variables['sci_water_depth'][:])
    depthMax = np.nanmax(nc.variables['sci_water_depth'][:])
    startTime = datetime.fromtimestamp(float(nc.variables['timestamp'][:][0]))
    endTime = datetime.fromtimestamp(float(nc.variables['timestamp'][:][-1]))
    # DURATION
    durationDays = math.floor((endTime-startTime).seconds / (24*3600))
    durationHours = math.floor(((endTime-startTime).seconds - 24*3600*durationDays)/3600)
    durationMinutes = math.floor(((endTime-startTime).seconds - 24*3600*durationDays - 3600*durationHours)/60)
    durationSeconds = (endTime-startTime).seconds - 24*3600*durationDays - 3600*durationHours - 60*durationMinutes
    duration = "PT"
    if(durationDays>0):
        duration += "%dD" % durationDays
    if(durationHours>0):
        duration += "%dH" % durationHours
    if(durationMinutes>0):
        duration += "%dM" % durationMinutes
    duration += "%dS" % durationSeconds
    ##  FROM PREVIOUS DEPLOYMENTS
    deploymentID = 33 # SHOULD CALCULATED AUTOMATICALLY
    ##  FROM DATABASE
    glider = gliders.loc[gliders['glider_name'] == gliderName]
    gliderSerialID = glider['glider_serial'].to_numpy()[0]
    platformType = glider['glider_type'].to_numpy()[0]
    WMOid = glider['WMO'].to_numpy()[0]

    

    #####################  ADD ATTRIBUTES  #####################
    ##  USER INPUT
    for key1 in attrs.keys():
        for key2 in attrs[key1]:
            nc.attrs[key2] = attrs[key1][key2]
    ##  CALCULATED
    deploymentDateTime = attrs['general']['deploymentDateTime']  ##  SHOULD BE CALCULATED AUTOMATICALLY
    nc.attrs['processingMode'] = processingMode
    nc.attrs['deployment_name'] = '%s-%s' % (gliderName, deploymentDateTime)
    nc.attrs['deployment_id'] = deploymentID
    nc.attrs['instrument_id'] = gliderName
    nc.attrs['glider_serial_id'] = gliderSerialID
    nc.attrs['platform_type'] = platformType
    nc.attrs['wmo_id'] = WMOid
    nc.attrs['wmo_platform_code'] = WMOid
    nc.attrs['cdm_data_type'] = dataType
    nc.attrs['geospatial_lat_min'] = latMin
    nc.attrs['geospatial_lat_max'] = latMax
    nc.attrs['geospatial_lon_min'] = lonMin
    nc.attrs['geospatial_lon_max'] = lonMax
    nc.attrs['geospatial_vertical_min'] = depthMin
    nc.attrs['geospatial_vertical_max'] = depthMax
    nc.attrs['time_coverage_start'] = startTime.strftime('%Y-%m-%dT%H:%M:%SZ')
    nc.attrs['time_coverage_end'] = endTime.strftime('%Y-%m-%dT%H:%M:%SZ')
    nc.attrs['id'] = '%s-%s' % (gliderName, deploymentDateTime)
    nc.attrs['title'] = "Slocum Glider data from glider %s" % deploymentID
    nc.attrs['source'] = "Observational Slocum glider data from source dba file XXX-YYYY-XXX-X-X-dbd(XXXXXXX)"
    nc.attrs['time_coverage_duration'] = duration
    nc.attrs['date_created'] = now
