% ------------------------------------------------------------------------------
% Check that json files of a deployment are compliant with EGO 1.4 format.
%
% SYNTAX :
%  [o_outputData] = gl_check_json_deployment_file(a_deployJsonFilePathName)
%
% INPUT PARAMETERS :
%   a_deployJsonFilePathName : main json file of the deployment
%
% OUTPUT PARAMETERS :
%   o_outputData : json files data (empty if error in json format or file
%                  contents not compliant)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = gl_check_json_deployment_file(a_deployJsonFilePathName)

% output parameters initialization
o_outputData = [];

% flag for specific input (NetCDF file of sea glider)
global g_decGl_seaGliderInputNc;


% retrieve reference list
refTables = get_ref_tables;
if (isempty(refTables))
   return
end

% read the json deployment file
try
   deployJsonData = gl_load_json(a_deployJsonFilePathName);
catch
   errorStruct = lasterror;
   fprintf('ERROR: error format in json file (%s)\n', ...
      a_deployJsonFilePathName);
   fprintf('%s\n', ...
      errorStruct.message);
   return
end

if ~(isfield(deployJsonData, 'EGO_format_version') && ...
      ~isempty(deployJsonData.EGO_format_version) && ...
      (str2double(deployJsonData.EGO_format_version) == 1.4))
   fprintf('ERROR: expected ''1.4'' EGO format version in json file (%s)\n', ...
      a_deployJsonFilePathName);
   return
end
if (isfield(deployJsonData, 'EGO_format_version'))
   deployJsonData = rmfield(deployJsonData, 'EGO_format_version');
end

% multi dimensional STRING information (TRANS_SYSTEM, TRANS_SYSTEM_ID,
% TRANS_FREQUENCY, POSITIONING_SYSTEM) are loaded in char array when possible
% (same size in second dimension)
struct1 = deployJsonData;
fieldNames1 = fields(struct1);
for idF1 = 1:length(fieldNames1)
   struct2 = struct1.(fieldNames1{idF1});
   fieldNames2 = fields(struct2);
   for idF2 = 1:length(fieldNames2)
      value = struct2.(fieldNames2{idF2});
      if (ischar(value) && (size(value, 1) > 1))
         value = cellstr(value)';
         deployJsonData.(fieldNames1{idF1}).(fieldNames2{idF2}) = value;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected fields
deployExpFieldList = {
   'global_attributes', ...
   'glider_characteristics', ...
   'glider_deployment', ...
   'coordinate_variables', ...
   'glider_sensor' ...
   };

