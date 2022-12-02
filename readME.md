# Slocum Glider Python Processing Toolbox

This is a minimal glider processing toolbox using the Python language, to go from Slocum glider raw data files to self describing `*.nc` files, that pass  [compliance checking](https://compliance.ioos.us/index.html "compliance checking") with the US Integrated Ocean Observing System (US-IOOS) Glider Data Aquisition Centre (GDAC). The `*.nc` files from this toolbox should pass requirements to be ingested into the Global Telecomunications System (GTS) for further use in models. We follow the US IOOS guidelines for file format and structure of glider data layed and provide an option for European Glider Observatory (EGO) format and ingestion into the Coriolis GDAC.

The intent of this toolbox is to produce a clean data set from raw glider data for sharing with data centres and for further careful scientific post-processing (expert processing), by preserving the original data resolution and associated metadata. This toolbox does not do enhanced checks for data Quality Control (QC).

This toolbox seperately supports both `realtime` (while glider is deployed) and `delayed` data mode (after glider is recovered). The user can tell the toolbox which mode to use. The processing levels in both modes are the same, but `delayed` mode will contain the complete dataset while `realtime` may not.

## Wish list and completed features:

- [x] Delayed mode: filter and convert `[*.d/e]bd` files into `[*.nc]` profiles and merge into a `[*.nc]` timeseries file
- [x] Realtime mode: convert `[*.s/t]bd` files into `[*.nc]` profiles and merge into a `[*.nc]` timeseries file
- [ ] Processing features:
	- [x] Preserve glider variables with original names under dimension [timestamp]
	- [x] Calculate salinity
	- [x] Apply salinity compensation to "sci_oxy4_oxygen" variable if salinity and oxygen are present in the data
	- [x] Convert NMEA positions to "dd.dd" format
	- [x] Convert variables from radians to degrees
	- [ ] Apply a correction for longitude/latitude dead reckoning
	- [ ] Calculate the profile number for easy splitting of glider dives into profiles from the timeseries plot
	- [ ] Identify the types of sensors present (optode, ctd) and store relevant sensor coefficients as variables in the profile and timeseries
- [ ] During processing read metadata from a prepared text file and understand whether to run `realtime` or `delayed` mode processing
- [ ] Use naming convention of IOOS or EGO decoder for certain required variable names (time, lon,lat,temperature, salinity, oxygen, optical channels ...)
- [ ] Provide an option to switch between IOOS and EGO format
- [ ] Apply QC flagging and checks for the EGO/Quartod format variables (spike test, flatline test, gradient test, etc ...) and set QC flags (=1, 2, 3, 4)
- [ ] Produce diagnostic plots:
	- [ ] From the timeseries file `realtime` or `delayed` mode, show science data sensors (CTD, oxygen, optics) and when data was collected as sensor plot
	- [ ] Produce a 2D colour plot for the science data as a function of profile number
 
## How it works

Modify and copy the attached example `*deployment_info*.txt` and `process_deployment*.sh` scripts for either realtime or delayed mode processing.
Be sure to update the metadata form in the `*.txt` file so that the toolbox uses the right information for metadata association.

Upload glider data to the glider_data directory, using the example format or change the paths to point to the glider data location.

## Sharing results

Once the toolbox runs or if it runs every day for realtime data, the user can set a shell script to ndownload new data (for example from SFMC) and upload the data to an FTP server or a GDAC.


## OLD INFOS

for the metadata included in each file I attached a trajectory file and a profile file.

- `ru32_2017_172_3_0_sf_dbd.nc`
- `crate_20200213T090614Z_dbd.nc`



For the naming convention we will replicate these files. For fields like the type of ctd installed and things like that we will need to have a small internal glider database to automatically assosciate the wmo id with the right glider.


## MAC USERS

This code uses Linux "date" function. Download the coreutils library  `brew install coreutils ; echo "alias date=gdate" >> ~/.bash_profile` 

					

					
