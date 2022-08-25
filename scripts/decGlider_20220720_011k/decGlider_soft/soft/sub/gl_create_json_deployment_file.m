% ------------------------------------------------------------------------------
% Create the EGO json file of a deployment from json user files (one file for
% the deployment and one file for each sensor mounted on the glider) and from
% json EGO format reference file.
%
% SYNTAX :
%  [o_deploymentFileName] = gl_create_json_deployment_file( ...
%    a_deploymentDirName, a_egoReferenceFilePathName, a_dataDirPathName)
%
% INPUT PARAMETERS :
%   a_deploymentDirName        : directory of the deployment
%   a_egoReferenceFilePathName : json reference file of the EGO format
%   a_dataDirPathName          : directory of input data files
%
% OUTPUT PARAMETERS :
%   o_deploymentFileName : name of the created deployment file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_deploymentFileName] = gl_create_json_deployment_file( ...
   a_deploymentDirName, a_egoReferenceFilePathName, a_dataDirPathName)

% output parameters initialization
o_deploymentFileName = [];

% flag for specific input (NetCDF file of sea glider)
global g_decGl_seaGliderInputNc;


% name of the json deployment file
a_deploymentDirName = [a_deploymentDirName '/'];
a_deploymentDirName = regexprep(a_deploymentDirName, '\', '/');
a_deploymentDirName = regexprep(a_deploymentDirName, '//', '/');
sep = strfind(a_deploymentDirName, '/');
dirName = a_deploymentDirName(sep(end-1)+1:sep(end)-1);
jsonInputPathFile = [a_deploymentDirName '/json/' dirName '.json'];
if ~(exist(jsonInputPathFile, 'file') == 2)
   fprintf('ERROR: expected json deployment file not found (%s) => deployment ignored\n', ...
      jsonInputPathFile);
   return
end

% check and retrieve EGO format from json file
[egoJsonData] = check_ego_json(a_egoReferenceFilePathName);
if (isempty(egoJsonData))
   return
end

% add nc file data in deployJsonData
if (g_decGl_seaGliderInputNc == 1)
   [jsonInputPathFile] = add_nc_data_in_json_deployment_file(jsonInputPathFile, a_dataDirPathName);
   if (isempty(jsonInputPathFile))
      return
   end
end

% check and retrieve deployment information from json file
[deployJsonData] = gl_check_json_deployment_file(jsonInputPathFile);
if (isempty(deployJsonData))
   return
end

% write the final decoder json file
jsonOutPathFile = [a_deploymentDirName 'deployment_' dirName '.json'];
egoFileName = [dirName '_R'];
[ok] = write_json_deployment_file(jsonOutPathFile, egoJsonData, deployJsonData, egoFileName);
if (ok == 0)
   return
end

o_deploymentFileName = jsonOutPathFile;

return

% ------------------------------------------------------------------------------
% Replace input json file templates (which refer to global attributes or
% variable values from input NetCDF file) with corresponding value.
%
% SYNTAX :
%  [o_deployJsonFilePathName] = add_nc_data_in_json_deployment_file( ...
%    a_deployJsonFilePathName, a_dataDirPathName)
%
% INPUT PARAMETERS :
%   a_deployJsonFilePathName : input json file of the deployment
%   a_dataDirPathName        : directory of input NetCDF files
%
% OUTPUT PARAMETERS :
%   o_deployJsonFilePathName : output json file of the deployment
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_deployJsonFilePathName] = add_nc_data_in_json_deployment_file( ...
   a_deployJsonFilePathName, a_dataDirPathName)

% output parameters initialization
o_deployJsonFilePathName = a_deployJsonFilePathName;


% store JSON files to read
fileList{1} = a_deployJsonFilePathName;

% remove TMP dir in JSON file directory
[jsonPathName, ~, ~] = fileparts(a_deployJsonFilePathName);
tmpDirPathName = [jsonPathName '/tmp/'];
if (exist(tmpDirPathName, 'dir'))
   rmdir(tmpDirPathName, 's')
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

glSensorFile = deployJsonData.glider_sensor;
for idS = 1:length(glSensorFile)
   if (isfield(glSensorFile(idS), 'sensor_file_name'))
      fileList{end+1} = [jsonPathName '/' glSensorFile(idS).sensor_file_name];
   end
end

