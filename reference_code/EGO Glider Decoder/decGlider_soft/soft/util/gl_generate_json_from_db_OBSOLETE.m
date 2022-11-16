% ------------------------------------------------------------------------------
% Generate JSON deployment and sensor files from a data base (Excell file).
%
% SYNTAX :
%  gl_generate_json_from_db()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function gl_generate_json_from_db()
      
% input Excel file with DB export
INPUT_EXCEL_FILE = 'C:\Users\jprannou\_RNU\Glider\work\EGOdb2json_fromVT_20160208.xlsx';

% directory to store the deployment directories
OUTPUT_DIR = 'C:\Users\jprannou\_RNU\Glider\work\';

% reference file for JSON deployment file
JSON_DEPLOYMENT_FILE = 'C:\Users\jprannou\_RNU\Glider\soft\json\deployment_ref.json';

% reference file for JSON sensor
JSON_SENSOR_FILE = 'C:\Users\jprannou\_RNU\Glider\soft\json\sensor_ref.json';


% separator for multi dimensional information in DB
sep = ':';

% list of numerical fields
numericalFields = [ ...
   {'DEPLOYMENT_START_LATITUDE'} ...
   {'DEPLOYMENT_START_LONGITUDE'} ...
   {'DEPLOYMENT_START_QC'} ...
   {'DEPLOYMENT_END_LATITUDE'} ...
   {'DEPLOYMENT_END_LONGITUDE'} ...
   {'DEPLOYMENT_END_QC'} ...
   ];

