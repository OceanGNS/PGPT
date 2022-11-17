% ------------------------------------------------------------------------------
% Check the links glider_param <-> EGO_param stored in the JSON file of a
% deployment.
%
% SYNTAX :
%   gl_check_slocum_glider_var_2_ego_link or
%   gl_check_slocum_glider_var_2_ego_link('data', 'crate_mooset00_38')
%
% INPUT PARAMETERS :
%   varargin : input arguments
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DATA_DIRECTORY directory) to process
%      if no argument is provided: all the deployments of the
%      DATA_DIRECTORY directory are processed
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function gl_check_slocum_glider_var_2_ego_link(varargin)

% top directory of the deployment directories
DATA_DIRECTORY = 'C:\Users\jprannou\NEW_20190125\_DATA\GLIDER\FORMAT_1.4/';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\work\';

% file with links between EGO and glider param names
PARAM_GLIDER_2_EGO_LINK_FILE = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\soft\util\ref_lists\sensors_Claire_20160615.txt';

% default values initialization
gl_init_default_values;


% check configuration information
if ~(exist(DATA_DIRECTORY, 'dir') == 7)
   fprintf('ERROR: ''DATA_DIRECTORY'' directory not found: %s\n', DATA_DIRECTORY);
   return
end

if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   fprintf('ERROR: ''DIR_LOG_FILE'' directory not found: %s\n', DIR_LOG_FILE);
   return
end

if ~(exist(PARAM_GLIDER_2_EGO_LINK_FILE, 'file') == 2)
   fprintf('ERROR: ''PARAM_GLIDER_2_EGO_LINK_FILE'' file not found: %s\n', PARAM_GLIDER_2_EGO_LINK_FILE);
   return
end