modified2 = 0;
for idF = 1:length(fileList)
   
   filePathName = fileList{idF};
   
   % open the input file and read the data description
   fId = fopen(filePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Unable to open file: %s\n', filePathName);
      return
   end
   
   fileData = [];
   ncDataStruct = [];
   modified = 0;
   while (1)
      line = fgetl(fId);
      if (line == -1)
         break
      end
      
      stop = 0;
      while (~stop)
         
         stop = 1;
         ncGlAtt = '';
         if (any(strfind(line, '<nc.global_att.')))
            idF1 = strfind(line, '<nc.global_att.');
            idF2 = strfind(line(idF1+length('<nc.global_att.'):end), '>');
            ncGlAtt = line(idF1+length('<nc.global_att.'):idF1+length('<nc.global_att.')+idF2-2);
         end
         
         if (~isempty(ncGlAtt))
            ncDataStruct = get_nc_data(ncDataStruct, a_dataDirPathName);
            if (ischar(ncDataStruct.ATT.(ncGlAtt)))
               line = strrep(line, ['<nc.global_att.' ncGlAtt '>'], ncDataStruct.ATT.(ncGlAtt));
            else
               if (any(strfind(['"<nc.global_att.' ncGlAtt '>"'], line)))
                  line = strrep(line, ['"<nc.global_att.' ncGlAtt '>"'], sprintf('%g', ncDataStruct.ATT.(ncGlAtt)));
               else
                  line = strrep(line, ['<nc.global_att.' ncGlAtt '>'], sprintf('%g', ncDataStruct.ATT.(ncGlAtt)));
               end
            end
            modified = 1;
            stop = 0;
         end
         
         ncData = '';
         if (any(strfind(line, '<nc.data.')))
            idF1 = strfind(line, '<nc.data.');
            idF2 = strfind(line(idF1+length('<nc.data.'):end), '>');
            ncData = line(idF1+length('<nc.data.'):idF1+length('<nc.data.')+idF2-2);
         end
         
         if (~isempty(ncData))
            ncDataStruct = get_nc_data(ncDataStruct, a_dataDirPathName);
            if (ischar(ncDataStruct.VAR.(ncData)))
               line = strrep(line, ['<nc.data.' ncData '>'], ncDataStruct.VAR.(ncData).DATA);
            else
               line = strrep(line, ['"<nc.data.' ncData '>"'], sprintf('%g', ncDataStruct.VAR.(ncData).DATA));
            end
            modified = 1;
            stop = 0;
         end
      end
      
      fileData{end+1} = line;
   end
   fclose(fId);
   
   if (modified == 1)
      
      % create TMP dir in JSON file directory
      if (~exist(tmpDirPathName, 'dir'))
         mkdir(tmpDirPathName);
      end
      
      % create the modified json deployment file
      [~, fileName, fileExt] = fileparts(filePathName);
      jsonFilePathName = [tmpDirPathName fileName fileExt];
      fidOut = fopen(jsonFilePathName, 'wt');
      if (fidOut == -1)
         fprintf('ERROR: unable to create modified json deployment file: %s\n', jsonFilePathName);
         return
      end
      
      fprintf(fidOut, '%s\n', fileData{:});
      
      fclose(fidOut);
      
      modified2 = 1;
   end
end

if (modified2 == 1)
   
   for idF = 1:length(fileList)
      filePathName1 = fileList{idF};
      [~, fileName, fileExt] = fileparts(filePathName1);
      filePathName2 = [tmpDirPathName fileName fileExt];
      if ~(exist(filePathName2, 'file') == 2)
         copyfile(filePathName1, filePathName2);
      end
      if (idF == 1)
         o_deployJsonFilePathName = filePathName2;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Load NetCDF data in a matlab structure.
%
% SYNTAX :
%  [o_ncDataStruct] = get_nc_data(a_ncDataStruct, a_dataDirPathName)
%
% INPUT PARAMETERS :
%   a_ncDataStruct    : input data structure
%   a_dataDirPathName : directory of input NetCDF files
%
% OUTPUT PARAMETERS :
%   o_ncDataStruct : output data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncDataStruct] = get_nc_data(a_ncDataStruct, a_dataDirPathName)

% output parameters initialization
o_ncDataStruct = a_ncDataStruct;

if (isempty(o_ncDataStruct))
   
   % read first available NetCDF file
   files = dir([a_dataDirPathName '*.nc']);
   if (~isempty(files))
      [o_ncDataStruct] = gl_seaglider_netcdf_nc2matlab([a_dataDirPathName files(1).name]);
   end
end

return

% ------------------------------------------------------------------------------
% Create the EGO json file of a deployment from EGO reference format and from
% deployment information.
%
% SYNTAX :
%  [o_ok] = write_json_deployment_file(a_jsonOutPathFile, a_egoJsonData, a_deployJsonData)
%
% INPUT PARAMETERS :
%   a_jsonOutPathFile : file path name of the created json file
%   a_egoJsonData     : information for the EGO format
%   a_deployJsonData  : information for the deployment
%
% OUTPUT PARAMETERS :
%   o_ok : processing report flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = write_json_deployment_file(a_jsonOutPathFile, a_egoJsonData, a_deployJsonData, a_egoFileName)

% output parameters initialization
o_ok = 0;

% Matlab version (before or after R2017A)
global g_decGl_matlabVersionBeforeR2017A;


% list of global attributes
globAttList = {
   'data_type' ...
   'format_version' ...
   'platform_code' ...
   'date_update' ...
   'wmo_platform_code' ...
   'source' ...
   'history' ...
   'data_mode' ...
   'quality_index' ...
   'references' ...
   'comment' ...
   'Conventions' ...
   'netcdf_version' ...
   'title' ...
   'summary' ...
   'abstract' ...
   'keywords' ...
   'naming_authority' ...
   'id' ...
   'cdm_data_type' ...
   'area' ...
   'geospatial_lat_min' ...
   'geospatial_lat_max' ...
   'geospatial_lon_min' ...
   'geospatial_lon_max' ...
   'geospatial_vertical_min' ...
   'geospatial_vertical_max' ...
   'time_coverage_start' ...
   'time_coverage_end' ...
   'institution' ...
   'institution_references' ...
   'sdn_edmo_code' ...
   'authors' ...
   'data_assembly_center' ...
   'principal_investigator' ...
   'principal_investigator_email' ...
   'project_name' ...
   'observatory' ...
   'deployment_code' ...
   'deployment_label' ...
   'distribution_statement' ...
   'doi' ...
   'citation' ...
   'update_interval' ...
   'qc_manual' ...
   'license' ...
   'data_processing_chain_name' ...
   'data_processing_chain_version' ...
   'data_processing_chain_uri' ...
   };

