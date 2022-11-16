% ------------------------------------------------------------------------------
% Add the real time QCs to NetCDF EGO file.
%
% SYNTAX :
%  [o_testDoneListAll, o_testFailedListAll] = gl_add_rtqc_to_ego_file(a_ncEgoFilePathName)
%
% INPUT PARAMETERS :
%   a_ncEgoFilePathName : input EGO file path name
%
% OUTPUT PARAMETERS :
%   o_testDoneListAll   : test performed report variable
%   o_testFailedListAll : test failed report variable
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - V 1.0: creation
%   08/31/2018 - RNU - V 1.1: updated for EGO 1.3 format:
%                             - list of parameter retrieved from PARAMETER
%                             variable (instead of SENSOR)
%                             - do not consider JULD (removed from EGO 1.3
%                             format)
%   01/02/2020 - RNU - V 1.2: input parameters (tests to perform) are set in the
%                             configuration file of the EGO decoder
%   08/24/2020 - RNU - V 1.3: Updated to cope with version 3.3 of core Argo
%                             Quality Control Manual:
%                              - Test 11: Gradient test removed (except for
%                                DOXY).
%                              - Test 6: Global range test modified (for PRES).
%                              - Test 25: MEDD test added.
%                             Test 6 & 19: extended the list of parameters
%                             concerned by the test (added BBP700, BBP532,
%                             PH_IN_SITU_TOTAL, NITRATE, DOWN_IRRADIANCE380,
%                             DOWN_IRRADIANCE412, DOWN_IRRADIANCE443,
%                             DOWN_IRRADIANCE490 and DOWNWELLING_PAR
%                             parameters).
%                             Test 7: min TEMP value set to 21 °C (instead of
%                             21.7 °C) in the Read sea.
%                             Test 9: added spike test for PH_IN_SITU_TOTAL and
%                             NITRATE parameters.
%                             Update of density function EOS80 => TEOS 10.
%   03/30/2021 - RNU - V 1.4: Added global range test for BBP470.
%   04/28/2021 - RNU - V 1.5: Added DOXY specific test 57.
%   08/17/2021 - RNU - V 1.6: Updated to cope with version 3.5 of Argo Quality
%                             Control Manual For CTD and Trajectory Data
%                              - new test application order (tests 15 and 19
%                             have moved).
%                              - a measurement with QC = '3' is tested by other
%                             quality control tests.
%                             To follow Virginie Racapé's recomendation,
%                             TEST 25: MEDD test is not performed on (PRES,
%                             TEMP_DOXY) timeseries.
%   10/14/2021 - RNU - V 1.7: TEST 57: manage the case of Ascent/Descent phase
%                             with only 1 measurement.
%   02/22/2022 - RNU - V 1.8: Manage (PRES2, TEMP2, PSAL2) introduced for
%                             deployments with dual CTD sensors.
%   03/18/2022 - RNU - V 1.9: DOWN_IRRADIANCE532 and DOWN_IRRADIANCE555 added to
%                             RTQC tests (since the global range test has been
%                             specified).
% ------------------------------------------------------------------------------
function [o_testDoneListAll, o_testFailedListAll] = gl_add_rtqc_to_ego_file(a_ncEgoFilePathName)

% default values
global g_decGl_dateDef;
global g_decGl_argosLonDef;
global g_decGl_argosLatDef;

global g_decGl_janFirst1950InMatlab;
% QC flag values
global g_decGl_qcDef;
global g_decGl_qcNoQc;
global g_decGl_qcGood;
global g_decGl_qcProbablyGood;
global g_decGl_qcCorrectable;
global g_decGl_qcBad;
global g_decGl_qcChanged;
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;


% program version
global g_decGl_rtqcVersion;
g_decGl_rtqcVersion = '1.9';

% global configuration values
global g_decGl_rtqcTest2;
global g_decGl_rtqcTest3;
global g_decGl_rtqcTest4;
global g_decGl_rtqcTest6;
global g_decGl_rtqcTest7;
global g_decGl_rtqcTest9;
global g_decGl_rtqcTest11;
global g_decGl_rtqcTest15;
global g_decGl_rtqcTest19;
global g_decGl_rtqcTest20;
global g_decGl_rtqcTest25;
global g_decGl_rtqcTest57;
global g_decGl_rtqcGebcoFile;
global g_decGl_rtqcGreyList;

% PHASE codes
global g_decGl_phaseDescent;
global g_decGl_phaseAscent;

% RTQC test to perform
testToPerformList = [ ...
   {'TEST002_IMPOSSIBLE_DATE'} {g_decGl_rtqcTest2} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} {g_decGl_rtqcTest3} ...
   {'TEST004_POSITION_ON_LAND'} {g_decGl_rtqcTest4} ...
   {'TEST006_GLOBAL_RANGE'} {g_decGl_rtqcTest6} ...
   {'TEST007_REGIONAL_RANGE'} {g_decGl_rtqcTest7} ...
   {'TEST009_SPIKE'} {g_decGl_rtqcTest9} ...
   {'TEST011_GRADIENT'} {g_decGl_rtqcTest11} ...
   {'TEST015_GREY_LIST'} {g_decGl_rtqcTest15} ...
   {'TEST019_DEEPEST_PRESSURE'} {g_decGl_rtqcTest19} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {g_decGl_rtqcTest20} ...
   {'TEST025_MEDD'} {g_decGl_rtqcTest25} ...
   {'TEST057_DOXY'} {g_decGl_rtqcTest57} ...
   ];

% additional information needed for some RTQC test
TEST004_GEBCO_FILE = g_decGl_rtqcGebcoFile;
TEST015_GREY_LIST_FILE = g_decGl_rtqcGreyList;


% Glider data start date
janFirst1997InJulD = gl_gregorian_2_julian('1997/01/01 00:00:00');

% region definition for regional range test
RED_SEA_REGION = [[25 30 30 35]; ...
   [15 30 35 40]; ...
   [15 20 40 45]; ...
   [12.55 15 40 43]; ...
   [13 15 43 43.5]];

MEDITERRANEAN_SEA_REGION = [[30 40 -5 40]; ...
   [40 45 0 25]; ...
   [45 50 10 15]; ...
   [40 41 25 30]; ...
   [35.2 36.6 -5.4 -5]];


% check if the input file exists
if (~exist(a_ncEgoFilePathName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_ncEgoFilePathName);
   return
end

% retrieve the test to perform
lastTestNum = 63;
testFlagList = zeros(lastTestNum, 1);
for idT = 1:2:length(testToPerformList)
   if (testToPerformList{idT+1} == 1)
      testName = testToPerformList{idT};
      testFlagList(str2num(testName(5:7))) = 1;
   end
end

% check test additional information
if (testFlagList(4) == 1)
   % for position on land test, we need the GEBCO file path name
   gebcoPathFileName = TEST004_GEBCO_FILE;
   if ~(exist(gebcoPathFileName, 'file') == 2)
      fprintf('RTQC_WARNING: TEST004: GEBCO file (%s) not found => test #4 not performed\n', ...
         gebcoPathFileName);
      testFlagList(4) = 0;
   end
end
if (testFlagList(15) == 1)
   % for grey list test, we need the greylist file path name
   greyListPathFileName = TEST015_GREY_LIST_FILE;
   if ~(exist(greyListPathFileName, 'file') == 2)
      fprintf('RTQC_WARNING: TEST005: Grey list file (%s) not found => test #15 not performed\n', ...
         greyListPathFileName);
      testFlagList(15) = 0;
   else
      [ncEgoData] = gl_get_att_from_nc_file(a_ncEgoFilePathName, [], {'wmo_platform_code'});
      wmoNumber = gl_get_data_from_name('wmo_platform_code', ncEgoData);
      if (isempty(wmoNumber))
         fprintf('RTQC_WARNING: TEST005: No WMO number for glider => test #15 not performed\n');
         testFlagList(15) = 0;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ EGO FILE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve parameter fill values
paramJuld = gl_get_netcdf_param_attributes('JULD');
paramTime = gl_get_netcdf_param_attributes('TIME');
paramLat = gl_get_netcdf_param_attributes('LATITUDE');
paramLon = gl_get_netcdf_param_attributes('LONGITUDE');

% retrieve the data from the core mono profile file
wantedVars = [ ...
   {'DATA_MODE'} ...
   {'TIME'} ...
   {'TIME_QC'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'TIME_GPS'} ...
   {'TIME_GPS_QC'} ...
   {'LATITUDE_GPS'} ...
   {'LONGITUDE_GPS'} ...
   {'POSITION_GPS_QC'} ...
   {'PHASE'} ...
   {'PHASE_NUMBER'} ...
   {'PARAMETER'} ...
   ];

[ncEgoData] = gl_get_data_from_nc_file(a_ncEgoFilePathName, wantedVars);

dataMode = gl_get_data_from_name('DATA_MODE', ncEgoData)';
time = gl_get_data_from_name('TIME', ncEgoData)';
timeQc = gl_get_data_from_name('TIME_QC', ncEgoData)';
latitude = gl_get_data_from_name('LATITUDE', ncEgoData)';
longitude = gl_get_data_from_name('LONGITUDE', ncEgoData)';
positionQc = gl_get_data_from_name('POSITION_QC', ncEgoData)';
timeGps = gl_get_data_from_name('TIME_GPS', ncEgoData)';
timeGpsQc = gl_get_data_from_name('TIME_GPS_QC', ncEgoData)';
latitudeGps = gl_get_data_from_name('LATITUDE_GPS', ncEgoData)';
longitudeGps = gl_get_data_from_name('LONGITUDE_GPS', ncEgoData)';
positionGpsQc = gl_get_data_from_name('POSITION_GPS_QC', ncEgoData)';
phase = gl_get_data_from_name('PHASE', ncEgoData)';
phaseNumber = gl_get_data_from_name('PHASE_NUMBER', ncEgoData)';

if (dataMode == 'D')
   fprintf('Input file in DM : %s => exit\n', a_ncEgoFilePathName);
   return
end

% compute juld from time
juld = ones(size(time))*paramJuld.fillValue;
epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
idNodef = find(time ~= paramTime.fillValue);
juld(idNodef) = time(idNodef)/86400 + epoch_offset;

% compute juldGps from timeGps
juldGps = ones(size(timeGps))*paramJuld.fillValue;
epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
idNodef = find(timeGps ~= paramTime.fillValue);
juldGps(idNodef) = timeGps(idNodef)/86400 + epoch_offset;

% some tests are applied on set of measurements with the same PHASE_NUMBER, we
% then must first to add identify PHASE with a default PHASE_NUMBER
phaseNumberBis = single(phaseNumber);
idDef = find(phaseNumberBis == 99999);
for id = 1:length(idDef)
   nextPhaseNum = min(phaseNumberBis(idDef(id)+1:end));
   if (nextPhaseNum ~= 99999)
      phaseNumberBis(idDef(id)) = nextPhaseNum - 0.5;
   else
      tmp = phaseNumberBis(1:idDef(id)-1);
      tmp(find(tmp == 99999)) = [];
      phaseNumberBis(idDef(id)) = max(tmp) + 0.5;
   end
end
uPhaseNumberBis = unique(phaseNumberBis);

% create the list of parameters
param = gl_get_data_from_name('PARAMETER', ncEgoData);
% in previous version of EGO file PARAMETER list is stored in SENSOR variable
% also needed to process SOCIB EGO files
if (isempty(param))
   [ncEgoData] = gl_get_data_from_nc_file(a_ncEgoFilePathName, {'SENSOR'});
   param = gl_get_data_from_name('SENSOR', ncEgoData);
end
[~, nParam] = size(param);
ncParamNameList = [];
ncParamAdjNameList = [];
for idParam = 1:nParam
   paramName = deblank(param(:, idParam)');
   if (~isempty(paramName))
      ncParamNameList{end+1} = paramName;
      paramInfo = gl_get_netcdf_param_attributes(paramName);
      if (~isempty(paramInfo) && (paramInfo.adjAllowed == 1))
         ncParamAdjNameList = [ncParamAdjNameList ...
            {[paramName '_ADJUSTED']} ...
            ];
      end
   end
end
ncParamNameList = unique(ncParamNameList);
ncParamAdjNameList = unique(ncParamAdjNameList);

% retrieve the data
ncParamNameQcList = [];
wantedVars = [];
for idParam = 1:length(ncParamNameList)
   paramName = ncParamNameList{idParam};
   paramNameQc = [paramName '_QC'];
   ncParamNameQcList{end+1} = paramNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramName} ...
      {paramNameQc} ...
      ];
