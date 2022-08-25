% ------------------------------------------------------------------------------
% Convert JSON deployment and sencor files from EGO 1.2 to EGO 1.3.
% The default behaviour is :
%    - to process all the deployments (the directories) stored in the
%      DATA_DIRECTORY directory
% this behaviour can be modified by input arguments.
%
% SYNTAX :
%   gl_convert_json_files_from_1_2_to_1_3(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments 
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DATA_DIRECTORY directory) to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/22/2019 - RNU - creation
% ------------------------------------------------------------------------------
function gl_convert_json_files_from_1_2_to_1_3(varargin)

% top directory of the deployment directories
DATA_DIRECTORY = 'C:\Users\jprannou\NEW_20190125\_DATA\GLIDER\FORMAT_1.3/';
DATA_DIRECTORY = 'C:\Users\jprannou\NEW_20190125\_DATA\GLIDER\VALIDATION_DOXY/';

% directory to store log files
DIR_LOG_FILE = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\work\log\';

% reference file for JSON deployment file
JSON_DEPLOYMENT_REF_FILE = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\soft\util\json\deployment_ref.json';

% reference file for JSON sensor file
JSON_SENSOR_REF_FILE = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\soft\util\json\sensor_ref.json';

% default values initialization
gl_init_default_values;


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'gl_convert_json_files_from_1_2_to_1_3_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check input arguments
dataToProcessDir = '';
stop = 0;
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            dataToProcessDir = [DATA_DIRECTORY '/' varargin{id+1} '/'];
            deploymentDirName = varargin{id+1};
            if (~exist(dataToProcessDir, 'dir'))
               fprintf('ERROR: %s is not an existing directory => exit\n', varargin{id+1});
               stop = 1;
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
end
if (stop)
   return
end

% print the arguments understanding
if (isempty(dataToProcessDir))
   fprintf('INFO: process all the deployments of the %s directory\n', DATA_DIRECTORY);
else
   fprintf('INFO: process the deployment stored in the %s directory\n', dataToProcessDir);
end

% process glider data
if (isempty(dataToProcessDir))
   % process all the deployments of the DATA_DIRECTORY directory
   dirInfo = dir(DATA_DIRECTORY);
   for dirNum = 1:length(dirInfo)
      if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
         dirName = dirInfo(dirNum).name;
         
         % process the data of this deployment
         gl_convert_json_files( ...
            [DATA_DIRECTORY '/' dirName '/'], ...
            dirName, ...
            JSON_DEPLOYMENT_REF_FILE, ...
            JSON_SENSOR_REF_FILE);
      end
   end
else
   % process the data of this deployment
   gl_convert_json_files( ...
      dataToProcessDir, ...
      deploymentDirName, ...
      JSON_DEPLOYMENT_REF_FILE, ...
      JSON_SENSOR_REF_FILE);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Convert JSON deployment and sencor files from EGO 1.2 to EGO 1.3.
%
% SYNTAX :
%  gl_convert_json_files(a_deploymentDirName, a_deploymentName, ...
%    a_jsonDeploymentRefFile, a_jsonSensorRefFile)
%
% INPUT PARAMETERS :
%   a_deploymentDirName     : name of the deployment directory
%   a_deploymentName        : name of the deployment
%   a_jsonDeploymentRefFile : json deployment reference file
%   a_jsonDeploymentRefFile : json sensor reference file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/22/2019 - RNU - creation
% ------------------------------------------------------------------------------
function gl_convert_json_files(a_deploymentDirName, a_deploymentName, ...
   a_jsonDeploymentRefFile, a_jsonSensorRefFile)

deployJsonFile = [a_deploymentDirName '/json_1.2/' a_deploymentName '.json'];
if ~(exist(deployJsonFile, 'file') == 2)
   fprintf('ERROR: expected json deployment file not found (%s) => deployment ignored\n', ...
      deployJsonFile);
   return
end

fprintf('Converting json deployment file: %s\n', ...
   deployJsonFile);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ INPUT JSON FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read the json deployment file
try
   deployJsonData = gl_load_json(deployJsonFile);
catch
   errorStruct = lasterror;
   fprintf('ERROR: error format in json file (%s)\n', ...
      deployJsonFile);
   fprintf('%s\n', ...
      errorStruct.message);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of global attributes