if (exist(a_jsonOutPathFile, 'file') == 2)
   fprintf('INFO: removing existing file: %s\n', a_jsonOutPathFile);
   delete(a_jsonOutPathFile);
end

% create the json output file
fidOut = fopen(a_jsonOutPathFile, 'wt');
if (fidOut == -1)
   fprintf('ERROR: unable to create json output file: %s\n', a_jsonOutPathFile);
   return
end

fprintf(fidOut, '{\n');

fprintf(fidOut, '\t"EGO_format_version": "1.4",\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(fidOut, '\t"global_attributes": {\n');

egoFieldNames = fields(a_egoJsonData.global_attributes);
for idF = 1:length(globAttList)
   if (any(strcmp(globAttList{idF}, egoFieldNames) == 1))
      data = a_egoJsonData.global_attributes.(globAttList{idF});
      if (strcmp(globAttList{idF}, 'netcdf_version'))
         data = strtrim(netcdf.inqLibVers);
      end
   else
      data = a_deployJsonData.global_attributes.(globAttList{idF});
   end
   if (strcmp(globAttList{idF}, 'id') == 1)
      data = a_egoFileName;
   end
   if (strcmp(globAttList{idF}, 'authors') == 1)
      fprintf(fidOut, '\t\t"authors" : [\n');
      for idA = 1:length(data)
         fprintf(fidOut, '\t\t\t{\n');
         fprintf(fidOut, '\t\t\t\t"last_name" : "%s",\n', ...
            data(idA).last_name);
         fprintf(fidOut, '\t\t\t\t"first_name" : "%s",\n', ...
            data(idA).first_name);
         fprintf(fidOut, '\t\t\t\t"email" : "%s",\n', ...
            data(idA).email);
         fprintf(fidOut, '\t\t\t\t"orcid" : "%s",\n', ...
            data(idA).orcid);
         affiliationData = data(idA).affiliations;
         if (ischar(affiliationData) && (size(affiliationData, 1) > 1))
            affiliationData = cellstr(affiliationData)';
         end
         if (iscell(affiliationData))
            fprintf(fidOut, '\t\t\t\t"affiliations" : [\n');
            for idAf = 1:length(affiliationData)
               fprintf(fidOut, '\t\t\t\t\t{\n');
               fprintf(fidOut, '\t\t\t\t\t\t"affiliation" : "%s"\n', ...
                  affiliationData{idAf});
               if (idAf == length(affiliationData))
                  fprintf(fidOut, '\t\t\t\t\t}\n');
               else
                  fprintf(fidOut, '\t\t\t\t\t},\n');
               end
            end
            fprintf(fidOut, '\t\t\t\t]\n');
         else
            fprintf(fidOut, '\t\t\t\t\t"affiliations" : "%s"\n', ...
               affiliationData);
         end
         if (idA == length(data))
            fprintf(fidOut, '\t\t\t}\n');
         else
            fprintf(fidOut, '\t\t\t},\n');
         end
      end
      fprintf(fidOut, '\t\t]');
   else
      fprintf(fidOut, '\t\t"%s" : "%s"', ...
         globAttList{idF}, data);
   end
   if (idF < length(globAttList))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end

fprintf(fidOut, '\t},\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% item list
infoList = {
   'glider_characteristics', 'glider_characteristics_data', ...
   'glider_deployment', 'glider_deployment_data' ...
   };

for id = 1:2:length(infoList)
   inputName = infoList{id};
   outputName = infoList{id+1};
   
   fprintf(fidOut, '\t"%s": [\n', outputName);
   
   deployInfo = a_deployJsonData.(inputName);
   for id2 = 1:length(deployInfo)
      
      fprintf(fidOut, '\t\t{\n');
      
      if (length(deployInfo) == 1)
         paramStruct = deployInfo;
      else
         paramStruct = deployInfo{id2};
      end
      
      paramStructFieldNames = fields(paramStruct);
      for idF = 1:length(paramStructFieldNames)
         name = paramStructFieldNames{idF};
         value = paramStruct.(name);
         if (strcmp(name, 'FillValue'))
            name = ['_' name];
         end
         if (g_decGl_matlabVersionBeforeR2017A)
            if (isnumeric(value))
               if (~isempty(value))
                  fprintf(fidOut, '\t\t\t"%s" : %s', ...
                     name, num2str(value));
               else
                  fprintf(fidOut, '\t\t\t"%s" : null', ...
                     name);
               end
            elseif (iscell(value))
               value = sprintf('"%s", ', value{:});
               value = value(1:end-2);
               fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
                  name, value);
            else
               fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
                  name, value);
            end
         else
            if (isnumeric(value))
               if (~isempty(value))
                  fprintf(fidOut, '\t\t\t"%s" : %s', ...
                     name, num2str(value));
               else
                  fprintf(fidOut, '\t\t\t"%s" : null', ...
                     name);
               end
            elseif (iscell(value) || isstring(value))
               value = sprintf('"%s", ', value{:});
               value = value(1:end-2);
               fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
                  name, value);
            else
               fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
                  name, value);
            end
         end
         if (idF < length(paramStructFieldNames))
            fprintf(fidOut, ',\n');
         else
            fprintf(fidOut, '\n');
         end
      end
      
      if (id2 < length(deployInfo))
         fprintf(fidOut, '\t\t},\n');
      else
         fprintf(fidOut, '\t\t}\n');
      end
   end
   
   fprintf(fidOut, '\t],\n\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(fidOut, '\t"coordinate_variables": [\n');

coordVar = a_deployJsonData.coordinate_variables;

% add 'on the fly' additional coordinate variables
% if (isempty(find(strcmp('JULD', {coordVar.ego_variable_name}) == 1, 1)))
%    newStruct = struct( ...
%       'ego_variable_name', 'JULD', ...
%       'glider_variable_name', 'rawData.vars_sci_time.sci_juld');
%    coordVar = [coordVar newStruct];
% end
if (isempty(find(strcmp('TIME_GPS', {coordVar.ego_variable_name}) == 1, 1)))
   newStruct = struct( ...
      'ego_variable_name', 'TIME_GPS', ...
      'glider_variable_name', 'rawData.vars_time_gps.time');
   coordVar = [coordVar newStruct];
end
if (isempty(find(strcmp('LATITUDE_GPS', {coordVar.ego_variable_name}) == 1, 1)))
   newStruct = struct( ...
      'ego_variable_name', 'LATITUDE_GPS', ...
      'glider_variable_name', 'rawData.vars_time_gps.latitude');
   coordVar = [coordVar newStruct];
end
if (isempty(find(strcmp('LONGITUDE_GPS', {coordVar.ego_variable_name}) == 1, 1)))
   newStruct = struct( ...
      'ego_variable_name', 'LONGITUDE_GPS', ...
      'glider_variable_name', 'rawData.vars_time_gps.longitude');
   coordVar = [coordVar newStruct];
end

for idCVar = 1:length(coordVar)
   glVarName = coordVar(idCVar).glider_variable_name;
   sep = strfind(glVarName, '.');
   if (~isempty(sep))
      glVarName = glVarName(sep(end)+1:end);
   end
   
   egoVarName = coordVar(idCVar).ego_variable_name;
   if (isempty(deblank(egoVarName)))
      fprintf('WARNING: cannot find EGO variable for glider variable ''%s'' => glider variable ignored\n', ...
         glVarName);
      continue
   end
   [egoVarStruct] = gl_get_ego_var_attributes(egoVarName);
   if (isempty(egoVarStruct))
      fprintf('WARNING: no attributes for EGO variable ''%s'' => glider variable ''%s'' ignored\n', ...
         egoVarName, glVarName);
      continue
   end
   
   fprintf(fidOut, '\t\t{\n');
   
   gliderVarName = coordVar(idCVar).glider_variable_name;
   if (~isempty(gliderVarName) && ~any(gliderVarName == '.'))
      % fill path access to data in the rawData structure
      gliderVarName = ['rawData.' gl_get_path_to_data(gliderVarName) '.' gliderVarName];
   end
   fprintf(fidOut, '\t\t\t"variable_name" : "%s",\n', ...
      gliderVarName);
   
   varFieldNames = fields(egoVarStruct);
   for idF = 1:length(varFieldNames)
      name = varFieldNames{idF};
      if (strcmp(name, 'FillValue'))
         name = ['_' name];
      end
      value = egoVarStruct.(varFieldNames{idF});
      if (~isnumeric(value))
         fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
            name, value);
      else
         fprintf(fidOut, '\t\t\t"%s" : %s', ...
            name, num2str(value));
      end
      fprintf(fidOut, ',\n');
   end
   
   fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
      'glider_original_parameter_name', glVarName);
   fprintf(fidOut, '\n');
   fprintf(fidOut, '\t\t},\n');