% read Glider/EGO parameter links file
fId = fopen(PARAM_GLIDER_2_EGO_LINK_FILE, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', PARAM_GLIDER_2_EGO_LINK_FILE);
   return
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fclose(fId);

% process EGO parameter information
gliderEgoParamData = fileContents{:};
gliderEgoParamData = reshape(gliderEgoParamData, 2, size(gliderEgoParamData, 1)/2)';
gliderEgoParamData(:, 2) = lower(gliderEgoParamData(:, 2));

% check input arguments
deploymentDir = [];
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            if (exist([DATA_DIRECTORY '/' varargin{id+1}], 'dir'))
               deploymentDir = varargin{id+1};
            else
               fprintf('WARNING: %s is not an existing directory => ignored\n', varargin{id+1});
               return
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'gl_check_slocum_glider_var_2_ego_link_' deploymentDir '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check glider deployment
if (isempty(deploymentDir))
   % check all the deployments of the DATA_DIRECTORY directory
   dirInfo = dir(DATA_DIRECTORY);
   for dirNum = 1:length(dirInfo)
      if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
         dirName = dirInfo(dirNum).name;
         
         gl_check_deployment(DATA_DIRECTORY, dirName, gliderEgoParamData);
      end
   end
else
   % check the data of this deployment
   gl_check_deployment(DATA_DIRECTORY, deploymentDir, gliderEgoParamData);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Check the links glider_param <-> EGO_param stored in the JSON file of a
% deployment.
%
% SYNTAX :
%  gl_check_deployment(a_deploymentTopDirName, a_deploymentDirName, a_glider2EgoLink)
%
% INPUT PARAMETERS :
%   a_deploymentTopDirName : top directory of deployments directory
%   a_deploymentDirName    : directory of the deployment
%   a_glider2EgoLink       : links glider_param <-> EGO_param reference
%                            information
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/19/2017 - RNU - creation
% ------------------------------------------------------------------------------
function gl_check_deployment(a_deploymentTopDirName, a_deploymentDirName, a_glider2EgoLink)

fprintf('***********************************************************************\n');
fprintf('DEPLOYMENT: %s\n', a_deploymentDirName);
fprintf('***********************************************************************\n');

% look for split JSON files of the deployment
jsonDirectory = [a_deploymentTopDirName '/' a_deploymentDirName '/json/'];
if (exist(jsonDirectory, 'dir'))
   
   jsonInputPathFile = [a_deploymentTopDirName '/' a_deploymentDirName '/json/' a_deploymentDirName '.json'];
   if ~(~exist(jsonInputPathFile, 'dir') && exist(jsonInputPathFile, 'file'))
      fprintf('ERROR: expected json deployment file not found (%s) => deployment ignored\n', ...
         jsonInputPathFile);
      return
   end
   
   % check that it is a Slocum
   metaData = gl_load_json(jsonInputPathFile);
   if ~(isfield(metaData, 'EGO_format_version') && ...
         ~isempty(metaData.EGO_format_version) && ...
         (str2double(metaData.EGO_format_version) == 1.4))
      fprintf('ERROR: expected ''1.4'' EGO format version in json file (%s)\n', ...
         jsonInputPathFile);
      return
   end
   if (isfield(metaData, 'glider_characteristics') && ...
         isfield(metaData.glider_characteristics, 'PLATFORM_TYPE'))
      gliderType = lower(metaData.glider_characteristics.PLATFORM_TYPE);
      if (isempty(gliderType))
         fprintf('\nINFO: no information on glider type for deployment ''%s'' => deployment ignored\n\n', ...
            a_deploymentDirName);
         return
      elseif (isempty(strfind(gliderType, 'slocum')))
         fprintf('\nINFO: glider type is not ''slocum'' for deployment ''%s'' => deployment ignored\n\n', ...
            a_deploymentDirName);
         return
      end
   else
      fprintf('\nINFO: no information on glider type for deployment ''%s'' => deployment ignored\n\n', ...
         a_deploymentDirName);
      return
   end
   
   % retrieve sensor files
   sensorFileNames = [];
   if (isfield(metaData, 'glider_sensor'))
      for idFile = 1:length(metaData.glider_sensor)
         sensorFileNames{end+1} = metaData.glider_sensor(idFile).sensor_file_name;
      end
   end
   fprintf('INFO: using json split files:\n')
   fprintf('- %s\n', [a_deploymentDirName '.json']);
   for idFile = 1:length(sensorFileNames)
      fprintf('   -> %s\n', sensorFileNames{idFile});
   end
   
   tabSensorInfo = [];
   tabGliderParam = [];
   tabEGOParam = [];
   for idFile = 1:length(sensorFileNames)
      jsonSensorPathFile = [a_deploymentTopDirName '/' a_deploymentDirName '/json/' sensorFileNames{idFile}];
      if ~(~exist(jsonSensorPathFile, 'dir') && exist(jsonSensorPathFile, 'file'))
         fprintf('ERROR: expected json sensor file not found (%s) => deployment ignored\n', ...
            jsonSensorPathFile);
         return
      end
      
      sensorData = gl_load_json(jsonSensorPathFile);
      if ~(isfield(sensorData, 'EGO_format_version') && ...
            ~isempty(sensorData.EGO_format_version) && ...
            (str2double(sensorData.EGO_format_version) == 1.4))
         fprintf('ERROR: expected ''1.4'' EGO format version in json file (%s)\n', ...
            jsonSensorPathFile);
         return
      end
      paramTab = sensorData.PARAMETER;
      if (ischar(paramTab) && (size(paramTab, 1) > 1))
         paramTab = cellstr(paramTab)';
      end
      paramSensorTab = sensorData.PARAMETER_SENSOR;
      if (ischar(paramSensorTab) && (size(paramSensorTab, 1) > 1))
         paramSensorTab = cellstr(paramSensorTab)';
      end
      parameters = sensorData.parametersList;
      for idP = 1:length(parameters)
         if (iscell(parameters))
            paramData = parameters{idP};
         else
            paramData = parameters(idP);
         end
         idF = find(strcmp(paramData.ego_variable_name, paramTab));
         tabSensorInfo{end+1} = paramSensorTab{idF};
         tabGliderParam{end+1} = strtrim(paramData.glider_variable_name);
         tabEGOParam{end+1} = strtrim(paramData.ego_variable_name);
      end      
   end
   
   sensorList = unique(tabSensorInfo);
   for idS = 1:length(sensorList)
      fprintf('SENSOR #%d: %s\n', idS, sensorList{idS});
      paramListId = find(strcmp(sensorList{idS}, tabSensorInfo));
      for idP = 1:length(paramListId)
         fprintf('   - PARAM #%d: ''%s'' -> ''%s''\n', idP, tabGliderParam{paramListId(idP)}, tabEGOParam{paramListId(idP)});
      end
   end

else
   
      % look for the JSON file of the deployment
      jsonInputPathFile = [a_deploymentTopDirName '/' a_deploymentDirName '/' 'deployment_' a_deploymentDirName '.json'];
      if ~(~exist(jsonInputPathFile, 'dir') && exist(jsonInputPathFile, 'file'))
         fprintf('ERROR: expected json deployment file not found (%s) => deployment ignored\n', ...
            jsonInputPathFile);
         return
      end
   
      fprintf('INFO: using json deployment file %s\n', ['deployment_' a_deploymentDirName '.json'])
   
      % check that it is a Slocum
      metaData = gl_load_json(jsonInputPathFile);
      if ~(isfield(metaData, 'EGO_format_version') && ...
            ~isempty(metaData.EGO_format_version) && ...
            (str2double(metaData.EGO_format_version) == 1.4))
         fprintf('ERROR: expected ''1.4'' EGO format version in json file (%s)\n', ...
            jsonInputPathFile);
         return
      end
      if (isfield(metaData, 'glider_characteristics_data') && ...
            isfield(metaData.glider_characteristics_data, 'PLATFORM_TYPE'))
         gliderType = lower(metaData.glider_characteristics_data.PLATFORM_TYPE);
         if (isempty(gliderType))
            fprintf('\nINFO: no information on glider type for deployment ''%s'' => deployment ignored\n\n', ...
               a_deploymentDirName);
            return
         elseif (isempty(strfind(gliderType, 'slocum')))
            fprintf('\nINFO: glider type is not ''slocum'' for deployment ''%s'' => deployment ignored\n\n', ...
               a_deploymentDirName);
            return
         end
      else
         fprintf('\nINFO: no information on glider type for deployment ''%s'' => deployment ignored\n\n', ...
            a_deploymentDirName);
         return
      end
   
      tabSensorInfo = [];
      tabGliderParam = [];
      tabEGOParam = [];
      parameters = metaData.parametersList;
      for idP = 1:length(parameters)
         if (iscell(parameters))
            paramData = parameters{idP};
         else
            paramData = parameters(idP);
         end
         
         % store useful information
         tabSensorInfo{end+1} = strtrim(paramData.parameter_sensor);
         tabGliderParam{end+1} = strtrim(paramData.variable_name);
         tabEGOParam{end+1} = strtrim(paramData.ego_variable_name);
      end
      
      sensorList = unique(tabSensorInfo);
      for idS = 1:length(sensorList)
         fprintf('SENSOR #%d: %s\n', idS, sensorList{idS});
         paramListId = find(strcmp(sensorList{idS}, tabSensorInfo));
         for idP = 1:length(paramListId)
            fprintf('   - PARAM #%d: ''%s'' -> ''%s''\n', idP, tabGliderParam{paramListId(idP)}, tabEGOParam{paramListId(idP)});
         end
      end
      
      % check that the path to data is consistent
      fprintf('\nCHECK PATH TO DATA\n');
      fprintf('==================\n');
      error = 0;
      for idP = 1:length(tabGliderParam)
         gliderParam = tabGliderParam{idP};
         if (~isempty(gliderParam))
            idF = strfind(gliderParam, '.');
            gliderParamName = gliderParam(idF(end)+1:end);
            if (~strcmp(gliderParam(1:idF(end)), 'rawData.vars_sci_time.'))
               error = 1;
               fprintf('ERROR: data path to param ''%s'' is ''%s'' (whereas ''%s'' is expected)\n', ...
                  gliderParamName, gliderParam(1:idF(end)), 'rawData.vars_sci_time.');
            end
            tabGliderParam{idP} = gliderParamName;
         end
      end
      if (error == 0)
         fprintf('=> OK\n');
      end
end

% check that the links are consistent
fprintf('\nCHECK DEFINED LINKS\n');
fprintf('===================\n');
error = 0;
for idP = 1:length(tabGliderParam)
   gliderParam = tabGliderParam{idP};
   egoParam = tabEGOParam{idP};
   
   if (~isempty(gliderParam) && ~isempty(egoParam))
      
      % check glider param -> EGO param consistency
      idF = find(strcmpi(gliderParam, a_glider2EgoLink(:, 2)));
      if (~isempty(idF))
         egoParamExpected = unique(a_glider2EgoLink(idF, 1));
         egoParamExpected = egoParamExpected{:};
         if (~strcmp(egoParam, egoParamExpected))
            error = 1;
            fprintf('ERROR: glider param ''%s'' is linked to EGO param ''%s'' (whereas ''%s'' is expected)\n', ...
               gliderParam, egoParam, egoParamExpected);
         end
      end
      
      % check EGO param -> glider param consistency
      idF = find(strcmpi(egoParam, a_glider2EgoLink(:, 1)));
      if (~isempty(idF))
         gliderParamExpected = unique(a_glider2EgoLink(idF, 2));
         if (~any(strcmpi(gliderParam, gliderParamExpected)))
            error = 1;
            gliderParamExpectedStr = ['' gliderParamExpected{1} ''];
            for id = 2:length(gliderParamExpected)
               gliderParamExpectedStr = [gliderParamExpectedStr ...
                  sprintf(' or ''%s''', gliderParamExpected{id})];
            end
            fprintf('ERROR: EGO param ''%s'' is linked to glider param ''%s'' (whereas %s is expected)\n', ...
               egoParam, gliderParam, gliderParamExpectedStr);
         end
      end
   end
end
if (error == 0)
   fprintf('=> OK\n');
end

% check available data
fprintf('\nCHECK AVAILABLE PARAM\n');
fprintf('=====================\n');
fprintf('Reading data please wait ...\n');
[tabAvailableParam, tabAvailableData] = get_available_data(a_deploymentTopDirName, a_deploymentDirName);

% check any inconsistency between JSON glider param name and glider param name
% due to case sensitive name
for idP = 1:length(tabGliderParam)
   gliderParam = tabGliderParam{idP};
   if (~isempty(gliderParam))
      if (~any(strcmp(gliderParam, tabAvailableParam)))
         if (any(strcmpi(gliderParam, tabAvailableParam)))
            idF = find(strcmpi(gliderParam, tabAvailableParam));
            fprintf('WARNING: JSON glider param ''%s'' should be linked to glider param ''%s''\n', ...
               gliderParam, tabAvailableParam{idF});
         end
      end
   end
end

% check that JSON glider params exist in the data
% check that glider param data are not all Nan
for idP = 1:length(tabGliderParam)
   gliderParam = tabGliderParam{idP};
   if (~isempty(gliderParam))
      idF = find(strcmpi(gliderParam, tabAvailableParam));
      if (~isempty(idF))
         if (tabAvailableData(idF) == 0)
            fprintf('WARNING: JSON glider param ''%s'' has only NaN values\n', ...
               gliderParam);
         end
      else
         fprintf('WARNING: JSON glider param ''%s'' is not in glider available parameters\n', ...
            gliderParam);
      end
   end
end

% look for possible new links
tabNotLinkedParam = setdiff(tabAvailableParam, tabGliderParam);
for idP = 1:length(tabNotLinkedParam)
   notLinkedParam = tabNotLinkedParam{idP};
   idF = find(strcmpi(notLinkedParam, a_glider2EgoLink(:, 2)));
   if (~isempty(idF))
      % be sure that all data are not NaN
      idF2 = find(strcmpi(notLinkedParam, tabAvailableParam));
      if (tabAvailableData(idF2) ~= 0)
         egoParam = unique(a_glider2EgoLink(idF, 1));
         egoParam = egoParam{:};
         fprintf('INFO: glider param ''%s'' is in glider available data and can be linked to EGO param ''%s''\n', ...
            notLinkedParam, egoParam);
      end
   end
end

fprintf('\n');

return

% ------------------------------------------------------------------------------
% Retrive the variable names of a Slocum and information on data (useful data).
%
% SYNTAX :
%  [o_availableParam, o_availableData] = get_available_data(a_deploymentTopDirName, a_deploymentDirName)
%
% INPUT PARAMETERS :
%   a_deploymentTopDirName : top directory of deployments directory
%   a_deploymentDirName    : directory of the deployment
%
% OUTPUT PARAMETERS :
%   o_availableParam : list of parameter names for the deployment
%   o_availableData  : > 0 if useful data exist
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/19/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_availableParam, o_availableData] = get_available_data(a_deploymentTopDirName, a_deploymentDirName)

