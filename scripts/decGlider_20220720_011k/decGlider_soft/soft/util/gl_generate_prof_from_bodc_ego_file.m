% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from an EGO BODC NetCDF file.
%
% SYNTAX :
%  gl_generate_prof_from_bodc_ego_file(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments (all mandatory)
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'egofile'  : input EGO nc file (file path name)
%      'wmo'      : WMO number for the output profiles
%      'outputdir': directory to store output profiles
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function gl_generate_prof_from_bodc_ego_file(varargin)

% directory of the output profile files
OUTPUT_DATA_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\data_processing\mantis_25670_ego_files_from_bodc\bodc\output';

% directory to store log file
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';

% default values initialization
gl_init_default_values;


% create log file
logFile = [LOG_DIRECTORY '/' 'gl_generate_prof_from_bodc_ego_file_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
egoFilePathName = [];
wmoNumber = [];
profOutputDirName = OUTPUT_DATA_DIRECTORY;
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'egofile'))
            egoFilePathName = varargin{id+1};
         elseif (strcmpi(varargin{id}, 'wmo'))
            wmoNumber = varargin{id+1};
         elseif (strcmpi(varargin{id}, 'outputdir'))
            profOutputDirName = varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
      
      if (isempty(egoFilePathName) || isempty(profOutputDirName))
         fprintf('ERROR: missing mandatory arguments\n');
         fprintf('INFO: expected mandatory arguments\n');
         fprintf('      ''egofile'' : input EGO nc file (file path name)\n');
         fprintf('      ''outputdir'' : directory to store output profiles\n');
         return
      end
   end
end

% print the arguments understanding
fprintf('\nINFO: EGO file to process: %s\n', egoFilePathName);
fprintf('INFO: output directory: %s\n\n', profOutputDirName);

% check inputs
if ~(exist(egoFilePathName, 'file') == 2)
   fprintf('ERROR: EGO file not found: %s\n', egoFilePathName);
   return
end
if ~(exist(profOutputDirName, 'dir') == 7)
   [status, ~, ~] = mkdir(profOutputDirName);
   if (status == 1)
      fprintf('INFO: directory created: %s\n', profOutputDirName);
   else
      fprintf('ERROR: Cannot create directory: %s\n', egoFilePathName);
      return
   end
end

% create output directory for the current file
[~, egoFileName, ~] = fileparts(egoFilePathName);
profOutputDirName = [profOutputDirName '/' egoFileName '/'];
if ~(exist(profOutputDirName, 'dir') == 7)
   [status, ~, ~] = mkdir(profOutputDirName);
   if (status == 1)
      fprintf('INFO: directory created: %s\n', profOutputDirName);
   else
      fprintf('ERROR: Cannot create directory: %s\n', egoFilePathName);
      return
   end
end

% retrieve variable mapping from dedicated file
mapFileName = [egoFilePathName(1:end-3) '_map.txt'];
if ~(exist(mapFileName, 'file') == 2)
   fprintf('ERROR: Mapping file not found: %s\n', mapFileName);
   return
end
[parameterList] = get_glider_2_ego_var_link(mapFileName);

% generate the profiles
generate_prof_from_bodc_ego_file( ...
   egoFilePathName, profOutputDirName, parameterList, wmoNumber)

diary off;

return

% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from an EGO BODC NetCDF file.
%
% SYNTAX :
%  generate_prof_from_bodc_ego_file( ...
%    a_ncEgoFileName, a_outputDirName, a_parameterList, a_wmoNumber)
%
% INPUT PARAMETERS :
%   a_ncEgoFileName : EGO BODC NetCDF file path name
%   a_outputDirName : directory of the generated NetCDF files
%   a_parameterList : list of parameters to consider in the input file and
%                     associated names for the output files
%   a_wmoNumber     : WMO number for the output profiles
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_prof_from_bodc_ego_file( ...
   a_ncEgoFileName, a_outputDirName, a_parameterList, a_wmoNumber)

% phase codes
CODE_DESCENT = int8(1);
CODE_ASCENT = int8(4);

% generate a csv file of profile data (before and after the BIO data association
% to CTD levels)
GENERATE_CSV_FILES = 0;

% minimum length of a profile
NB_BIN_FOR_PROFILE = 10;


