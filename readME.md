X Use the attached list to filter dbd files and use all available data in the sbd, ebd and tbd files for merging.
X Create a profile and a time series file
X Do this seperately for the realtime (sbd/tbd) and delayed mode files (dbd/ebd)
X In terms of processing just present all the glider variables as are.
X The exception is to convert degrees decimal minutes variables (lon/lat, gps_lon/lat, wpt_lon/lat …) to decimal degrees
X Convert roll/pitch/heading/fin angle to degrees from radians
Calculate salinity from conductivity, temperature and pressure (sci_water_temp, sci_water_conductivity, sci_water_pressure).
Apply a correction to the value sci_oxy4_oxygen attached in the following file to compensate for salinity.

O2freshtosal.m
filter.txt

--------------------------------------------

for the metadata included in each file I attached a trajectory file and a profile file.

ru32_2017_172_3_0_sf_dbd.nc
crate_20200213T090614Z_dbd.nc

--------------------------------------------

For the naming convention we will replicate these files. For fields like the type of ctd installed and things like that we will need to have a small internal glider database to automatically assosciate the wmo id with the right glider.