% output parameters initialization
o_availableParam = [];
o_availableData = [];

% directory of glider data
gliderDataDirName = [a_deploymentTopDirName '/' a_deploymentDirName '/dat/'];
if ~(exist(gliderDataDirName, 'dir') == 7)
   fprintf('ERROR: directory not found: %s\n', gliderDataDirName);
   return
end

% create a temporary directory
tmpDirPathName = [tempdir 'gl_check_slocum_glider_var_2_ego_link/tmp/'];
if (exist(tmpDirPathName, 'dir'))
   rmdir(tmpDirPathName, 's')
end
mkdir(tmpDirPathName);

% read data
mFiles = dir([gliderDataDirName '/' '*_sbd.m']);
% nbFiles = length(mFiles);
% nbDigits = length(num2str(nbFiles));
% pattern = ['%0' num2str(nbDigits) 'd/%0' num2str(nbDigits) 'd\n'];
for idFile = 1:length(mFiles)
   
   %    if (rem(idFile, 10) == 1)
   %       if (idFile > 1)
   %          fprintf(repmat('\b', 1, 2*nbDigits+2));
   %       end
   %       fprintf(pattern, idFile, nbFiles);
   %    end
   
   mFileName = mFiles(idFile).name;
   mPathFileName = [gliderDataDirName '/' mFileName];
   
   % retrieve segment data parameters
   currentSegmentParamName = gl_slocum_get_param_name(mPathFileName);
   
   loadDataFlag = 0;
   for idP = 1:length(currentSegmentParamName)
      gliderParam = currentSegmentParamName{idP};
      if (~any(strcmp(gliderParam, o_availableParam)))
         loadDataFlag = 1;
         break
      else
         idF = find(strcmp(gliderParam, o_availableParam));
         if (o_availableData(idF) == 0)
            loadDataFlag = 1;
            break
         end
      end
   end
   
   if (loadDataFlag == 1)
      
      % read segment data
      currentSegmentData = gl_slocum_read_data(mPathFileName);
      
      data = currentSegmentData.data;
      currentSegmentData = rmfield(currentSegmentData, 'data');
      listFields = fieldnames(currentSegmentData);
      %    if (length(listFields) ~= size(data, 2))
      %       fprintf('ERROR: data inconsistent in file: %s => ignored\n', mFileName);
      %       continue
      %    end
      for idP = 1:length(listFields)
         varName = listFields{idP};
         if (~any(strcmp(varName, o_availableParam)))
            if (size(data, 2) >= currentSegmentData.(varName))
               o_availableParam{end+1} = varName;
               o_availableData(end+1) = any(~isnan(data(:, currentSegmentData.(varName))));
            end
         else
            idF = find(strcmp(varName, o_availableParam));
            if (size(data, 2) >= currentSegmentData.(varName))
               o_availableData(idF) = o_availableData(idF) + any(~isnan(data(:, currentSegmentData.(varName))));
            end
         end
      end
   end
