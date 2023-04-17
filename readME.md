# Slocum Glider Python Processing Toolbox

This is a minimal glider processing toolbox using the Python language, to go from Slocum glider raw data files to self describing `*.nc` files, that pass  [compliance checking](https://compliance.ioos.us/index.html "compliance checking") with the US Integrated Ocean Observing System (US-IOOS) Glider Data Aquisition Centre (GDAC). The `*.nc` files from this toolbox should pass requirements to be ingested into the Global Telecomunications System (GTS) for further use in models. We follow the US IOOS guidelines for file format and structure of glider data.

The intent of this toolbox is to produce a clean data set from raw glider data for sharing with data centres and for further careful scientific post-processing (expert processing), by preserving the original data resolution and associated metadata. This toolbox does not do enhanced checks for data Quality Control (QC).

This toolbox seperately supports both `realtime` (while glider is deployed) and `delayed` data mode (after glider is recovered). The user can tell the toolbox which mode to use. The processing levels in both modes are the same, but `delayed` mode will contain the complete dataset while `realtime` may not.

## ISSUES
- some metadata fields not properly updated or calculated in profile/trajectory file
- some compliance issues remain when checking the compliance report
- in some parts the code is clunky. Some parts can be streamlined and made general to make it easier to solve issues in the future.

## Features

- [x] Delayed mode: filter and convert `[*.d/e]bd` files into `[*.nc]` profiles and merge into a `[*.nc]` timeseries file
- [x] Realtime mode: convert `[*.s/t]bd` files into `[*.nc]` profiles and merge into a `[*.nc]` timeseries file
- [x] Processing features:
	- [x] Preserve glider variables with original names under dimension [timestamp]
	- [x] Calculate salinity
	- [x] Apply salinity compensation to "sci_oxy4_oxygen" variable if salinity and oxygen are present in the data
	- [x] Convert NMEA positions to "dd.dd" format
	- [x] Convert variables from radians to degrees
	- [x] Apply a correction for longitude/latitude dead reckoning
	- [x] Calculate the profile number for easy splitting of glider dives into profiles from the timeseries plot
- [x] During processing add metadata information from a prepared text file to provide complete record of glider data following US IOOS standards
- [x] Use naming convention of IOOS  decoder for certain required variable names (time, lon,lat,temperature, salinity, oxygen, optical channels ...) to discover data files in GTS and ERDAP
 
## How it works

Modify and copy the attached data example `*deployment_info*.yml` and `process_deployment*.sh` scripts for either realtime or delayed mode processing.
Be sure to update the metadata form in the `*.yml` file so that the toolbox uses the right information for metadata association.

Upload glider data to the glider_data directory, using the example format or change the paths to point to the glider data location.

## Sharing results

Once the toolbox runs or if it runs every day for realtime data, the user can set a shell script to download new data (for example from SFMC) and upload the data to an FTP server or a GDAC.


## MAC USERS

This code uses Linux "date" function. Download the coreutils library  `brew install coreutils ; echo "alias date=gdate" >> ~/.bash_profile`

					

					
