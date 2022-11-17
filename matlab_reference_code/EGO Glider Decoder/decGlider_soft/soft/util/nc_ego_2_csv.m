% ------------------------------------------------------------------------------
% Convert NetCDF EGO file contents in CSV format (convert also associated
% profile files).
% The default behaviour is :
%    - to process all the deployments (the directories) stored in the
%      DIR_INPUT_NC_FILES directory
% this behaviour can be modified by input arguments.
%
% SYNTAX :
%   nc_ego_2_csv(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments 
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DIR_INPUT_NC_FILES directory) to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_2_csv(varargin)

% top directory of the deployment directories
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\GLIDER\FORMAT_1.4/';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\GLIDER\NC/';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY\FORMAT_1.4\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\GLIDER\DATA_PROCESSING\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\Glider\work\';

% default values initialization
gl_init_default_values;


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_ego_2_csv_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check input arguments
dataToProcessDir = [];
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            if (exist([DIR_INPUT_NC_FILES '/' varargin{id+1}], 'dir'))
               dataToProcessDir = [DIR_INPUT_NC_FILES '/' varargin{id+1}];
            else
               fprintf('WARNING: %s is not an existing directory => ignored\n', varargin{id+1});
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
end

% convert glider data
if (isempty(dataToProcessDir))
   % convert all the deployments of the DIR_INPUT_NC_FILES directory
   dirInfo = dir(DIR_INPUT_NC_FILES);
   for dirNum = 1:length(dirInfo)
      if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
         dirName = dirInfo(dirNum).name;
         
         nc_ego_2_csv_file([DIR_INPUT_NC_FILES '/' dirName]);
      end
   end
else
   % convert the data of this deployment
   nc_ego_2_csv_file(dataToProcessDir);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Convert the NetCDF EGO file of a given directory in CSV format.
%
% SYNTAX :
%  nc_ego_2_csv_file(a_dirName)
%
% INPUT PARAMETERS :
%   a_dirName : directory of the EGO file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_2_csv_file(a_dirName)

% global default values
global g_decGl_dateDef;