end

% remove the temporary directory
if (exist(tmpDirPathName, 'dir'))
   rmdir(tmpDirPathName, 's')
end

return

% ------------------------------------------------------------------------------
% Read Slocum available parameters.
%
% SYNTAX :
%  [o_paramNameList] = gl_slocum_get_param_name(a_mFileNameIn)
%
% INPUT PARAMETERS :
%   a_mFileNameIn    : name of the .m file from a yo
%
% OUTPUT PARAMETERS :
%   o_paramNameList : list of available parameters
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramNameList] = gl_slocum_get_param_name(a_mFileNameIn)

% output parameter initialization
o_paramNameList = [];


% open the input file and read the data description
fId = fopen(a_mFileNameIn, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_mFileNameIn);
   return
end

globalVarList = [];
while (1)
   line = fgetl(fId);
   
   if (line == -1)
      break
   end
   
   if (any(strfind(line, 'global')))
      globalVarList{end+1} = strtrim(regexprep(line, 'global', ''));
   elseif (any(strfind(line, '=')))
      idFEq = strfind(line, '=');
      varName = strtrim(line(1:idFEq(1)-1));
      if (any(strcmp(varName, globalVarList)))
         idFEnd = strfind(line, ';');
         varNum = strtrim(line(idFEq(1)+1:idFEnd(1)-1));
         if (~any(~ismember(varNum, 48:57)))
            o_paramNameList{end+1} = varName;
         end
      end
   end
end

fclose(fId);

return