% check if the file exists
if (~exist(a_ncEgoFileName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_ncEgoFileName);
   return
end

% open NetCDF file
fCdf = netcdf.open(a_ncEgoFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncEgoFileName);
   return
end

% retrieve PHASE information
phaseData = [];
phaseNumData = [];
if (gl_var_is_present(fCdf, 'PHASE') && gl_var_is_present(fCdf, 'PHASE_NUMBER'))
   phaseData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PHASE'), '_FillValue');
   if ((length(unique(phaseData)) == 1) && (unique(phaseData) == fillVal))
      phaseData = [];
   end
   phaseNumData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'), '_FillValue');
   if ((length(unique(phaseNumData)) == 1) && (unique(phaseNumData) == fillVal))
      phaseNumData = [];
   end
end

% if PHASE information is missing, compute PHASE and PHASE_NUMBER data
if (isempty(phaseData) || isempty(phaseNumData))
   fprintf('WARNING: PHASE information is missing => we compute PHASE and PHASE_NUMBER data\n');
   if (gl_var_is_present(fCdf, 'PRES') && gl_var_is_present(fCdf, 'TIME'))
      presData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
      if (gl_att_is_present(fCdf, 'PRES', '_FillValue'))
         presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
      else
         presFillVal = [];
      end
      timeData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   else
      fprintf('ERROR: Unable to get ''PRES'' and ''TIME'' data in NetCDF input file: %s\n', a_ncEgoFileName);
      netcdf.close(fCdf);
      return
   end
   
   [phaseData, phaseNumData] = gl_compute_phase(timeData, presData, presFillVal);
end

% retrieve the JULD data
paramJuldName = 'JULD';
paramJuldDef = [];
paramJuldData = [];
paramDef = gl_get_netcdf_param_attributes(paramJuldName);
if (~isempty(paramDef))
   if (gl_var_is_present(fCdf, paramJuldName))
      paramJuldDef = paramDef;
      paramJuldData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramJuldName));
   else
      fprintf('WARNING: Variable %s not present in file : %s\n', ...
         paramJuldName, a_ncEgoFileName);
   end
end

% read and store the variable data (of the parameters listed in the mapping
% file)
tabParamName = [];
tabParamDef = [];
tabParamData = [];
for idParam = 1:length(a_parameterList)
   param = a_parameterList{idParam};
   paramNameIn = strtrim(param{1});
   paramNameOut = strtrim(param{2});
   paramDef = gl_get_netcdf_param_attributes(paramNameOut);
   if (~isempty(paramDef))
      if (gl_var_is_present(fCdf, paramNameIn))
         tabParamName{end+1} = paramNameOut;
         tabParamDef = [tabParamDef paramDef];
         
         paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramNameIn));
         fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramNameIn), '_FillValue');
         paramData(find(paramData == fillVal)) = paramDef.fillValue;
         tabParamData = [tabParamData paramData];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            paramNameIn, a_ncEgoFileName);
      end
   end
end

% abort if no profile can be generated
if (isempty(phaseNumData))
   fprintf('INFO: No profile to generate from EGO nc file : %s\n', ...
      a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end

% compute the indices of the profile measurements
tabStart = [];
tabStop = [];
tabDir = [];
idSplit = find(diff(phaseNumData) ~= 0);
idStart = 1;
for id = 1:length(idSplit)+1
   if (id <= length(idSplit))
      idStop = idSplit(id);
   else
      idStop = length(phaseData);
   end
   phase = unique(phaseData(idStart:idStop));
   if ((phase == CODE_DESCENT) || (phase == CODE_ASCENT))
      tabStart = [tabStart; idStart];
      tabStop = [tabStop; idStop];
      if (phase == CODE_DESCENT)
         tabDir = [tabDir 'D'];
      else
         tabDir = [tabDir 'A'];
      end
   end
   idStart = idStop + 1;
end

% abort if no profile can be generated
if (isempty(tabStart))
   fprintf('INFO: No profile to generate from EGO nc file : %s\n', ...
      a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end

% retrieve the GPS position data
tabGpsPosDate = [];
tabGpsPosLon = [];
tabGpsPosLat = [];
tabMeasPosDate = [];
tabMeasPosLon = [];
tabMeasPosLat = [];
if (gl_var_is_present(fCdf, 'TIME') && ...
      gl_var_is_present(fCdf, 'LONGITUDE_GPS') && ...
      gl_var_is_present(fCdf, 'LATITUDE_GPS'))
   tabGpsPosDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   
   tabGpsPosLon = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'));
   fillValGpsPosLon = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'), '_FillValue');
   
   tabGpsPosLat = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'));
   fillValtabGpsPosLat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'), '_FillValue');
   
   idDel = find((tabGpsPosLon == fillValGpsPosLon) | (tabGpsPosLat == fillValtabGpsPosLat));
   tabGpsPosDate(idDel) = [];
   tabGpsPosLon(idDel) = [];
   tabGpsPosLat(idDel) = [];
end

% interpolate the GPS position data for all the TIME times
if (~isempty(tabGpsPosDate))
   tabMeasPosDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   fillValPosLon = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), '_FillValue');
   fillValPosLat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), '_FillValue');
   
   tabMeasPosLon = ones(length(tabMeasPosDate), 1)*fillValPosLon;
   tabMeasPosLat = ones(length(tabMeasPosDate), 1)*fillValPosLat;
   
   [tabMeasPosDate, idSort] = sort(tabMeasPosDate);
   tabMeasPosLon = tabMeasPosLon(idSort);
   tabMeasPosLat = tabMeasPosLat(idSort);
   
   if (length(tabMeasPosLon) > 1)
      tabMeasPosLon = interp1q(tabGpsPosDate, tabGpsPosLon, tabMeasPosDate);
      tabMeasPosLat = interp1q(tabGpsPosDate, tabGpsPosLat, tabMeasPosDate);
      
      tabMeasPosLon(find(isnan(tabMeasPosLon))) = fillValPosLon;
      tabMeasPosLat(find(isnan(tabMeasPosLat))) = fillValPosLat;
   end