end

paramQc = a_egoJsonData.parameter_qc;
paramQcFieldNames = fields(paramQc);
% coordQcVarNameList = [{'TIME_QC'}, {'JULD_QC'}, {'POSITION_QC'}, {'TIME_GPS_QC'}, {'POSITION_GPS_QC'}];
coordQcVarNameList = [{'TIME_QC'}, {'POSITION_QC'}, {'TIME_GPS_QC'}, {'POSITION_GPS_QC'}];
for idV = 1:length(coordQcVarNameList)
   
   fprintf(fidOut, '\t\t{\n');
   
   for idF = 1:length(paramQcFieldNames)
      name = paramQcFieldNames{idF};
      if (strcmp(name, 'FillValue'))
         name = ['_' name];
      end
      value = paramQc.(paramQcFieldNames{idF});
      if (strcmp(name, 'ego_variable_name'))
         value = coordQcVarNameList{idV};
      end
      if (strcmp(name, 'dim'))
         if (~isempty(strfind(coordQcVarNameList{idV}, '_GPS')))
            value = [value '_GPS'];
         end
      end
      if (~isnumeric(value))
         fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
            name, value);
      elseif (length(value) > 1)
         val = '';
         for id = 1:length(value)
            val = [val sprintf('%s, ', num2str(value(id)))];
         end
         val = val(1:end-2);
         fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
            name, val);
      else
         fprintf(fidOut, '\t\t\t"%s" : %s', ...
            name, num2str(value));
      end
      if (idF < length(paramQcFieldNames))
         fprintf(fidOut, ',\n');
      else
         fprintf(fidOut, '\n');
      end
   end
   if (idV < length(coordQcVarNameList))
      fprintf(fidOut, '\t\t},\n');
   else
      fprintf(fidOut, '\t\t}\n');
   end