deployGlobAttList = {
   'platform_code', ...
   'wmo_platform_code', ...
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
   'update_interval' ...
   };

inputFields = fields(deployJsonData.global_attributes);
globAttStruct = [];
for idGa = 1:length(deployGlobAttList)
   outputField = deployGlobAttList{idGa};
   globAttStruct.(outputField) = '';
   idF = find(cellfun(@(x) strncmp(outputField, x, length(outputField)), inputFields) == 1);
   if (~isempty(idF))
      if (length(idF) > 1)
         idF = find(cellfun(@(x) strcmp(outputField, x), inputFields) == 1);
      end
      if (~isempty(deployJsonData.global_attributes.(inputFields{idF})))
         globAttStruct.(outputField) = deployJsonData.global_attributes.(inputFields{idF});
      end
   elseif (strcmp(outputField, 'authors'))
      globAttStruct.(outputField) = deployJsonData.global_attributes.author;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of glider characteristics
deployGliderCharactList = {
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
   'DAC_FORMAT_ID' ...
   };

inputFields = fields(deployJsonData.glider_characteristics);
gliderCharStruct = [];
for idGc = 1:length(deployGliderCharactList)
   outputField = deployGliderCharactList{idGc};
   gliderCharStruct.(outputField) = '';
   idF = find(cellfun(@(x) strncmp(outputField, x, length(outputField)), inputFields) == 1);
   if (~isempty(idF))
      if (length(idF) > 1)
         idF = find(cellfun(@(x) strcmp(outputField, x), inputFields) == 1);
      end
      if (~isempty(deployJsonData.glider_characteristics.(inputFields{idF})))
         gliderCharStruct.(outputField) = deployJsonData.glider_characteristics.(inputFields{idF});
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of glider deployment items
deployGliderDeployList = {
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

inputFields = fields(deployJsonData.glider_deployment);
gliderDeplStruct = [];
for idGd = 1:length(deployGliderDeployList)
   outputField = deployGliderDeployList{idGd};
   gliderDeplStruct.(outputField) = '';
   idF = find(cellfun(@(x) strncmp(outputField, x, length(outputField)), inputFields) == 1);
   if (~isempty(idF))
      if (length(idF) > 1)
         idF = find(cellfun(@(x) strcmp(outputField, x), inputFields) == 1);
      end
      if (~isempty(deployJsonData.glider_deployment.(inputFields{idF})))
         gliderDeplStruct.(outputField) = deployJsonData.glider_deployment.(inputFields{idF});
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% coordinate variables
coorVarData = [];
inputData = deployJsonData.coordinate_variables;
for idCv = 1:length(inputData)
   coorData = inputData(idCv);
   if (ismember(coorData.ego_variable_name, [{'TIME'}, {'LATITUDE'}, {'LONGITUDE'}]))
      gliderVarName = coorData.glider_variable_name;
      idF = strfind(gliderVarName, '.');
      coorData.glider_variable_name = gliderVarName(idF(end)+1:end);
      coorVarData = [coorVarData coorData];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% glider sensors
glSensorData = deployJsonData.glider_sensor;

glSensorFileData = [];
for idGs = 1:length(glSensorData)
   glSensor = glSensorData(idGs);
   sensorFileName = glSensor.sensor_file_name;
   
   sensorJsonFile = [a_deploymentDirName '/json_1.2/' sensorFileName];
   if ~(exist(sensorJsonFile, 'file') == 2)
      fprintf('ERROR: expected json sensor file not found (%s) => deployment ignored\n', ...
         sensorJsonFile);
      return
   end
   
   fprintf('Converting json sensor file: %s\n', ...
      sensorJsonFile);
   
   % read the json sensor file
   try
      sensorJsonData = gl_load_json(sensorJsonFile);
   catch
      errorStruct = lasterror;
      fprintf('ERROR: error format in json file (%s)\n', ...
         sensorJsonFile);
      fprintf('%s\n', ...
         errorStruct.message);
      return
   end
   
   dataStruct = [];
   dataStruct.file = sensorFileName;
   dataStruct.data = sensorJsonData;
   glSensorFileData = [glSensorFileData dataStruct];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE JSON DEPLOYMENT FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read reference JSON deployment contents
% open the file
fIdIn = fopen(a_jsonDeploymentRefFile, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_jsonDeploymentRefFile);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of numeric items
numericItemList = {
   'DEPLOYMENT_START_LATITUDE', ...
   'DEPLOYMENT_START_LONGITUDE', ...
   'DEPLOYMENT_START_QC', ...
   'DEPLOYMENT_END_LATITUDE', ...
   'DEPLOYMENT_END_LONGITUDE', ...
   'DEPLOYMENT_END_QC' ...
   };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of multi-dim items
multiDimItemList = {
   'POSITIONING_SYSTEM', ...
   'TRANS_SYSTEM', ...
   'TRANS_SYSTEM_ID', ...
   'TRANS_FREQUENCY' ...
   };

% convert deployment file
jsonDeploy = [];
currentStruct = [];
for idL = 1:length(jsonDeployRef)
   line = jsonDeployRef{idL};
   
   if (any(strfind(line, 'global_attributes')))
      currentStruct = globAttStruct;
   elseif (any(strfind(line, 'glider_characteristics')))
      currentStruct = gliderCharStruct;
   elseif (any(strfind(line, 'glider_deployment')))
      currentStruct = gliderDeplStruct;
   elseif (any(strfind(line, 'coordinate_variables')))
      currentStruct = [];
   elseif (any(strfind(line, 'glider_sensor')))
      currentStruct = [];
   end
   
   if (any(strfind(line, '<') & strfind(line, '>')))
      posStart = strfind(line, '<');
      posEnd = strfind(line, '>');
      pattern = line(posStart:posEnd);
      patternName = line(posStart+1:posEnd-1);
      
      patternValue = '';
      if (~isempty(currentStruct))
         if (ismember(patternName, multiDimItemList))
            dataValue = currentStruct.(patternName);
            if (ischar(dataValue) && (size(dataValue, 1) > 1))
               dataValue = cellstr(dataValue)';
            end
            if (iscellstr(dataValue))
               dataValueList = sprintf('"%s", ', dataValue{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            else
               patternValue = sprintf('"%s"', dataValue);
            end
         elseif (strcmp(patternName, 'authors'))
            dataValue = currentStruct.(patternName);
            
            firstName = '';
            lastName = '';
            email = '';
            affiliation = '';
            if (any(strfind(dataValue, '@')))
               email = dataValue;
               idF = strfind(dataValue, '@');
               if (length(idF) == 1)
                  part1 = dataValue(1:idF-1);
                  part2 = dataValue(idF+1:end);
                  if (any(strfind(part1, '.')))
                     idF = strfind(part1, '.');
                     if (length(idF) == 1)
                        firstName = part1(1:idF-1);
                        lastName = part1(idF+1:end);
                     end
                  end
                  if (any(strfind(part2, '.')))
                     idF = strfind(part2, '.');
                     if (length(idF) == 1)
                        affiliation = part2(1:idF-1);
                     end
                  end
               end
            end
            patternValue = [patternValue '[\n'];
            patternValue = [patternValue '            {\n'];
            patternValue = [patternValue sprintf('                "first_name": "%s",\n', firstName)];
            patternValue = [patternValue sprintf('                "last_name": "%s",\n', lastName)];
            patternValue = [patternValue sprintf('                "email": "%s",\n', email)];
            patternValue = [patternValue '                "orcid": "",\n'];
            patternValue = [patternValue sprintf('                "affiliations": "%s"\n', affiliation)];
            patternValue = [patternValue '            }\n'];
            patternValue = [patternValue '        ]'];
            
            fprintf('\nCheck conversion from ''author'' to ''authors''\n');
            fprintf('INPUT ''author'': %s\n', dataValue);
            fprintf('OUTPUT ''authors'':\n');
            fprintf('first_name: "%s"\n', firstName);
            fprintf('last_name: "%s"\n', lastName);
            fprintf('email: "%s"\n\n', email);
         else
            if (ischar(currentStruct.(patternName)) || iscell(currentStruct.(patternName)))
               patternValue = currentStruct.(patternName);
            else
               patternValue = num2str(currentStruct.(patternName));
            end
            if (isempty(patternValue))
               if (ismember(patternName, numericItemList))
                  patternValue = 'null';
               end
            end
         end
      elseif (strcmp(patternName, 'coordinate_variables'))
         for idCv = 1:length(coorVarData)
            coorVar = coorVarData(idCv);
            patternValue = [patternValue '        {\n'];
            patternValue = [patternValue sprintf('            "glider_variable_name": "%s",\n', coorVar.glider_variable_name)];
            patternValue = [patternValue sprintf('            "ego_variable_name": "%s"\n', coorVar.ego_variable_name)];
            patternValue = [patternValue '        }'];
            if (idCv < length(coorVarData))
               patternValue = [patternValue ',\n'];
            end
         end
      elseif (strcmp(patternName, 'glider_sensor'))
         for idGs = 1:length(glSensorData)
            glSensor = glSensorData(idGs);
            patternValue = [patternValue '        {\n'];
            patternValue = [patternValue sprintf('            "sensor_file_name": "%s"\n', glSensor.sensor_file_name)];
            patternValue = [patternValue '        }'];
            if (idGs < length(glSensorData))
               patternValue = [patternValue ',\n'];
            end
         end
      end
      line = regexprep(line, pattern, patternValue);
   end
   
   jsonDeploy{end+1} = sprintf('%s', line);
end

% create output directory
outputDirName = [a_deploymentDirName '/json_1.3/'];
% outputDirName = [a_deploymentDirName '/json_1.3_' datestr(now, 'yyyymmddTHHMMSS') '/'];
if (exist(outputDirName, 'dir') == 7)
   %    fprintf('ERROR: directory %s already exists => deployment ignored\n', ...
   %       outputDirName);
   %    return
else
   mkdir(outputDirName);
end

% create deployment file
ouputDeployJsonFile = [outputDirName '/' a_deploymentName '.json'];
fIdOut = fopen(ouputDeployJsonFile, 'wt');
if (fIdOut == -1)
   fprintf('ERROR: While creating file : %s\n', ouputDeployJsonFile);
   return
end

fprintf(fIdOut, '%s\n', jsonDeploy{:});

fclose(fIdOut);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE JSON SENSOR FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read reference JSON sensor contents
% open the file
fIdIn = fopen(a_jsonSensorRefFile, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_jsonSensorRefFile);
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

% convert sensor files
for idGs = 1:length(glSensorFileData)
   glSensor = glSensorFileData(idGs);
   glSensorData = glSensor.data;
   paramList = glSensorData.parametersList;
   
   paramDataTab = [];
   for idP = 1:length(paramList)
      paramInfo = paramList(idP);
      
      paramData = [];
      if (strcmp(paramInfo.ego_variable_name, 'PRES'))
         paramData.PARAMETER_SENSOR = 'CTD_PRES';
         paramData.PARAMETER_UNITS = 'decibar';
      elseif (strcmp(paramInfo.ego_variable_name, 'TEMP'))
         paramData.PARAMETER_SENSOR = 'CTD_TEMP';
         paramData.PARAMETER_UNITS = 'degree_Celsius';
      elseif (strcmp(paramInfo.ego_variable_name, 'CNDC'))
         paramData.PARAMETER_SENSOR = 'CTD_CNDC';
         paramData.PARAMETER_UNITS = 'mhos/m';
      elseif (strcmp(paramInfo.ego_variable_name, 'PSAL'))
         paramData.PARAMETER_SENSOR = 'CTD_CNDC';
         paramData.PARAMETER_UNITS = 'psu';
      else
         paramData.PARAMETER_SENSOR = '';
         paramData.PARAMETER_UNITS = '';
      end
      paramData.PARAMETER = paramInfo.ego_variable_name;
      paramData.PARAMETER_DATA_MODE = 'R';
      paramData.PARAMETER_ACCURACY = '';
      paramData.PARAMETER_RESOLUTION = '';
      paramData.ego_variable_name = paramInfo.ego_variable_name;
      gliderVarName = paramInfo.glider_variable_name;
      idF = strfind(gliderVarName, '.');
      if (~isempty(idF))
         gliderVarName = gliderVarName(idF(end)+1:end);
      end
      paramData.glider_variable_name = gliderVarName;
      paramData.comment = '';
      paramData.cell_methods = paramInfo.cell_methods;
      paramData.reference_scale = paramInfo.reference_scale;
      paramData.derivation_equation = paramInfo.derivation_equation;
      paramData.derivation_coefficient = paramInfo.derivation_coefficient;
      paramData.derivation_comment = paramInfo.derivation_comment;
      paramData.derivation_date = paramInfo.derivation_date;
      paramData.processing_id = '';
      
      paramDataTab = [paramDataTab paramData];
   end
   
   jsonSensor = [];
   for idL = 1:length(jsonSensorRef)
      line = jsonSensorRef{idL};
      
      if (any(strfind(line, '<') & strfind(line, '>')))
         posStart = strfind(line, '<');
         posEnd = strfind(line, '>');
         pattern = line(posStart:posEnd);
         patternName = line(posStart+1:posEnd-1);
         
         patternValue = '';
         nbSensor = length(unique({paramDataTab.PARAMETER_SENSOR}));
         switch (patternName)
            case 'SENSOR'
               dataList = unique({paramDataTab.PARAMETER_SENSOR}, 'stable');
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case {'SENSOR_MAKER', 'SENSOR_MODEL', 'SENSOR_ORIENTATION'}
               dataList = cell(1, nbSensor);
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'SENSOR_SERIAL_NO'
               dataValueList = repmat(sprintf('"%s", ', glSensorData.SENSOR_SERIAL_NO), 1, nbSensor);
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'SENSOR_MOUNT'
               dataValueList = repmat('"MOUNTED_ON_GLIDER", ', 1, nbSensor);
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
               
            case 'PARAMETER'
               dataList = {paramDataTab.PARAMETER};
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'PARAMETER_SENSOR'
               dataList = {paramDataTab.PARAMETER_SENSOR};
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'PARAMETER_DATA_MODE'
               dataList = {paramDataTab.PARAMETER_DATA_MODE};
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'PARAMETER_UNITS'
               dataList = {paramDataTab.PARAMETER_UNITS};
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'PARAMETER_ACCURACY'
               dataList = {paramDataTab.PARAMETER_ACCURACY};
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
            case 'PARAMETER_RESOLUTION'
               dataList = {paramDataTab.PARAMETER_RESOLUTION};
               dataValueList = sprintf('"%s", ', dataList{:});
               patternValue = sprintf('[%s]', dataValueList(1:end-2));
               
            case 'parametersList'
               for idP = 1:length(paramDataTab)
                  paramData = paramDataTab(idP);
                  patternValue = [patternValue '        {\n'];
                  patternValue = [patternValue sprintf('            "ego_variable_name"     : "%s",\n', paramData.ego_variable_name)];
                  patternValue = [patternValue sprintf('            "glider_variable_name"  : "%s",\n', paramData.glider_variable_name)];
                  patternValue = [patternValue sprintf('            "comment"               : "%s",\n', paramData.comment)];
                  patternValue = [patternValue sprintf('            "cell_methods"          : "%s",\n', paramData.cell_methods)];
                  patternValue = [patternValue sprintf('            "reference_scale"       : "%s",\n', paramData.reference_scale)];
                  patternValue = [patternValue '\n'];
                  patternValue = [patternValue sprintf('            "derivation_equation"   : "%s",\n', paramData.derivation_equation)];
                  patternValue = [patternValue sprintf('            "derivation_coefficient": "%s",\n', paramData.derivation_coefficient)];
                  patternValue = [patternValue sprintf('            "derivation_comment"    : "%s",\n', paramData.derivation_comment)];
                  patternValue = [patternValue sprintf('            "derivation_date"       : "%s",\n', paramData.derivation_date)];
                  patternValue = [patternValue '\n'];
                  patternValue = [patternValue sprintf('            "processing_id": "%s"\n', paramData.processing_id)];
                  patternValue = [patternValue '        }'];
                  if (idP < length(paramDataTab))
                     patternValue = [patternValue ',\n'];
                  end
               end
         end
         
         line = regexprep(line, pattern, patternValue);
      end
      
      jsonSensor{end+1} = sprintf('%s', line);
   end
   
   % create sensor file
   ouputSensorJsonFile = [outputDirName '/' glSensor.file];
   fIdOut = fopen(ouputSensorJsonFile, 'wt');
   if (fIdOut == -1)
      fprintf('ERROR: While creating file : %s\n', ouputSensorJsonFile);
      return
   end
   
   fprintf(fIdOut, '%s\n', jsonSensor{:});
   
   fclose(fIdOut);
end

return