% list of sensor fields
sensorFields = [ ...
   {'SENSOR_NAME'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   {'SENSOR_MOUNT'} ...
   {'SENSOR_ORIENTATION'} ...
   ];

% list of parameter fields
parameterFields = [ ...
   {'glider_variable_name'} ...
   {'ego_variable_name'} ...
   {'accuracy'} ...
   {'precision'} ...
   {'resolution'} ...
   {'cell_methods'} ...
   {'reference_scale'} ...
   {'derivation_equation'} ...
   {'derivation_coefficient'} ...
   {'derivation_comment'} ...
   {'derivation_date'} ...
   ];

% list of max length for string information
maxSizeFields = [ ...
   {'PLATFORM_FAMILY'} {256}  ...
   {'PLATFORM_TYPE'} {32}  ...
   {'PLATFORM_MAKER'} {256}  ...
   {'FIRMWARE_VERSION_NAVIGATION'} {16}  ...
   {'FIRMWARE_VERSION_SCIENCE'} {16}  ...
   {'MANUAL_VERSION'} {16}  ...
   {'GLIDER_SERIAL_NO'} {16}  ...
   {'STANDARD_FORMAT_ID'} {16}  ...
   {'DAC_FORMAT_ID'} {16}  ...
   {'WMO_INST_TYPE'} {4}  ...
   {'PROJECT_NAME'} {64}  ...
   {'DATA_CENTRE'} {2}  ...
   {'PI_NAME'} {64}  ...
   {'ANOMALY'} {256}  ...
   {'BATTERY_TYPE'} {64}  ...
   {'BATTERY_PACKS'} {64}  ...
   {'SPECIAL_FEATURES'} {1024}  ...
   {'GLIDER_OWNER'} {64}  ...
   {'OPERATING_INSTITUTION'} {64}  ...
   {'CUSTOMIZATION'} {1024}  ...
   {'DEPLOYMENT_START_DATE'} {14}  ...
   {'DEPLOYMENT_PLATFORM'} {32}  ...
   {'DEPLOYMENT_CRUISE_ID'} {32}  ...
   {'DEPLOYMENT_REFERENCE_STATION_ID'} {256}  ...
   {'DEPLOYMENT_END_DATE'} {14}  ...
   {'DEPLOYMENT_END_STATUS'} {1}  ...
   {'DEPLOYMENT_OPERATOR'} {256}  ...
   {'SENSOR_NAME'} {64}  ...
   {'SENSOR_MAKER'} {256}  ...
   {'SENSOR_MODEL'} {256}  ...
   {'SENSOR_SERIAL_NO'} {16}  ...
   {'derivation_equation'} {4096}  ...
   {'derivation_coefficient'} {4096}  ...
   {'derivation_comment'} {4096}  ...
   {'derivation_date'} {14}  ...
   ];

% list of date fields (expected to be in 'dd/mm/yyyy HH:MM:SS' in the Excel
% file)
dateFields = [ ...
   {'DEPLOYMENT_START_DATE'}  ...
   {'DEPLOYMENT_END_DATE'}  ...
   {'derivation_date'} ...
   ];

% read information from DB
[num, txt, raw] = xlsread(INPUT_EXCEL_FILE);

% find '<use>' column to select deployments to generate
idF1 = strfind([raw{1, :}], '<use>');
if (isempty(idF1))
   fprintf('ERROR: Cannot find column ''<use>'' in file: %s => exit\n', INPUT_EXCEL_FILE);
   return
end
idF2 = find([raw{2:end, idF1}] == 1);
if (isempty(idF2))
   fprintf('INFO: No deployment selected in file: %s => exit\n', INPUT_EXCEL_FILE);
   return
end
% consider only lines to use
data = raw([1 idF2+1], :);
data(:, idF1) = [];

% retrieve usefull columns (with template information, i.e. '<*>')
nbCol = size(data, 2);
colLabel = [];
colId = [];
for idC = 1:nbCol
   if (any(strfind(data{1, idC}, '<') & strfind(data{1, idC}, '>')))
      value = strtrim(data{1, idC});
      if ((value(1) == '<') & (value(end) == '>'))
         value = value(2:end-1);
         colLabel{end+1} = value;
         colId(end+1) = idC;
      end
   end
end

% create information structures
dataStruct = [];
nbLig = size(data, 1);
nbCol = length(colLabel);
for idL = 2:nbLig
   newStruct = [];
   newStruct.sensorList = [];
   for idC = 1:nbCol
      if (isstr(data{idL, colId(idC)}))
         value = strtrim(data{idL, colId(idC)});
      else
         value = data{idL, colId(idC)};
      end
      if (ismember(colLabel{idC}, sensorFields))
         if (~isnan(value))
            idSep = strfind(value, sep);
            if (length(idSep) == 1)
               sensor = strtrim(value(1:idSep-1));
               info = strtrim(value(idSep+1:end));
               newStruct.(sensor).(colLabel{idC}) = info;
               newStruct.sensorList = [newStruct.sensorList {sensor}];
            else
               fprintf('ERROR: (L,C) (%d,%d): Inconsistent information => ignored\n', idL, idC);
            end
         end
      elseif (ismember(colLabel{idC}, parameterFields))
         if (~isnan(value))
            idSep = strfind(value, sep);
            if (length(idSep) == 2)
               sensor = strtrim(value(1:idSep(1)-1));
               param = strtrim(value(idSep(1)+1:idSep(2)-1));
               info = strtrim(value(idSep(2)+1:end));
               newStruct.(sensor).(param).(colLabel{idC}) = info;
               newStruct.sensorList = [newStruct.sensorList {sensor}];
               if (~isfield(newStruct.(sensor), 'paramList'))
                  newStruct.(sensor).paramList = {param};
               else
                  newStruct.(sensor).paramList = [newStruct.(sensor).paramList {param}];
               end
            else
               fprintf('ERROR: (L,C) (%d,%d): Inconsistent information => ignored\n', idL, idC);
            end
         end
      else
         newStruct.(colLabel{idC}) = value;
      end
   end
   
   % clean collected data
   newStruct.sensorList = unique(newStruct.sensorList, 'stable');
   for idS = 1:length(newStruct.sensorList)
      sensor = newStruct.sensorList{idS};
      newStruct.(sensor).paramList = unique(newStruct.(sensor).paramList, 'stable');
   end
   
   % convert date fields
   [newStruct] = convert_date(newStruct, dateFields, idL);
   for idS = 1:length(newStruct.sensorList)
      sensor = newStruct.sensorList{idS};
      [newStruct.(sensor)] = convert_date(newStruct.(sensor), dateFields, idL);
      for idP = 1:length(newStruct.(sensor).paramList)
         param = newStruct.(sensor).paramList{idP};
         [newStruct.(sensor).(param)] = convert_date(newStruct.(sensor).(param), dateFields, idL);
      end
   end
   
   % check data size for STRING<X> information
   [newStruct] = check_size(newStruct, maxSizeFields, idL);
   
   dataStruct{end+1} = newStruct;
end

% create general output directory
outputDirName = [OUTPUT_DIR 'generated_deployments_' datestr(now, 'yyyymmddTHHMMSS')];
mkdir(outputDirName);

% store reference JSON deployment contents
% open the file
fIdIn = fopen(JSON_DEPLOYMENT_FILE, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', JSON_DEPLOYMENT_FILE);
   return
end

% read the data
jsonDeployRef = [];
while (1)
   line = fgetl(fIdIn);
   if (line == -1)
      break
   end
   jsonDeployRef{end+1} = line;
end
fclose(fIdIn);

% store reference JSON sensor contents
% open the file
fIdIn = fopen(JSON_SENSOR_FILE, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', JSON_SENSOR_FILE);
   return
end

% read the data
jsonSensorRef = [];
while (1)
   line = fgetl(fIdIn);
   if (line == -1)
      break
   end
   jsonSensorRef{end+1} = line;
end
fclose(fIdIn);

% generate JSON deployment files for each deployement of the dataStruct
% structure
for idS = 1:length(dataStruct)
   curStruct = dataStruct{idS};
   if (isfield(curStruct, 'platform_code') && ~isempty(curStruct.platform_code) && ...
         isfield(curStruct, 'deployment_label') && ~isempty(curStruct.deployment_label) && ...
         isfield(curStruct, 'PLATFORM_TYPE') && ~isempty(curStruct.PLATFORM_TYPE))
      if (~isempty(strfind(lower(curStruct.PLATFORM_TYPE), 'slocum')) || ...
            ~isempty(strfind(lower(curStruct.PLATFORM_TYPE), 'seaglider')) || ...
            ~isempty(strfind(lower(curStruct.PLATFORM_TYPE), 'seaexplorer')))
         
         deployId = [lower(curStruct.platform_code) '_' lower(curStruct.deployment_label)];
         
         % update and store deployment data for the current deployment
         jsonDeploy = [];
         jsonCovar = [];
         for idL = 1:length(jsonDeployRef)
            line = jsonDeployRef{idL};
            while (any(strfind(line, '<') & strfind(line, '>')))
               posStart = strfind(line, '<');
               posEnd = strfind(line, '>');
               fName = line(posStart+1:posEnd-1);
               if (strcmp(fName, 'coordinate_variables'))
                  % add coordinate variables
                  [ok, jsonCovar] = add_coordinate_variables(deployId, curStruct);
                  if (ok == 0)
                     continue
                  end
                  line = '#coordinate_variables#';
               elseif (strcmp(fName, 'glider_sensor'))
                  % add glider sensor files
                  for idSe = 1:length(curStruct.sensorList)
                     jsonDeploy{end+1} = sprintf('\t\t{');
                     jsonDeploy{end+1} = sprintf('\t\t\t"sensor_file_name" : "%s.json"', curStruct.sensorList{idSe});
                     if (idSe == length(curStruct.sensorList))
                        jsonDeploy{end+1} = sprintf('\t\t}');
                     else
                        jsonDeploy{end+1} = sprintf('\t\t},');
                     end
                  end
                  line = [];
               elseif (isfield(curStruct, fName) && ...
                     ((~isstr(curStruct.(fName)) && ~isnan(curStruct.(fName))) || ...
                     (isstr(curStruct.(fName)) && ~isempty(curStruct.(fName)))))
                  if (isstr(curStruct.(fName)))
                     line = regexprep(line, line(posStart:posEnd), curStruct.(fName));
                  else
                     line = regexprep(line, line(posStart:posEnd), num2str(curStruct.(fName)));
                  end
               else
                  if (~ismember(fName, numericalFields))
                     line = regexprep(line, line(posStart:posEnd), '');
                  else
                     line = regexprep(line, line(posStart:posEnd), 'null');
                  end
               end
            end
            if (~isempty(line))
               jsonDeploy{end+1} = sprintf('%s', line);
            end
         end
         
         % create output directory for the JSON files of the current deployment
         outputDirName2 = [outputDirName '/' deployId '/json/'];
         mkdir(outputDirName2);
         
         % create deployment file
         outputFileName = [outputDirName2 '/' deployId '.json'];
         fIdOut = fopen(outputFileName, 'wt');
         if (fIdOut == -1)
            fprintf('ERROR: While creating file : %s\n', outputFileName);
            return
         end
         
         for idL = 1:length(jsonDeploy)
            if (strcmp(jsonDeploy{idL}, '#coordinate_variables#'))
               for idL2 = 1:length(jsonCovar)
                  fprintf(fIdOut, '%s\n', jsonCovar{idL2});
               end
            else
               fprintf(fIdOut, '%s\n', jsonDeploy{idL});
            end
         end
         
         fclose(fIdOut);
         
         % update and store sensor data for the current deployment
         for idSe = 1:length(curStruct.sensorList)
            jsonSensor = [];
            jsonSensorParam = [];
            sensor = curStruct.sensorList{idSe};
            sensorStruct = curStruct.(sensor);
            
            for idL = 1:length(jsonSensorRef)
               line = jsonSensorRef{idL};
               while (any(strfind(line, '<') & strfind(line, '>')))
                  posStart = strfind(line, '<');
                  posEnd = strfind(line, '>');
                  fName = line(posStart+1:posEnd-1);
                  if (strcmp(fName, 'parametersList'))
                     % add parameter information
                     [ok, jsonSensorParam] = add_parameter_variables(sensor, curStruct, parameterFields);
                     if (ok == 0)
                        continue
                     end
                     line = '#parametersList#';
                  elseif (isfield(sensorStruct, fName) && ...
                        ((~isstr(sensorStruct.(fName)) && ~isnan(sensorStruct.(fName))) || ...
                        (isstr(sensorStruct.(fName)) && ~isempty(sensorStruct.(fName)))))
                     if (isstr(sensorStruct.(fName)))
                        line = regexprep(line, line(posStart:posEnd), sensorStruct.(fName));
                     else
                        line = regexprep(line, line(posStart:posEnd), num2str(sensorStruct.(fName)));
                     end
                  else
                     if (~ismember(fName, numericalFields))
                        line = regexprep(line, line(posStart:posEnd), '');
                     else
                        line = regexprep(line, line(posStart:posEnd), 'null');
                     end
                  end
               end
               if (~isempty(line))
                  jsonSensor{end+1} = sprintf('%s', line);
               end
            end
            
            % create sensor file
            outputFileName = [outputDirName2 '/' sensor '.json'];
            fIdOut = fopen(outputFileName, 'wt');
            if (fIdOut == -1)
               fprintf('ERROR: While creating file : %s\n', outputFileName);
               return
            end
            
            for idL = 1:length(jsonSensor)
               if (strcmp(jsonSensor{idL}, '#parametersList#'))
                  for idL2 = 1:length(jsonSensorParam)
                     fprintf(fIdOut, '%s\n', jsonSensorParam{idL2});
                  end
               else
                  fprintf(fIdOut, '%s\n', jsonSensor{idL});
               end
            end
            
            fclose(fIdOut);
         end
      else
         fprintf('WARNING: Deployment #%d ''PLATFORM_TYPE'' should contain (''slocum'' or ''seaglider'' or ''seaexplorer'') => JSON not generated\n', idS);
      end
   else
      fprintf('WARNING: Deployment #%d ''platform_code'', ''deployment_label'' and ''PLATFORM_TYPE'' are mandatory => JSON not generated\n', idS);
   end
end

return

% ------------------------------------------------------------------------------
% Generate the 'coordinate_variables' item of a JSON deployment file.
%
% SYNTAX :
%  [o_ok, o_jsonCovar] = add_coordinate_variables(a_deployId, a_dbStruct)
%
% INPUT PARAMETERS :
%   a_deployId : deployment Id
%   a_dbStruct : structure information for the deployment
%
% OUTPUT PARAMETERS :
%   o_ok        : ok flag (1 if generation is ok, 0 otherwise)
%   o_jsonCovar : text for 'coordinate_variables'
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_jsonCovar] = add_coordinate_variables(a_deployId, a_dbStruct)

o_ok = 0;
o_jsonCovar = [];

if (~isempty(strfind(lower(a_dbStruct.PLATFORM_TYPE), 'slocum')))
   pathTime = 'rawData.vars_sci_time.';
   pathTimeGps = 'rawData.vars_time_gps.';
   juldLabel = 'sci_juld';
elseif (~isempty(strfind(lower(a_dbStruct.PLATFORM_TYPE), 'seaglider')))
   pathTime = 'rawData.vars_time.';
   pathTimeGps = 'rawData.vars_time_gps.';
   juldLabel = 'juld';
elseif (~isempty(strfind(lower(a_dbStruct.PLATFORM_TYPE), 'seaexplorer')))
   pathTime = 'rawData.vars_sci_time.';
   pathTimeGps = 'rawData.vars_time_gps.';
   juldLabel = 'sci_juld_PLD_REALTIMECLOCK';
end

if ~(isfield(a_dbStruct, 'TIME') && ~isempty(a_dbStruct.TIME))
   fprintf('WARNING: Deployment ''%s'' ''TIME'' is mandatory => JSON not generated\n', a_deployId);
   return
end

o_jsonCovar{end+1} = sprintf('\t\t{');
o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTime, a_dbStruct.TIME);
o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "TIME"');
o_jsonCovar{end+1} = sprintf('\t\t},');
o_jsonCovar{end+1} = sprintf('\t\t{');
o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTime, juldLabel);
o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "JULD"');
o_jsonCovar{end+1} = sprintf('\t\t},');