end

fprintf(fidOut, '\t],\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of sensor information
sensorInfoList = {
   'SENSOR', ...
   'SENSOR_MAKER', ...
   'SENSOR_MODEL', ...
   'SENSOR_SERIAL_NO', ...
   'SENSOR_MOUNT', ...
   'SENSOR_ORIENTATION', ...
   };

paramInfoList = {
   'PARAMETER', ...
   'PARAMETER_SENSOR', ...
   'PARAMETER_DATA_MODE', ...
   'PARAMETER_UNITS', ...
   'PARAMETER_ACCURACY', ...
   'PARAMETER_RESOLUTION' ...
   };

sensor = [];
sensorMaker = [];
sensorModel = [];
sensorSerialNo = [];
sensorMount = [];
sensorOrientation = [];

parameter = [];
parameterSensor = [];
parameterDataMode = [];
parameterUnits = [];
parameterAccuracy = [];
parameterResolution = [];

derivationParameter = [];
derivationEquation = [];
derivationCoefficient = [];
derivationComment = [];
derivationDate = [];

parameterList = [];

sensorData = a_deployJsonData.glider_sensor;
for idS = 1:length(sensorData)
   
   % collect sensor information
   for id = 1:length(sensorInfoList)
      name = sensorInfoList{id};
      value = sensorData(idS).sensor_data.(name);
      if (~isempty(value) && ~iscell(value))
         value = cellstr(value)';
      end
      if (id == 1)
         nbVal = length(value);
      end
      for id2 = 1:nbVal
         if (~isempty(value))
            val = value{id2};
         else
            val = '';
         end
         if (id == 1)
            sensor{end+1} = val;
         elseif (id == 2)
            sensorMaker{end+1} = val;
         elseif (id == 3)
            sensorModel{end+1} = val;
         elseif (id == 4)
            sensorSerialNo{end+1} = val;
         elseif (id == 5)
            sensorMount{end+1} = val;
         elseif (id == 6)
            sensorOrientation{end+1} = val;
         end
      end
   end
   
   % collect parameter information
   for id = 1:length(paramInfoList)
      name = paramInfoList{id};
      value = sensorData(idS).sensor_data.(name);
      if (~isempty(value) && ~iscell(value))
         value = cellstr(value)';
      end
      if (id == 1)
         nbVal = length(value);
      end
      for id2 = 1:nbVal
         if (~isempty(value))
            val = value{id2};
         else
            val = '';
         end
         if (id == 1)
            parameter{end+1} = val;
         elseif (id == 2)
            parameterSensor{end+1} = val;
         elseif (id == 3)
            parameterDataMode{end+1} = val;
         elseif (id == 4)
            parameterUnits{end+1} = val;
         elseif (id == 5)
            parameterAccuracy{end+1} = val;
         elseif (id == 6)
            parameterResolution{end+1} = val;
         end
      end
   end
   
   % collect parameter list
   param = sensorData(idS).sensor_data.parametersList;
   for idP = 1:length(param)
      if (iscell(param))
         paramStruct = param{idP};
      else
         paramStruct = param(idP);
      end
      parameterList{end+1} = paramStruct;
   end
end

% print parameter list and store derivation information
fprintf(fidOut, '\t"parametersList" : [\n');

firstParamSet = 0;
for idP = 1:length(parameterList)
   paramStruct = parameterList{idP};
      
   glVarName = paramStruct.glider_variable_name;
   
   sep = strfind(glVarName, '.');
   if (~isempty(sep))
      glVarName = glVarName(sep(end)+1:end);
   end
   
   egoVarName = paramStruct.ego_variable_name;
   if (isempty(deblank(egoVarName)))
      fprintf('WARNING: cannot find EGO variable for glider variable ''%s'' => glider variable ignored\n', ...
         paramStruct.glider_variable_name);
      continue
   end
   [egoVarStruct] = gl_get_ego_var_attributes(egoVarName);
   if (isempty(egoVarStruct))
      fprintf('WARNING: no attributes for EGO variable ''%s'' => glider variable ''%s'' ignored\n', ...
         egoVarName, paramStruct.glider_variable_name);
      continue
   end
   
   if (firstParamSet)
      fprintf(fidOut, ',\n');
   end
   
   fprintf(fidOut, '\t\t{\n');
   
   paramFieldNames = fields(paramStruct);
   for idFP = 1:length(paramFieldNames)
      name = paramFieldNames{idFP};
      value = paramStruct.(name);

      if (strcmp(name, 'glider_variable_name'))
         
         if (~isempty(value) && ~any(value == '.'))
            % fill path access to data in the rawData structure
            value = ['rawData.' gl_get_path_to_data(value) '.' value];
         end
         
         fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
            'variable_name', value);
         varFieldNames = fields(egoVarStruct);
         for idFV = 1:length(varFieldNames)
            name = varFieldNames{idFV};
            if (strcmp(name, 'FillValue'))
               name = ['_' name];
            end
            value = egoVarStruct.(varFieldNames{idFV});
            if (~isnumeric(value))
               fprintf(fidOut, ',\n\t\t\t"%s" : "%s"', ...
                  name, value);
            else
               fprintf(fidOut, ',\n\t\t\t"%s" : %s', ...
                  name, num2str(value));
            end
         end
         
         fprintf(fidOut, ',\n\t\t\t"%s" : "%s"', ...
            'glider_original_parameter_name', glVarName);
         
      elseif (strncmp(name, 'derivation_', length('derivation_')))
         if (strcmp(name, 'derivation_equation'))
            derivationParameter{end+1} = egoVarStruct.ego_variable_name;
            derivationEquation{end+1} = value;
         elseif (strcmp(name, 'derivation_coefficient'))
            derivationCoefficient{end+1} = value;
         elseif (strcmp(name, 'derivation_comment'))
            derivationComment{end+1} = value;
         elseif (strcmp(name, 'derivation_date'))
            derivationDate{end+1} = value;
         end
         continue
      elseif (strcmp(name, 'ego_variable_name'))
         continue
      elseif (strcmp(name, 'glider_adjusted_variable_name'))
         
         if (~isempty(value) && ~any(value == '.'))
            % fill path access to data in the rawData structure
            value = ['rawData.' gl_get_path_to_data(value) '.' value];
         end
         
         fprintf(fidOut, ',\n\t\t\t"%s" : "%s"', ...
            'adjusted_variable_name', value);
      else
         fprintf(fidOut, ',\n\t\t\t"%s" : "%s"', ...
            name, value);
      end
   end
   
   % for a QC parameter provided by the glider we have only the variable name
   if (length(paramFieldNames) > 2)
      %       fprintf(fidOut, ',\n\t\t\t\t\t"DM_indicator" : "%s"', ...
      %          a_egoJsonData.parameter_att.DM_indicator);
      fprintf(fidOut, ',\n\t\t\t"coordinates" : "%s"', ...
         a_egoJsonData.parameter_att.coordinates);
   end
   
   % retrieve associated sensor
   idF = [];
   for idS = 1:length(sensorData)
      paramTab = sensorData(idS).sensor_data.PARAMETER;
      if (ischar(paramTab))
         paramTab = cellstr(paramTab)';
      end
      idF = find(strcmp(paramStruct.ego_variable_name, paramTab) == 1, 1);
      if (~isempty(idF))
         break
      end
   end
   if (isempty(idF))
      fprintf('ERROR: unable to retrieve ''%s'' associated sensor\n', ...
         paramStruct.ego_variable_name);
      return
   end
   paramSensorTab = sensorData(idS).sensor_data.PARAMETER_SENSOR;
   if (ischar(paramSensorTab))
      paramSensorTab = cellstr(paramSensorTab)';
   end
   derivedParamSensor = paramSensorTab{idF};
   
   fprintf(fidOut, ',\n\t\t\t"parameter_sensor" : "%s"', ...
      derivedParamSensor);
   
   % insert derived parameter processing information
   if ((isempty(glVarName) && ~isempty(paramStruct.ego_variable_name)) || ...
         ~isempty(paramStruct.processing_id))

      % retrieve calibration coefficients for this sensor
      calibCoefTab = sensorData(idS).sensor_data.CALIBRATION_COEFFICIENT;
      calibCoefSensorTab = [];
      if (iscell(calibCoefTab))
         for idCT = 1:length(calibCoefTab)
            if (isfield(calibCoefTab{idCT}, derivedParamSensor))
               calibCoefSensorTab = calibCoefTab{idCT}.(derivedParamSensor);
               break
            end
         end
      else
         if (isfield(calibCoefTab, derivedParamSensor))
            calibCoefSensorTab = calibCoefTab.(derivedParamSensor);
         end
      end
      if (~isempty(calibCoefSensorTab))
         if ((length(calibCoefSensorTab) == 1))
            fprintf(fidOut, ',\n\t\t\t"calib_coef" : [');
            fprintf(fidOut, '\n\t\t\t\t{');
            structCoef = calibCoefSensorTab;
            if (iscell(structCoef))
               structCoef = structCoef{:};
            end
            fieldNames = fields(structCoef);
            for idF = 1:length(fieldNames)
               if (~strcmp(fieldNames{idF}, 'Case'))
                  fprintf(fidOut, '\n\t\t\t\t\t"%s" : %g', ...
                     fieldNames{idF}, structCoef.(fieldNames{idF}));
                  if (idF < length(fieldNames))
                     fprintf(fidOut, ',');
                  end
               end
            end
            fprintf(fidOut, '\n\t\t\t\t}');
            fprintf(fidOut, '\n\t\t\t]');
         else
            for idC = 1:length(calibCoefSensorTab)
               if (strcmp(calibCoefSensorTab{idC}.Case, paramStruct.processing_id))
                  fprintf(fidOut, ',\n\t\t\t"calib_coef" : [');
                  fprintf(fidOut, '\n\t\t\t\t{');
                  structCoef = calibCoefSensorTab{idC};
                  fieldNames = fields(structCoef);
                  for idF = 1:length(fieldNames)
                     if (~strcmp(fieldNames{idF}, 'Case'))
                        fprintf(fidOut, '\n\t\t\t\t\t"%s" : %g', ...
                           fieldNames{idF}, structCoef.(fieldNames{idF}));
                        if (idF < length(fieldNames))
                           fprintf(fidOut, ',');
                        end
                     end
                  end
                  fprintf(fidOut, '\n\t\t\t\t}');
                  fprintf(fidOut, '\n\t\t\t]');
                  break
               end
            end
         end
      end
   end
   
   fprintf(fidOut, '\n\t\t}');
   firstParamSet = 1;
