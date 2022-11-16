% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from an EGO Socib NetCDF file.
%
% SYNTAX :
%  gl_generate_prof_from_socib_ego_file(varargin)
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
%   04/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function gl_generate_prof_from_socib_ego_file(varargin)

% directory of the output profile files
OUTPUT_DATA_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\data_processing\mantis_25832_ego_files_from_socib\EGO_socib\output\';

% directory to store log file
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';

% parameters to export
parameterList = [ ...
   {'pressure'} {'PRES'}; ...
   {'temperature'} {'TEMP'}; ...
   {'temperature_corrected_thermal'} {'TEMP_ADJUSTED'}; ...
   {'conductivity'} {'CNDC'}; ...
   {'conductivity_corrected_thermal'} {'CNDC_ADJUSTED'}; ...
   {'salinity'} {'PSAL'}; ...
   {'salinity_corrected_thermal'} {'PSAL_ADJUSTED'}; ...
   {'oxygen_concentration'} {'MOLAR_DOXY'}; ...
   {'temperature_oxygen'} {'TEMP_DOXY'}; ...
   {'chlorophyll'} {'CHLA'}; ...
   {'turbidity'} {'TURBIDITY'}; ...
   {'cdom'} {'CDOM'} ...
   ];

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

% create log file
[~, egoFileName, ~] = fileparts(egoFilePathName);
logFile = [LOG_DIRECTORY '/' 'gl_generate_prof_from_socib_ego_file_' egoFileName '_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);
tic;

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
      fprintf('ERROR: cannot create directory: %s\n', egoFilePathName);
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

% generate the profiles
generate_prof_from_socib_ego_file( ...
   egoFilePathName, profOutputDirName, parameterList, wmoNumber)

% export data in a CSV file
% export_csv_socib_ego_file(egoFilePathName)

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from an EGO Socib NetCDF file.
%
% SYNTAX :
%  generate_prof_from_socib_ego_file( ...
%    a_ncEgoFileName, a_outputDirName, a_parameterList, a_wmoNumber)
%
% INPUT PARAMETERS :
%   a_ncEgoFileName : EGO Socib NetCDF file path name
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
%   04/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_prof_from_socib_ego_file( ...
   a_ncEgoFileName, a_outputDirName, a_parameterList, a_wmoNumber)

% default values initialization
gl_init_default_values;

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

% compute PHASE and PHASE_NUMBER data
if (gl_var_is_present(fCdf, 'pressure') && gl_var_is_present(fCdf, 'TIME'))
   presData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'pressure'));
   if (gl_att_is_present(fCdf, 'pressure', '_FillValue'))
      presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'pressure'), '_FillValue');
   else
      presFillVal = [];
   end
   timeData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
else
   fprintf('ERROR: Unable to get ''pressure'' and ''TIME'' data in NetCDF input file: %s\n', a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end
[phaseData, phaseNumData] = gl_compute_phase(timeData, presData, presFillVal);

% create JULD from TIME
paramJuldName = 'JULD';
paramJuldDef = [];
paramJuldData = [];
paramDef = gl_get_netcdf_param_attributes(paramJuldName);
if (~isempty(paramDef))
   paramNameIn = 'TIME';
   paramNameOut = 'JULD';
   if (gl_var_is_present(fCdf, paramNameIn))
      paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramNameIn));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramNameIn), '_FillValue');
      paramData(find(paramData == fillVal)) = paramDef.fillValue;
      
      paramJuldDef = paramDef;
      paramJuldData = paramData;
      
      offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      idNoFillval = find(paramJuldData ~= paramDef.fillValue);
      paramJuldData(idNoFillval) = paramJuldData(idNoFillval)/86400 + offset;
   else
      fprintf('WARNING: Variable %s not present in file : %s\n', ...
         paramNameIn, a_ncEgoFileName);
   end
end