if (isfield(a_dbStruct, 'LATITUDE') && ...
      ((~ischar(a_dbStruct.LATITUDE) && ~isnan(a_dbStruct.LATITUDE)) || ...
      (ischar(a_dbStruct.LATITUDE) && ~isempty(a_dbStruct.LATITUDE))) && ...
      isfield(a_dbStruct, 'LONGITUDE') && ...
      ((~ischar(a_dbStruct.LONGITUDE) && ~isnan(a_dbStruct.LONGITUDE)) || ...
      (ischar(a_dbStruct.LONGITUDE) && ~isempty(a_dbStruct.LONGITUDE))))   
   
   o_jsonCovar{end+1} = sprintf('\t\t{');
   o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTime, a_dbStruct.LATITUDE);
   o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "LATITUDE"');
   o_jsonCovar{end+1} = sprintf('\t\t},');
   o_jsonCovar{end+1} = sprintf('\t\t{');
   o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTime, a_dbStruct.LONGITUDE);
   o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "LONGITUDE"');
   o_jsonCovar{end+1} = sprintf('\t\t},');
end
   
o_jsonCovar{end+1} = sprintf('\t\t{');
o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTimeGps, 'time');
o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "TIME_GPS"');
o_jsonCovar{end+1} = sprintf('\t\t},');
o_jsonCovar{end+1} = sprintf('\t\t{');
o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTimeGps, 'latitude');
o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "LATITUDE_GPS"');
o_jsonCovar{end+1} = sprintf('\t\t},');
o_jsonCovar{end+1} = sprintf('\t\t{');
o_jsonCovar{end+1} = sprintf('\t\t\t"glider_variable_name"\t: "%s%s",', pathTimeGps, 'longitude');
o_jsonCovar{end+1} = sprintf('\t\t\t"ego_variable_name"\t\t: "LONGITUDE_GPS"');
o_jsonCovar{end+1} = sprintf('\t\t}');

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Generate the 'parametersList' item of a JSON sensor file.
%
% SYNTAX :
%  [o_ok, o_jsonSensorParam] = add_parameter_variables(a_sensor, a_dbStruct, a_parameterFields)
%
% INPUT PARAMETERS :
%   a_sensor          : name of the concerned sensor
%   a_dbStruct        : structure information for the deployment
%   a_parameterFields : list of fields expected to be present for each parameter
%
% OUTPUT PARAMETERS :
%   o_ok              : ok flag (1 if generation is ok, 0 otherwise)
%   o_jsonSensorParam : text for 'parametersList'
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_jsonSensorParam] = add_parameter_variables(a_sensor, a_dbStruct, a_parameterFields)
                     