end

fprintf(fidOut, '\n\t],\n\n');

clear parameterList;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print sensor information
fprintf(fidOut, '\t"glider_sensor_data": {\n');
fprintf(fidOut, '\t\t"SENSOR": [\n');
for id = 1:length(sensor)
   fprintf(fidOut, '\t\t\t"%s"', sensor{id});
   if (id < length(sensor))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"SENSOR_MAKER": [\n');
for id = 1:length(sensor)
   fprintf(fidOut, '\t\t\t"%s"', sensorMaker{id});
   if (id < length(sensor))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"SENSOR_MODEL": [\n');
for id = 1:length(sensor)
   fprintf(fidOut, '\t\t\t"%s"', sensorModel{id});
   if (id < length(sensor))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"SENSOR_SERIAL_NO": [\n');
for id = 1:length(sensor)
   fprintf(fidOut, '\t\t\t"%s"', sensorSerialNo{id});
   if (id < length(sensor))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"SENSOR_MOUNT": [\n');
for id = 1:length(sensor)
   fprintf(fidOut, '\t\t\t"%s"', sensorMount{id});
   if (id < length(sensor))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"SENSOR_ORIENTATION": [\n');
for id = 1:length(sensor)
   fprintf(fidOut, '\t\t\t"%s"', sensorOrientation{id});
   if (id < length(sensor))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t]\n');
fprintf(fidOut, '\t},\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print parameter information
fprintf(fidOut, '\t"glider_parameter_data": {\n');
fprintf(fidOut, '\t\t"PARAMETER": [\n');
for id = 1:length(parameter)
   fprintf(fidOut, '\t\t\t"%s"', parameter{id});
   if (id < length(parameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"PARAMETER_SENSOR": [\n');
for id = 1:length(parameter)
   fprintf(fidOut, '\t\t\t"%s"', parameterSensor{id});
   if (id < length(parameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"PARAMETER_DATA_MODE": [\n');
for id = 1:length(parameter)
   fprintf(fidOut, '\t\t\t"%s"', parameterDataMode{id});
   if (id < length(parameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"PARAMETER_UNITS": [\n');
for id = 1:length(parameter)
   fprintf(fidOut, '\t\t\t"%s"', parameterUnits{id});
   if (id < length(parameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"PARAMETER_ACCURACY": [\n');
for id = 1:length(parameter)
   fprintf(fidOut, '\t\t\t"%s"', parameterAccuracy{id});
   if (id < length(parameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"PARAMETER_RESOLUTION": [\n');
for id = 1:length(parameter)
   fprintf(fidOut, '\t\t\t"%s"', parameterResolution{id});
   if (id < length(parameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t]\n');
fprintf(fidOut, '\t},\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print derivation information
fprintf(fidOut, '\t"glider_parameter_derivation_data": {\n');
fprintf(fidOut, '\t\t"DERIVATION_PARAMETER": [\n');
for id = 1:length(derivationParameter)
   fprintf(fidOut, '\t\t\t"%s"', derivationParameter{id});
   if (id < length(derivationParameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"DERIVATION_EQUATION": [\n');
for id = 1:length(derivationParameter)
   fprintf(fidOut, '\t\t\t"%s"', derivationEquation{id});
   if (id < length(derivationParameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"DERIVATION_COEFFICIENT": [\n');
for id = 1:length(derivationParameter)
   fprintf(fidOut, '\t\t\t"%s"', derivationCoefficient{id});
   if (id < length(derivationParameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"DERIVATION_COMMENT": [\n');
for id = 1:length(derivationParameter)
   fprintf(fidOut, '\t\t\t"%s"', derivationComment{id});
   if (id < length(derivationParameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t],\n');
fprintf(fidOut, '\t\t"DERIVATION_DATE": [\n');
for id = 1:length(derivationParameter)
   fprintf(fidOut, '\t\t\t"%s"', derivationDate{id});
   if (id < length(derivationParameter))
      fprintf(fidOut, ',\n');
   else
      fprintf(fidOut, '\n');
   end
end
fprintf(fidOut, '\t\t]\n');
fprintf(fidOut, '\t},\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% item list
egoInfoList = {
   'parameter_qc', 'parameter_qc', ...
   'parameter_adjusted_error', 'parameter_adjusted_error', ...
   'phase_management', 'phase_management', ...
   'positioning_method', 'positioning_method', ...
   'glider_characteristics', 'glider_characteristics_def', ...
   'glider_deployment', 'glider_deployment_def', ...
   'glider_sensor', 'glider_sensor_def', ...
   'glider_parameter', 'glider_parameter_def', ...
   'glider_parameter_derivation', 'glider_parameter_derivation_def', ...
   'history', 'history' ...
   };

for idI = 1:2:length(egoInfoList)
   
   inputName = egoInfoList{idI};
   outputName = egoInfoList{idI+1};
   
   fprintf(fidOut, '\t"%s": [\n', outputName);
   
   egoInfo = a_egoJsonData.(inputName);
   for id2 = 1:length(egoInfo)
      
      fprintf(fidOut, '\t\t{\n');
      
      if (length(egoInfo) == 1)
         paramStruct = egoInfo;
      else
         paramStruct = egoInfo{id2};
      end
      
      paramStructFieldNames = fields(paramStruct);
      for idF = 1:length(paramStructFieldNames)
         name = paramStructFieldNames{idF};
         value = paramStruct.(name);
         if (strcmp(name, 'FillValue'))
            name = ['_' name];
         end
         if (isnumeric(value))
            if (length(value) > 1)
               val = '';
               for id = 1:length(value)
                  val = [val sprintf('%s, ', num2str(value(id)))];
               end
               val = val(1:end-2);
               fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
                  name, val);
            else
               fprintf(fidOut, '\t\t\t"%s" : %s', ...
                  name, num2str(value));
            end
         elseif (iscell(value))
            value = sprintf('"%s", ', value{:});
            value = value(1:end-2);
            fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
               name, value);
         else
            if (g_decGl_matlabVersionBeforeR2017A)
               if (strcmp(name, 'dim') && (size(value, 1) > 1))
                  % gl_load_json fails in reading dimension ["N_HISTORY", "DATE_TIME"]
                  % because of DATE_TIME ?
                  val = '';
                  for id = 1:size(value, 1)
                     val = [val sprintf('"%s", ', value(id, :))];
                  end
                  val = val(1:end-2);
                  fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
                     name, val);
               else
                  fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
                     name, value);
               end
            else
               if (strcmp(name, 'dim'))
                  if (isstring(value))
                     val = '';
                     for id = 1:length(value)
                        val = [val sprintf('"%s", ', char(value(id)))];
                     end
                     val = val(1:end-2);
                     fprintf(fidOut, '\t\t\t"%s" : [%s]', ...
                        name, val);
                  else
                     fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
                        name, value);
                  end
               else
                  fprintf(fidOut, '\t\t\t"%s" : "%s"', ...
                     name, value);
               end
            end
         end
         if (idF < length(paramStructFieldNames))
            fprintf(fidOut, ',\n');
         else
            fprintf(fidOut, '\n');
         end
      end
      
      if (id2 < length(egoInfo))
         fprintf(fidOut, '\t\t},\n');
      else
         fprintf(fidOut, '\t\t}\n');
      end
   end
   
   fprintf(fidOut, '\t]');
   
   if (idI < length(egoInfoList)-1)
      fprintf(fidOut, ',\n\n');
   else
      fprintf(fidOut, '\n');
   end
end

fprintf(fidOut, '}\n');

fclose(fidOut);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Check the information of the json reference file of the EGO format and
% retrieve its contents.
%
% SYNTAX :
% [o_outputData] = check_ego_json(a_egoJsonFilePathName)
%
% INPUT PARAMETERS :
%   a_egoJsonFilePathName : json reference file of the EGO format
%
% OUTPUT PARAMETERS :
%   o_outputData : json file contents
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = check_ego_json(a_egoJsonFilePathName)

% output parameters initialization
o_outputData = [];

% read the EGO format from json file
egoJsonData = gl_load_json(a_egoJsonFilePathName);

if ~(isfield(egoJsonData, 'EGO_format_version') && ...
      ~isempty(egoJsonData.EGO_format_version) && ...
      (str2double(egoJsonData.EGO_format_version) == 1.4))
   fprintf('ERROR: expected ''1.4'' EGO format version in json file (%s)\n', ...
      a_egoJsonFilePathName);
   return
end
if (isfield(egoJsonData, 'EGO_format_version'))
   egoJsonData = rmfield(egoJsonData, 'EGO_format_version');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected fields
egoExpFieldList = {
   'global_attributes', ...
   'glider_characteristics', ...
   'glider_deployment', ...
   'glider_sensor', ...
   'glider_parameter', ...
   'parameter_att', ...
   'parameter_qc', ...
   'parameter_adjusted_error', ...
   'glider_parameter_derivation', ...
   'phase_management', ...
   'positioning_method', ...
   'history' ...
   };

fieldNames = fields(egoJsonData);
for idF = 1:length(egoExpFieldList)
   if (~any(strcmp(egoExpFieldList{idF}, fieldNames) == 1))
      fprintf('ERROR: %s field expected in json file (%s)\n', ...
         egoExpFieldList{idF}, a_egoJsonFilePathName);
      return
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of expected global attributes
egoExpGlobAttList = {
   'data_type' ...
   'format_version' ...
   'date_update' ...
   'source' ...
   'history' ...
   'data_mode' ...
   'quality_index' ...
   'Conventions' ...
   'netcdf_version' ...
   'naming_authority' ...
   'id' ...
   'cdm_data_type' ...
   'geospatial_lat_min' ...
   'geospatial_lat_max' ...
   'geospatial_lon_min' ...
   'geospatial_lon_max' ...
   'geospatial_vertical_min' ...
   'geospatial_vertical_max' ...
   'time_coverage_start' ...
   'time_coverage_end' ...
   'distribution_statement' ...
   'qc_manual' ...
   'license' ...
   'data_processing_chain_name' ...
   'data_processing_chain_version' ...
   'data_processing_chain_uri' ...
   };

fieldNames = fields(egoJsonData.global_attributes);
for idF = 1:length(egoExpGlobAttList)
   if (~any(strcmp(egoExpGlobAttList{idF}, fieldNames) == 1))
      fprintf('ERROR: %s field expected in ''global_attributes'' of json file (%s)\n', ...
         egoExpGlobAttList{idF}, a_egoJsonFilePathName);
      return
   end
end

o_outputData = egoJsonData;

return