% read and store the variable data (of the parameters listed in the mapping
% file)
tabParamName = [];
tabParamDef = [];
tabParamData = [];
for idParam = 1:size(a_parameterList, 1)
   paramNameIn = strtrim(a_parameterList{idParam, 1});
   paramNameOut = strtrim(a_parameterList{idParam, 2});
   if ((length(paramNameOut) > 9) && strcmp(paramNameOut(end-8:end), '_ADJUSTED'))
      paramDef = gl_get_netcdf_param_attributes(paramNameOut(1:end-9));
      paramDef.name = paramNameOut;
   else
      paramDef = gl_get_netcdf_param_attributes(paramNameOut);
   end
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
      gl_var_is_present(fCdf, 'LONGITUDE') && ...
      gl_var_is_present(fCdf, 'LATITUDE'))
   tabGpsPosDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   
   tabGpsPosLon = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'));
   fillValGpsPosLon = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), '_FillValue');
   
   tabGpsPosLat = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'));
   fillValtabGpsPosLat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), '_FillValue');
   
   idDel = find((tabGpsPosLon == fillValGpsPosLon) | (tabGpsPosLat == fillValtabGpsPosLat));
   tabGpsPosDate(idDel) = [];
   tabGpsPosLon(idDel) = [];
   tabGpsPosLat(idDel) = [];
end

% interpolate the GPS position data for all the TIME times
if (~isempty(tabGpsPosDate))
   tabMeasPosDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   fillValPosLon = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'longitude'), '_FillValue');
   fillValPosLat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'latitude'), '_FillValue');
   
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
presData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'pressure'));
if (gl_att_is_present(fCdf, 'pressure', '_FillValue'))
   presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'pressure'), '_FillValue');
   ctdLevels = find(presData ~= presFillVal);
end

% retrieve the time of the parameter measurements
time = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));