end

% find the CTD levels
ctdLevels = [];
presData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
if (gl_att_is_present(fCdf, 'PRES', '_FillValue'))
   presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
   ctdLevels = find(presData ~= presFillVal);
end

% retrieve the time of the parameter measurements
time = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));

% store the profile data in structures
tabProfiles = [];
cyNum = 1;
for idProf = 1:length(tabStart)
   
   fprintf('Computing profile #%d\n', idProf);
   
   idStart = tabStart(idProf);
   idStop = tabStop(idProf);
   
   if (idStop-idStart+1 < NB_BIN_FOR_PROFILE)
      fprintf('N_LEVELS = %d < %d => profile file not generated\n', ...
         idStop-idStart+1, NB_BIN_FOR_PROFILE);
      continue
   end
   
   measPosDate = [];
   measPosDateOnly = [];
   if (~isempty(tabMeasPosDate))
      
      measPosDate = tabMeasPosDate(idStart:idStop);
      measPosLon = tabMeasPosLon(idStart:idStop);
      measPosLat = tabMeasPosLat(idStart:idStop);
      
      lonFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), '_FillValue');
      latFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), '_FillValue');
      
      measPosDateOnly = measPosDate;
      
      offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      measPosDateOnly = measPosDateOnly/86400 + offset;
      
      idDel = find((measPosLon == lonFillVal) | (measPosLat == latFillVal));
      
      measPosDate(idDel) = [];
      measPosLon(idDel) = [];
      measPosLat(idDel) = [];
      
      offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      measPosDate = measPosDate/86400 + offset;
   end
   
   % create the profile structure
   profStruct = gl_get_profile_init_struct;
   
   % fill the structure
   profStruct.cycleNumber = cyNum;
   cyNum = cyNum + 1;
   profStruct.decodedProfileNumber = 1;
   profStruct.profileNumber = 1;
   profStruct.primarySamplingProfileFlag = 1;
   profStruct.phaseNumber = -1;
   profStruct.direction = tabDir(idProf);
   
   if (~isempty(measPosDateOnly))
      
      % profile date
      profStruct.date = mean(measPosDateOnly);
      
      % profile location
      if (~isempty(measPosDate))
         [~, minId] = min(abs(measPosDate-profStruct.date));
         profStruct.locationDate = measPosDate(minId);
         profStruct.locationLon = measPosLon(minId);
         profStruct.locationLat = measPosLat(minId);
         profStruct.locationQc = '8';
         profStruct.posSystem = 'GPS';
      end
   end
   
   % parameter definitions for this profile
   profStruct.paramList = tabParamDef;
   profStruct.dateList = paramJuldDef;
   
   % parameter measurements
   profParam = tabParamData(idStart:idStop, :);
   
   % compute PSAL parameter
   pres = [];
   temp = [];
   cndc = [];
   for idParam = 1:size(profParam, 2)
      paramName = tabParamDef(idParam).name;
      if (strcmp(paramName, 'PRES'))
         pres = profParam(:, idParam);
         presFillVal = tabParamDef(idParam).fillValue;
      elseif (strcmp(paramName, 'TEMP'))
         temp = profParam(:, idParam);
         tempFillVal = tabParamDef(idParam).fillValue;
      elseif (strcmp(paramName, 'CNDC'))
         cndc = profParam(:, idParam);
         cndcFillVal = tabParamDef(idParam).fillValue;
      end
      if (~isempty(pres) && ~isempty(temp) && ~isempty(cndc))
         break
      end
   end
   if (~isempty(pres) && ~isempty(temp) && ~isempty(cndc))
      psalParamDef = gl_get_netcdf_param_attributes('PSAL');
      psal = ones(size(pres))*psalParamDef.fillValue;
      
      idNoFill = find((pres ~= presFillVal) & (temp ~= tempFillVal) & (cndc ~= cndcFillVal));
      for id = 1:length(idNoFill)
         psalValue = gl_compute_salinity(pres(idNoFill(id)), ...
            temp(idNoFill(id)), cndc(idNoFill(id))*10);
         % psalValue can be complex (due to bad noisy data), store only real values
         if (isreal(psalValue))
            psal(idNoFill(id)) = psalValue;
         end
      end
   
      profStruct.paramList = [profStruct.paramList psalParamDef];
      profParam = [profParam psal];
   end
   
   if (GENERATE_CSV_FILES)
      outputFileName = ['./' 'PROF_' num2str(idProf) '_all_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
         return
      end
      
      fprintf(fidOut, 'JULD');
      fprintf(fidOut, ';%s', profStruct.paramList(:).name);
      fprintf(fidOut, '\n');
      
      juld = paramJuldData(idStart:idStop);
      for idL = 1:size(profParam, 1)
         fprintf(fidOut, '%s;', gl_julian_2_gregorian(juld(idL)));
         fprintf(fidOut, '%g;', profParam(idL, 1:end));
         fprintf(fidOut, '\n');
      end
      
      fclose(fidOut);
   end
   
   % attach all the parameter measurements to the bin levels of the CTD
   
   idProfCtdLevels = find(ismember(ctdLevels, idStart:idStop));
   profCtdLevels = ctdLevels(idProfCtdLevels);
   
   for idParam = 1:size(profParam, 2)
      paramName = profStruct.paramList(idParam).name;
      
      timeData = time(idStart:idStop);
      data = profParam(:, idParam);
      dataFillVal = profStruct.paramList(idParam).fillValue;
      idDel = find(data == dataFillVal);
      timeData(idDel) = [];
      data(idDel) = [];
      
      usedLevel = zeros(length(idProfCtdLevels), 1);
      timeDiff = ones(length(idProfCtdLevels), 1)*-1;
      dataNew = ones(length(idProfCtdLevels), 1)*dataFillVal;
      for idData = 1:length(data)
         
         if (data(idData) == dataFillVal)
            continue
         end
         
         % find the timely closest CTD bin to assign the measurements
         idF1 = find(timeData(idData) >= time(profCtdLevels), 1, 'last');
         idF2 = find(timeData(idData) <= time(profCtdLevels), 1, 'first');
         if (idF1 == idF2)
            idMin = idF1;
            minVal = 0;
         else
            if (abs(time(profCtdLevels(idF1)) - timeData(idData)) < ...
                  abs(time(profCtdLevels(idF2)) - timeData(idData)))
               idMin = idF1;
               minVal = abs(time(profCtdLevels(idF1)) - timeData(idData));
            else
               idMin = idF2;
               minVal = abs(time(profCtdLevels(idF2)) - timeData(idData));
            end
         end
         %          [minVal, idMin] = min(abs(time(profCtdLevels) - timeData(idData)));
         if (usedLevel(idMin) == 0)
            dataNew(idMin) = data(idData);
            usedLevel(idMin) = 1;
            timeDiff(idMin) = minVal;
         else
            if (timeDiff(idMin) > minVal)
               dataNew(idMin) = data(idData);
               timeDiff(idMin) = minVal;
            end
            fprintf('WARNING: one %s measurement ignored during the CTD level assigment process of the Argo profile generation\n', ...
               paramName);
         end
         
         % store the processed data
         profParam(1:length(profCtdLevels), idParam) = dataNew;
      end
   end
   profStruct.data = profParam(1:length(profCtdLevels), :);
   profStruct.dataQc = repmat(' ', size(profStruct.data));
   profStruct.dates = paramJuldData(profCtdLevels);
   
   if (GENERATE_CSV_FILES)
      outputFileName = ['./' 'PROF_' num2str(idProf) '_min_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
         return
      end
      
      fprintf(fidOut, 'JULD');
      fprintf(fidOut, ';%s', tabParamDef(:).name);
      fprintf(fidOut, '\n');
      
      juld = profStruct.dates;
      for idL = 1:size(profStruct.data, 1)
         fprintf(fidOut, '%s;', gl_julian_2_gregorian(juld(idL)));
         fprintf(fidOut, '%g;', profStruct.data(idL, 1:end));
         fprintf(fidOut, '\n');
      end
      
      fclose(fidOut);
   end
   
   % measurement dates
   dates = profStruct.dates;
   dates(find(dates == paramJuldDef.fillValue)) = [];
   profStruct.minMeasDate = min(dates);
   profStruct.maxMeasDate = max(dates);
   
   % retrieve and store additional meta-data
   tabMetaData = [];
   if (gl_att_is_present(fCdf, [], 'wmo_platform_code'))
      wmoPlatformCode = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'wmo_platform_code'));
      if (~isempty(deblank(wmoPlatformCode)))
         tabMetaData = [tabMetaData {'PLATFORM_NUMBER'} {wmoPlatformCode}];
      else
         tabMetaData = [tabMetaData {'PLATFORM_NUMBER'} {a_wmoNumber}];
      end
   end
   if (gl_var_is_present(fCdf, 'PROJECT_NAME'))
      projectName = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PROJECT_NAME'))');
      if (~isempty(deblank(projectName)))
         tabMetaData = [tabMetaData {'PROJECT_NAME'} {projectName}];
      end
   end
   if (gl_var_is_present(fCdf, 'PI_NAME'))
      piName = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PI_NAME'))');
      if (~isempty(deblank(piName)))
         tabMetaData = [tabMetaData {'PI_NAME'} {piName}];
      end
   end
   if (gl_var_is_present(fCdf, 'DATA_CENTRE'))
      dataCentre = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_CENTRE'))');
      if (~isempty(deblank(dataCentre)))
         tabMetaData = [tabMetaData {'DATA_CENTRE'} {dataCentre}];
      end
   end
   platformCode = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'platform_code'));
   tabMetaData = [tabMetaData {'INST_REFERENCE'} {platformCode}];
   if (gl_var_is_present(fCdf, 'FIRMWARE_VERSION_NAVIGATION'))
      firmwareVersion = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'FIRMWARE_VERSION_NAVIGATION'))');
      if (~isempty(deblank(firmwareVersion)))
         tabMetaData = [tabMetaData {'FIRMWARE_VERSION'} {firmwareVersion}];
      end
   end
   if (gl_var_is_present(fCdf, 'WMO_INST_TYPE'))
      wmoInstType = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'WMO_INST_TYPE'))');
      if (~isempty(deblank(wmoInstType)))
         tabMetaData = [tabMetaData {'WMO_INST_TYPE'} {wmoInstType}];
      end
   end
   
   tabProfiles = [tabProfiles profStruct];