end
ncParamAdjNameQcList = [];
for idParam = 1:length(ncParamAdjNameList)
   paramAdjName = ncParamAdjNameList{idParam};
   paramAdjNameQc = [paramAdjName '_QC'];
   ncParamAdjNameQcList{end+1} = paramAdjNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramAdjName} ...
      {paramAdjNameQc} ...
      ];
end

[ncEgoData] = gl_get_data_from_nc_file(a_ncEgoFilePathName, wantedVars);

ncParamDataList = [];
ncParamDataQcList = [];
ncParamFillValueList = [];
for idParam = 1:length(ncParamNameList)
   paramName = ncParamNameList{idParam};
   paramNameData = lower(paramName);
   ncParamDataList{end+1} = paramNameData;
   paramNameQc = ncParamNameQcList{idParam};
   paramNameQcData = lower(paramNameQc);
   ncParamDataQcList{end+1} = paramNameQcData;
   paramInfo = gl_get_netcdf_param_attributes(paramName);
   if (~isempty(paramInfo))
      ncParamFillValueList{end+1} = paramInfo.fillValue;
   else
      ncParamFillValueList{end+1} = single(99999);
   end
   
   data = gl_get_data_from_name(paramName, ncEgoData)';
   dataQc = gl_get_data_from_name(paramNameQc, ncEgoData)';
   
   eval([paramNameData ' = data;']);
   eval([paramNameQcData ' = dataQc;']);