% store the profile data in structures
tabProfiles = [];
cyNum = 1;
for idProf = 1:length(tabStart)
      
   idStart = tabStart(idProf);
   idStop = tabStop(idProf);

   idProfCtdLevels = find(ismember(ctdLevels, idStart:idStop));

   if (length(idProfCtdLevels) < NB_BIN_FOR_PROFILE)
      fprintf('Profile Id %d: N_LEVELS = %d < %d => profile file not generated\n', ...
         idProf, length(idProfCtdLevels), NB_BIN_FOR_PROFILE);
      continue
   end
   
   fprintf('Computing profile #%d (N_LEVELS = %d)\n', cyNum, length(idProfCtdLevels));
   
   measPosDate = [];
   if (~isempty(tabMeasPosDate))
      
      measPosDate = tabMeasPosDate(idStart:idStop);
      measPosLon = tabMeasPosLon(idStart:idStop);
      measPosLat = tabMeasPosLat(idStart:idStop);
      
      dateFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME'), '_FillValue');
      lonFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'longitude'), '_FillValue');
      latFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'latitude'), '_FillValue');
      
      measPosDateOnly = measPosDate;
      idDel = find(measPosDateOnly == dateFillVal);
      measPosDateOnly(idDel) = [];
      
      offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      measPosDateOnly = measPosDateOnly/86400 + offset;
      
      idDel = find((measPosDate == dateFillVal) | (measPosLon == lonFillVal) | (measPosLat == latFillVal));
      
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
         [minVal, minId] = min(abs(measPosDate-profStruct.date));
         profStruct.locationDate = measPosDate(minId);
         profStruct.locationLon = measPosLon(minId);
         profStruct.locationLat = measPosLat(minId);
         profStruct.locationQc = '8';
         profStruct.posSystem = 'GPS';
      end
   end
   
   % parameter definitions
   profStruct.paramList = tabParamDef;
   profStruct.dateList = paramJuldDef;
   
   % parameter measurements
   profParam = tabParamData(idStart:idStop, :);
   
   if (GENERATE_CSV_FILES)
      outputFileName = ['./' 'PROF_' num2str(cyNum-1) '_all_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
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
      nbLost = 0;
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
            nbLost = nbLost + 1;
         end
         
         % store the processed data
         profParam(1:length(profCtdLevels), idParam) = dataNew;
      end
      if (nbLost > 0)
         fprintf('WARNING: %d %s measurement ignored during the CTD level assigment process of the Argo profile generation\n', ...
            nbLost, paramName);
      end
   end
   profStruct.data = profParam(1:length(profCtdLevels), :);
   
   % compute DOXY parameter
   profParam = profStruct.data;
   pres = [];
   temp = [];
   psal = [];
   molarDoxy = [];
   for idParam = 1:size(profParam, 2)
      paramName = tabParamDef(idParam).name;
      if (strcmp(paramName, 'PRES'))
         pres = profParam(:, idParam);
         presFillVal = tabParamDef(idParam).fillValue;
      elseif (strcmp(paramName, 'TEMP'))
         temp = profParam(:, idParam);
         tempFillVal = tabParamDef(idParam).fillValue;
      elseif (strcmp(paramName, 'PSAL'))
         psal = profParam(:, idParam);
         psalFillVal = tabParamDef(idParam).fillValue;
      elseif (strcmp(paramName, 'MOLAR_DOXY'))
         molarDoxy = profParam(:, idParam);
         molarDoxyFillVal = tabParamDef(idParam).fillValue;
      end
      if (~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ~isempty(molarDoxy))
         break
      end
   end
   if (~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ~isempty(molarDoxy))
      doxyParamDef = gl_get_netcdf_param_attributes('DOXY');
      doxy = ones(size(pres))*doxyParamDef.fillValue;
      
      idNoDef = find((pres ~= presFillVal) & (temp ~= tempFillVal) & ...
         (psal ~= psalFillVal) & (molarDoxy ~= molarDoxyFillVal));
      if (~isempty(idNoDef))

         molarDoxyValues = molarDoxy(idNoDef);
         presValues = pres(idNoDef);
         tempValues = temp(idNoDef);
         salValues = psal(idNoDef);
         
         % salinity effect correction
         doxyCalibRefSalinity = 0;
         oxygenSalComp = calcoxy_salcomp_old(molarDoxyValues, salValues, tempValues, doxyCalibRefSalinity);
         
         % pressure effect correction
         oxygenPresComp = calcoxy_prescomp_old(oxygenSalComp, presValues);
         
         % compute potential temperature and potential density
         tpot = tetai(presValues, tempValues, salValues, 0);
         [null, sigma0] = swstat90(salValues, tpot, 0);
         rho = (sigma0+1000)/1000;
         
         % units convertion (micromol/L to micromol/kg)
         oxyValues = oxygenPresComp ./ rho;
         
         doxy(idNoDef) = oxyValues;
      end
      
      profStruct.paramList = [profStruct.paramList doxyParamDef];
      profParam = [profParam doxy];
   end
   
   profStruct.data = profParam;
   profStruct.dataQc = repmat(' ', size(profStruct.data));
   profStruct.dates = paramJuldData(profCtdLevels);
   
   if (GENERATE_CSV_FILES)
      outputFileName = ['./' 'PROF_' num2str(cyNum-1) '_min_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
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
   tabMetaData = [tabMetaData {'PLATFORM_NUMBER'} {a_wmoNumber}];
   
   if (gl_att_is_present(fCdf, [], 'project'))
      projectName = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'project'));
      if (~isempty(projectName))
         tabMetaData = [tabMetaData {'PROJECT_NAME'} {projectName}];
      end
   end
   if (gl_att_is_present(fCdf, [], 'principal_investigator'))
      piName = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'principal_investigator'));
      if (~isempty(piName))
         tabMetaData = [tabMetaData {'PI_NAME'} {piName}];
      end
   end
   %    if (gl_att_is_present(fCdf, [], 'data_center'))
   %       dataCentre = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'data_center'));
   %       if (~isempty(dataCentre))
   %          tabMetaData = [tabMetaData {'DATA_CENTRE'} {dataCentre}];
   %       end
   %    end
   
   tabProfiles = [tabProfiles profStruct];
end

% create the base file name of the NetCDF profile files
baseFileName = [a_wmoNumber '_'];