o_ok = 0;
o_jsonSensorParam = [];

if (~isempty(strfind(lower(a_dbStruct.PLATFORM_TYPE), 'slocum')))
   pathTime = 'rawData.vars_sci_time.';
elseif (~isempty(strfind(lower(a_dbStruct.PLATFORM_TYPE), 'seaglider')))
   pathTime = 'rawData.vars_time.';
elseif (~isempty(strfind(lower(a_dbStruct.PLATFORM_TYPE), 'seaexplorer')))
   pathTime = 'rawData.vars_sci_time.';
end

% retrieve information
sensorStruct = a_dbStruct.(a_sensor);
paramList = sensorStruct.paramList;

for idP = 1:length(paramList)
   param = paramList{idP};
   paramStruct = sensorStruct.(param);
   
   o_jsonSensorParam{end+1} = sprintf('\t\t{');
   for idF = 1:length(a_parameterFields)
      fName = a_parameterFields{idF};
      value = '';
      if (isfield(paramStruct, fName))
         value = paramStruct.(fName);
      end
      if (strcmp(fName, 'glider_variable_name'))
         if (~isempty(value))
            o_jsonSensorParam{end+1} = sprintf('\t\t\t"%s": "%s%s",', fName, pathTime, value);
         else
            o_jsonSensorParam{end+1} = sprintf('\t\t\t"%s": "%s",', fName, value);
         end
      elseif (strcmp(fName, 'ego_variable_name'))
         o_jsonSensorParam{end+1} = sprintf('\t\t\t"%s": "%s",', fName, param);
      else
         if (idF == length(a_parameterFields))
            o_jsonSensorParam{end+1} = sprintf('\t\t\t"%s": "%s"', fName, value);
         else
            o_jsonSensorParam{end+1} = sprintf('\t\t\t"%s": "%s",', fName, value);
         end
      end
   end
   if (idP == length(paramList))
      o_jsonSensorParam{end+1} = sprintf('\t\t}');
   else
      o_jsonSensorParam{end+1} = sprintf('\t\t},');
   end