fieldNames = fields(deployJsonData);
error = 0;
for idF = 1:length(deployExpFieldList)
   if (~any(strcmp(deployExpFieldList{idF}, fieldNames) == 1))
      fprintf('ERROR: ''%s'' field expected in json file (%s)\n', ...
         deployExpFieldList{idF}, a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected global attributes
deployExpGlobAttList = {
   'platform_code', ...
   'wmo_platform_code', ...
   'references', ...
   'comment', ...
   'title', ...
   'summary', ...
   'abstract', ...
   'keywords', ...
   'area', ...
   'institution', ...
   'institution_references', ...
   'sdn_edmo_code', ...
   'authors', ...
   'data_assembly_center', ...
   'principal_investigator', ...
   'principal_investigator_email', ...
   'project_name', ...
   'observatory', ...
   'deployment_code', ...
   'deployment_label', ...
   'doi', ...
   'citation', ...
   'update_interval' ...
   };

fieldNames = fields(deployJsonData.global_attributes);
error = 0;
for idGa = 1:length(deployExpGlobAttList)
   if (~any(strcmp(deployExpGlobAttList{idGa}, fieldNames) == 1))
      fprintf('ERROR: ''%s'' field expected in ''global_attributes'' of json file (%s)\n', ...
         deployExpGlobAttList{idGa}, a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

% constraints on global attributes
checkGlobAttList = {
   'platform_code', 1, ''; ...
   'data_assembly_center', 0, '4'; ...
   'update_interval', 0, '6' ...
   };

error = 0;
for idGa = 1:size(checkGlobAttList, 1)
   attName = checkGlobAttList{idGa, 1};
   attValue = deployJsonData.global_attributes.(attName);
   mandFlag = checkGlobAttList{idGa, 2};
   reftable = checkGlobAttList{idGa, 3};
   if (mandFlag && isempty(strtrim(attValue)))
      fprintf('ERROR: ''%s'' ''global_attributes'' is mandatory in json file (%s)\n', ...
         attName, a_deployJsonFilePathName);
      error = 1;
   end
   if (~isempty(reftable) && ~isempty(strtrim(attValue)))
      idF = find(strcmp(reftable, refTables(:, 1)));
      if (~ismember(strtrim(attValue), refTables{idF, 2}))
         fprintf('ERROR: ''%s'' ''global_attributes'' value (%s) is not in reference table %s in json file (%s)\n', ...
            attName, strtrim(attValue), reftable, a_deployJsonFilePathName);
         error = 1;
      end
   end
end
if (error)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected glider characteristics
deployExpGliderCharactList = {
   'PLATFORM_FAMILY', ...
   'PLATFORM_TYPE', ...
   'PLATFORM_MAKER', ...
   'GLIDER_SERIAL_NO', ...
   'GLIDER_OWNER', ...
   'OPERATING_INSTITUTION', ...
   'WMO_INST_TYPE', ...
   'POSITIONING_SYSTEM', ...
   'TRANS_SYSTEM', ...
   'TRANS_SYSTEM_ID', ...
   'TRANS_FREQUENCY', ...
   'BATTERY_TYPE', ...
   'BATTERY_PACKS', ...
   'SPECIAL_FEATURES', ...
   'FIRMWARE_VERSION_NAVIGATION', ...
   'FIRMWARE_VERSION_SCIENCE', ...
   'GLIDER_MANUAL_VERSION', ...
   'ANOMALY', ...
   'CUSTOMIZATION', ...
   'DAC_FORMAT_ID', ...
   };

fieldNames = fields(deployJsonData.glider_characteristics);
error = 0;
for idGc = 1:length(deployExpGliderCharactList)
   if (~any(strcmp(deployExpGliderCharactList{idGc}, fieldNames) == 1))
      fprintf('ERROR: ''%s'' field expected in ''glider_characteristics'' of json file (%s)\n', ...
         deployExpGliderCharactList{idGc}, a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

% constraints on glider characteristics
checkGliderCharactList = {
   'PLATFORM_FAMILY', 0, '22'; ...
   'PLATFORM_TYPE', 0, '23'; ...
   'PLATFORM_MAKER', 0, '24'; ...
   'WMO_INST_TYPE', 0, '8'; ...
   'POSITIONING_SYSTEM', 0, '9.1'; ...
   'TRANS_SYSTEM', 0, '10.1' ...
   };

error = 0;
for idGc = 1:size(checkGliderCharactList, 1)
   attName = checkGliderCharactList{idGc, 1};
   attValue = deployJsonData.glider_characteristics.(attName);
   mandFlag = checkGliderCharactList{idGc, 2};
   reftable = checkGliderCharactList{idGc, 3};
   if (iscellstr(attValue))
      attValueList = attValue;
      for idV = 1:length(attValueList)
         attValue = attValueList{idV};
         if (mandFlag && isempty(strtrim(attValue)))
            fprintf('ERROR: ''%s'' ''glider_characteristics'' is mandatory in json file (%s)\n', ...
               attName, a_deployJsonFilePathName);
            error = 1;
         end
         if (~isempty(reftable) && ~isempty(strtrim(attValue)))
            idF = find(strcmp(reftable, refTables(:, 1)));
            if (~ismember(strtrim(attValue), refTables{idF, 2}))
               fprintf('ERROR: ''%s'' ''glider_characteristics'' value (%s) is not in reference table %s in json file (%s)\n', ...
                  attName, strtrim(attValue), reftable, a_deployJsonFilePathName);
               error = 1;
            end
         end
      end
   else
      if (mandFlag && isempty(strtrim(attValue)))
         fprintf('ERROR: ''%s'' ''glider_characteristics'' is mandatory in json file (%s)\n', ...
            attName, a_deployJsonFilePathName);
         error = 1;
      end
      if (~isempty(reftable) && ~isempty(strtrim(attValue)))
         idF = find(strcmp(reftable, refTables(:, 1)));
         if (~ismember(strtrim(attValue), refTables{idF, 2}))
            fprintf('ERROR: ''%s'' ''glider_characteristics'' value (%s) is not in reference table %s in json file (%s)\n', ...
               attName, strtrim(attValue), reftable, a_deployJsonFilePathName);
            error = 1;
         end
      end
   end
end
if (error)
   return
end

% contraints on free text variable length
checkMaxSizeFields = {
   'GLIDER_SERIAL_NO', 16; ...
   'GLIDER_OWNER', 64; ...
   'OPERATING_INSTITUTION', 64; ...
   'TRANS_SYSTEM_ID', 32; ...
   'TRANS_FREQUENCY', 16; ...
   'BATTERY_TYPE', 64; ...
   'BATTERY_PACKS', 64; ...
   'SPECIAL_FEATURES', 1024; ...
   'FIRMWARE_VERSION_NAVIGATION', 16; ...
   'FIRMWARE_VERSION_SCIENCE', 16; ...
   'GLIDER_MANUAL_VERSION', 16; ...
   'ANOMALY', 256; ...
   'CUSTOMIZATION', 1024; ...
   'DAC_FORMAT_ID', 16 ...
   };

error = 0;
for idGc = 1:size(checkMaxSizeFields, 1)
   attName = checkMaxSizeFields{idGc, 1};
   attValue = deployJsonData.glider_characteristics.(attName);
   if (ischar(attValue) && (size(attValue, 1) > 1))
      attValue = cellstr(attValue)';
   end
   maxSize = checkMaxSizeFields{idGc, 2};
   if (iscellstr(attValue))
      attValueList = attValue;
      for idV = 1:length(attValueList)
         attValue = attValueList{idV};
         if (length(attValue) > maxSize)
            fprintf('ERROR: ''%s'' ''glider_characteristics'' value should not exceed %d characters in json file (%s)\n', ...
               attName, maxSize, a_deployJsonFilePathName);
            error = 1;
         end
      end
   else
      if (length(attValue) > maxSize)
         fprintf('ERROR: ''%s'' ''glider_characteristics'' value should not exceed %d characters in json file (%s)\n', ...
            attName, maxSize, a_deployJsonFilePathName);
         error = 1;
      end
   end
end
if (error)
   return
end

% items with expected common dimension
dimGliderCharactList = {
   'TRANS_SYSTEM', ...
   'TRANS_SYSTEM_ID', ...
   'TRANS_FREQUENCY', ...
   };

dim = [];
error = 0;
for idGc = 1:length(dimGliderCharactList)
   attName = dimGliderCharactList{idGc};
   attValue = deployJsonData.glider_characteristics.(attName);
   if (ischar(attValue) && (size(attValue, 1) > 1))
      attValue = cellstr(attValue)';
   end
   if (iscellstr(attValue))
      dim = [dim length(attValue)];
   else
      if (~isempty(attValue))
         dim = [dim 1];
      elseif (size(attValue, 2) > 0)
         dim = [dim size(attValue, 2)];
      else
         dim = [dim 1];
      end
   end
end
if (length(unique(dim)) > 1)
   listStr = sprintf('%s, ', dimGliderCharactList{:});
   fprintf('ERROR: ''%s'' of ''glider_characteristics'' should have the same dimension in json file (%s)\n', ...
      listStr(1:end-2), a_deployJsonFilePathName);
   error = 1;
end
if (error)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected glider deployment
deployExpGliderDeploytList = {
   'DEPLOYMENT_START_DATE', ...
   'DEPLOYMENT_START_LATITUDE', ...
   'DEPLOYMENT_START_LONGITUDE', ...
   'DEPLOYMENT_START_QC', ...
   'DEPLOYMENT_PLATFORM', ...
   'DEPLOYMENT_CRUISE_ID', ...
   'DEPLOYMENT_REFERENCE_STATION_ID', ...
   'DEPLOYMENT_END_DATE', ...
   'DEPLOYMENT_END_LATITUDE', ...
   'DEPLOYMENT_END_LONGITUDE', ...
   'DEPLOYMENT_END_QC', ...
   'DEPLOYMENT_END_STATUS', ...
   'DEPLOYMENT_OPERATOR' ...
   };

fieldNames = fields(deployJsonData.glider_deployment);
error = 0;
for idGd = 1:length(deployExpGliderDeploytList)
   if (~any(strcmp(deployExpGliderDeploytList{idGd}, fieldNames) == 1))
      fprintf('ERROR: ''%s'' field expected in ''glider_deployment'' of json file (%s)\n', ...
         deployExpGliderDeploytList{idGd}, a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

% expected numeric fields
numericGliderDeployList = {
   'DEPLOYMENT_START_LATITUDE', ...
   'DEPLOYMENT_START_LONGITUDE', ...
   'DEPLOYMENT_START_QC', ...
   'DEPLOYMENT_END_LATITUDE', ...
   'DEPLOYMENT_END_LONGITUDE', ...
   'DEPLOYMENT_END_QC' ...
   };

error = 0;
for idGd = 1:length(numericGliderDeployList)
   attName = numericGliderDeployList{idGd};
   attValue = deployJsonData.glider_deployment.(attName);
   if (~isnumeric(attValue))
      fprintf('ERROR: ''%s'' of ''glider_deployment'' should be numeric in json file (%s)\n', ...
         attName, a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

% constraints on glider deployment
checkGliderDeployList = {
   'DEPLOYMENT_START_QC', 0, '2.1'; ...
   'DEPLOYMENT_END_QC', 0, '2.1' ...
   };

error = 0;
for idGd = 1:size(checkGliderDeployList, 1)
   attName = checkGliderDeployList{idGd, 1};
   attValue = deployJsonData.glider_deployment.(attName);
   mandFlag = checkGliderDeployList{idGd, 2};
   reftable = checkGliderDeployList{idGd, 3};
   if (mandFlag && isempty(attValue))
      fprintf('ERROR: ''%s'' ''glider_deployment'' is mandatory in json file (%s)\n', ...
         attName, a_deployJsonFilePathName);
      error = 1;
   end
   if (~isempty(reftable) && ~isempty(attValue))
      idF = find(strcmp(reftable, refTables(:, 1)));
      if (~ismember(strtrim(num2str(attValue)), refTables{idF, 2}))
         fprintf('ERROR: ''%s'' ''glider_deployment'' value (%s) is not in reference table %s in json file (%s)\n', ...
            attName, strtrim(num2str(attValue)), reftable, a_deployJsonFilePathName);
         error = 1;
      end
   end
end
if (error)
   return
end

% contraints on free text variable length
checkMaxSizeFields = {
   'DEPLOYMENT_START_DATE', 14; ...
   'DEPLOYMENT_PLATFORM', 32; ...
   'DEPLOYMENT_CRUISE_ID', 32; ...
   'DEPLOYMENT_REFERENCE_STATION_ID', 256; ...
   'DEPLOYMENT_END_DATE', 14; ...
   'DEPLOYMENT_END_STATUS', 1; ...
   'DEPLOYMENT_OPERATOR', 256 ...
   };

error = 0;
for idGd = 1:size(checkMaxSizeFields, 1)
   attName = checkMaxSizeFields{idGd, 1};
   attValue = deployJsonData.glider_deployment.(attName);
   if (ischar(attValue) && (size(attValue, 1) > 1))
      attValue = cellstr(attValue)';
   end
   maxSize = checkMaxSizeFields{idGd, 2};
   if (iscellstr(attValue))
      attValueList = attValue;
      for idV = 1:length(attValueList)
         attValue = attValueList{idV};
         if (length(attValue) > maxSize)
            fprintf('ERROR: ''%s'' ''glider_deployment'' value should not exceed %d characters in json file (%s)\n', ...
               attName, maxSize, a_deployJsonFilePathName);
            error = 1;
         end
      end
   else
      if (length(attValue) > maxSize)
         fprintf('ERROR: ''%s'' ''glider_deployment'' value should not exceed %d characters in json file (%s)\n', ...
            attName, maxSize, a_deployJsonFilePathName);
         error = 1;
      end
   end
end
if (error)
   return
end

% check dates
error = 0;
if (~isempty(deployJsonData.glider_deployment.DEPLOYMENT_START_DATE))
   if (~check_date(deployJsonData.glider_deployment.DEPLOYMENT_START_DATE))
      fprintf('ERROR: ''DEPLOYMENT_START_DATE'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
if (~isempty(deployJsonData.glider_deployment.DEPLOYMENT_END_DATE))
   if (~check_date(deployJsonData.glider_deployment.DEPLOYMENT_END_DATE))
      fprintf('ERROR: ''DEPLOYMENT_END_DATE'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

% check latitudes and longitudes
error = 0;
lat = deployJsonData.glider_deployment.DEPLOYMENT_START_LATITUDE;
if (~isempty(lat))
   if ((lat < -90) || (lat > 90))
      fprintf('ERROR: ''DEPLOYMENT_START_LATITUDE'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
lat = deployJsonData.glider_deployment.DEPLOYMENT_END_LATITUDE;
if (~isempty(lat))
   if ((lat < -90) || (lat > 90))
      fprintf('ERROR: ''DEPLOYMENT_END_LATITUDE'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
lon = deployJsonData.glider_deployment.DEPLOYMENT_START_LONGITUDE;
if (~isempty(lat))
   if ((lon < -180) || (lon > 180))
      fprintf('ERROR: ''DEPLOYMENT_START_LONGITUDE'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
lon = deployJsonData.glider_deployment.DEPLOYMENT_END_LONGITUDE;
if (~isempty(lat))
   if ((lon < -180) || (lon > 180))
      fprintf('ERROR: ''DEPLOYMENT_END_LONGITUDE'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

% check DEPLOYMENT_END_STATUS value
error = 0;
if (~isempty(deployJsonData.glider_deployment.DEPLOYMENT_END_STATUS))
   if (any(~ismember(deployJsonData.glider_deployment.DEPLOYMENT_END_STATUS, {'L', 'R'})))
      fprintf('ERROR: ''DEPLOYMENT_END_STATUS'' ''glider_deployment'' value is not consistent in json file (%s)\n', ...
         a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% coordinate variables information
coordVar = deployJsonData.coordinate_variables;
error = 0;
egoVarName = [];
gliderVarName = [];
for idC = 1:length(coordVar)
   if (~isfield(coordVar(idC), 'ego_variable_name') || ...
         ~isfield(coordVar(idC), 'glider_variable_name'))
      fprintf('ERROR: inconsistent ''coordinate_variables'' (#%d) information in json file (%s)\n', ...
         idC, a_deployJsonFilePathName);
      error = 1;
   else
      egoVarName{end+1} = coordVar(idC).ego_variable_name;
      gliderVarName{end+1} = coordVar(idC).glider_variable_name;
   end
end
if (error)
   return
end

error = 0;
egoVarNameRef = sort([{'TIME'} {'LATITUDE'} {'LONGITUDE'}]);
if (~isempty(setdiff(egoVarName, egoVarNameRef)) || ...
      ~isempty(setdiff(egoVarNameRef, egoVarName)))
   fprintf('ERROR: ''ego_variable_name'' of ''coordinate_variables'' should be ''TIME'', ''LATITUDE'' and ''LONGITUDE'' in json file (%s)\n', ...
      a_deployJsonFilePathName);
   error = 1;
end
if (error)
   return
end

error = 0;
idF = find(strcmp(egoVarName, 'TIME'));
if (isempty(gliderVarName{idF}))
   fprintf('ERROR: ''glider_variable_name'' of ''coordinate_variables'' should be set for ''TIME'' in json file (%s)\n', ...
      a_deployJsonFilePathName);
   error = 1;
end
if (error)
   return
end

error = 0;
idF1 = find(strcmp(egoVarName, 'LATITUDE'));
idF2 = find(strcmp(egoVarName, 'LONGITUDE'));
if ((isempty(gliderVarName{idF1}) && ~isempty(gliderVarName{idF2})) || ...
      (~isempty(gliderVarName{idF1}) && isempty(gliderVarName{idF2})))
   fprintf('ERROR: ''glider_variable_name'' of ''coordinate_variables'' should be both empty or both set for ''LATITUDE'' and ''LONGITUDE'' in json file (%s)\n', ...
      a_deployJsonFilePathName);
   error = 1;
end
if (error)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% glider sensor file information
glSensorFile = deployJsonData.glider_sensor;
error = 0;
for idS = 1:length(glSensorFile)
   if (~isfield(glSensorFile(idS), 'sensor_file_name'))
      fprintf('ERROR: inconsistent ''glider_sensor'' (#%d) information in json file (%s)\n', ...
         idS, a_deployJsonFilePathName);
      error = 1;
   end
end
if (error)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected sensor information
sensorExpInfoList = {
   'SENSOR', ...
   'SENSOR_MAKER', ...
   'SENSOR_MODEL', ...
   'SENSOR_SERIAL_NO', ...
   'SENSOR_MOUNT', ...
   'SENSOR_ORIENTATION', ...
   'PARAMETER', ...
   'PARAMETER_SENSOR', ...
   'PARAMETER_DATA_MODE', ...
   'PARAMETER_UNITS', ...
   'PARAMETER_ACCURACY', ...
   'PARAMETER_RESOLUTION', ...
   'CALIBRATION_COEFFICIENT', ...
   'parametersList' ...
   };

% constraints on sensor information
checkInfoList = {
   'SENSOR', 1, '25'; ...
   'SENSOR_MAKER', 1, '26'; ...
   'SENSOR_MODEL', 1, '27'; ...
   'SENSOR_SERIAL_NO', 1, ''; ...
   'SENSOR_MOUNT', 0, '20'; ...
   'SENSOR_ORIENTATION', 0, '21'; ...
   'PARAMETER', 1, '3'; ...
   'PARAMETER_SENSOR', 1, '25'; ...
   'PARAMETER_DATA_MODE', 1, '19' ...
   };

% list of expected parameter information
if (g_decGl_seaGliderInputNc == 1)
   paramExpInfoList = {
      'ego_variable_name', ...
      'glider_variable_name', ...
      'glider_adjusted_variable_name', ...
      'comment', ...
      'cell_methods', ...
      'reference_scale', ...
      'derivation_equation', ...
      'derivation_coefficient', ...
      'derivation_comment', ...
      'derivation_date', ...
      'processing_id' ...
      };
else
   paramExpInfoList = {
      'ego_variable_name', ...
      'glider_variable_name', ...
      'comment', ...
      'cell_methods', ...
      'reference_scale', ...
      'derivation_equation', ...
      'derivation_coefficient', ...
      'derivation_comment', ...
      'derivation_date', ...
      'processing_id' ...
      };
end

% items with expected common dimension
dimSensorList = {
   'SENSOR', ...
   'SENSOR_MAKER', ...
   'SENSOR_MODEL', ...
   'SENSOR_SERIAL_NO', ...
   'SENSOR_MOUNT', ...
   'SENSOR_ORIENTATION', ...
   };

% items with expected common dimension
dimParamList = {
   'PARAMETER', ...
   'PARAMETER_SENSOR', ...
   'PARAMETER_DATA_MODE', ...
   'PARAMETER_UNITS', ...
   'PARAMETER_ACCURACY', ...
   'PARAMETER_RESOLUTION', ...
   };

% contraints on free text variable length
checkMaxSizeSensorFields = {
   'SENSOR_SERIAL_NO', 16 ...
   };

checkMaxSizeParamFields = {
   'PARAMETER_UNITS', 32; ...
   'PARAMETER_ACCURACY', 32; ...
   'PARAMETER_RESOLUTION', 32 ...
   };

checkMaxSizeParamListFields = {
   'derivation_equation', 4096; ...
   'derivation_coefficient', 4096; ...
   'derivation_comment', 4096; ...
   'derivation_date', 14 ...
   };

% check sensor files
[jsonDir, ~, ~] = fileparts(a_deployJsonFilePathName);
sensorFiles = deployJsonData.glider_sensor;
error = 0;
for idFile = 1:length(sensorFiles)
   sensorFileName = sensorFiles(idFile).sensor_file_name;
   sensorFilePathName = [jsonDir '/' sensorFileName];
   if ~(exist(sensorFilePathName, 'file') == 2)
      fprintf('ERROR: sensor file not found (%s)\n', ...
         sensorFilePathName);
      error = 1;
   else
      
      % read the sensor information from json file
      try
         sensorData = gl_load_json(sensorFilePathName);
      catch
         errorStruct = lasterror;
         fprintf('ERROR: error format in json file (%s)\n', ...
            sensorFilePathName);
         fprintf('%s\n', ...
            errorStruct.message);
         return
      end
      
      if ~(isfield(sensorData, 'EGO_format_version') && ...
            ~isempty(sensorData.EGO_format_version) && ...
            (str2double(sensorData.EGO_format_version) == 1.4))
         fprintf('ERROR: expected ''1.4'' EGO format version in json file (%s)\n', ...
            sensorFilePathName);
         return
      end
      if (isfield(sensorData, 'EGO_format_version'))
         sensorData = rmfield(sensorData, 'EGO_format_version');
      end
      
      if (isfield(sensorData, 'PARAMETER_DATA_MODE'))
         sensorData.PARAMETER_DATA_MODE = cellstr(sensorData.PARAMETER_DATA_MODE')';
      end
      
      % check the field list
      fieldNames = fields(sensorData);
      for idS = 1:length(sensorExpInfoList)
         if (~any(strcmp(sensorExpInfoList{idS}, fieldNames) == 1))
            fprintf('ERROR: %s field expected in json file (%s) => deployment ignored\n', ...
               sensorExpInfoList{idS}, sensorFilePathName);
            return
         end
         
         idF = find(strcmp(sensorExpInfoList{idS}, checkInfoList(:, 1)));
         if (~isempty(idF))
            attName = checkInfoList{idF, 1};
            attValue = sensorData.(attName);
            mandFlag = checkInfoList{idF, 2};
            reftable = checkInfoList{idF, 3};
            if (ischar(attValue) && (size(attValue, 1) > 1))
               attValue = cellstr(attValue)';
            end
            if (iscellstr(attValue))
               attValueList = attValue;
               for idV = 1:length(attValueList)
                  attValue = attValueList{idV};
                  if (~isempty(attValue))
                     attValue = strtrim(attValue);
                  end
                  if (mandFlag && isempty(attValue))
                     fprintf('ERROR: ''%s'' ''sensor'' is mandatory in json file (%s)\n', ...
                        attName, sensorFilePathName);
                     error = 1;
                  end
                  if (~isempty(reftable) && ~isempty(attValue))
                     idF = find(strcmp(reftable, refTables(:, 1)));
                     if (~ismember(attValue, refTables{idF, 2}))
                        if (strcmp(attName, 'SENSOR') || strcmp(attName, 'PARAMETER'))
                           attValueSize = 1;
                           attValue2 = attValue(1:attValueSize);
                           while ((~ismember(attValue2, refTables{idF, 2})) && (attValueSize < length(attValue)))
                              attValueSize = attValueSize + 1;
                              attValue2 = attValue(1:attValueSize);
                           end
                           if (~ismember(attValue2, refTables{idF, 2}))
                              fprintf('ERROR: ''%s'' ''sensor'' value (%s) is not in reference table %s in json file (%s)\n', ...
                                 attName, attValue, reftable, sensorFilePathName);
                              error = 1;
                           else
                              remain = attValue(attValueSize+1:end);
                              if ~(((remain(1) == '_') && (ismember(double(attValue2(end)), 48:57)) && (~any(~ismember(double(remain(2:end)), 48:57)))) || ...
                                    (~any(~ismember(double(remain), 48:57))))
                                 fprintf('ERROR: ''%s'' ''sensor'' value (%s) is not in reference table %s in json file (%s)\n', ...
                                    attName, attValue, reftable, sensorFilePathName);
                                 error = 1;
                              end
                           end
                        else
                           fprintf('ERROR: ''%s'' ''sensor'' value (%s) is not in reference table %s in json file (%s)\n', ...
                              attName, attValue, reftable, sensorFilePathName);
                           error = 1;
                        end
                     end
                  end
               end
            else
               if (~isempty(attValue))
                  attValue = strtrim(attValue);
               end
               if (mandFlag && isempty(attValue))
                  fprintf('ERROR: ''%s'' ''sensor'' is mandatory in json file (%s)\n', ...
                     attName, sensorFilePathName);
                  error = 1;
               end
               if (~isempty(reftable) && ~isempty(attValue))
                  idF = find(strcmp(reftable, refTables(:, 1)));
                  if (~ismember(attValue, refTables{idF, 2}))
                     fprintf('ERROR: ''%s'' ''sensor'' value (%s) is not in reference table %s in json file (%s)\n', ...
                        attName, attValue, reftable, sensorFilePathName);
                     error = 1;
                  end
               end
            end
         end

         if (strcmp(sensorExpInfoList{idS}, 'parametersList'))
            paramVar = sensorData.parametersList;
            for idP = 1:length(paramVar)
               if (iscell(paramVar))
                  paramStruct = paramVar{idP};
               else
                  paramStruct = paramVar(idP);
               end
               
               if (~isfield(paramStruct, 'ego_variable_name') || ...
                     ~isfield(paramStruct, 'glider_variable_name'))
                  fprintf('ERROR: inconsistent ''parametersList'' (#%d) information in json file (%s) => deployment ignored\n', ...
                     idP, a_deployJsonFilePathName);
                  return
               end
               
               % check the field list of the parameter
               paramFieldNames = fields(paramStruct);
               for idP2 = 1:length(paramExpInfoList)
                  if (~any(strcmp(paramExpInfoList{idP2}, paramFieldNames) == 1))
                     fprintf('ERROR: ''%s'' field expected in the attributes of EGO var ''%s'' in json file (%s) => deployment ignored\n', ...
                        paramExpInfoList{idP2}, paramStruct.ego_variable_name, sensorFilePathName);
                     return
                  end
               end
            end
         end
      end
      
      for idGs = 1:size(checkMaxSizeSensorFields, 1)
         attName = checkMaxSizeSensorFields{idGs, 1};
         attValue = sensorData.(attName);
         if (ischar(attValue) && (size(attValue, 1) > 1))
            attValue = cellstr(attValue)';
         end
         maxSize = checkMaxSizeSensorFields{idGs, 2};
         if (iscellstr(attValue))
            attValueList = attValue;
            for idV = 1:length(attValueList)
               attValue = attValueList{idV};
               if (length(attValue) > maxSize)
                  fprintf('ERROR: ''%s'' ''sensor'' value should not exceed %d characters in json file (%s)\n', ...
                     attName, maxSize, a_deployJsonFilePathName);
                  error = 1;
               end
            end
         else
            if (length(attValue) > maxSize)
               fprintf('ERROR: ''%s'' ''sensor'' value should not exceed %d characters in json file (%s)\n', ...
                  attName, maxSize, a_deployJsonFilePathName);
               error = 1;
            end
         end
      end
      
      for idGp = 1:size(checkMaxSizeParamFields, 1)
         attName = checkMaxSizeParamFields{idGp, 1};
         attValue = sensorData.(attName);
         if (ischar(attValue) && (size(attValue, 1) > 1))
            attValue = cellstr(attValue)';
         end
         maxSize = checkMaxSizeParamFields{idGp, 2};
         if (iscellstr(attValue))
            attValueList = attValue;
            for idV = 1:length(attValueList)
               attValue = attValueList{idV};
               if (length(attValue) > maxSize)
                  fprintf('ERROR: ''%s'' ''parameter'' value should not exceed %d characters in json file (%s)\n', ...
                     attName, maxSize, a_deployJsonFilePathName);
                  error = 1;
               end
            end
         else
            if (length(attValue) > maxSize)
               fprintf('ERROR: ''%s'' ''parameter'' value should not exceed %d characters in json file (%s)\n', ...
                  attName, maxSize, a_deployJsonFilePathName);
               error = 1;
            end
         end
      end

      for idGp = 1:size(checkMaxSizeParamListFields, 1)
         attName = checkMaxSizeParamListFields{idGp, 1};
         maxSize = checkMaxSizeParamListFields{idGp, 2};
         for idPl = 1:size(sensorData.parametersList, 2)
            paramList = sensorData.parametersList(idPl);
            attValue = paramList.(attName);
            if (length(attValue) > maxSize)
               fprintf('ERROR: ''%s'' ''parameter'' value should not exceed %d characters in json file (%s)\n', ...
                  attName, maxSize, a_deployJsonFilePathName);
               error = 1;
            end
         end
      end
      
      % check derivation date
      for idPl = 1:size(sensorData.parametersList, 2)
         paramList = sensorData.parametersList(idPl);
         attValue = paramList.derivation_date;
         if (~isempty(attValue))
            if (~check_date(attValue))
               fprintf('ERROR: ''derivation_date'' ''parameter'' value is not consistent in json file (%s)\n', ...
                  sensorFilePathName);
               error = 1;
            end
         end
      end
      
      dim = [];
      for idS = 1:length(dimSensorList)
         attName = dimSensorList{idS};
         attValue = sensorData.(attName);
         if (ischar(attValue) && (size(attValue, 1) > 1))
            attValue = cellstr(attValue)';
         end
         if (iscellstr(attValue))
            dim = [dim length(attValue)];
         else
            if (~isempty(attValue))
               dim = [dim 1];
            elseif (size(attValue, 2) > 0)
               dim = [dim size(attValue, 2)];
            end
         end
      end
      if (length(unique(dim)) > 1)
         listStr = sprintf('%s, ', dimSensorList{:});
         fprintf('ERROR: ''%s'' of ''sensor'' should have the same dimension in json file (%s)\n', ...
            listStr(1:end-2), sensorFilePathName);
         error = 1;
      end
      
      dim = [];
      for idP = 1:length(dimParamList)
         attName = dimParamList{idP};
         attValue = sensorData.(attName);
         if (ischar(attValue) && (size(attValue, 1) > 1))
            attValue = cellstr(attValue)';
         end
         if (iscellstr(attValue))
            dim = [dim length(attValue)];
         else
            if (~isempty(attValue))
               dim = [dim 1];
            elseif (size(attValue, 2) > 0)
               dim = [dim size(attValue, 2)];
            end
         end
      end
      if (length(unique(dim)) > 1)
         listStr = sprintf('%s, ', dimParamList{:});
         fprintf('ERROR: ''%s'' of ''sensor'' should have the same dimension in json file (%s)\n', ...
            listStr(1:end-2), sensorFilePathName);
         error = 1;
      end
      
      % check that all sensors of PARAMETER_SENSOR are in SENSOR
      sensorList = sensorData.SENSOR;
      if (ischar(sensorList) && (size(sensorList, 1) > 1))
         sensorList = cellstr(sensorList)';
      end
      parameterSensorList = sensorData.PARAMETER_SENSOR;
      if (ischar(parameterSensorList) && (size(parameterSensorList, 1) > 1))
         parameterSensorList = cellstr(parameterSensorList)';
      end
      missingSensor = setdiff(parameterSensorList, sensorList);
      if (~isempty(missingSensor))
         listStr = sprintf('%s, ', missingSensor{:});
         fprintf('ERROR: ''%s'' of ''PARAMETER_SENSOR'' should be declared in ''SENSOR'' in json file (%s)\n', ...
            listStr(1:end-2), sensorFilePathName);
         error = 1;
      end
      
      % store the data
      if (iscell(sensorData.parametersList))
         % the fields are present but not in the same order => the concatenation
         % cannot be done.
         % we will sort the fields
         parametersList2 = [];
         for id = 1:size(sensorData.parametersList, 2)
            parametersList2 = [parametersList2 orderfields(sensorData.parametersList{1, id}, sensorData.parametersList{1, 1})];
         end
         sensorData.parametersList = parametersList2;
      end
      
      deployJsonData.glider_sensor(idFile).sensor_data = sensorData;
   end
end
if (error)
   return
end

o_outputData = deployJsonData;

return

% ------------------------------------------------------------------------------
% Read reference tables (that should be in Matlab path).
%
% SYNTAX :
%  [o_refTables] = get_ref_tables
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_refTables : reference tables information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_refTables] = get_ref_tables

% output parameters initialization
o_refTables = [];


% list of reference tables
refTableList = {
   '1', ...
   '2.1', ...
   '2.2', ...
   '3', ...
   '4', ...
   '6', ...
   '7', ...
   '8', ...
   '9.1', ...
   '9.2', ...
   '10.1', ...
   '10.2' ...
   '11' ...
   '12' ...
   '19' ...
   '20' ...
   '21' ...
   '22' ...
   '23' ...
   '24' ...
   '25' ...
   '26' ...
   '27' ...
   };

refTables = cell(length(refTableList), 2);
for idT = 1:length(refTableList)
   refTableName = ['GL_REFERENCE_TABLE_' refTableList{idT} '.txt'];
   if ~(exist(refTableName, 'file') == 2)
      fprintf('ERROR: %s file should be in the Matlab path\n', refTableName);
      return
   end
   
   % read ref table file
   fId = fopen(refTableName, 'r');
   if (fId == -1)
      fprintf('ERROR: Unable to open file: %s\n', refTableName);
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\t');
   fclose(fId);
   
   refTables{idT, 1} = refTableList{idT};
   refTables{idT, 2} = fileContents{:}';
end

o_refTables = refTables;

return

% ------------------------------------------------------------------------------
% Check that input date string is compliant with expected format
% (YYYYMMDDHHMISS).
%
% SYNTAX :
%  [o_ok] = check_date(a_dateStr)
%
% INPUT PARAMETERS :
%   a_dateStr : date to be checked
%
% OUTPUT PARAMETERS :
%   o_ok : 1: date is compliant, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/27/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = check_date(a_dateStr)

% output parameters initialization
o_ok = 0;

% default values
global g_decGl_janFirst1950InMatlab;


% check input date
if (length(a_dateStr) == 14)
   if (~any(~ismember(double(a_dateStr), 48:57)))
      juldDate = datenum(a_dateStr, 'yyyymmddHHMMSS') - g_decGl_janFirst1950InMatlab;
      janFirst2000InJulD = gl_gregorian_2_julian('2000/01/01 00:00:00');
      if (juldDate > janFirst2000InJulD)
         o_ok = 1;
      end
   end
end

return