% generate the NetCDF Argo PROF files
gl_create_nc_mono_prof_files_3_0(tabProfiles, tabMetaData, a_outputDirName, baseFileName);

netcdf.close(fCdf);

return

% ------------------------------------------------------------------------------
% Export EGO Socib NetCDF file contents in a CSV file.
%
% SYNTAX :
%  export_csv_socib_ego_file(a_ncEgoFileName)
%
% INPUT PARAMETERS :
%   a_ncEgoFileName : EGO Socib NetCDF file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function export_csv_socib_ego_file(a_ncEgoFileName)

% name of the CSV output file
[pathstr, name, ext] = fileparts(a_ncEgoFileName);
csvEgoFileName = [pathstr '/' name '.csv'];

% create the CSV output file
fidOut = fopen(csvEgoFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', csvEgoFileName);
   return
end

% parameters to export
parameterList = [ ...
   {'TIME'} ...
   {'TIME_QC'} ...
   {'latitude'} ...
   {'longitude'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'profile_direction'} ...
   {'profile_index'} ...
   {'pressure'} ...
   {'temperature'} ...
   {'temperature_corrected_thermal'} ...
   {'conductivity'} ...
   {'conductivity_corrected_thermal'} ...
   {'salinity'} ...
   {'salinity_corrected_thermal'} ...
   {'oxygen_concentration'} ...
   {'temperature_oxygen'} ...
   {'chlorophyll'} ...
   {'turbidity'} ...
   {'cdom'} ...
   ];

% parameterList = [ ...
%    {'TIME'} ...
%    {'TIME_QC'} ...
%    {'latitude'} ...
%    {'longitude'} ...
%    {'LATITUDE'} ...
%    {'LONGITUDE'} ...
%    {'profile_direction'} ...
%    {'profile_index'} ...
%    {'depth_ctd'} ...
%    {'temperature'} ...
%    {'conductivity'} ...
%    {'salinity'} ...
%    {'salinity_corrected_thermal'} ...
%    {'density'} ...
%    {'chlorophyll'} ...
%    {'oxygen_concentration'} ...
%    {'oxygen_saturation'} ...
%    {'temperature_oxygen'} ...
%    {'turbidity'} ...
%    {'water_velocity_eastward'} ...
%    {'water_velocity_northward'} ...
%    {'pressure'} ...
%    {'DEPTH'} ...
%    {'distance_over_ground'} ...
%    ];

% open NetCDF file
fCdf = netcdf.open(a_ncEgoFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncEgoFileName);
   return
end

juld = [];
if (gl_var_is_present(fCdf, 'TIME'))
   time = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME'), '_FillValue');
   idDef = find(time ~= fillVal);
   offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
   juld = time;
   juld(idDef) = juld(idDef)/86400 + offset;
   juld(find(juld == fillVal)) = nan;
else
   fprintf('WARNING: Variable %s not present in file : %s\n', ...
      'TIME', a_ncEgoFileName);
end

tabParamName = [];
tabParamFmt = [];
tabParamData = [];
for idParam = 1:length(parameterList)
   paramNameIn = strtrim(parameterList{idParam});
   if (gl_var_is_present(fCdf, paramNameIn))
      paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramNameIn));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramNameIn), '_FillValue');
      paramData(find(paramData == fillVal)) = nan;
      if (~isempty(find(~isnan(paramData), 1)))
         tabParamName = [tabParamName ';' paramNameIn];
         tabParamFmt = [tabParamFmt '; %f'];
         tabParamData = [tabParamData double(paramData)];
      else
         fprintf('WARNING: Variable %s is empty in file : %s\n', ...
            paramNameIn, a_ncEgoFileName);
      end
   end
end

fprintf(fidOut, '%s\n', ['DATE' tabParamName]);
for id = 1:size(tabParamData, 1)
   fprintf(fidOut, ['%s' tabParamFmt '\n'], ...
      gl_julian_2_gregorian(juld(id)), tabParamData(id, :));
end

netcdf.close(fCdf);

fclose(fidOut);

return