end

% create the base file name of the NetCDF profile files
gliderId = [];
if (gl_att_is_present(fCdf, [], 'wmo_platform_code'))
   gliderId = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'wmo_platform_code'));
   if (isempty(deblank(gliderId)))
      gliderId = a_wmoNumber;
   end
end
if (isempty(gliderId))
   gliderId = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'platform_code'));
end
deploymentStartDate = [];
if (gl_var_is_present(fCdf, 'DEPLOYMENT_START_DATE'))
   deploymentStartDate = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPLOYMENT_START_DATE'))');
   if (~isempty(deploymentStartDate))
      deploymentStartDate = deploymentStartDate(1:8);
   end
end
if (isempty(deploymentStartDate))
   deploymentStartDate = '99999999';
end
baseFileName = [gliderId '_' deploymentStartDate];

% generate the NetCDF Argo PROF files
gl_create_nc_mono_prof_files_3_0(tabProfiles, tabMetaData, a_outputDirName, baseFileName);

netcdf.close(fCdf);

return

% ------------------------------------------------------------------------------
% Read a mapping file and return the glider variable 2 EGO variable association.
%
% SYNTAX :
%  [o_parameterList] = get_glider_2_ego_var_link(a_mapFileName)
%
% INPUT PARAMETERS :
%   a_mapFileName : mapping file path name
%
% OUTPUT PARAMETERS :
%   o_parameterList : glider variable 2 EGO variable association
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parameterList] = get_glider_2_ego_var_link(a_mapFileName)

% output data initialization
o_parameterList = [];


% check if the file exists
if (~exist(a_mapFileName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_mapFileName);
   return
end

% open the mapping file
fIdIn = fopen(a_mapFileName, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_mapFileName);
   return
end

% read the variables
lineNum = 0;
while (1)
   line = fgetl(fIdIn);
   lineNum = lineNum + 1;
   if (isempty(line))
      continue
   end
   if (line == -1)
      break
   end
   var = textscan(line, '%s');
   if (size(var{:}, 1) == 2)
      o_parameterList{end+1} = var{:}';
   else
      fprintf('ERROR: Line#%d ignored: ''%s''\n', lineNum, line);
   end
end

fclose(fIdIn);

return