end

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Convert date format (from 'dd/mm/yyyy HH:MM:SS' in the Excel file to
% 'yyyymmddHHMMSS' in the JSON file).
%
% SYNTAX :
%  [o_struct] = convert_date(a_struct, a_dateFields, a_refLine)
%
% INPUT PARAMETERS :
%   a_struct     : input information for the deployment
%   a_dateFields : list of date fields
%   a_refLine    : line number (for output message)
%
% OUTPUT PARAMETERS :
%   o_struct : output information for the deployment
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_struct] = convert_date(a_struct, a_dateFields, a_refLine)
                     
o_struct = a_struct;
   
for idF = 1:length(a_dateFields)
   fName = a_dateFields{idF};
   if (isfield(o_struct, fName))
      if ((~isstr(o_struct.(fName)) && ~isnan(o_struct.(fName))) || ...
            (isstr(o_struct.(fName)) && ~isempty(o_struct.(fName))))
         if (length(o_struct.(fName)) == 10)
            o_struct.(fName) = [o_struct.(fName) ' 00:00:00'];
         end
         [val, count, errmsg, nextindex] = sscanf(o_struct.(fName), '%d/%d/%d %d:%d:%d');
         if (isempty(errmsg) && (count == 6))
            o_struct.(fName) = sprintf('%04d%02d%02d%02d%02d%02d', ...
               val(3), val(2), val(1), val(4), val(5), val(6));
         else
            fprintf('WARNING: Line #%d: Badly formatted date in ''%s''\n', ...
               a_refLine, fName);
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Check size for STRING array data.
%
% SYNTAX :
%  [o_struct] = check_size(a_struct, a_maxSizeFields, a_refLine)
%
% INPUT PARAMETERS :
%   a_struct        : input information for the deployment
%   a_maxSizeFields : list of STRING fields with their max size
%   a_refLine       : line number (for output message)
%
% OUTPUT PARAMETERS :
%   o_struct : output information for the deployment
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_struct] = check_size(a_struct, a_maxSizeFields, a_refLine)
                     
o_struct = a_struct;

for idF = 1:2:length(a_maxSizeFields)
   fName = a_maxSizeFields{idF};
   fSize = a_maxSizeFields{idF+1};
   if (isfield(o_struct, fName))
      if (length(o_struct.(fName)) > fSize)
         o_struct.(fName) = o_struct.(fName)(1:fSize);
         fprintf('WARNING: Line #%d: ''%s'' truncated to STRING%d => %s\n', ...
            a_refLine, fName, fSize, o_struct.(fName));
      end
   end
end

return