end
ncParamAdjDataList = [];
ncParamAdjDataQcList = [];
ncParamAdjFillValueList = [];
for idParam = 1:length(ncParamAdjNameList)
   paramAdjName = ncParamAdjNameList{idParam};
   paramAdjNameData = lower(paramAdjName);
   ncParamAdjDataList{end+1} = paramAdjNameData;
   paramAdjNameQc = ncParamAdjNameQcList{idParam};
   paramAdjNameQcData = lower(paramAdjNameQc);
   ncParamAdjDataQcList{end+1} = paramAdjNameQcData;
   adjPos = strfind(paramAdjName, '_ADJUSTED');
   paramName = paramAdjName(1:adjPos-1);
   paramInfo = gl_get_netcdf_param_attributes(paramName);
   ncParamAdjFillValueList{end+1} = paramInfo.fillValue;
   
   data = gl_get_data_from_name(paramAdjName, ncEgoData)';
   dataQc = gl_get_data_from_name(paramAdjNameQc, ncEgoData)';
   
   eval([paramAdjNameData ' = data;']);
   eval([paramAdjNameQcData ' = dataQc;']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List of parameters that have at least one RTQC test
%
%    {'PRES'} ...
%    {'TEMP'} ...
%    {'PSAL'} ...
%    {'CNDC'} ...
%    {'DOXY'} ...
%    {'TEMP_DOXY'} ...
%    {'CHLA'} ...
%    {'BBP700'} ...
%    {'BBP470'} ...
%    {'BBP532'} ...
%    {'PH_IN_SITU_TOTAL'} ...
%    {'NITRATE'} ...
%    {'DOWN_IRRADIANCE380'} ...
%    {'DOWN_IRRADIANCE412'} ...
%    {'DOWN_IRRADIANCE443'} ...
%    {'DOWN_IRRADIANCE490'} ...
%    {'DOWN_IRRADIANCE532'} ...
%    {'DOWN_IRRADIANCE555'} ...
%    {'DOWNWELLING_PAR'} ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specific variables generated by the Coriolis decoder
%
% PRES2, TEMP2, PSAL2 for deployments with dual CTD sensors ( SBE and RBR)
% DOXY2 (generally computed from MOLAR_DOXY whereas DOXY is computed from intermediate parameters)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY RTQC TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

testDoneList = zeros(lastTestNum, 1);
testFailedList = zeros(lastTestNum, 1);
o_testDoneListAll = zeros(lastTestNum, length(time));
o_testFailedListAll = zeros(lastTestNum, length(time));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 2: impossible date test
%
if (testFlagList(2) == 1)
   
   % as TIME is an EPOCH date we only need to check it is after 01/01/1997
   % and before the current date
   
   % check TIME
   idToCheck = find((time ~= paramTime.fillValue)  & ...
      (timeQc ~= g_decGl_qcCorrectable) & ...
      (timeQc ~= g_decGl_qcBad));
   
   % initialize Qc flag
   timeQc(idToCheck) = gl_set_qc(timeQc(idToCheck), g_decGl_qcGood);
   testDoneList(2) = 1;
   o_testDoneListAll(2, idToCheck) = 1;
   
   % apply the test
   idToFlag = find((juld(idToCheck) < janFirst1997InJulD) | ...
      ((juld(idToCheck)+g_decGl_janFirst1950InMatlab) > gl_now_utc));
   if (~isempty(idToFlag))
      timeQc(idToCheck(idToFlag)) = gl_set_qc(timeQc(idToCheck(idToFlag)), g_decGl_qcBad);
      testFailedList(2) = 1;
      o_testFailedListAll(2, idToCheck(idToFlag)) = 1;
   end
   
   % check TIME_GPS
   idToCheck = find((timeGps ~= paramTime.fillValue)  & ...
      (timeGpsQc ~= g_decGl_qcCorrectable) & ...
      (timeGpsQc ~= g_decGl_qcBad));
   
   % initialize Qc flag
   timeGpsQc(idToCheck) = gl_set_qc(timeGpsQc(idToCheck), g_decGl_qcGood);
   testDoneList(2) = 1;
   
   % apply the test
   idToFlag = find((juldGps(idToCheck) < janFirst1997InJulD) | ...
      ((juldGps(idToCheck)+g_decGl_janFirst1950InMatlab) > gl_now_utc));
   if (~isempty(idToFlag))
      timeGpsQc(idToCheck(idToFlag)) = gl_set_qc(timeGpsQc(idToCheck(idToFlag)), g_decGl_qcBad);
      testFailedList(2) = 1;
   end
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 3: impossible location test
%
if (testFlagList(3) == 1)
   
   % check LATITUDE and LONGITUDE
   if (~isempty(latitude) && ~isempty(longitude))
      
      idToCheck = find((latitude ~= paramLat.fillValue) & ...
         (longitude ~= paramLon.fillValue) & ...
         (positionQc ~= g_decGl_qcCorrectable) & ...
         (positionQc ~= g_decGl_qcBad));
      
      % initialize Qc flag
      positionQc(idToCheck) = gl_set_qc(positionQc(idToCheck), g_decGl_qcGood);
      testDoneList(3) = 1;
      o_testDoneListAll(3, idToCheck) = 1;
      
      % apply the test
      idToFlag = find((latitude(idToCheck) > 90) | (latitude(idToCheck) < -90) | ...
         (longitude(idToCheck) > 180) | (longitude(idToCheck) < -180));
      if (~isempty(idToFlag))
         positionQc(idToCheck(idToFlag)) = gl_set_qc(positionQc(idToCheck(idToFlag)), g_decGl_qcBad);
         testFailedList(3) = 1;
         o_testFailedListAll(3, idToCheck(idToFlag)) = 1;
      end
   end
   
   % check LATITUDE_GPS and LONGITUDE_GPS
   idToCheck = find(((latitudeGps ~= paramLat.fillValue) & ...
      (longitudeGps ~= paramLon.fillValue)) & ...
      (positionGpsQc ~= g_decGl_qcCorrectable) & ...
      (positionGpsQc ~= g_decGl_qcBad));
   
   % initialize Qc flag
   positionGpsQc(idToCheck) = gl_set_qc(positionGpsQc(idToCheck), g_decGl_qcGood);
   testDoneList(3) = 1;
   
   % apply the test
   idToFlag = find((latitudeGps(idToCheck) > 90) | (latitudeGps(idToCheck) < -90) | ...
      (longitudeGps(idToCheck) > 180) | (longitudeGps(idToCheck) < -180));
   if (~isempty(idToFlag))
      positionGpsQc(idToCheck(idToFlag)) = gl_set_qc(positionGpsQc(idToCheck(idToFlag)), g_decGl_qcBad);
      testFailedList(3) = 1;
   end
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 4: position on land test
%
if (testFlagList(4) == 1)
   
   % we check that the mean value of the elevations provided by the GEBCO
   % bathymetric atlas is < 0 at the location
   
   % check LATITUDE and LONGITUDE
   if (~isempty(latitude) && ~isempty(longitude))
      
      idToCheck = find((latitude ~= paramLat.fillValue) & ...
         (longitude ~= paramLon.fillValue) & ...
         (positionQc ~= g_decGl_qcCorrectable) & ...
         (positionQc ~= g_decGl_qcBad));
      
      % initialize Qc flag
      positionQc(idToCheck) = gl_set_qc(positionQc(idToCheck), g_decGl_qcGood);
      testDoneList(4) = 1;
      o_testDoneListAll(4, idToCheck) = 1;

      % retrieve GEBCO elevations
      [elev] = gl_get_gebco_elev_point(longitude(idToCheck), latitude(idToCheck), gebcoPathFileName);
      
      % apply the test
      idToFlag = [];
      for idP = 1:length(idToCheck)
         elevation = elev(idP, :);
         elevation(find(isnan(elevation))) = [];
         if (mean(elevation) >= 0)
            idToFlag = [idToFlag idP];
         end
      end
      
      if (~isempty(idToFlag))
         positionQc(idToCheck(idToFlag)) = gl_set_qc(positionQc(idToCheck(idToFlag)), g_decGl_qcBad);
         testFailedList(4) = 1;
         o_testFailedListAll(4, idToCheck(idToFlag)) = 1;
      end
   end
   
   % check LATITUDE_GPS and LONGITUDE_GPS
   
   idToCheck = find((latitudeGps ~= paramLat.fillValue) & ...
      (longitudeGps ~= paramLon.fillValue) & ...
      (positionGpsQc ~= g_decGl_qcCorrectable) & ...
      (positionGpsQc ~= g_decGl_qcBad));
   
   % initialize Qc flag
   positionGpsQc(idToCheck) = gl_set_qc(positionGpsQc(idToCheck), g_decGl_qcGood);
   testDoneList(4) = 1;
   
   % retrieve GEBCO elevations
   [elev] = gl_get_gebco_elev_point(longitudeGps(idToCheck), latitudeGps(idToCheck), gebcoPathFileName);
   
   % apply the test
   idToFlag = [];
   for idP = 1:length(idToCheck)
      elevation = elev(idP, :);
      elevation(find(isnan(elevation))) = [];
      if (mean(elevation) >= 0)
         idToFlag = [idToFlag idP];
      end
   end
   
   if (~isempty(idToFlag))
      positionGpsQc(idToCheck(idToFlag)) = gl_set_qc(positionGpsQc(idToCheck(idToFlag)), g_decGl_qcBad);
      testFailedList(4) = 1;
   end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 20: questionable Argos position test
%
if (testFlagList(20) == 1)
   
   % check LATITUDE_GPS and LONGITUDE_GPS
   
   % we use the PHASE_NUMBER to identify successive surface periods (recorded as
   % cycle numbers)
   cycleNumber = ones(size(latitudeGps))*-1;
   idToCheck = find(((latitudeGps ~= paramLat.fillValue) & ...
      (longitudeGps ~= paramLon.fillValue)) & ...
      (positionGpsQc ~= g_decGl_qcCorrectable) & ...
      (positionGpsQc ~= g_decGl_qcBad));
   
   % assign a cycle number to each GPS fix
   phasePrevMaxDate = -1;
   cyNum = 0;
   VERBOSE = 0;
   for idP = 1:length(uPhaseNumberBis)
      phaseNum = uPhaseNumberBis(idP);
      idMeasForPh = find(phaseNumberBis == phaseNum);
      juldPhase = juld(idMeasForPh);
      juldPhase(find(juldPhase == paramJuld.fillValue)) = [];
      if (isempty(juldPhase))
         continue
      end
      phaseMinDate = min(juldPhase);
      phaseMaxDate = max(juldPhase);
      
      if (phasePrevMaxDate > 0)
         idF = find((juldGps(idToCheck) >= phasePrevMaxDate) & (juldGps(idToCheck) <= phaseMinDate));
         if (~isempty(idF))
            if (VERBOSE == 1)
               for id = 1:length(idF)
                  fprintf('Gps #%03d/%03d : %s\n', ...
                     idF(id), length(idToCheck), gl_julian_2_gregorian(juldGps(idToCheck(idF(id)))));
               end
            end
            cycleNumber(idToCheck(idF)) = cyNum;
            cyNum = cyNum + 1;
         end
         idF = find((juldGps(idToCheck) >= phaseMinDate) & (juldGps(idToCheck) <= phaseMaxDate));
         if (~isempty(idF))
            if (VERBOSE == 1)
               for id = 1:length(idF)
                  fprintf('Gps #%03d/%03d : %s\n', ...
                     idF(id), length(idToCheck), gl_julian_2_gregorian(juldGps(idToCheck(idF(id)))));
               end
            end
            cycleNumber(idToCheck(idF)) = cyNum;
            cyNum = cyNum + 1;
         end
      else
         idF = find(juldGps(idToCheck) <= phaseMinDate);
         if (~isempty(idF))
            if (VERBOSE == 1)
               for id = 1:length(idF)
                  fprintf('Gps #%03d/%03d : %s\n', ...
                     idF(id), length(idToCheck), gl_julian_2_gregorian(juldGps(idToCheck(idF(id)))));
               end
            end
            cycleNumber(idToCheck(idF)) = cyNum;
            cyNum = cyNum + 1;
         end
      end
      
      if (VERBOSE == 1)
         fprintf('Phase #%5.1f (%d): %s - %s\n', ...
            phaseNum, unique(phase(idMeasForPh)), ...
            gl_julian_2_gregorian(phaseMinDate), ...
            gl_julian_2_gregorian(phaseMaxDate));
      end
      
      phasePrevMaxDate = phaseMaxDate;
   end
   idF = find(juldGps(idToCheck) >= phaseMaxDate);
   if (~isempty(idF))
      if (VERBOSE == 1)
         for id = 1:length(idF)
            fprintf('Gps #%03d/%03d : %s\n', ...
               idF(id), length(idToCheck), gl_julian_2_gregorian(juldGps(idToCheck(idF(id)))));
         end
      end
      cycleNumber(idToCheck(idF)) = cyNum;
      cyNum = cyNum + 1;
   end
   
   if (VERBOSE == 1)
      fprintf('\n');
      for idP = 1:length(latitudeGps)
         fprintf('Gps #%03d : Cycle #%3d: Qc %d: %s %.3f %.3f\n', ...
            idP, cycleNumber(idP), positionGpsQc(idP), ...
            gl_julian_2_gregorian(juldGps(idP)), latitudeGps(idP), longitudeGps(idP));
      end
   end
   
   % apply test #20 to GPS fixes
   uCycleNumber = unique(cycleNumber(find(cycleNumber >= 0)));
   cyNumPrev = -1;
   for idCy = 1:length(uCycleNumber)
      cyNum = uCycleNumber(idCy);
      idMeasForCy = find(cycleNumber == cyNum);
      
      lastLocDateOfPrevCycle = g_decGl_dateDef;
      lastLocLonOfPrevCycle = g_decGl_argosLonDef;
      lastLocLatOfPrevCycle = g_decGl_argosLatDef;
      if ((cyNumPrev ~= -1) && (cyNumPrev == cyNum-1))
         lastLocDateOfPrevCycle = lastLocDate;
         lastLocLonOfPrevCycle = lastLocLon;
         lastLocLatOfPrevCycle = lastLocLat;
      end
      
      [positionGpsQc(idMeasForCy)] = gl_compute_jamstec_qc( ...
         juldGps(idMeasForCy), ...
         longitudeGps(idMeasForCy), ...
         latitudeGps(idMeasForCy), ...
         repmat('G', 1, length(idMeasForCy)), ...
         lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
      
      cyNumPrev = cyNum;
      [lastLocDate, idLast] = max(juldGps(idMeasForCy));
      lastLocLon = longitudeGps(idMeasForCy(idLast));
      lastLocLat = latitudeGps(idMeasForCy(idLast));
      
      if (any((positionGpsQc(idMeasForCy) == g_decGl_qcCorrectable) | ...
            (positionGpsQc(idMeasForCy) == g_decGl_qcBad)))
         testFailedList(20) = 1;
      end
      testDoneList(20) = 1;
   end
   
   if (VERBOSE == 1)
      fprintf('\n');
      for idP = 1:length(latitudeGps)
         fprintf('Gps #%03d : Cycle #%3d: Qc %d: %s %.3f %.3f\n', ...
            idP, cycleNumber(idP), positionGpsQc(idP), ...
            gl_julian_2_gregorian(juldGps(idP)), latitudeGps(idP), longitudeGps(idP));
      end
   end
   
   % check LATITUDE and LONGITUDE
   
   if (~isempty(latitude) && ~isempty(longitude))
      
      idToCheck = find( ...
         (latitude ~= paramLat.fillValue) & ...
         (longitude ~= paramLon.fillValue) & ...
         (positionQc ~= g_decGl_qcCorrectable) & ...
         (positionQc ~= g_decGl_qcBad) & ...
         (time ~= paramTime.fillValue) & ...
         (timeQc ~= g_decGl_qcCorrectable) & ...
         (timeQc ~= g_decGl_qcBad));
      
      % initialize Qc flag
      positionQc(idToCheck) = gl_set_qc(positionQc(idToCheck), g_decGl_qcGood);
      testDoneList(20) = 1;
      o_testDoneListAll(20, idToCheck) = 1;
      
      % no need to apply the test since:
      % - the base surface positions used for interpolation have already
      %   succeeded test #20
      % - we didn't extrapolate subsurface trajectory
      
      %       % apply the test
      %       [idToFlag] = gl_check_subsurface_speed( ...
      %          juld(idToCheck), ...
      %          longitude(idToCheck), ...
      %          latitude(idToCheck), ...
      %          juldGps(idGoodGPS), ...
      %          longitudeGps(idGoodGPS), ...
      %          latitudeGps(idGoodGPS));
      %
      %       if (~isempty(idToFlag))
      %          positionQc(idToCheck(idToFlag)) = gl_set_qc(positionQc(idToCheck(idToFlag)), g_decGl_qcBad);
      %          testFailedList(20) = 1;
      %          o_testDoneListAll(20, idToCheck(idToFlag)) = 1;
      %       end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 15: grey list test
%
if (testFlagList(15) == 1)
   
   % read grey list file
   fId = fopen(greyListPathFileName, 'r');
   if (fId == -1)
      fprintf('RTQC_WARNING: TEST015: Unable to open grey list file (%s) => test #15 not performed\n', ...
         greyListPathFileName);
   else
      fileContents = textscan(fId, '%s', 'delimiter', ',');
      fclose(fId);
      fileContents = fileContents{:};
      if (rem(size(fileContents, 1), 7) ~= 0)
         fprintf('RTQC_WARNING: TEST015: Unable to parse grey list file (%s) => test #15 not performed\n', ...
            greyListPathFileName);
      else
         
         greyListInfo = reshape(fileContents, 7, size(fileContents, 1)/7)';
         
         % retrieve information for the current float
         idF = find(strcmp(num2str(wmoNumber), greyListInfo(:, 1)) == 1);
         
         % get measurement dates
         idJuldNoDef = find(juld ~= paramJuld.fillValue);
         
         if (~isempty(idJuldNoDef))
            
            testDoneList(15) = 1;
            o_testDoneListAll(15, idJuldNoDef) = 1;
            
            % apply the grey list information
            for id = 1:length(idF)
               for idD = 1:2
                  if (idD == 1)
                     % non adjusted data processing
                     
                     % set the name list
                     ncParamXNameList = ncParamNameList;
                     ncParamXDataList = ncParamDataList;
                     ncParamXDataQcList = ncParamDataQcList;
                     ncParamXFillValueList = ncParamFillValueList;
                     
                     % retrieve grey listed parameter name
                     param = greyListInfo{idF(id), 2};
                  else
                     % adjusted data processing
                     
                     % set the name list
                     ncParamXNameList = ncParamAdjNameList;
                     ncParamXDataList = ncParamAdjDataList;
                     ncParamXDataQcList = ncParamAdjDataQcList;
                     ncParamXFillValueList = ncParamAdjFillValueList;
                     
                     % retrieve grey listed parameter adjusted name
                     param = [greyListInfo{idF(id), 2} '_ADJUSTED'];
                  end
                  
                  startDate = greyListInfo{idF(id), 3};
                  endDate = greyListInfo{idF(id), 4};
                  qcVal = greyListInfo{idF(id), 5};
                  
                  startDateJuld = datenum(startDate, 'yyyymmdd') - g_decGl_janFirst1950InMatlab;
                  endDateJuld = '';
                  if (~isempty(endDate))
                     endDateJuld = datenum(endDate, 'yyyymmdd') - g_decGl_janFirst1950InMatlab;
                  end
                  
                  if (~isempty(endDateJuld))
                     idToFlag = find(((juld(idJuldNoDef) >= startDateJuld) && (juld(idJuldNoDef) <= endDateJuld)));
                  else
                     idToFlag = find(juld(idJuldNoDef) >= startDateJuld);
                  end
                  
                  if (~isempty(idToFlag))
                     
                     idParam = find(strcmp(param, ncParamXNameList) == 1, 1);
                     if (~isempty(idParam))
                        data = eval(ncParamXDataList{idParam});
                        dataQc = eval(ncParamXDataQcList{idParam});
                        paramFillValue = ncParamXFillValueList{idParam};
                        
                        idNoDefParam = find(data ~= paramFillValue);
                        if (~isempty(idNoDefParam))
                           
                           % apply the test
                           idToFlagParam = find(ismember(idNoDefParam, idJuldNoDef(idToFlag)) == 1);
                           dataQc(idToFlagParam) = gl_set_qc(dataQc(idToFlagParam), int8(str2num(qcVal)));
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testFailedList(15) = 1;
                           o_testFailedListAll(15, idToFlagParam) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 19: deepest pressure test
%
if (testFlagList(19) == 1)

   % DEEPEST_PRES value
   deepestPres = 1000;

   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2

      switch idLoop
         case 1
            % list of parameters concerned by this test
            paramTestList = [ ...
               {'PRES'} ...
               {'TEMP'} ...
               {'PSAL'} ...
               {'CNDC'} ...
               {'DOXY'} ...
               {'DOXY2'} ...
               {'CHLA'} ...
               {'CHLA2'} ...
               {'BBP700'} ...
               {'BBP470'} ...
               {'BBP532'} ...
               {'PH_IN_SITU_TOTAL'} ...
               {'NITRATE'} ...
               {'DOWN_IRRADIANCE380'} ...
               {'DOWN_IRRADIANCE412'} ...
               {'DOWN_IRRADIANCE443'} ...
               {'DOWN_IRRADIANCE490'} ...
               {'DOWN_IRRADIANCE532'} ...
               {'DOWN_IRRADIANCE555'} ...
               {'DOWNWELLING_PAR'} ...
               ];
            presName = 'PRES';
         case 2
            paramTestList = [ ...
               {'PRES2'} ...
               {'TEMP2'} ...
               {'PSAL2'} ...
               ];
            presName = 'PRES2';
         otherwise
            fprintf('RTQC_ERROR: TEST019: Too many loops\n');
            continue
      end

      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing

            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;

            % retrieve PRES data from the workspace
            idPres = find(strcmp(presName, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing

            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;

            % retrieve PRES adjusted data from the workspace
            idPres = find(strcmp([presName '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end

         if (~isempty(idPres))
            presData = eval(ncParamXDataList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};

            if (~isempty(presData))

               % apply the test
               idNoDef = find(presData ~= presDataFillValue);
               idToFlag = find(presData(idNoDef) > deepestPres*1.1);

               if (~isempty(idToFlag))

                  for idP = 1:length(paramTestList)
                     paramName = paramTestList{idP};
                     if (idD == 2)
                        paramName = [paramName '_ADJUSTED'];
                     end

                     idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
                     if (~isempty(idParam))
                        data = eval(ncParamXDataList{idParam});
                        dataQc = eval(ncParamXDataQcList{idParam});
                        paramFillValue = ncParamXFillValueList{idParam};

                        idNoDefParam = find(data ~= paramFillValue);
                        if (~isempty(idNoDefParam))

                           % initialize Qc flags
                           dataQc(idNoDefParam) = gl_set_qc(dataQc(idNoDefParam), g_decGl_qcGood);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testDoneList(19) = 1;
                           o_testDoneListAll(19, idNoDefParam) = 1;

                           % apply the test
                           if (~isempty(idToFlag))
                              idToFlagParam = find(ismember(idNoDefParam, idNoDef(idToFlag)) == 1);
                              dataQc(idToFlagParam) = gl_set_qc(dataQc(idToFlagParam), g_decGl_qcBad);
                              eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(19) = 1;
                              o_testFailedListAll(19, idToFlagParam) = 1;
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 6: global range test
%
if (testFlagList(6) == 1)
   
   % list of parameters concerned by this test
   paramTestList = [ ...
      {'PRES'} ...
      {'PRES2'} ...
      {'TEMP'} ...
      {'TEMP2'} ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      {'PSAL'} ...
      {'PSAL2'} ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'CHLA'} ...
      {'CHLA2'} ...
      {'BBP700'} ...
      {'BBP470'} ...
      {'BBP532'} ...
      {'PH_IN_SITU_TOTAL'} ...
      {'NITRATE'} ...
      {'DOWN_IRRADIANCE380'} ...
      {'DOWN_IRRADIANCE412'} ...
      {'DOWN_IRRADIANCE443'} ...
      {'DOWN_IRRADIANCE490'} ...
      {'DOWN_IRRADIANCE532'} ...
      {'DOWN_IRRADIANCE555'} ...
      {'DOWNWELLING_PAR'} ...
      ];
   
   paramTestMinMax = [ ...
      {''} {''}; ... % PRES => specific: if PRES < –5dbar, then PRES_QC = '4', TEMP_QC = '4', PSAL_QC = '4' elseif –5dbar <= PRES <= –2.4dbar, then PRES_QC = '3', TEMP_QC = '3', PSAL_QC = '3'.
      {''} {''}; ... % PRES2 => specific: if PRES2 < –5dbar, then PRES2_QC = '4', TEMP2_QC = '4', PSAL2_QC = '4' elseif –5dbar <= PRES2 <= –2.4dbar, then PRES2_QC = '3', TEMP2_QC = '3', PSAL2_QC = '3'.
      {-2.5} {40}; ... % TEMP
      {-2.5} {40}; ... % TEMP2
      {-2.5} {40}; ... % TEMP_DOXY
      {-2.5} {40}; ... % TEMP_DOXY2
      {2} {41}; ... % PSAL
      {2} {41}; ... % PSAL2
      {-5} {600}; ... % DOXY
      {-5} {600}; ... % DOXY2
      {-0.1} {50}; ... % CHLA
      {-0.1} {50}; ... % CHLA2
      {-0.000025} {0.1}; ... % BBP700
      {-0.000005} {0.1}; ... % BBP470
      {-0.000005} {0.1}; ... % BBP532
      {7.3} {8.5}; ... % PH_IN_SITU_TOTAL
      {-2} {50}; ... % NITRATE
      {-1} {1.7}; ... % DOWN_IRRADIANCE380
      {-1} {2.9}; ... % DOWN_IRRADIANCE412
      {-1} {3.2}; ... % DOWN_IRRADIANCE443
      {-1} {3.4}; ... % DOWN_IRRADIANCE490
      {-1} {3.3}; ... % DOWN_IRRADIANCE532
      {-1} {3.2}; ... % DOWN_IRRADIANCE555
      {-1} {4672}; ... % DOWNWELLING_PAR
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      for idP = 1:length(paramTestList)
         paramName = paramTestList{idP};
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         
         idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncParamXDataList{idParam});
            dataQc = eval(ncParamXDataQcList{idParam});
            paramFillValue = ncParamXFillValueList{idParam};
            
            idNoDef = find(data ~= paramFillValue);
            if (~isempty(idNoDef))
               if (~strncmp(paramName, 'PRES', length('PRES')))
                  
                  % initialize Qc flag
                  dataQc(idNoDef) = gl_set_qc(dataQc(idNoDef), g_decGl_qcGood);
                  eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                  testDoneList(6) = 1;
                  o_testDoneListAll(6, idNoDef) = 1;
                  
                  % apply the test
                  paramTestMin = paramTestMinMax{idP, 1};
                  paramTestMax = paramTestMinMax{idP, 2};
                  if (~isempty(paramTestMax))
                     idToFlag = find((data(idNoDef) < paramTestMin) | ...
                        (data(idNoDef) > paramTestMax));
                  else
                     idToFlag = find(data(idNoDef) < paramTestMin);
                  end
                  if (~isempty(idToFlag))
                     flagValue = g_decGl_qcBad;
                     if (strncmp(paramName, 'BBP', length('BBP')))
                        flagValue = g_decGl_qcCorrectable;
                     end
                     dataQc(idNoDef(idToFlag)) = gl_set_qc(dataQc(idNoDef(idToFlag)), flagValue);
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                     testFailedList(6) = 1;
                     o_testFailedListAll(6, idNoDef(idToFlag)) = 1;
                  end
               else
                  % specific to PRES parameter
                  idPres = idParam;
                  presData = data;
                  presDataQc = dataQc;
                  presDataFillValue = paramFillValue;
                  
                  tempData = [];
                  psalData = [];

                  if (strncmp(paramName, 'PRES2', length('PRES2')))
                     if (idD == 1)
                        idTemp = find(strcmp('TEMP2', ncParamXNameList) == 1, 1);
                        idPsal = find(strcmp('PSAL2', ncParamXNameList) == 1, 1);
                     else
                        idTemp = find(strcmp('TEMP2_ADJUSTED', ncParamXNameList) == 1, 1);
                        idPsal = find(strcmp('PSAL2_ADJUSTED', ncParamXNameList) == 1, 1);
                     end
                  else
                     if (idD == 1)
                        idTemp = find(strcmp('TEMP', ncParamXNameList) == 1, 1);
                        idPsal = find(strcmp('PSAL', ncParamXNameList) == 1, 1);
                     else
                        idTemp = find(strcmp('TEMP_ADJUSTED', ncParamXNameList) == 1, 1);
                        idPsal = find(strcmp('PSAL_ADJUSTED', ncParamXNameList) == 1, 1);
                     end
                  end
                  
                  if (~isempty(idTemp))
                     tempData = eval(ncParamXDataList{idTemp});
                     tempDataQc = eval(ncParamXDataQcList{idTemp});
                     tempDataFillValue = ncParamXFillValueList{idTemp};
                  end
                  
                  if (~isempty(idPsal))
                     psalData = eval(ncParamXDataList{idPsal});
                     psalDataQc = eval(ncParamXDataQcList{idPsal});
                     psalDataFillValue = ncParamXFillValueList{idPsal};
                  end
                  
                  idPresNoDef = find(presData ~= presDataFillValue);
                  
                  % initialize Qc flag
                  presDataQc(idPresNoDef) = gl_set_qc(presDataQc(idPresNoDef), g_decGl_qcGood);
                  eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                  testDoneList(6) = 1;
                  o_testDoneListAll(6, idPresNoDef) = 1;                  
                  
                  % apply the test
                  for idT = 1:2
                     if (idT == 1)
                        idPresToFlag = find(presData(idPresNoDef) < -5);
                        flagValue = g_decGl_qcBad;
                     else
                        idPresToFlag = find((presData(idPresNoDef) >= -5) & ...
                           (presData(idPresNoDef) <= -2.4));
                        flagValue = g_decGl_qcCorrectable;
                     end
                     
                     if (~isempty(idPresToFlag))
                        presDataQc(idPresNoDef(idPresToFlag)) = gl_set_qc(presDataQc(idPresNoDef(idPresToFlag)), flagValue);
                        eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                        testFailedList(6) = 1;
                        o_testFailedListAll(6, idPresNoDef(idToFlag)) = 1;
                        
                        if (~isempty(tempData))
                           idTempNoDef = find(tempData ~= tempDataFillValue);
                           idTempToFlag = idTempNoDef(find(ismember(idTempNoDef, idPresNoDef(idPresToFlag))));
                           if (~isempty(idTempToFlag))
                              % initialize Qc flags
                              tempDataQc(idTempNoDef) = gl_set_qc(tempDataQc(idTempNoDef), g_decGl_qcGood);
                              % set Qc flags according to test results
                              tempDataQc(idTempToFlag) = gl_set_qc(tempDataQc(idTempToFlag), flagValue);
                              eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                           end
                        end
                        
                        if (~isempty(psalData))
                           idPsalNoDef = find(psalData ~= psalDataFillValue);
                           idPsalToFlag = idPsalNoDef(find(ismember(idPsalNoDef, idPresNoDef(idPresToFlag))));
                           if (~isempty(idPsalToFlag))
                              % initialize Qc flags
                              psalDataQc(idPsalNoDef) = gl_set_qc(psalDataQc(idPsalNoDef), g_decGl_qcGood);
                              % set Qc flags according to test result
                              psalDataQc(idPsalToFlag) = gl_set_qc(psalDataQc(idPsalToFlag), flagValue);
                              eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 7: regional range test
%
if (testFlagList(7) == 1)
   
   % interpolate GPS locations at the measurement times
   idNodef = find(timeQc == g_decGl_qcGood);
   latMeas = ones(size(time))*paramLat.fillValue;
   lonMeas = ones(size(time))*paramLon.fillValue;
   
   idGpsNodef = find((timeGpsQc == g_decGl_qcGood) & (positionGpsQc == g_decGl_qcGood));
   timeGps2 = timeGps(idGpsNodef);
   latitudeGps2 = latitudeGps(idGpsNodef);
   longitudeGps2 = longitudeGps(idGpsNodef);
   
   if (length(latitudeGps2) > 1)
      latMeas(idNodef) = interp1q(timeGps2', latitudeGps2', time(idNodef)')';
      lonMeas(idNodef) = interp1q(timeGps2', longitudeGps2', time(idNodef)')';
      
      latMeas(isnan(latMeas)) = paramLat.fillValue;
      lonMeas(isnan(lonMeas)) = paramLon.fillValue;
   end
   
   idToCheck = find((latMeas ~= paramLat.fillValue) & (lonMeas ~= paramLon.fillValue));
   
   % list of parameters concerned by this test
   paramTestList = [ ...
      {'TEMP'} ...
      {'TEMP2'} ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      {'PSAL'} ...
      {'PSAL2'} ...
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      for idR = 1:2
         
         if (idR == 1)
            % READ SEA
            regionLimits = RED_SEA_REGION;
            
            paramTestMinMax = [ ...
               21 40; ... % TEMP
               21 40; ... % TEMP2
               21 40; ... % TEMP_DOXY
               21 40; ... % TEMP_DOXY2
               2 41; ... % PSAL
               2 41; ... % PSAL2
               ];
         else
            % MEDITERRANEAN SEA
            regionLimits = MEDITERRANEAN_SEA_REGION;
            
            paramTestMinMax = [ ...
               10 40; ... % TEMP
               10 40; ... % TEMP2
               10 40; ... % TEMP_DOXY
               10 40; ... % TEMP_DOXY2
               2 40; ... % PSAL
               2 40; ... % PSAL2
               ];
         end
         
         idMeasInRegion = find(location_in_region(lonMeas(idToCheck), latMeas(idToCheck), regionLimits) == 1);
         
         if (~isempty(idMeasInRegion))
            
            for idP = 1:length(paramTestList)
               paramName = paramTestList{idP};
               if (idD == 2)
                  paramName = [paramName '_ADJUSTED'];
               end
               
               idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  data = eval(ncParamXDataList{idParam});
                  dataQc = eval(ncParamXDataQcList{idParam});
                  paramFillValue = ncParamXFillValueList{idParam};
                  
                  if (~isempty(data))
                     idNoDef = find(data(idToCheck(idMeasInRegion)) ~= paramFillValue);
                     if (~isempty(idNoDef))
                        
                        % initialize Qc flag
                        dataQc(idToCheck(idMeasInRegion(idNoDef))) = gl_set_qc(dataQc(idToCheck(idMeasInRegion(idNoDef))), g_decGl_qcGood);
                        eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                        testDoneList(7) = 1;
                        o_testDoneListAll(7, idToCheck(idMeasInRegion(idNoDef))) = 1;
                        
                        % apply the test
                        paramTestMin = paramTestMinMax(idP, 1);
                        paramTestMax = paramTestMinMax(idP, 2);
                        idToFlag = find((data(idToCheck(idMeasInRegion(idNoDef))) < paramTestMin) | ...
                           (data(idToCheck(idMeasInRegion(idNoDef))) > paramTestMax));
                        if (~isempty(idToFlag))
                           dataQc(idToCheck(idMeasInRegion(idNoDef(idToFlag)))) = gl_set_qc(dataQc(idToCheck(idMeasInRegion(idNoDef(idToFlag)))), g_decGl_qcBad);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testFailedList(7) = 1;
                           o_testFailedListAll(7, idToCheck(idMeasInRegion(idNoDef(idToFlag)))) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 9: spike test
%

% NOTE THAT A SPIKE TEST IS DEFINED FOR BBP (IT IS SIMILAR TO CHLA ONE) BUT NOT
% IMPLEMENTED YET (Catherine SCHMECHTIG's decision).

if (testFlagList(9) == 1)
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2

      switch idLoop
         case 1
            % list of parameters concerned by this test
            % list of parameters concerned by this test
            paramTestList = [ ...
               {'TEMP'} ...
               {'TEMP_DOXY'} ...
               {'TEMP_DOXY2'} ...
               {'PSAL'} ...
               {'DOXY'} ...
               {'DOXY2'} ...
               {'CHLA'} ...
               {'CHLA2'} ...
               {'PH_IN_SITU_TOTAL'} ...
               {'NITRATE'} ...
               ];
            paramTestShallowDeep = [ ...
               6 2; ... % TEMP
               6 2; ... % TEMP_DOXY
               6 2; ... % TEMP_DOXY2
               0.9 0.3; ... % PSAL
               50 25; ... % DOXY
               50 25; ... % DOXY2
               ];
            presName = 'PRES';
         case 2
            paramTestList = [ ...
               {'TEMP2'} ...
               {'PSAL2'} ...
               ];
            paramTestShallowDeep = [ ...
               6 2; ... % TEMP2
               0.9 0.3; ... % PSAL2
               ];
            presName = 'PRES2';
         otherwise
            fprintf('RTQC_ERROR: TEST009: Too many loops\n');
            continue
      end

      latMeas = [];
      lonMeas = [];
   
      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing

            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;

            % retrieve PRES data from the workspace
            idPres = find(strcmp(presName, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing

            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;

            % retrieve PRES adjusted data from the workspace
            idPres = find(strcmp([presName '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end

         if (~isempty(idPres))
            presData = eval(ncParamXDataList{idPres});
            presDataQc = eval(ncParamXDataQcList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};

            for idP = 1:length(paramTestList)
               paramName = paramTestList{idP};
               if (idD == 2)
                  paramName = [paramName '_ADJUSTED'];
               end

               idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  data = eval(ncParamXDataList{idParam});
                  dataQc = eval(ncParamXDataQcList{idParam});
                  paramFillValue = ncParamXFillValueList{idParam};

                  idNoDef = find(data ~= paramFillValue);
                  if (~isempty(idNoDef))

                     % initialize Qc flag
                     dataQc(idNoDef) = gl_set_qc(dataQc(idNoDef), g_decGl_qcGood);
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                     testDoneList(9) = 1;
                     o_testDoneListAll(9, idNoDef) = 1;

                     idToFlag = [];
                     if (~strcmp(paramTestList{idP}, 'CHLA') && ...
                           ~strcmp(paramTestList{idP}, 'CHLA2') && ...
                           ~strcmp(paramTestList{idP}, 'PH_IN_SITU_TOTAL') && ...
                           ~strcmp(paramTestList{idP}, 'NITRATE'))

                        % spike test for TEMP, TEMP_DOXY, PSAL and DOXY
                        idDefOrBad = find((presData == presDataFillValue) | ...
                           (presDataQc == g_decGl_qcBad) | ...
                           (data == paramFillValue) | ...
                           (dataQc == g_decGl_qcBad));
                        idDefOrBad = [0 idDefOrBad length(data)+1];
                        for idSlice1 = 1:length(idDefOrBad)-1

                           % part of continuous measurements
                           idLevel = idDefOrBad(idSlice1)+1:idDefOrBad(idSlice1+1)-1;
                           if (~isempty(idLevel))

                              % spike test is applied on set of
                              % measurements with the same PHASE_NUMBER
                              uPhaseNumberBisForSlice = unique(phaseNumberBis(idLevel), 'stable');
                              for idSlice2 = 1:length(uPhaseNumberBisForSlice)
                                 phaseNum = uPhaseNumberBisForSlice(idSlice2);
                                 idMeasForPh = find(phaseNumberBis(idLevel) == phaseNum);

                                 % apply the test
                                 if (length(idMeasForPh) > 2)
                                    for id = 2:length(idMeasForPh)-1
                                       idL = idLevel(idMeasForPh(id));
                                       testVal = abs(data(idL)-(data(idL+1)+data(idL-1))/2) - abs((data(idL+1)-data(idL-1))/2);
                                       if (presData(idL) < 500)
                                          if (testVal > paramTestShallowDeep(idP, 1))
                                             idToFlag = [idToFlag idL];
                                          end
                                       else
                                          if (testVal > paramTestShallowDeep(idP, 2))
                                             idToFlag = [idToFlag idL];
                                          end
                                       end
                                    end
                                 end
                              end
                           end
                        end

                     elseif (strcmp(paramTestList{idP}, 'CHLA') || ...
                           strcmp(paramTestList{idP}, 'CHLA2'))

                        % spike test for CHLA
                        idDefOrBad = find((data == paramFillValue) | ...
                           (dataQc == g_decGl_qcBad));
                        idDefOrBad = [0 idDefOrBad length(data)+1];
                        for idSlice1 = 1:length(idDefOrBad)-1

                           % part of continuous measurements
                           idLevel = idDefOrBad(idSlice1)+1:idDefOrBad(idSlice1+1)-1;
                           if (~isempty(idLevel))

                              % spike test is applied on set of
                              % measurements with the same PHASE_NUMBER
                              uPhaseNumberBisForSlice = unique(phaseNumberBis(idLevel), 'stable');
                              for idSlice2 = 1:length(uPhaseNumberBisForSlice)
                                 phaseNum = uPhaseNumberBisForSlice(idSlice2);
                                 idMeasForPh = find(phaseNumberBis(idLevel) == phaseNum);

                                 % apply the test
                                 if (length(idMeasForPh) > 4)
                                    resData = ones(1, length(idMeasForPh)-4)*paramFillValue;
                                    idList = 3:length(idMeasForPh)-2;
                                    for id = 1:length(idList)
                                       idL = idLevel(idMeasForPh(idList(id)));
                                       resData(id) = data(idL) - median(data(idL-2:idL+2));
                                    end
                                    sortedResData = sort(resData);
                                    idPct10 = ceil(length(sortedResData)*0.1);
                                    percentile10 = sortedResData(idPct10);
                                    if (any(resData < 2*percentile10))
                                       idToFlag = [idToFlag idLevel(idMeasForPh(find(resData < 2*percentile10))) + 2];
                                    end
                                 end
                              end
                           end
                        end

                     elseif (strcmp(paramTestList{idP}, 'PH_IN_SITU_TOTAL'))

                        % spike test for PH_IN_SITU_TOTAL
                        idDefOrBad = find((data == paramFillValue) | ...
                           (dataQc == g_decGl_qcBad));
                        idDefOrBad = [0 idDefOrBad length(data)+1];
                        for idSlice1 = 1:length(idDefOrBad)-1

                           % part of continuous measurements
                           idLevel = idDefOrBad(idSlice1)+1:idDefOrBad(idSlice1+1)-1;
                           if (~isempty(idLevel))

                              % spike test is applied on set of
                              % measurements with the same PHASE_NUMBER
                              uPhaseNumberBisForSlice = unique(phaseNumberBis(idLevel), 'stable');
                              for idSlice2 = 1:length(uPhaseNumberBisForSlice)
                                 phaseNum = uPhaseNumberBisForSlice(idSlice2);
                                 idMeasForPh = find(phaseNumberBis(idLevel) == phaseNum);

                                 % apply the test
                                 if (length(idMeasForPh) > 4)
                                    resData = ones(1, length(idMeasForPh)-4)*paramFillValue;
                                    idList = 3:length(idMeasForPh)-2;
                                    for id = 1:length(idList)
                                       idL = idLevel(idMeasForPh(idList(id)));
                                       resData(id) = abs(data(idL) - median(data(idL-2:idL+2))) - 0.04*data(idL);
                                    end
                                    if (any(resData > 0))
                                       idToFlag = [idToFlag idLevel(idMeasForPh(find(resData > 0))) + 2];
                                    end
                                 end
                              end
                           end
                        end

                     elseif (strcmp(paramTestList{idP}, 'NITRATE'))

                        if (isempty(latMeas))

                           % interpolate GPS locations at the measurement times
                           idNodef = find(timeQc == g_decGl_qcGood);
                           latMeas = ones(size(time))*paramLat.fillValue;
                           lonMeas = ones(size(time))*paramLon.fillValue;

                           idGpsNodef = find((timeGpsQc == g_decGl_qcGood) & (positionGpsQc == g_decGl_qcGood));
                           timeGps2 = timeGps(idGpsNodef);
                           latitudeGps2 = latitudeGps(idGpsNodef);
                           longitudeGps2 = longitudeGps(idGpsNodef);

                           if (length(latitudeGps2) > 1)
                              latMeas(idNodef) = interp1q(timeGps2', latitudeGps2', time(idNodef)')';
                              lonMeas(idNodef) = interp1q(timeGps2', longitudeGps2', time(idNodef)')';

                              latMeas(isnan(latMeas)) = paramLat.fillValue;
                              lonMeas(isnan(lonMeas)) = paramLon.fillValue;
                           end

                           idPosNoDef = find((latMeas ~= paramLat.fillValue) & (lonMeas ~= paramLon.fillValue));
                        end

                        % determine spike threshold value
                        % 1 micromole/kg in Mediterranean Sea and Red Sea
                        % 5 micromole/kg anywhere else
                        spikeThreshold = 5;
                        if (~isempty(idPosNoDef))
                           if (any(location_in_region(lonMeas(idPosNoDef), latMeas(idPosNoDef), RED_SEA_REGION)) || ...
                                 any(location_in_region(lonMeas(idPosNoDef), latMeas(idPosNoDef), MEDITERRANEAN_SEA_REGION)))
                              spikeThreshold = 1;
                           end
                        end

                        % spike test for NITRATE
                        % Catherine SCHMECHTIG's decision 05/21/2019
                        % values with QC = g_decGl_qcCorrectable should be
                        % considered in spike test (this is usually the NITRATE_QC
                        % value at this processing step)
                        %                      idDefOrBad = find((data == paramFillValue) | ...
                        %                         (dataQc == g_decGl_qcCorrectable) | ...
                        %                         (dataQc == g_decGl_qcBad));
                        idDefOrBad = find((data == paramFillValue) | ...
                           (dataQc == g_decGl_qcBad));
                        idDefOrBad = [0 idDefOrBad length(data)+1];
                        for idSlice1 = 1:length(idDefOrBad)-1

                           % part of continuous measurements
                           idLevel = idDefOrBad(idSlice1)+1:idDefOrBad(idSlice1+1)-1;
                           if (~isempty(idLevel))

                              % spike test is applied on set of
                              % measurements with the same PHASE_NUMBER
                              uPhaseNumberBisForSlice = unique(phaseNumberBis(idLevel), 'stable');
                              for idSlice2 = 1:length(uPhaseNumberBisForSlice)
                                 phaseNum = uPhaseNumberBisForSlice(idSlice2);
                                 idMeasForPh = find(phaseNumberBis(idLevel) == phaseNum);

                                 % apply the test
                                 if (length(idMeasForPh) > 4)
                                    resData = ones(1, length(idMeasForPh)-4)*paramFillValue;
                                    idList = 3:length(idMeasForPh)-2;
                                    for id = 1:length(idList)
                                       idL = idLevel(idMeasForPh(idList(id)));
                                       resData(id) = abs(data(idL) - median(data(idL-2:idL+2))) - spikeThreshold;
                                    end
                                    if (any(resData > 0))
                                       idToFlag = [idToFlag idLevel(idMeasForPh(find(resData > 0))) + 2];
                                    end
                                 end
                              end
                           end
                        end
                     end

                     if (~isempty(idToFlag))
                        dataQc(idToFlag) = gl_set_qc(dataQc(idToFlag), g_decGl_qcBad);
                        eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                        testFailedList(9) = 1;
                        o_testFailedListAll(9, idToFlag) = 1;
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 11: gradient test
%
if (testFlagList(11) == 1)
   
   % list of parameters concerned by this test
   paramTestList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      ];
   
   paramTestShallowDeep = [ ...
      50 25; ... % DOXY
      50 25; ... % DOXY2
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
         
         % retrieve PRES data from the workspace
         idPres = find(strcmp('PRES', ncParamXNameList) == 1, 1);
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
         
         % retrieve PRES adjusted data from the workspace
         idPres = find(strcmp('PRES_ADJUSTED', ncParamXNameList) == 1, 1);
      end

      if (~isempty(idPres))
         presData = eval(ncParamXDataList{idPres});
         presDataQc = eval(ncParamXDataQcList{idPres});
         presDataFillValue = ncParamXFillValueList{idPres};
         
         for idP = 1:length(paramTestList)
            paramName = paramTestList{idP};
            if (idD == 2)
               paramName = [paramName '_ADJUSTED'];
            end
            
            idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
            if (~isempty(idParam))
               data = eval(ncParamXDataList{idParam});
               dataQc = eval(ncParamXDataQcList{idParam});
               paramFillValue = ncParamXFillValueList{idParam};
               
               idNoDef = find(data ~= paramFillValue);
               if (~isempty(idNoDef))
                  
                  % initialize Qc flag
                  dataQc(idNoDef) = gl_set_qc(dataQc(idNoDef), g_decGl_qcGood);
                  eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                  testDoneList(11) = 1;
                  o_testDoneListAll(11, idNoDef) = 1;
                  
                  idToFlag = [];
                  
                  % DOXY tests should ignore DOXY_QC = 4, DOXY_ADJUSTED_QC = 3 and DOXY_ADJUSTED_QC = 4
                  if (idD == 1)
                     idDefOrBad = find((presData == presDataFillValue) | ...
                        (presDataQc == g_decGl_qcBad) | ...
                        (data == paramFillValue) | ...
                        (dataQc == g_decGl_qcBad));
                  else
                     idDefOrBad = find((presData == presDataFillValue) | ...
                        (presDataQc == g_decGl_qcCorrectable) | ...
                        (presDataQc == g_decGl_qcBad) | ...
                        (data == paramFillValue) | ...
                        (dataQc == g_decGl_qcCorrectable) | ...
                        (dataQc == g_decGl_qcBad));
                  end
                  idDefOrBad = [0 idDefOrBad length(data)+1];
                  for idSlice1 = 1:length(idDefOrBad)-1
                     
                     % part of continuous measurements
                     idLevel = idDefOrBad(idSlice1)+1:idDefOrBad(idSlice1+1)-1;
                     if (~isempty(idLevel))
                        
                        % spike and gradient test are applied on set of
                        % measurements with the same PHASE_NUMBER
                        uPhaseNumberBisForSlice = unique(phaseNumberBis(idLevel), 'stable');
                        for idSlice2 = 1:length(uPhaseNumberBisForSlice)
                           phaseNum = uPhaseNumberBisForSlice(idSlice2);
                           idMeasForPh = find(phaseNumberBis(idLevel) == phaseNum);
                           
                           % apply the test
                           if (length(idMeasForPh) > 2)
                              for id = 2:length(idMeasForPh)-1
                                 idL = idLevel(idMeasForPh(id));
                                 testVal = abs(data(idL)-(data(idL+1)+data(idL-1))/2);
                                 if (presData(idL) < 500)
                                    if (testVal > paramTestShallowDeep(idP, 1))
                                       idToFlag = [idToFlag idL];
                                    end
                                 else
                                    if (testVal > paramTestShallowDeep(idP, 2))
                                       idToFlag = [idToFlag idL];
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
                  
                  if (~isempty(idToFlag))
                     dataQc(idToFlag) = gl_set_qc(dataQc(idToFlag), g_decGl_qcBad);
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                     testFailedList(11) = 1;
                     o_testFailedListAll(11, idToFlag) = 1;
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 25: MEDian with a Distance (MEDD) test
%
if (testFlagList(25) == 1)
   
   % interpolate GPS locations at the measurement times
   idNodef = find(timeQc == g_decGl_qcGood);
   latMeas = nan(size(time));
   lonMeas = nan(size(time));
   
   idGpsNodef = find((timeGpsQc == g_decGl_qcGood) & (positionGpsQc == g_decGl_qcGood));
   timeGps2 = timeGps(idGpsNodef);
   latitudeGps2 = latitudeGps(idGpsNodef);
   longitudeGps2 = longitudeGps(idGpsNodef);
   
   if (length(latitudeGps2) > 1)
      latMeas(idNodef) = interp1q(timeGps2', latitudeGps2', time(idNodef)')';
      lonMeas(idNodef) = interp1q(timeGps2', longitudeGps2', time(idNodef)')';
   end
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2
      
      switch idLoop
         case 1
            paramNamePres = 'PRES';
            paramNameTemp = 'TEMP';
            paramNamePsal = 'PSAL';
         case 2
            paramNamePres = 'PRES2';
            paramNameTemp = 'TEMP2';
            paramNamePsal = 'PSAL2';
         otherwise
            fprintf('RTQC_ERROR: TEST025: Too many loops\n');
            continue
      end
      
      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;
            
            % retrieve PRES, TEMP and PSAL data from the workspace
            idPres = find(strcmp(paramNamePres, ncParamXNameList) == 1, 1);
            idTemp = find(strcmp(paramNameTemp, ncParamXNameList) == 1, 1);
            idPsal = '';
            if (~isempty(paramNamePsal))
               idPsal = find(strcmp(paramNamePsal, ncParamXNameList) == 1, 1);
            end
         else
            % adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;
            
            % retrieve PRES, TEMP and PSAL adjusted data from the workspace
            idPres = find(strcmp([paramNamePres '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idTemp = find(strcmp([paramNameTemp '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idPsal = '';
            if (~isempty(paramNamePsal))
               idPsal = find(strcmp([paramNamePsal '_ADJUSTED'], ncParamXNameList) == 1, 1);
            end
         end
         
         if (~isempty(idPres) && ~isempty(idTemp))
            
            presData = eval(ncParamXDataList{idPres});
            presDataQc = eval(ncParamXDataQcList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};
            
            tempData = eval(ncParamXDataList{idTemp});
            tempDataQc = eval(ncParamXDataQcList{idTemp});
            tempDataFillValue = ncParamXFillValueList{idTemp};
            
            psalData = [];
            if (~isempty(idPsal))
               psalData = eval(ncParamXDataList{idPsal});
               psalDataQc = eval(ncParamXDataQcList{idPsal});
               psalDataFillValue = ncParamXFillValueList{idPsal};
            end
            
            if (~isempty(presData) && ~isempty(tempData))
               
               % initialize Qc flags
               idNoDefTemp = find(tempData ~= tempDataFillValue);
               tempDataQc(idNoDefTemp) = gl_set_qc(tempDataQc(idNoDefTemp), g_decGl_qcGood);
               eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
               testDoneList(25) = 1;
               o_testDoneListAll(25, idNoDefTemp) = 1;
               
               if (~isempty(psalData))
                  idNoDefPsal = find(psalData ~= psalDataFillValue);
                  psalDataQc(idNoDefPsal) = gl_set_qc(psalDataQc(idNoDefPsal), g_decGl_qcGood);
                  eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);
                  testDoneList(25) = 1;
                  o_testDoneListAll(25, idNoDefPsal) = 1;
               end
               
               if (~isempty(psalData))
                  idNoDefAndGood = find((presData ~= presDataFillValue) & ...
                     (presDataQc ~= g_decGl_qcBad) & ...
                     (tempData ~= tempDataFillValue) & ...
                     (tempDataQc ~= g_decGl_qcBad) & ...
                     (psalData ~= psalDataFillValue) & ...
                     (psalDataQc ~= g_decGl_qcBad));
                  presDataOk = presData(idNoDefAndGood);
                  tempDataOk = tempData(idNoDefAndGood);
                  psalDataOk = psalData(idNoDefAndGood);
               else
                  idNoDefAndGood = find((presData ~= presDataFillValue) & ...
                     (presDataQc ~= g_decGl_qcBad) & ...
                     (tempData ~= tempDataFillValue) & ...
                     (tempDataQc ~= g_decGl_qcBad));
                  presDataOk = presData(idNoDefAndGood);
                  tempDataOk = tempData(idNoDefAndGood);
                  psalDataOk = nan(size(presDataOk));
               end
               
               if (~isempty(presDataOk) && ~isempty(tempDataOk))
                  if (any(~isnan(lonMeas(idNoDefAndGood)) & ~isnan(latMeas(idNoDefAndGood))))
                     
                     % apply the test
                     
                     % compute density using Seawater library
                     if (~isempty(psalData))
                        inSituDensity = potential_density_gsw(presDataOk, tempDataOk, psalDataOk, 0, lonMeas(idNoDefAndGood), latMeas(idNoDefAndGood));
                     else
                        inSituDensity = nan(size(tempDataOk));
                     end
                     
                     % apply MEDD test
                     [tempSpike, pSalSpike, ~, ~, ~, ~, ~, ~, ~, ~, ~ ,~, ~] = ...
                        QTRT_spike_check_MEDD_main(presDataOk', tempDataOk', psalDataOk', inSituDensity', latMeas(idNoDefAndGood));
                     
                     tempSpike(isnan(tempSpike)) = 0;
                     pSalSpike(isnan(pSalSpike)) = 0;
                     idTempToFlag = find(tempSpike == 1);
                     idPsalToFlag = find(pSalSpike == 1);
                     
                     if (~isempty(idTempToFlag))
                        % set Qc flags according to test results
                        tempDataQc(idNoDefAndGood(idTempToFlag)) = gl_set_qc(tempDataQc(idNoDefAndGood(idTempToFlag)), g_decGl_qcBad);
                        eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                        testFailedList(25) = 1;
                        o_testFailedListAll(25, idNoDefAndGood(idTempToFlag)) = 1;
                     end
                     
                     if (~isempty(psalData))
                        if (~isempty(idPsalToFlag))
                           % set Qc flags according to test results
                           psalDataQc(idNoDefAndGood(idPsalToFlag)) = gl_set_qc(psalDataQc(idNoDefAndGood(idPsalToFlag)), g_decGl_qcBad);
                           eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);
                           testFailedList(25) = 1;
                           o_testFailedListAll(25, idNoDefAndGood(idPsalToFlag)) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 57: DOXY specific test
%
if (testFlagList(57) == 1)
   
   % First specific test:
   % set DOXY_QC = '3'
   
   % list of parameters concerned by this test
   paramTestList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      for idP = 1:length(paramTestList)
         paramName = paramTestList{idP};
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         
         idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncParamXDataList{idParam});
            dataQc = eval(ncParamXDataQcList{idParam});
            paramFillValue = ncParamXFillValueList{idParam};
            
            idNoDef = find(data ~= paramFillValue);
            if (~isempty(idNoDef))
               
               % initialize Qc flag
               dataQc(idNoDef) = gl_set_qc(dataQc(idNoDef), g_decGl_qcCorrectable);
               eval([ncParamXDataQcList{idParam} ' = dataQc;']);
               
               testDoneList(57) = 1;
               o_testDoneListAll(57, idNoDef) = 1;
               
               testFailedList(57) = 1;
               o_testFailedListAll(57, idToFlag) = 1;
            end
         end
      end
   end
   
   % Second specific test:
   % if TEMP_QC=4 or PRES_QC=4, then DOXY_QC=4; if PSAL_QC=4, then DOXY_QC=3

   % list of parameters concerned by this test
   paramTestList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
         
         % retrieve PRES, TEMP and PSAL data from the workspace
         idPres = find(strcmp('PRES', ncParamXNameList) == 1, 1);
         idTemp = find(strcmp('TEMP', ncParamXNameList) == 1, 1);
         idPsal = find(strcmp('PSAL', ncParamXNameList) == 1, 1);
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
         
         % retrieve PRES, TEMP and PSAL data from the workspace
         idPres = find(strcmp('PRES_ADJUSTED', ncParamXNameList) == 1, 1);
         idTemp = find(strcmp('TEMP_ADJUSTED', ncParamXNameList) == 1, 1);
         idPsal = find(strcmp('PSAL_ADJUSTED', ncParamXNameList) == 1, 1);
      end
      
      if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
         
         presData = eval(ncParamXDataList{idPres});
         presDataQc = eval(ncParamXDataQcList{idPres});
         presDataFillValue = ncParamXFillValueList{idPres};
         
         tempData = eval(ncParamXDataList{idTemp});
         tempDataQc = eval(ncParamXDataQcList{idTemp});
         tempDataFillValue = ncParamXFillValueList{idTemp};
         
         psalData = eval(ncParamXDataList{idPsal});
         psalDataQc = eval(ncParamXDataQcList{idPsal});
         psalDataFillValue = ncParamXFillValueList{idPsal};
         
         for idP = 1:length(paramTestList)
            paramName = paramTestList{idP};
            if (idD == 2)
               paramName = [paramName '_ADJUSTED'];
            end
            
            idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
            if (~isempty(idParam))
               data = eval(ncParamXDataList{idParam});
               dataQc = eval(ncParamXDataQcList{idParam});
               paramFillValue = ncParamXFillValueList{idParam};
               
               idNoDef = find(data ~= paramFillValue);
               if (~isempty(idNoDef))
                  
                  % initialize Qc flag
                  % useless for DOXY_QC, which has been previously set to '3'
                  dataQc(idNoDef) = gl_set_qc(dataQc(idNoDef), g_decGl_qcGood);
                  eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                  
                  testDoneList(57) = 1;
                  o_testDoneListAll(57, idNoDef) = 1;
                  
                  % if PRES_QC=4, then DOXY_QC=4
                  if (~isempty(presData))

                     % apply the test
                     idNoDef = find((presData ~= presDataFillValue) & ...
                        (data ~= paramFillValue));
                     idToFlag = find((presDataQc(idNoDef) == g_decGl_qcBad));
                     if (~isempty(idToFlag))
                        dataQc(idNoDef(idToFlag)) = gl_set_qc(dataQc(idNoDef(idToFlag)), g_decGl_qcBad);
                        eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                        
                        testFailedList(57) = 1;
                        o_testFailedListAll(57, idNoDef(idToFlag)) = 1;
                     end
                  end
                     
                  % if TEMP_QC=4, then DOXY_QC=4
                  if (~isempty(tempData))

                     % process DESCENT and ASCENT phases only (because
                     % interpolation need the PRES to be monotonic)
                     uPhaseNumber = unique(phaseNumber(phaseNumber ~= 99999));
                     for idPhase = 1:length(uPhaseNumber)
                        idMeasForPhase = find(phaseNumber == uPhaseNumber(idPhase));
                        phaseDir = unique(phase(idMeasForPhase));
                        if ((phaseDir ~= g_decGl_phaseDescent) && ...
                              (phaseDir ~= g_decGl_phaseAscent))
                           continue
                        end
                        
                        % interpolate and extrapolate the CTD TEMP data at the pressures
                        % of the DOXY measurements
                        [tempDataInt, tempDataIntQc] = compute_interpolated_PARAM_measurements( ...
                           presData(idMeasForPhase), tempData(idMeasForPhase), tempDataQc(idMeasForPhase), presData(idMeasForPhase), ...
                           presDataFillValue, tempDataFillValue, presDataFillValue, phaseDir);
                        
                        % apply the test
                        idNoDef = find((tempDataInt ~= tempDataFillValue) & ...
                           (data(idMeasForPhase) ~= paramFillValue));
                        idToFlag = find((tempDataIntQc(idNoDef) == g_decGl_qcBad));
                        if (~isempty(idToFlag))
                           dataQc(idMeasForPhase(idNoDef(idToFlag))) = gl_set_qc(dataQc(idMeasForPhase(idNoDef(idToFlag))), g_decGl_qcBad);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           
                           testFailedList(57) = 1;
                           o_testFailedListAll(57, idMeasForPhase(idNoDef(idToFlag))) = 1;
                        end
                     end
                  end
                     
                  %  if PSAL_QC=4, then DOXY_QC=3
                  if (~isempty(psalData))

                     % process DESCENT and ASCENT phases only (because
                     % interpolation need the PRES to be monotonic)
                     uPhaseNumber = unique(phaseNumber(phaseNumber ~= 99999));
                     for idPhase = 1:length(uPhaseNumber)
                        idMeasForPhase = find(phaseNumber == uPhaseNumber(idPhase));
                        phaseDir = unique(phase(idMeasForPhase));
                        if ((phaseDir ~= g_decGl_phaseDescent) && ...
                              (phaseDir ~= g_decGl_phaseAscent))
                           continue
                        end
                        
                        % interpolate and extrapolate the CTD PSAL data at the pressures
                        % of the DOXY measurements
                        [psalDataInt, psalDataIntQc] = compute_interpolated_PARAM_measurements( ...
                           presData(idMeasForPhase), psalData(idMeasForPhase), psalDataQc(idMeasForPhase), presData(idMeasForPhase), ...
                           presDataFillValue, psalDataFillValue, presDataFillValue, phaseDir);
                        
                        % apply the test
                        idNoDef = find((psalDataInt ~= psalDataFillValue) & ...
                           (data(idMeasForPhase) ~= paramFillValue));
                        idToFlag = find(psalDataIntQc(idNoDef) == g_decGl_qcBad);
                        if (~isempty(idToFlag))
                           dataQc(idMeasForPhase(idNoDef(idToFlag))) = gl_set_qc(dataQc(idMeasForPhase(idNoDef(idToFlag))), g_decGl_qcCorrectable);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           
                           testFailedList(57) = 1;
                           o_testFailedListAll(57, idMeasForPhase(idNoDef(idToFlag))) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CNDC gliders
%
if (~isempty(find(strcmp('CNDC', ncParamNameList) == 1, 1)))
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2

      switch idLoop
         case 1
            paramNameTemp = 'TEMP';
            paramNamePsal = 'PSAL';
         case 2
            paramNameTemp = 'TEMP2';
            paramNamePsal = 'PSAL2';
         otherwise
            fprintf('RTQC_ERROR: CNDC gliders: Too many loops\n');
            continue
      end

      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing

            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;

            % retrieve TEMP and PSAL data from the workspace
            idTemp = find(strcmp(paramNameTemp, ncParamXNameList) == 1, 1);
            idPsal = find(strcmp(paramNamePsal, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing

            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;

            % retrieve TEMP and PSAL adjusted data from the workspace
            idTemp = find(strcmp([paramNameTemp '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idPsal = find(strcmp([paramNamePsal '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end

         if (~isempty(idTemp) && ~isempty(idPsal))

            tempData = eval(ncParamXDataList{idTemp});
            tempDataQc = eval(ncParamXDataQcList{idTemp});
            tempDataFillValue = ncParamXFillValueList{idTemp};

            psalData = eval(ncParamXDataList{idPsal});
            psalDataQc = eval(ncParamXDataQcList{idPsal});
            psalDataFillValue = ncParamXFillValueList{idPsal};

            if (~isempty(tempData) && ~isempty(psalData))

               % initialize Qc flags
               idNoDefPsal = find(psalData ~= psalDataFillValue);
               psalDataQc(idNoDefPsal) = gl_set_qc(psalDataQc(idNoDefPsal), g_decGl_qcGood);
               eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);

               idNoDef = find((tempData ~= tempDataFillValue) & (psalData ~= psalDataFillValue));
               tempDataQc = tempDataQc(idNoDef);

               % apply the test
               idToFlag = find((tempDataQc == g_decGl_qcCorrectable) | (tempDataQc == g_decGl_qcBad));
               if (~isempty(idToFlag))
                  psalDataQc(idNoDef(idToFlag)) = max(psalDataQc(idNoDef(idToFlag)), tempDataQc(idToFlag));
                  eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE THE REPORT HEX VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the report hex values
testDoneHex = gl_compute_qctest_hex(find(testDoneList == 1));
testFailedHex = gl_compute_qctest_hex(find(testFailedList == 1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE THE EGO NETCDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory to store temporary files
[ncEgoInputPath, ~, ~] = fileparts(a_ncEgoFilePathName);
DIR_TMP_FILE = [ncEgoInputPath '/tmp/'];

% delete the temp directory
gl_remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the input file to be updated
[~, fileName, fileExtension] = fileparts(a_ncEgoFilePathName);
tmpNcEgoOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
copyfile(a_ncEgoFilePathName, tmpNcEgoOutputPathFileName);

% create the list of data Qc to store in the NetCDF trajectory
dataQcList = [ ...
   {'TIME_QC'} {timeQc} ...
   {'POSITION_QC'} {positionQc} ...
   {'TIME_GPS_QC'} {timeGpsQc} ...
   {'POSITION_GPS_QC'} {positionGpsQc} ...
   ];
for idParam = 1:length(ncParamNameList)
   dataQcList = [dataQcList ...
      {upper(ncParamDataQcList{idParam})} {eval(ncParamDataQcList{idParam})} ...
      ];
end
for idParam = 1:length(ncParamAdjNameList)
   dataQcList = [dataQcList ...
      {upper(ncParamAdjDataQcList{idParam})} {eval(ncParamAdjDataQcList{idParam})} ...
      ];
end

% update the input file
[ok] = nc_update_file(tmpNcEgoOutputPathFileName, ...
   dataQcList, testDoneHex, testFailedHex);

if (ok == 1)
   
   % if the update succeeded move the file in the output directory
   [ncEgoOutputPath, ~, ~] = fileparts(a_ncEgoFilePathName);
   [~, fileName, fileExtension] = fileparts(tmpNcEgoOutputPathFileName);
   movefile(tmpNcEgoOutputPathFileName, [ncEgoOutputPath '/' fileName fileExtension]);
end

% delete the temp directory
gl_remove_directory(DIR_TMP_FILE);

return

% ------------------------------------------------------------------------------
% Update NetCDF EGO file after RTQC has been performed.
%
% SYNTAX :
%  [o_ok] = nc_update_file(a_egoFileName, a_dataQc, a_testDoneHex, a_testFailedHex)
%
% INPUT PARAMETERS :
%   a_egoFileName   : EGO file path name to update
%   a_dataQc        : QC data to store in the EGO file
%   a_testDoneHex   : HEX code of test performed on EGO file data
%   a_testFailedHex : HEX code of test failed on EGO file data
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function [o_ok] = nc_update_file(a_egoFileName, a_dataQc, a_testDoneHex, a_testFailedHex)

% output parameters initialization
o_ok = 0;

% program version
global g_decGl_rtqcVersion;


% modify the N_HISTORY dimension of the EGO file
[ok] = gl_update_n_history_dim_in_ego_file(a_egoFileName, 2);
if (ok == 0)
   fprintf('RTQC_ERROR: Unable to update the N_HISTORY dimension of the NetCDF file: %s\n', a_egoFileName);
   return
end

% date of the file update
dateUpdate = datestr(gl_now_utc, 'yyyymmddHHMMSS');

% update the EGO file

% retrieve data from profile file
wantedVars = [ ...
   {'HISTORY_INSTITUTION'} ...
   ];

[ncEgoData] = gl_get_data_from_nc_file(a_egoFileName, wantedVars);

% open the file to update
fCdf = netcdf.open(a_egoFileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', a_egoFileName);
   return
end

% update <PARAM>_QC values
for idParamQc = 1:2:length(a_dataQc)
   paramQcName = a_dataQc{idParamQc};
   if (gl_var_is_present(fCdf, paramQcName))
      dataQc = a_dataQc{idParamQc+1};
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), dataQc');
   end
end

% retrieve data to update global attributes
time = [];
if (gl_var_is_present(fCdf, 'TIME') && ...
      gl_var_is_present(fCdf, 'TIME_QC') && ...
      gl_att_is_present(fCdf, 'TIME', '_FillValue'))
   time = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   timeQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME'), '_FillValue');
   time(find((time == fillVal) | ((timeQc ~= 1) & (timeQc ~= 2)))) = [];
end
timeGps = [];
if (gl_var_is_present(fCdf, 'TIME_GPS') && ...
      gl_var_is_present(fCdf, 'TIME_GPS_QC') && ...
      gl_att_is_present(fCdf, 'TIME_GPS', '_FillValue'))
   timeGps = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'));
   timeGpsQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'), '_FillValue');
   timeGps(find((timeGps == fillVal) | ((timeGpsQc ~= 1) & (timeGpsQc ~= 2)))) = [];
end
time = [time; timeGps];

latitude = [];
if (gl_var_is_present(fCdf, 'LATITUDE') && ...
      gl_var_is_present(fCdf, 'POSITION_QC') && ...
      gl_att_is_present(fCdf, 'LATITUDE', '_FillValue'))
   latitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'));
   positionQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), '_FillValue');
   latitude(find((latitude == fillVal) | ((positionQc ~= 1) & (positionQc ~= 2)))) = [];
end
latitudeGps = [];
if (gl_var_is_present(fCdf, 'LATITUDE_GPS') && ...
      gl_var_is_present(fCdf, 'POSITION_GPS_QC') && ...
      gl_att_is_present(fCdf, 'LATITUDE_GPS', '_FillValue'))
   latitudeGps = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'));
   positionGpsQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_GPS_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'), '_FillValue');
   latitudeGps(find((latitudeGps == fillVal) | ((positionGpsQc ~= 1) & (positionGpsQc ~= 2)))) = [];
end
latitude = [latitude; latitudeGps];

longitude = [];
if (gl_var_is_present(fCdf, 'LONGITUDE') && ...
      gl_var_is_present(fCdf, 'POSITION_QC') && ...
      gl_att_is_present(fCdf, 'LONGITUDE', '_FillValue'))
   longitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'));
   positionQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), '_FillValue');
   longitude(find((longitude == fillVal) | ((positionQc ~= 1) & (positionQc ~= 2)))) = [];
end
longitudeGps = [];
if (gl_var_is_present(fCdf, 'LONGITUDE_GPS') && ...
      gl_var_is_present(fCdf, 'POSITION_GPS_QC') && ...
      gl_att_is_present(fCdf, 'LONGITUDE_GPS', '_FillValue'))
   longitudeGps = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'));
   positionGpsQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_GPS_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'), '_FillValue');
   longitudeGps(find((longitudeGps == fillVal) | ((positionGpsQc ~= 1) & (positionGpsQc ~= 2)))) = [];
end
longitude = [longitude; longitudeGps];

depth = [];
if (gl_var_is_present(fCdf, 'DEPTH') && ...
      gl_var_is_present(fCdf, 'DEPTH_QC') && ...
      gl_att_is_present(fCdf, 'DEPTH', '_FillValue'))
   depth = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPTH'));
   depthQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPTH_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'DEPTH'), '_FillValue');
   depth(find((depth == fillVal) | ((depthQc ~= 1) & (depthQc ~= 2)))) = [];
end
pres = [];
if (gl_var_is_present(fCdf, 'PRES') && ...
      gl_var_is_present(fCdf, 'PRES_QC') && ...
      gl_att_is_present(fCdf, 'PRES', '_FillValue'))
   pres = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
   presQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_QC'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
   pres(find((pres == fillVal) | ((presQc ~= 1) & (presQc ~= 2)))) = [];
end
depth = [depth; pres];

% update miscellaneous information
netcdf.reDef(fCdf);
globalVarId = netcdf.getConstant('NC_GLOBAL');

% update the 'date_update' global attribute
currentDate = datestr(gl_now_utc, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdf, globalVarId, 'date_update', currentDate);

% update the 'history' global attribute
attValue = [netcdf.getAtt(fCdf, globalVarId, 'history') '; ' ...
   currentDate ' ' ...
   sprintf('Processed RTQC tests (coriolis COQC software)')];
netcdf.putAtt(fCdf, globalVarId, 'history', attValue);

% update the 'geospatial_lat_min', 'geospatial_lat_max',
% 'geospatial_lon_min', 'geospatial_lon_max',
% 'geospatial_vertical_min', 'geospatial_vertical_max',
% 'time_coverage_start', 'time_coverage_end' global attributes
attValue = num2str(min(latitude));
netcdf.putAtt(fCdf, globalVarId, 'geospatial_lat_min', attValue);

attValue = num2str(max(latitude));
netcdf.putAtt(fCdf, globalVarId, 'geospatial_lat_max', attValue);

attValue = num2str(min(longitude));
netcdf.putAtt(fCdf, globalVarId, 'geospatial_lon_min', attValue);

attValue = num2str(max(longitude));
netcdf.putAtt(fCdf, globalVarId, 'geospatial_lon_max', attValue);

attValue = num2str(min(depth));
netcdf.putAtt(fCdf, globalVarId, 'geospatial_vertical_min', attValue);

attValue = num2str(max(depth));
netcdf.putAtt(fCdf, globalVarId, 'geospatial_vertical_max', attValue);

epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
attValue = datestr((min(time)/86400) + epoch_offset, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdf, globalVarId, 'time_coverage_start', attValue);

attValue = datestr((max(time)/86400) + epoch_offset, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdf, globalVarId, 'time_coverage_end', attValue);

netcdf.endDef(fCdf);

% update history information
historyInstitution = gl_get_data_from_name('HISTORY_INSTITUTION', ncEgoData);
[~, nHistory] = size(historyInstitution);
nHistory = nHistory - 1;
histoInstitution = 'IF';
histoStep = 'ARGQ';
histoSoftware = 'COQC';
histoSoftwareRelease = g_decGl_rtqcVersion;

for idHisto = 1:2
   if (idHisto == 1)
      histoAction = 'QCP$';
   else
      nHistory = nHistory + 1;
      histoAction = 'QCF$';
   end
   if (idHisto == 1)
      histoQcTest = a_testDoneHex;
   else
      histoQcTest = a_testFailedHex;
   end
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(histoInstitution)]), histoInstitution');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(histoStep)]), histoStep');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(histoSoftware)]), histoSoftware');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(histoSoftwareRelease)]), histoSoftwareRelease');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(dateUpdate)]), dateUpdate');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(dateUpdate)]), dateUpdate');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(histoAction)]), histoAction');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
      fliplr([nHistory-1 0]), ...
      fliplr([1 length(histoQcTest)]), histoQcTest');
end

netcdf.close(fCdf);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Check if locations are inside a given region (defined by a list of rectangles)
%
% SYNTAX :
%  [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)
%
% INPUT PARAMETERS :
%   a_lon    : locations longitude
%   a_lat    : locations latitude
%   a_region : region
%
% OUTPUT PARAMETERS :
%   o_inRegionFlag : in region flag (1 if in region, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)

% output parameters initialization
o_inRegionFlag = zeros(size(a_lon));

tabId = [];
for idR = 1:size(a_region, 1)
   region = a_region(idR, :);
   tabId = [tabId find((a_lat >= region(1)) & (a_lat <= region(2)) & (a_lon >= region(3)) & (a_lon <= region(4)))];
end

o_inRegionFlag(unique(tabId)) = 1;

return

% ------------------------------------------------------------------------------
% Interpolate the PARAM measurements of a CTD profile at given P levels.
%
% SYNTAX :
%  [o_paramInt, o_paramIntQc] = compute_interpolated_PARAM_measurements( ...
%    a_ctdPres, a_ctdParam, a_ctdParamQc, a_presInt, ...
%    a_ctdPresFv, a_ctdParamFv, a_presIntFv, a_phaseDir)
%
% INPUT PARAMETERS :
%   a_ctdPres    : CTD PRES profile measurements
%   a_ctdParam   : CTD PARAM profile measurements
%   a_ctdParam   : CTD PARAM profile QCs
%   a_presInt    : P levels of PARAM measurement interpolation
%   a_ctdPresFv  : fill value of CTD PRES profile measurements
%   a_ctdParamFv : fill value of CTD PARAM profile measurements
%   a_presIntFv  : fill value of P levels of PARAM measurement interpolation
%   a_phaseDir   : current phase value
%
% OUTPUT PARAMETERS :
%   o_paramInt   : CTD PARAM interpolated data
%   o_paramIntQc : CTD PARAM interpolated data QCs
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/13/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramInt, o_paramIntQc] = compute_interpolated_PARAM_measurements( ...
   a_ctdPres, a_ctdParam, a_ctdParamQc, a_presInt, ...
   a_ctdPresFv, a_ctdParamFv, a_presIntFv, a_phaseDir)

% QC flag values
global g_decGl_qcDef;
global g_decGl_qcBad;

% PHASE codes
global g_decGl_phaseAscent;

% output parameters initialization
o_paramInt = ones(size(a_presInt))*a_ctdParamFv;
o_paramIntQc = repmat(g_decGl_qcDef, size(a_presInt));


% get the measurement levels of output data
idNoDefOutput = find((a_presInt ~= a_presIntFv));

% interpolate the PARAM measurements at the output P levels
idNoDefInput = find((a_ctdPres ~= a_ctdPresFv) & (a_ctdParam ~= a_ctdParamFv));

if (~isempty(idNoDefInput))
   
   % get PRES and PARAM measurements
   ctdPres = a_ctdPres(idNoDefInput);
   ctdParam = a_ctdParam(idNoDefInput);
   ctdParamQc = a_ctdParamQc(idNoDefInput);
   
   if (length(ctdPres) > 1)
      
      if (a_phaseDir == g_decGl_phaseAscent)
         ctdPres = fliplr(ctdPres);
         ctdParam = fliplr(ctdParam);
         ctdParamQc = fliplr(ctdParamQc);
      end
      
      % consider increasing pressures only (we start the algorithm from the middle
      % of the profile)
      idToDelete = [];
      idStart = fix(length(ctdPres)/2);
      pMin = ctdPres(idStart);
      for id = idStart-1:-1:1
         if (ctdPres(id) >= pMin)
            idToDelete = [idToDelete id];
         else
            pMin = ctdPres(id);
         end
      end
      pMax = ctdPres(idStart);
      for id = idStart+1:length(ctdPres)
         if (ctdPres(id) <= pMax)
            idToDelete = [idToDelete id];
         else
            pMax = ctdPres(id);
         end
      end
      
      ctdPres(idToDelete) = [];
      ctdParam(idToDelete) = [];
      ctdParamQc(idToDelete) = [];
      
      if (~isempty(ctdPres))
         
         % duplicate PARAM values 10 dbar above the shallowest level
         ctdPres = [ctdPres(1)-10 ctdPres];
         ctdParam = [ctdParam(1) ctdParam];
         ctdParamQc = [ctdParamQc(1) ctdParamQc];
         
         % duplicate PARAM values 50 dbar below the deepest level
         ctdPres = [ctdPres ctdPres(end)+50];
         ctdParam = [ctdParam ctdParam(end)];
         ctdParamQc = [ctdParamQc ctdParamQc(end)];
      end
      
      if (a_phaseDir == g_decGl_phaseAscent)
         ctdPres = fliplr(ctdPres);
         ctdParam = fliplr(ctdParam);
         ctdParamQc = fliplr(ctdParamQc);
      end
   else
      o_paramInt(idNoDefOutput) = ctdParam;
      o_paramIntQc(idNoDefOutput) = ctdParamQc;
   end
   
   if (length(ctdPres) > 1)
      
      % interpolate T values
      paramInt = interp1(ctdPres, ...
         ctdParam, ...
         a_presInt(idNoDefOutput), 'linear');
      paramInt(isnan(paramInt)) = a_ctdParamFv;
      
      % interpolate T QC values
      ctdParamQcNum = zeros(size(ctdParam));
      ctdParamQcNum(find(ctdParamQc == g_decGl_qcBad)) = 1;
      
      paramIntQcNum = interp1(ctdPres, ...
         ctdParamQcNum, ...
         a_presInt(idNoDefOutput), 'linear');
      paramIntQcNum(isnan(paramIntQcNum)) = 0;
      
      paramIntQc = repmat(g_decGl_qcDef, size(paramIntQcNum));
      paramIntQc(find(paramIntQcNum ~= 0)) = g_decGl_qcBad;
      
      o_paramInt(idNoDefOutput) = paramInt;
      o_paramIntQc(idNoDefOutput) = paramIntQc;
   end
end

return