ncFiles = dir([a_dirName '/*.nc']);
for idF = 1:length(ncFiles)
   ncFileName = ncFiles(idF).name;
   [~, name, ext] = fileparts(ncFileName);
   inputFilePathName = [a_dirName '/' name ext];
   outFilePathName = [a_dirName '/' name '.csv'];
   
   fprintf('Converting: %s to %s\n', inputFilePathName, outFilePathName);
   
   % read the EGO file contents
   [dimensions, globalAttributes, gliderCharData, gliderDeployData, ...
      gpsData, timeData, paramList, measData, currentData, sensorInfoData, ...
      paramInfoData, histoData, derivData] = gl_read_file_ego(inputFilePathName);
   
   % create CSV file
   fidOut = fopen(outFilePathName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create output file: %s\n', outFilePathName);
      return
   end
   
   fprintf(fidOut, '*********\n');
   fprintf(fidOut, 'DIMENSION\n');
   fprintf(fidOut, '*********\n');
   fprintf(fidOut, 'Dim. name; Dim. value\n');
   fprintf(fidOut, '-------\n');
   
   for id = 1:2:length(dimensions)
      if (~isempty(dimensions{id+1}))
         fprintf(fidOut, '%s; %d\n', dimensions{id}, dimensions{id+1});
      end
   end
   
   fprintf(fidOut, '*****************\n');
   fprintf(fidOut, 'GLOBAL ATTRIBUTES\n');
   fprintf(fidOut, '*****************\n');
   fprintf(fidOut, 'Att. name; Att. value\n');
   fprintf(fidOut, '-------\n');
   
   floatWmo = gl_get_data_from_name('wmo_platform_code', globalAttributes);
   if (isempty(floatWmo))
      floatWmo = 9999999;
   else
      floatWmo = str2num(floatWmo);
   end
   for id = 1:2:length(globalAttributes)
      fprintf(fidOut, '%s; %s\n', globalAttributes{id}, globalAttributes{id+1});
   end
   
   fprintf(fidOut, '**********************\n');
   fprintf(fidOut, 'GLIDER CHARACTERISTICS\n');
   fprintf(fidOut, '**********************\n');
   fprintf(fidOut, 'Variable name; Variable value\n');
   fprintf(fidOut, '-------\n');
   
   for id = 1:2:length(gliderCharData)
      if (size(gliderCharData{id+1}, 2) > 1)
         value = cellstr(gliderCharData{id+1}');
         valueStr = sprintf('%s;', value{:});
         valueStr = valueStr(1:end-1);
      else
         valueStr = gliderCharData{id+1};
      end
      fprintf(fidOut, '%s; %s\n', gliderCharData{id}, valueStr);
   end
   
   fprintf(fidOut, '*************************\n');
   fprintf(fidOut, 'DEPLOYMENT INFORMATION\n');
   fprintf(fidOut, '*************************\n');
   fprintf(fidOut, 'Variable name; Variable value\n');
   fprintf(fidOut, '-------\n');
   
   for id = 1:2:length(gliderDeployData)
      if (ischar(gliderDeployData{id+1}))
         valueStr = gliderDeployData{id+1};
      else
         valueStr = sprintf('%g', gliderDeployData{id+1});
      end
      fprintf(fidOut, '%s; %s\n', gliderDeployData{id}, valueStr);
   end
   
   fprintf(fidOut, '********\n');
   fprintf(fidOut, 'GPS DATA\n');
   fprintf(fidOut, '********\n');
   fprintf(fidOut, '#; Date; Qc; Lon; Lat; Qc\n');
   fprintf(fidOut, '-------\n');
   
   timeGps = gl_get_data_from_name('TIME_GPS', gpsData);
   timeGpsQc = gl_get_data_from_name('TIME_GPS_QC', gpsData);
   latitudeGps = gl_get_data_from_name('LATITUDE_GPS', gpsData);
   longitudeGps = gl_get_data_from_name('LONGITUDE_GPS', gpsData);
   positionGpsQc = gl_get_data_from_name('POSITION_GPS_QC', gpsData);
   
   % compute juldGps
   paramTime = gl_get_ego_var_attributes('TIME_GPS');
   juldGps = ones(size(timeGps))*g_decGl_dateDef;
   epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
   idNodef = find(timeGps ~= paramTime.FillValue);
   juldGps(idNodef) = timeGps(idNodef)/86400 + epoch_offset;
   
   for id = 1:length(juldGps)
      fprintf(fidOut, '%d; %s; %d; %.3f; %.3f; %d\n', ...
         id, gl_julian_2_gregorian(juldGps(id)), timeGpsQc(id), longitudeGps(id), latitudeGps(id), positionGpsQc(id));
   end
   
   fprintf(fidOut, '*********\n');
   fprintf(fidOut, 'MEAS DATA\n');
   fprintf(fidOut, '*********\n');
   
   time = gl_get_data_from_name('TIME', timeData);
   timeQc = gl_get_data_from_name('TIME_QC', timeData);
   latitude = gl_get_data_from_name('LATITUDE', timeData);
   longitude = gl_get_data_from_name('LONGITUDE', timeData);
   positionQc = gl_get_data_from_name('POSITION_QC', timeData);
   posMethod = gl_get_data_from_name('POSITIONING_METHOD', timeData);
   phase = gl_get_data_from_name('PHASE', timeData);
   phaseNumber = gl_get_data_from_name('PHASE_NUMBER', timeData);

   % compute Julian 1950 dates from EPOCH 1970 dates
   paramTime = gl_get_netcdf_param_attributes('TIME');
   paramJuld = gl_get_netcdf_param_attributes('JULD');
   juld = ones(size(time))*paramJuld.fillValue;
   idNoDef = find(time ~= paramTime.fillValue);
   epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
   juld(idNoDef) = time(idNoDef)/86400 + epoch_offset;
   juldQc = timeQc;
   
   if (~isempty(latitude))
      fprintf(fidOut, '#; Date; Qc; Lon; Lat; Qc; Pos method; Phase; Phase #');
   else
      fprintf(fidOut, '#; Date; Qc; Phase; Phase #');
   end
   
   paramData = [];
   paramDataQc = [];
   for id = 1:length(paramList)
      fprintf(fidOut, '; %s; Qc', paramList{id});
      paramData = cat(2, paramData, gl_get_data_from_name(paramList{id}, measData));
      paramDataQc = cat(2, paramDataQc, gl_get_data_from_name([paramList{id} '_QC'], measData));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, '-------\n');
   
   for idJ = 1:length(juld)
      if (~isempty(latitude))
         fprintf(fidOut, '%d; %s; %d; %.3f; %.3f; %d; %d; %d; %d', ...
            idJ, gl_julian_2_gregorian(juld(idJ)), juldQc(idJ), longitude(idJ), latitude(idJ), positionQc(idJ), posMethod(idJ), phase(idJ), phaseNumber(idJ));
      else
         fprintf(fidOut, '%d; %s; %d; %d; %d', ...
            idJ, gl_julian_2_gregorian(juld(idJ)), juldQc(idJ), phase(idJ), phaseNumber(idJ));
      end
      for idM = 1:length(paramList)
         fprintf(fidOut, '; %g; %d', paramData(idJ, idM), paramDataQc(idJ, idM));
      end
      fprintf(fidOut, '\n');
   end
   
   wcTime = gl_get_data_from_name('WATERCURRENTS_TIME', currentData);
   wcLat = gl_get_data_from_name('WATERCURRENTS_LATITUDE', currentData);
   wcLon = gl_get_data_from_name('WATERCURRENTS_LONGITUDE', currentData);
   wcDepth = gl_get_data_from_name('WATERCURRENTS_DEPTH', currentData);
   wcU = gl_get_data_from_name('WATERCURRENTS_U', currentData);
   wcV = gl_get_data_from_name('WATERCURRENTS_V', currentData);
   
   % compute Julian 1950 dates from EPOCH 1970 dates
   paramTime = gl_get_netcdf_param_attributes('TIME');
   paramJuld = gl_get_netcdf_param_attributes('JULD');
   wcJuld = ones(size(wcTime))*paramJuld.fillValue;
   idNoDef = find(wcTime ~= paramTime.fillValue);
   epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
   wcJuld(idNoDef) = wcTime(idNoDef)/86400 + epoch_offset;
   
   if (~isempty(wcJuld))
      
      fprintf(fidOut, '********\n');
      fprintf(fidOut, 'CURRENT DATA\n');
      fprintf(fidOut, '********\n');
      fprintf(fidOut, '#; Date; Lon; Lat; Depth; U; V\n');
      fprintf(fidOut, '-------\n');
      
      for id = 1:length(wcJuld)
         fprintf(fidOut, '%d; %s; %.3f; %.3f; %.1f; %.1f; %.1f\n', ...
            id, gl_julian_2_gregorian(wcJuld(id)), wcLon(id), wcLat(id), wcDepth(id), wcU(id), wcV(id));
      end
   end
   
   fprintf(fidOut, '**********\n');
   fprintf(fidOut, 'HISTO DATA\n');
   fprintf(fidOut, '**********\n');
   fprintf(fidOut, '#; Histo. name; Histo. value\n');
   fprintf(fidOut, '-------;-------;-------\n');
   
   histoInstitution = gl_get_data_from_name('HISTORY_INSTITUTION', histoData);
   histoStep = gl_get_data_from_name('HISTORY_STEP', histoData);
   histoSoftware = gl_get_data_from_name('HISTORY_SOFTWARE', histoData);
   histoSoftwareRelease = gl_get_data_from_name('HISTORY_SOFTWARE_RELEASE', histoData);
   histoReference = gl_get_data_from_name('HISTORY_REFERENCE', histoData);
   histoDate = gl_get_data_from_name('HISTORY_DATE', histoData);
   histoAction = gl_get_data_from_name('HISTORY_ACTION', histoData);
   histoParameter = gl_get_data_from_name('HISTORY_PARAMETER', histoData);
   histoPreviousValue = gl_get_data_from_name('HISTORY_PREVIOUS_VALUE', histoData);
   histoStartTimeIndex = gl_get_data_from_name('HISTORY_START_TIME_INDEX', histoData);
   histoStopTimeIndex = gl_get_data_from_name('HISTORY_STOP_TIME_INDEX', histoData);
   histoQcTest = gl_get_data_from_name('HISTORY_QCTEST', histoData);
   
   for id = 1:size(histoInstitution, 2)
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_INSTITUTION', strtrim(histoInstitution(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_STEP', strtrim(histoStep(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_SOFTWARE', strtrim(histoSoftware(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_SOFTWARE_RELEASE', strtrim(histoSoftwareRelease(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_REFERENCE', strtrim(histoReference(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_DATE', strtrim(histoDate(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_ACTION', strtrim(histoAction(:, id)'));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_PARAMETER', strtrim(histoParameter(:, id)'));
      fprintf(fidOut, '%d; %s; %g\n', ...
         id, 'HISTORY_PREVIOUS_VALUE', histoPreviousValue(id));
      fprintf(fidOut, '%d; %s; %d\n', ...
         id, 'HISTORY_START_TIME_INDEX', histoStartTimeIndex(id));
      fprintf(fidOut, '%d; %s; %d\n', ...
         id, 'HISTORY_STOP_TIME_INDEX', histoStopTimeIndex(id));
      fprintf(fidOut, '%d; %s; %s\n', ...
         id, 'HISTORY_QCTEST', strtrim(histoQcTest(:, id)'));
      fprintf(fidOut, '-------;-------;-------\n');
   end
   
   fprintf(fidOut, '***********\n');
   fprintf(fidOut, 'SENSOR DATA\n');
   fprintf(fidOut, '***********\n');
   
   sensor = gl_get_data_from_name('SENSOR', sensorInfoData);
   sensorMaker = gl_get_data_from_name('SENSOR_MAKER', sensorInfoData);
   sensorModel = gl_get_data_from_name('SENSOR_MODEL', sensorInfoData);
   sensorSerialNo = gl_get_data_from_name('SENSOR_SERIAL_NO', sensorInfoData);
   sensorMount = gl_get_data_from_name('SENSOR_MOUNT', sensorInfoData);
   sensorOrientation = gl_get_data_from_name('SENSOR_ORIENTATION', sensorInfoData);

   fprintf(fidOut, 'SENSOR');
   for id = 1:size(sensor, 2)
      fprintf(fidOut, ';%s', strtrim(sensor(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'SENSOR_MAKER');
   for id = 1:size(sensorMaker, 2)
      fprintf(fidOut, ';"%s"', strtrim(sensorMaker(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'SENSOR_MODEL');
   for id = 1:size(sensorModel, 2)
      fprintf(fidOut, ';"%s"', strtrim(sensorModel(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'SENSOR_SERIAL_NO');
   for id = 1:size(sensorSerialNo, 2)
      fprintf(fidOut, ';"%s"', strtrim(sensorSerialNo(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'SENSOR_MOUNT');
   for id = 1:size(sensorMount, 2)
      fprintf(fidOut, ';"%s"', strtrim(sensorMount(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'SENSOR_ORIENTATION');
   for id = 1:size(sensorOrientation, 2)
      fprintf(fidOut, ';%s', strtrim(sensorOrientation(:, id)'));
   end
   fprintf(fidOut, '\n');   
   
   fprintf(fidOut, '**************\n');
   fprintf(fidOut, 'PARAMETER DATA\n');
   fprintf(fidOut, '**************\n');
   
   param = gl_get_data_from_name('PARAMETER', paramInfoData);
   paramSensor = gl_get_data_from_name('PARAMETER_SENSOR', paramInfoData);
   paramDataMode = gl_get_data_from_name('PARAMETER_DATA_MODE', paramInfoData);
   paramUnits = gl_get_data_from_name('PARAMETER_UNITS', paramInfoData);
   paramAccuracy = gl_get_data_from_name('PARAMETER_ACCURACY', paramInfoData);
   paramResolution = gl_get_data_from_name('PARAMETER_RESOLUTION', paramInfoData);

   fprintf(fidOut, 'PARAMETER');
   for id = 1:size(param, 2)
      fprintf(fidOut, ';%s', strtrim(param(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'PARAMETER_SENSOR');
   for id = 1:size(paramSensor, 2)
      fprintf(fidOut, ';"%s"', strtrim(paramSensor(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'PARAMETER_DATA_MODE');
   for id = 1:size(paramDataMode, 1)
      fprintf(fidOut, ';"%s"', paramDataMode(id, 1));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'PARAMETER_UNITS');
   for id = 1:size(paramUnits, 2)
      fprintf(fidOut, ';"%s"', strtrim(paramUnits(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'PARAMETER_ACCURACY');
   for id = 1:size(paramAccuracy, 2)
      fprintf(fidOut, ';"%s"', strtrim(paramAccuracy(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'PARAMETER_RESOLUTION');
   for id = 1:size(paramResolution, 2)
      fprintf(fidOut, ';"%s"', strtrim(paramResolution(:, id)'));
   end
   fprintf(fidOut, '\n');     

   fprintf(fidOut, '**********\n');
   fprintf(fidOut, 'DERIV DATA\n');
   fprintf(fidOut, '**********\n');
   
   derivParameter = gl_get_data_from_name('DERIVATION_PARAMETER', derivData);
   derivEquation = gl_get_data_from_name('DERIVATION_EQUATION', derivData);
   derivCoefficient = gl_get_data_from_name('DERIVATION_COEFFICIENT', derivData);
   derivComment = gl_get_data_from_name('DERIVATION_COMMENT', derivData);
   derivDate = gl_get_data_from_name('DERIVATION_DATE', derivData);

   fprintf(fidOut, 'PARAMETER');
   for id = 1:size(derivParameter, 2)
      fprintf(fidOut, ';%s', strtrim(derivParameter(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'EQUATION');
   for id = 1:size(derivEquation, 2)
      fprintf(fidOut, ';"%s"', strtrim(derivEquation(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'COEFFICIENT');
   for id = 1:size(derivCoefficient, 2)
      fprintf(fidOut, ';"%s"', strtrim(derivCoefficient(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'COMMENT');
   for id = 1:size(derivComment, 2)
      fprintf(fidOut, ';"%s"', strtrim(derivComment(:, id)'));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'DATE');
   for id = 1:size(derivDate, 2)
      fprintf(fidOut, ';%s', strtrim(derivDate(:, id)'));
   end
   fprintf(fidOut, '\n');
   
   fclose(fidOut);
end

% convert associated NetCDF profile files
if (exist([a_dirName '/profiles/'], 'dir'))
   
   fprintf('Converting associated profile files:\n');
   
   ncFiles = dir([a_dirName '/profiles/*.nc']);
   for idF = 1:length(ncFiles)
      ncFileName = ncFiles(idF).name;
      [~, name, ext] = fileparts(ncFileName);
      inputFilePathName = [a_dirName '/profiles/' name ext];
      outFilePathName = [a_dirName '/profiles/' name '.csv'];
      
      %       fprintf('   -> Converting: %s to %s\n', [a_dirName name ext], [a_dirName name '.csv']);
      
      nc_prof_adj_2_csv_file(inputFilePathName, outFilePathName, ...
         floatWmo, 0, 1, 1)
   end
end

return

% ------------------------------------------------------------------------------
% Convert one NetCDF profile file contents in CSV format.
%
% SYNTAX :
%  nc_prof_adj_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
%    a_floatNum, a_comparisonFlag, a_writeQcFlag, a_cfileFlag)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%   a_floatNum           : float WMO number
%   a_comparisonFlag     : if 1, do not print current dates
%   a_writeQcFlag        : if 1, print parameter QC values
%   a_cfileFlag          : 0 if B file, 1 if C file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_prof_adj_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag, a_writeQcFlag, a_cfileFlag)

% QC flag values (char)
global g_decGl_qcStrDef;
global g_decGl_qcStrUnused2;


% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('   -> Converting: %s to %s\n', inputFileName, ourputFileName);

% open NetCDF file
fCdf = netcdf.open(a_inputPathFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_inputPathFileName);
   return
end

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return
end

% dimensions
nProf = -1;
nParam = -1;
nHistory = -1;
nCalib = -1;
dimList = [ ...
   {'N_PROF'} ...
   {'N_PARAM'} ...
   {'N_LEVELS'} ...
   {'N_HISTORY'} ...
   {'N_CALIB'} ...
   ];
fprintf(fidOut, ' WMO; ----------; ----------; DIMENSION\n');
for idDim = 1:length(dimList)
   if (gl_dim_is_present(fCdf, dimList{idDim}))
      [dimName, dimLen] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, dimList{idDim}));
      fprintf(fidOut, ' %d; ; ; %s; %d\n', a_floatNum, dimName, dimLen);
      if (strcmp(dimName, 'N_PROF'))
         nProf = dimLen;
      end
      if (strcmp(dimName, 'N_PARAM'))
         nParam = dimLen;
      end
      if (strcmp(dimName, 'N_HISTORY'))
         nHistory = dimLen;
      end
      if (strcmp(dimName, 'N_CALIB'))
         nCalib = dimLen;
      end
   end
end
[dimName, dimLength] = gl_dim_is_present2(fCdf, 'N_VALUES');
for idDim = 1:length(dimName)
   fprintf(fidOut, ' %d; ; ; %s; %d\n', a_floatNum, dimName{idDim}, dimLength(idDim));
end

% global attributes
globAttList = [ ...
   {'title'} ...
   {'institution'} ...
   {'source'} ...
   {'history'} ...
   {'references'} ...
   {'user_manual_version'} ...
   {'Conventions'} ...
   {'featureType'} ...
   ];
if (a_comparisonFlag == 1)
   globAttList = [ ...
      {'title'} ...
      {'institution'} ...
      {'source'} ...
      {'references'} ...
      {'user_manual_version'} ...
      {'Conventions'} ...
      {'featureType'} ...
      ];
end
fprintf(fidOut, ' WMO; ----------; ----------; GLOBAL_ATT\n');
for idAtt = 1:length(globAttList)
   if (gl_global_att_is_present(fCdf, globAttList{idAtt}))
      attValue = netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), globAttList{idAtt});
      fprintf(fidOut, ' %d; ; ; %s; %s\n', a_floatNum, globAttList{idAtt}, strtrim(attValue));
   else
      fprintf('WARNING: Global attribute %s is missing in file %s\n', ...
         globAttList{idAtt}, inputFileName);
   end
end

% file meta-data
varList = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'REFERENCE_DATE_TIME'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   ];
if (a_comparisonFlag == 1)
   varList = [ ...
      {'DATA_TYPE'} ...
      {'FORMAT_VERSION'} ...
      {'HANDBOOK_VERSION'} ...
      {'REFERENCE_DATE_TIME'} ...
      ];
end
fprintf(fidOut, ' WMO; ----------; ----------; META-DATA\n');
for idVar = 1:length(varList)
   if (gl_var_is_present(fCdf, varList{idVar}))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varList{idVar}));
      fprintf(fidOut, ' %d; ; ; %s; %s\n', a_floatNum, varList{idVar}, strtrim(varValue));
   else
      fprintf('WARNING: Variable %s is missing in file %s\n', ...
         varList{idVar}, inputFileName);
   end
end

% profile meta-data
varList = [ ...
   {'PLATFORM_NUMBER'} ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'DATA_CENTRE'} ...
   {'DC_REFERENCE'} ...
   {'PLATFORM_TYPE'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'FIRMWARE_VERSION'} ...
   {'WMO_INST_TYPE'} ...
   ];
for idVar = 1:length(varList)
   if (gl_var_is_present(fCdf, varList{idVar}))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varList{idVar}));
      fprintf(fidOut, ' %d; ; ; %s', a_floatNum, varList{idVar});
      for idP = 1:nProf
         fprintf(fidOut, '; %s', strtrim(varValue(:, idP)'));
      end
      fprintf(fidOut, '\n');
      %    else
      %       fprintf('WARNING: Variable %s is missing in file %s\n', ...
      %          varList{idVar}, inputFileName);
   end
end

varName = 'CYCLE_NUMBER';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   cycleNumber = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'DIRECTION';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   direction = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'DATA_MODE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   dataMode = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'PARAMETER_DATA_MODE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   parameterDataMode = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'DATA_STATE_INDICATOR';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   dataStateIndicator = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'JULD';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   julD = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'JULD_QC';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   julDQc = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'JULD_LOCATION';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   julDLocation = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'LATITUDE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   latitude = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'LONGITUDE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   longitude = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'POSITION_QC';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   positionQc = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'POSITIONING_SYSTEM';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   positioningSystem = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'STATION_PARAMETERS';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   stationParameters = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'VERTICAL_SAMPLING_SCHEME';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   verticalSamplingScheme = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

% varName = 'CONFIG_MISSION_NUMBER';
% if (gl_var_is_present(fCdf, varName))
%    varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
%    configMissionNumber = varValue;
% else
%    fprintf('WARNING: Variable %s is missing in file %s\n', ...
%       varName, inputFileName);
% end

paramList2 = [ ...
   {'TEMP_STD'} ...
   {'TEMP_MED'} ...
   {'PSAL_STD'} ...
   {'PSAL_MED'} ...
   ];
sufixList = [{''} {'_STD'} {'_MED'}];
sufixList = [{''}];
paramList = [];
if (a_cfileFlag == 0)
   for idP = 1:length(paramList2)
      if (gl_var_is_present(fCdf, paramList2{idP}))
         paramList = [paramList {paramList2{idP}}];
      end
   end
end
for id3 = 1:size(stationParameters, 3)
   for id2 = 1:size(stationParameters, 2)
      paramName = strtrim(stationParameters(:, id2, id3)');
      if (~isempty(paramName))
         paramList = [paramList {paramName}];
         paramInfo = gl_get_netcdf_param_attributes(paramName);
         if (paramInfo.adjAllowed == 1)
            if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
               paramList = [paramList {[paramName '_ADJUSTED']}];
            end
         end
      end
   end
end
paramList = unique(paramList);

if (a_writeQcFlag == 0)
   
   paramData = [];
   paramFormat = [];
   paramFillValue = [];
   profileParamQc = [];
   for idParam = 1:length(paramList)
      if (gl_var_is_present(fCdf, paramList{idParam}))
         
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'double');
         else
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}));
         end
         paramData = [paramData {varValue}];
         varFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'C_format');
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varFormat = '%u';
         else
            varFormat = '%g';
         end
         paramFormat = [paramFormat {varFormat}];
         varFillValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), '_FillValue');
         paramFillValue = [paramFillValue {varFillValue}];
      else
         if ~(strcmp(paramList{idParam}, 'PRES_ADJUSTED') && (a_cfileFlag == 0))
            fprintf('WARNING: Variable %s is missing in file %s\n', ...
               paramList{idParam}, inputFileName);
         end
         paramData = [paramData ''];
         paramFormat = [paramFormat ''];
         paramFillValue = [paramFillValue ''];
      end
      profileParamVarName = ['PROFILE_' paramList{idParam} '_QC'];
      if (gl_var_is_present(fCdf, profileParamVarName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, profileParamVarName));
         profileParamQc = [profileParamQc {varValue}];
      else
         if ~(((a_cfileFlag == 0) && ...
               (strcmp(paramList{idParam}, 'PRES') || ...
               strcmp(paramList{idParam}(end-3:end), '_STD') || ...
               strcmp(paramList{idParam}(end-3:end), '_MED'))) || ...
               (~isempty(strfind(paramList{idParam}, '_ADJUSTED'))))
            fprintf('WARNING: Variable %s is missing in file %s\n', ...
               profileParamVarName, inputFileName);
         end
         profileParamQc = [profileParamQc {''}];
      end
   end
   
   % profile data
   for idP = 1:nProf
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_META-DATA\n');
      
      fprintf(fidOut, ' %d; %d; %d; VERTICAL_SAMPLING_SCHEME; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(verticalSamplingScheme(:, idP)'));
      fprintf(fidOut, ' %d; %d; %d; CONFIG_MISSION_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         configMissionNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; CYCLE_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         cycleNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; DIRECTION; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         direction(idP));
      fprintf(fidOut, ' %d; %d; %d; DATA_MODE; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         dataMode(idP));
      fprintf(fidOut, ' %d; %d; %d; PARAMETER_DATA_MODE; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         parameterDataMode(:, idP)');
      fprintf(fidOut, ' %d; %d; %d; DATA_STATE_INDICATOR; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(dataStateIndicator(:, idP)'));
      fprintf(fidOut, ' %d; %d; %d; JULD; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         gl_julian_2_gregorian(julD(idP)));
      fprintf(fidOut, ' %d; %d; %d; JULD_QC; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         julDQc(idP));
      fprintf(fidOut, ' %d; %d; %d; JULD_LOCATION; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         gl_julian_2_gregorian(julDLocation(idP)));
      fprintf(fidOut, ' %d; %d; %d; LATITUDE; %.3f\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         latitude(idP));
      fprintf(fidOut, ' %d; %d; %d; LONGITUDE; %.3f\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         longitude(idP));
      fprintf(fidOut, ' %d; %d; %d; POSITION_QC; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         positionQc(idP));
      fprintf(fidOut, ' %d; %d; %d; POSITIONING_SYSTEM; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(positioningSystem(:, idP)'));
      
      fprintf(fidOut, ' %d; %d; %d; STATION_PARAMETERS', ...
         a_floatNum, cycleNumber(idP), idP);
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            % PARAM
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  fprintf(fidOut, '; %s', ...
                     paramName);
               else
                  for id1 = 1:size(dataTmp, 1);
                     fprintf(fidOut, '; %s', ...
                        sprintf('%s_%d', paramName, id1));
                  end
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
            
            % PARAM_ADJUSTED
            if (~strcmp(paramName, 'PRES_STD') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_MED') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_STD'))
               paramInfo = gl_get_netcdf_param_attributes(paramName);
               if (~isempty(paramInfo))
                  if (paramInfo.adjAllowed == 1)
                     paramName = [paramName '_ADJUSTED'];
                     idF = find(strcmp(paramList, paramName) == 1, 1);
                     if (~isempty(idF))
                        dataTmp = paramData{idF};
                        if (ndims(dataTmp) == 2)
                           fprintf(fidOut, '; %s', ...
                              paramName);
                        else
                           for id1 = 1:size(dataTmp, 1);
                              fprintf(fidOut, '; %s', ...
                                 sprintf('%s_%d', paramName, id1));
                           end
                        end
                     elseif (idS == 1)
                        if ~(strcmp(parameterName, 'PRES') && (a_cfileFlag == 0))
                           fprintf('ERROR: Variable %s is missing in file %s\n', ...
                              paramName, inputFileName);
                        end
                     end
                  end
               end
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  % PARAM
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        fprintf(fidOut, '; %s', ...
                           paramName);
                     else
                        for id1 = 1:size(dataTmp, 1);
                           fprintf(fidOut, '; %s', ...
                              sprintf('%s_%d', paramName, id1));
                        end
                     end
                  elseif (idS == 1)
                     fprintf('ERROR: Variable %s is missing in file %s\n', ...
                        paramName, inputFileName);
                  end
               end
            end
         end
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; PROFILE_<PARAM>_QC; ', ...
         a_floatNum, cycleNumber(idP), idP);
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            % PARAM
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               profileParamQcTmp = profileParamQc{idF};
               if (~isempty(profileParamQcTmp))
                  fprintf(fidOut, '%c; ', ...
                     profileParamQcTmp(idP));
                  dataTmp = paramData{idF};
                  if (ndims(dataTmp) == 3)
                     for id1 = 2:size(dataTmp, 1);
                        fprintf(fidOut, '; ');
                     end
                  end
               else
                  fprintf(fidOut, '; ');
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
            
            % PARAM_ADJUSTED
            if (~strcmp(paramName, 'PRES_STD') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_MED') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_STD'))
               paramInfo = gl_get_netcdf_param_attributes(paramName);
               if (paramInfo.adjAllowed == 1)
                  if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                     fprintf(fidOut, '; ');
                  end
               end
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  % PARAM
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     profileParamQcTmp = profileParamQc{idF};
                     if (~isempty(profileParamQcTmp))
                        fprintf(fidOut, '%c; ', ...
                           profileParamQcTmp(idP));
                        dataTmp = paramData{idF};
                        if (ndims(dataTmp) == 3)
                           for id1 = 2:size(dataTmp, 1);
                              fprintf(fidOut, '; ');
                           end
                        end
                     else
                        fprintf(fidOut, '; ');
                     end
                  elseif (idS == 1)
                     fprintf('ERROR: Variable %s is missing in file %s\n', ...
                        paramName, inputFileName);
                  end
               end
            end
         end
      end
      fprintf(fidOut, '\n');
      
      data = [];
      dataFillValue = [];
      format = '';
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            % PARAM
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  data = [data double(dataTmp(:, idP))];
                  dataFillValue = [dataFillValue paramFillValue{idF}];
                  format = [format '; ' paramFormat{idF}];
               else
                  for id1 = 1:size(dataTmp, 1);
                     data = [data double(dataTmp(id1, :, idP)')];
                     dataFillValue = [dataFillValue paramFillValue{idF}];
                     format = [format '; ' paramFormat{idF}];
                  end
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
            
            % PARAM_ADJUSTED
            if (~strcmp(paramName, 'PRES_STD') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_MED') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_STD'))
               paramInfo = gl_get_netcdf_param_attributes(paramName);
               if (paramInfo.adjAllowed == 1)
                  paramName = [paramName '_ADJUSTED'];
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        data = [data double(dataTmp(:, idP))];
                        dataFillValue = [dataFillValue paramFillValue{idF}];
                        format = [format '; ' paramFormat{idF}];
                     else
                        for id1 = 1:size(dataTmp, 1);
                           data = [data double(dataTmp(id1, :, idP)')];
                           dataFillValue = [dataFillValue paramFillValue{idF}];
                           format = [format '; ' paramFormat{idF}];
                        end
                     end
                  elseif (idS == 1)
                     if ~(strcmp(parameterName, 'PRES') && (a_cfileFlag == 0))
                        fprintf('ERROR: Variable %s is missing in file %s\n', ...
                           paramName, inputFileName);
                     end
                  end
               end
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  % PARAM
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        data = [data double(dataTmp(:, idP))];
                        dataFillValue = [dataFillValue paramFillValue{idF}];
                        format = [format '; ' paramFormat{idF}];
                     else
                        for id1 = 1:size(dataTmp, 1);
                           data = [data double(dataTmp(id1, :, idP)')];
                           dataFillValue = [dataFillValue paramFillValue{idF}];
                           format = [format '; ' paramFormat{idF}];
                        end
                     end
                  elseif (idS == 1)
                     fprintf('ERROR: Variable %s is missing in file %s\n', ...
                        paramName, inputFileName);
                  end
               end
            end
         end
      end
      
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_MEAS\n');
      for idLev = 1:size(data, 1);
         if (sum(data(idLev, :) == dataFillValue) ~= size(data, 2))
            fprintf(fidOut, ' %d; %d; %d; MEAS #%d', ...
               a_floatNum, cycleNumber(idP), idP, idLev);
            fprintf(fidOut, format, ...
               data(idLev, :));
            fprintf(fidOut, '\n');
         end
      end
      
   end
else
   
   paramData = [];
   paramDataQc = [];
   paramFormat = [];
   paramFillValue = [];
   profileParamQc = [];
   for idParam = 1:length(paramList)
      if (gl_var_is_present(fCdf, paramList{idParam}))
         
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'double');
         else
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}));
         end
         paramData = [paramData {varValue}];
         varFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'C_format');
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varFormat = '%u';
         else
            varFormat = '%g';
         end
         paramFormat = [paramFormat {varFormat}];
         varFillValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), '_FillValue');
         paramFillValue = [paramFillValue {varFillValue}];
         
         if (((a_cfileFlag == 0) && ...
               (strcmp(paramList{idParam}, 'PRES') || ...
               strcmp(paramList{idParam}(end-3:end), '_STD') || ...
               strcmp(paramList{idParam}(end-3:end), '_MED'))))
            paramDataQc = [paramDataQc {''}];
         else
            varQcValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, [paramList{idParam} '_QC']));
            paramDataQc = [paramDataQc {varQcValue}];
         end
      else
         if ~(strcmp(paramList{idParam}, 'PRES_ADJUSTED') && (a_cfileFlag == 0))
            fprintf('WARNING: Variable %s is missing in file %s\n', ...
               paramList{idParam}, inputFileName);
         end
         paramData = [paramData ''];
         paramFormat = [paramFormat ''];
         paramFillValue = [paramFillValue ''];
         paramDataQc = [paramDataQc ''];
      end
      profileParamVarName = ['PROFILE_' paramList{idParam} '_QC'];
      if (gl_var_is_present(fCdf, profileParamVarName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, profileParamVarName));
         profileParamQc = [profileParamQc {varValue}];
      else
         if ~(((a_cfileFlag == 0) && ...
               (strcmp(paramList{idParam}, 'PRES') || ...
               strcmp(paramList{idParam}(end-3:end), '_STD') || ...
               strcmp(paramList{idParam}(end-3:end), '_MED'))) || ...
               (~isempty(strfind(paramList{idParam}, '_ADJUSTED'))))
            fprintf('WARNING: Variable %s is missing in file %s\n', ...
               profileParamVarName, inputFileName);
         end
         profileParamQc = [profileParamQc {''}];
      end
   end
   
   % profile data
   for idP = 1:nProf
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_META-DATA\n');
      
      fprintf(fidOut, ' %d; %d; %d; VERTICAL_SAMPLING_SCHEME; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(verticalSamplingScheme(:, idP)'));
%       fprintf(fidOut, ' %d; %d; %d; CONFIG_MISSION_NUMBER; %d\n', ...
%          a_floatNum, cycleNumber(idP), idP, ...
%          configMissionNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; CYCLE_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         cycleNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; DIRECTION; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         direction(idP));
      fprintf(fidOut, ' %d; %d; %d; DATA_MODE; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         dataMode(idP));
      fprintf(fidOut, ' %d; %d; %d; PARAMETER_DATA_MODE; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         parameterDataMode(:, idP)');
      fprintf(fidOut, ' %d; %d; %d; DATA_STATE_INDICATOR; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(dataStateIndicator(:, idP)'));
      fprintf(fidOut, ' %d; %d; %d; JULD; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         gl_julian_2_gregorian(julD(idP)));
      fprintf(fidOut, ' %d; %d; %d; JULD_QC; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         julDQc(idP));
      fprintf(fidOut, ' %d; %d; %d; JULD_LOCATION; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         gl_julian_2_gregorian(julDLocation(idP)));
      fprintf(fidOut, ' %d; %d; %d; LATITUDE; %.3f\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         latitude(idP));
      fprintf(fidOut, ' %d; %d; %d; LONGITUDE; %.3f\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         longitude(idP));
      fprintf(fidOut, ' %d; %d; %d; POSITION_QC; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         positionQc(idP));
      fprintf(fidOut, ' %d; %d; %d; POSITIONING_SYSTEM; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(positioningSystem(:, idP)'));
      
      fprintf(fidOut, ' %d; %d; %d; STATION_PARAMETERS', ...
         a_floatNum, cycleNumber(idP), idP);
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            % PARAM
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  fprintf(fidOut, '; %s', ...
                     paramName);
               else
                  for id1 = 1:size(dataTmp, 1);
                     fprintf(fidOut, '; %s', ...
                        sprintf('%s_%d', paramName, id1));
                  end
               end
               if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                  fprintf(fidOut, '; QC');
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
            
            % PARAM_ADJUSTED
            if (~strcmp(paramName, 'PRES_STD') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_MED') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_STD'))
               paramInfo = gl_get_netcdf_param_attributes(paramName);
               if (~isempty(paramInfo))
                  if (paramInfo.adjAllowed == 1)
                     if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                        paramName = [paramName '_ADJUSTED'];
                        idF = find(strcmp(paramList, paramName) == 1, 1);
                        if (~isempty(idF))
                           dataTmp = paramData{idF};
                           if (ndims(dataTmp) == 2)
                              fprintf(fidOut, '; %s', ...
                                 paramName);
                           else
                              for id1 = 1:size(dataTmp, 1);
                                 fprintf(fidOut, '; %s', ...
                                    sprintf('%s_%d', paramName, id1));
                              end
                           end
                           if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                              fprintf(fidOut, '; QC');
                           end
                        else
                           if ~(strcmp(parameterName, 'PRES') && (a_cfileFlag == 0))
                              fprintf('ERROR: Variable %s is missing in file %s\n', ...
                                 paramName, inputFileName);
                           end
                        end
                     end
                  end
               end
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  % PARAM
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        fprintf(fidOut, '; %s', ...
                           paramName);
                     else
                        for id1 = 1:size(dataTmp, 1);
                           fprintf(fidOut, '; %s', ...
                              sprintf('%s_%d', paramName, id1));
                        end
                     end
                     %                      if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                     %                         fprintf(fidOut, '; QC');
                     %                      end
                  elseif (idS == 1)
                     fprintf('ERROR: Variable %s is missing in file %s\n', ...
                        paramName, inputFileName);
                  end
               end
            end
         end
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; PROFILE_<PARAM>_QC; ', ...
         a_floatNum, cycleNumber(idP), idP);
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            % PARAM
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               profileParamQcTmp = profileParamQc{idF};
               if (~isempty(profileParamQcTmp))
                  fprintf(fidOut, '%c; ', ...
                     profileParamQcTmp(idP));
                  dataTmp = paramData{idF};
                  if (ndims(dataTmp) == 3)
                     for id1 = 2:size(dataTmp, 1);
                        fprintf(fidOut, '; ');
                     end
                  end
                  fprintf(fidOut, '; ');
               else
                  fprintf(fidOut, '; ');
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
            
            % PARAM_ADJUSTED
            if (~strcmp(paramName, 'PRES_STD') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_MED') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_STD'))
               paramInfo = gl_get_netcdf_param_attributes(paramName);
               if (~isempty(paramInfo))
                  if (paramInfo.adjAllowed == 1)
                     if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                        fprintf(fidOut, '; ; ');
                     end
                  end
               end
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  % PARAM
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     profileParamQcTmp = profileParamQc{idF};
                     if (~isempty(profileParamQcTmp))
                        fprintf(fidOut, '%c; ', ...
                           profileParamQcTmp(idP));
                        dataTmp = paramData{idF};
                        if (ndims(dataTmp) == 3)
                           for id1 = 2:size(dataTmp, 1);
                              fprintf(fidOut, '; ');
                           end
                        end
                        fprintf(fidOut, '; ');
                     else
                        fprintf(fidOut, '; ');
                     end
                  elseif (idS == 1)
                     fprintf('ERROR: Variable %s is missing in file %s\n', ...
                        paramName, inputFileName);
                  end
               end
            end
         end
      end
      fprintf(fidOut, '\n');
      
      data = [];
      dataFillValue = [];
      format = '';
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            % PARAM
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  data = [data double(dataTmp(:, idP))];
                  dataFillValue = [dataFillValue paramFillValue{idF}];
                  format = [format '; ' paramFormat{idF}];
               else
                  for id1 = 1:size(dataTmp, 1);
                     data = [data double(dataTmp(id1, :, idP)')];
                     dataFillValue = [dataFillValue paramFillValue{idF}];
                     format = [format '; ' paramFormat{idF}];
                  end
               end
               dataQcTmp = paramDataQc{idF};
               if (~isempty(dataQcTmp))
                  dataQcTmp = dataQcTmp(:, idP);
                  dataQcTmp(find(dataQcTmp == g_decGl_qcStrDef)) = g_decGl_qcStrUnused2;
                  dataQcTmp = str2num(dataQcTmp);
                  dataQcTmp(find(dataQcTmp == str2num(g_decGl_qcStrUnused2))) = -1;
                  data = [data double(dataQcTmp)];
                  dataFillValue = [dataFillValue -1];
                  format = [format '; ' '%d'];
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
            
            % PARAM_ADJUSTED
            if (~strcmp(paramName, 'PRES_STD') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_MED') && ...
                  ~strcmp(paramName, 'MOLAR_DOXY_STD'))
               paramInfo = gl_get_netcdf_param_attributes(paramName);
               if (~isempty(paramInfo))
                  if (paramInfo.adjAllowed == 1)
                     if ~(strcmp(paramName, 'PRES') && (a_cfileFlag == 0))
                        paramName = [paramName '_ADJUSTED'];
                        idF = find(strcmp(paramList, paramName) == 1, 1);
                        if (~isempty(idF))
                           dataTmp = paramData{idF};
                           if (ndims(dataTmp) == 2)
                              data = [data double(dataTmp(:, idP))];
                              dataFillValue = [dataFillValue paramFillValue{idF}];
                              format = [format '; ' paramFormat{idF}];
                           else
                              for id1 = 1:size(dataTmp, 1);
                                 data = [data double(dataTmp(id1, :, idP)')];
                                 dataFillValue = [dataFillValue paramFillValue{idF}];
                                 format = [format '; ' paramFormat{idF}];
                              end
                           end
                           dataQcTmp = paramDataQc{idF};
                           if (~isempty(dataQcTmp))
                              dataQcTmp = dataQcTmp(:, idP);
                              dataQcTmp(find(dataQcTmp == g_decGl_qcStrDef)) = g_decGl_qcStrUnused2;
                              dataQcTmp = str2num(dataQcTmp);
                              dataQcTmp(find(dataQcTmp == str2num(g_decGl_qcStrUnused2))) = -1;
                              data = [data double(dataQcTmp)];
                              dataFillValue = [dataFillValue -1];
                              format = [format '; ' '%d'];
                           end
                        elseif (idS == 1)
                           if ~(strcmp(parameterName, 'PRES') && (a_cfileFlag == 0))
                              fprintf('ERROR: Variable %s is missing in file %s\n', ...
                                 paramName, inputFileName);
                           end
                        end
                     end
                  end
               end
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  % PARAM
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        data = [data double(dataTmp(:, idP))];
                        dataFillValue = [dataFillValue paramFillValue{idF}];
                        format = [format '; ' paramFormat{idF}];
                     else
                        for id1 = 1:size(dataTmp, 1);
                           data = [data double(dataTmp(id1, :, idP)')];
                           dataFillValue = [dataFillValue paramFillValue{idF}];
                           format = [format '; ' paramFormat{idF}];
                        end
                     end
                     dataQcTmp = paramDataQc{idF};
                     if (~isempty(dataQcTmp))
                        dataQcTmp = dataQcTmp(:, idP);
                        dataQcTmp(find(dataQcTmp == g_decGl_qcStrDef)) = g_decGl_qcStrUnused2;
                        dataQcTmp = str2num(dataQcTmp);
                        dataQcTmp(find(dataQcTmp == str2num(g_decGl_qcStrUnused2))) = -1;
                        data = [data double(dataQcTmp)];
                        dataFillValue = [dataFillValue -1];
                        format = [format '; ' '%d'];
                     end
                  elseif (idS == 1)
                     fprintf('ERROR: Variable %s is missing in file %s\n', ...
                        paramName, inputFileName);
                  end
               end
            end
         end
      end
      
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_MEAS\n');
      for idLev = 1:size(data, 1);
         if (sum(data(idLev, :) == dataFillValue) ~= size(data, 2))
            fprintf(fidOut, ' %d; %d; %d; MEAS #%d', ...
               a_floatNum, cycleNumber(idP), idP, idLev);
            fprintf(fidOut, format, ...
               data(idLev, :));
            fprintf(fidOut, '\n');
         end
      end
      
   end
end

varName = 'PARAMETER';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   parameter = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_EQUATION';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibEquation = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_COEFFICIENT';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibCoefficient = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_COMMENT';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibComment = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_DATE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibDate = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

% calibration information
fprintf(fidOut, ' WMO; N_PROF; N_CALIB; CALIB_DATA\n');
for idP = 1:nProf
   for idC = 1:nCalib
      fprintf(fidOut, ' %d; %d; %d; PARAMETER', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(parameter(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_EQUATION', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibEquation(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_COEFFICIENT', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibCoefficient(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_COMMENT', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibComment(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_DATE', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibDate(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
   end
end

varName = 'HISTORY_INSTITUTION';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyInstitution = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_STEP';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyStep = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_SOFTWARE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historySoftware = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_SOFTWARE_RELEASE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historySoftwareRelease = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_REFERENCE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyReference = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_DATE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyDate = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_ACTION';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyAction = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_PARAMETER';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyParameter = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_START_PRES';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyStartPres = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_STOP_PRES';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyStopPres = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_PREVIOUS_VALUE';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyPreviousValue = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_QCTEST';
if (gl_var_is_present(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyQcTest = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

% history information
fprintf(fidOut, ' WMO; N_HISTORY; N_PROF; HISTORY_DATA\n');
for idH = 1:nHistory
   for idP = 1:nProf
      fprintf(fidOut, ' %d; %d; %d; HISTORY_INSTITUTION; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyInstitution(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_STEP; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyStep(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_SOFTWARE; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historySoftware(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_SOFTWARE_RELEASE; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historySoftwareRelease(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_REFERENCE; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyReference(:, idP, idH)'));
      if (a_comparisonFlag == 0)
         fprintf(fidOut, ' %d; %d; %d; HISTORY_DATE; %s\n', ...
            a_floatNum, idH, idP, ...
            strtrim(historyDate(:, idP, idH)'));
      end
      fprintf(fidOut, ' %d; %d; %d; HISTORY_ACTION; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyAction(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_PARAMETER; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyParameter(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_START_PRES; %g\n', ...
         a_floatNum, idH, idP, ...
         historyStartPres(idP, idH));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_STOP_PRES; %g\n', ...
         a_floatNum, idH, idP, ...
         historyStopPres(idP, idH));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_PREVIOUS_VALUE; %g\n', ...
         a_floatNum, idH, idP, ...
         historyPreviousValue(idP, idH));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_QCTEST; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyQcTest(:, idP, idH)'));
   end
end

fclose(fidOut);

netcdf.close(fCdf);

return
