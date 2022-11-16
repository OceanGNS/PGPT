% ------------------------------------------------------------------------------
% Retrieve, from NetCDF EGO files and associated profiles, the list of failed
% RTQC tests.
% The default behaviour is :
%    - to process all the deployments (the directories) stored in the
%      DIR_INPUT_NC_FILES directory
% this behaviour can be modified by input arguments.
%
% SYNTAX :
%   nc_ego_get_rtqc_failed_tests(varargin)
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
%   09/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_get_rtqc_failed_tests(varargin)

% top directory of the deployment directories
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY\FORMAT_1.4\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\Glider\work\csv\';

% default values initialization
gl_init_default_values;

% report information structure
global g_negrft_reportData;
g_negrft_reportData.fileType = [];
g_negrft_reportData.fileName = [];
g_negrft_reportData.profParam = [];
g_negrft_reportData.rtqcTestDate = [];
g_negrft_reportData.qcTestFailed = [];


% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/' 'nc_ego_get_rtqc_failed_tests_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
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

% process glider data
if (isempty(dataToProcessDir))
   % process all the deployments of the DIR_INPUT_NC_FILES directory
   dirInfo = dir(DIR_INPUT_NC_FILES);
   for dirNum = 1:length(dirInfo)
      if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
         dirName = dirInfo(dirNum).name;
         nc_ego_get_rtqc_failed_tests_file([DIR_INPUT_NC_FILES '/' dirName]);
      end
   end
else
   % convert the data of this deployment
   nc_ego_get_rtqc_failed_tests_file(dataToProcessDir);
end

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_ego_get_rtqc_failed_tests_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'FILE_TYPE;FILE_NAME;PARAM_LIST;HISTORY_DATE';
testList = [2:4 6:9 11:15 19 20 25 57];
testListStr = sprintf('Test#%d;', testList);
fprintf(fidOut, '%s;%s\n', header, testListStr(1:end-1));

for idL = 1:length(g_negrft_reportData.fileType)
   
   [~, fileName, fileExt] = fileparts(g_negrft_reportData.fileName{idL});
   paramList = g_negrft_reportData.profParam{idL};
   paramList = sprintf('%s/', paramList{:});
   testFailedFlag = get_qctest_flag(g_negrft_reportData.qcTestFailed{idL});
   testFailedFlag(setdiff(1:63, testList)) = [];
   testFailedFlag = sprintf('%c;', testFailedFlag);
   
   fprintf(fidOut, '%s;%s;%s;%s;%s\n', ...
      g_negrft_reportData.fileType{idL}, ...
      g_negrft_reportData.fileName{idL}, ...
      paramList(1:end-1), ...
      g_negrft_reportData.rtqcTestDate{idL}, ...
      testFailedFlag(1:end-1));
end
fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve, from NetCDF EGO files and associated profiles of a given deployment,
% the list of failed RTQC tests.
%
% SYNTAX :
%  nc_ego_get_rtqc_failed_tests_file(a_dirName)
%
% INPUT PARAMETERS :
%   a_dirName : directory of the deployment
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_get_rtqc_failed_tests_file(a_dirName)

% process EGO file
ncFiles = dir([a_dirName '/*.nc']);
for idF = 1:length(ncFiles)
   ncFileName = ncFiles(idF).name;
   [~, name, ext] = fileparts(ncFileName);
   inputFilePathName = [a_dirName '/' name ext];
   
   fprintf('Processing: %s\n', a_dirName);
   fprintf('   - EGO file: %s\n', [name ext]);
   process_ego_nc_file(inputFilePathName, [name ext]);
end

% process associated NetCDF profile files
if (exist([a_dirName '/profiles/'], 'dir'))
      
   ncFiles = dir([a_dirName '/profiles/*.nc']);
   for idF = 1:length(ncFiles)
      ncFileName = ncFiles(idF).name;
      [~, name, ext] = fileparts(ncFileName);
      inputFilePathName = [a_dirName '/profiles/' name ext];
      
      fprintf('   - Profile file: %s\n', [name ext]);
      process_profile_nc_file(inputFilePathName, [name ext]);
   end
end

return

% ------------------------------------------------------------------------------
% Process one EGO NetCDF file.
%
% SYNTAX :
%  process_ego_nc_file(a_ncPathFileName, a_ncFileName)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : pathname of the EGO file to process
%   a_ncFileName     : name of the EGO file to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function process_ego_nc_file(a_ncPathFileName, a_ncFileName)

% report information structure
global g_negrft_reportData;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % get information from the file
   wantedInputVars = [ ...
      {'PARAMETER'} ...
      {'HISTORY_INSTITUTION'} ...
      {'HISTORY_STEP'} ...
      {'HISTORY_SOFTWARE'} ...
      {'HISTORY_DATE'} ...
      {'HISTORY_PARAMETER'} ...
      {'HISTORY_ACTION'} ...
      {'HISTORY_QCTEST'} ...
      ];
   [inputData] = gl_get_data_from_nc_file(a_ncPathFileName, wantedInputVars);
   if (~isempty(inputData))
      
      idVal = find(strcmp('PARAMETER', inputData(1:2:end)) == 1, 1);
      parameter = inputData{2*idVal};
      [~, inputNParam] = size(parameter);
      idVal = find(strcmp('HISTORY_INSTITUTION', inputData(1:2:end)) == 1, 1);
      historyInstitution = inputData{2*idVal};
      [~, inputNHistory] = size(historyInstitution);
      idVal = find(strcmp('HISTORY_STEP', inputData(1:2:end)) == 1, 1);
      historyStep = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_SOFTWARE', inputData(1:2:end)) == 1, 1);
      historySoftware = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_DATE', inputData(1:2:end)) == 1, 1);
      historyDate = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_ACTION', inputData(1:2:end)) == 1, 1);
      historyAction = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_QCTEST', inputData(1:2:end)) == 1, 1);
      historyQcTest = inputData{2*idVal};
      
      profHistoDate = [];
      profHistoQcTest = [];
      for idHisto = 1:inputNHistory
         histoAct = deblank(historyAction(:, idHisto)');
         histoQctest = deblank(historyQcTest(:, idHisto)');
         if (strcmp(histoAct, 'QCF$') && ~strcmp(unique(histoQctest), '0'))
            histoInst = deblank(historyInstitution(:, idHisto)');
            histoStep = deblank(historyStep(:, idHisto)');
            histoSoft = deblank(historySoftware(:, idHisto)');
            histoDate = historyDate(:, idHisto)';
            histoQctest = historyQcTest(:, idHisto)';
            
            if (strcmp(histoInst, 'IF') && strcmp(histoStep, 'ARGQ') && strcmp(histoSoft, 'COQC'))
               profHistoDate = [profHistoDate; histoDate];
               profHistoQcTest = [profHistoQcTest; histoQctest];
            end
         end
      end
      if (~isempty(profHistoDate))
         if (size(profHistoDate, 1) > 1)
            [~, idMax] = max(datenum(profHistoDate, 'yyyymmddHHMMSS'));
            profHistoDate = profHistoDate(idMax, :);
            profHistoQcTest = profHistoQcTest(idMax, :);
         end
         
         paramList = [];
         for idParam = 1:inputNParam
            paramName = deblank(parameter(:, idParam)');
            if (~isempty(paramName))
               paramList{end+1} = paramName;
            end
         end
         
         g_negrft_reportData.fileType = [g_negrft_reportData.fileType {'EGO file'}];
         g_negrft_reportData.fileName = [g_negrft_reportData.fileName {a_ncFileName}];
         g_negrft_reportData.profParam = [g_negrft_reportData.profParam {paramList}];
         g_negrft_reportData.rtqcTestDate = [g_negrft_reportData.rtqcTestDate {deblank(profHistoDate)}];
         g_negrft_reportData.qcTestFailed = [g_negrft_reportData.qcTestFailed {deblank(profHistoQcTest)}];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Process one profile NetCDF file.
%
% SYNTAX :
%  process_profile_nc_file(a_ncPathFileName, a_ncFileName)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : pathname of the profile file to process
%   a_ncFileName     : name of the profile file to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function process_profile_nc_file(a_ncPathFileName, a_ncFileName)

% report information structure
global g_negrft_reportData;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % get information from the file
   wantedInputVars = [ ...
      {'STATION_PARAMETERS'} ...
      {'HISTORY_INSTITUTION'} ...
      {'HISTORY_STEP'} ...
      {'HISTORY_SOFTWARE'} ...
      {'HISTORY_DATE'} ...
      {'HISTORY_PARAMETER'} ...
      {'HISTORY_ACTION'} ...
      {'HISTORY_QCTEST'} ...
      ];
   [inputData] = gl_get_data_from_nc_file(a_ncPathFileName, wantedInputVars);
   if (~isempty(inputData))
      
      idVal = find(strcmp('STATION_PARAMETERS', inputData(1:2:end)) == 1, 1);
      stationParameters = inputData{2*idVal};
      [~, inputNParam, ~] = size(stationParameters);
      idVal = find(strcmp('HISTORY_INSTITUTION', inputData(1:2:end)) == 1, 1);
      historyInstitution = inputData{2*idVal};
      [~, inputNProf, inputNHistory] = size(historyInstitution);
      idVal = find(strcmp('HISTORY_STEP', inputData(1:2:end)) == 1, 1);
      historyStep = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_SOFTWARE', inputData(1:2:end)) == 1, 1);
      historySoftware = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_DATE', inputData(1:2:end)) == 1, 1);
      historyDate = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_ACTION', inputData(1:2:end)) == 1, 1);
      historyAction = inputData{2*idVal};
      idVal = find(strcmp('HISTORY_QCTEST', inputData(1:2:end)) == 1, 1);
      historyQcTest = inputData{2*idVal};
      
      for idProf = 1:inputNProf
         profHistoDate = [];
         profHistoQcTest = [];
         for idHisto = 1:inputNHistory
            histoAct = deblank(historyAction(:, idProf, idHisto)');
            histoQctest = deblank(historyQcTest(:, idProf, idHisto)');
            if (strcmp(histoAct, 'QCF$') && ~strcmp(unique(histoQctest), '0'))
               histoInst = deblank(historyInstitution(:, idProf, idHisto)');
               histoStep = deblank(historyStep(:, idProf, idHisto)');
               histoSoft = deblank(historySoftware(:, idProf, idHisto)');
               histoDate = historyDate(:, idProf, idHisto)';
               histoQctest = historyQcTest(:, idProf, idHisto)';
               
               if (strcmp(histoInst, 'IF') && strcmp(histoStep, 'ARGQ') && strcmp(histoSoft, 'COQC'))
                  profHistoDate = [profHistoDate; histoDate];
                  profHistoQcTest = [profHistoQcTest; histoQctest];
               end
            end
         end
         if (~isempty(profHistoDate))
            if (size(profHistoDate, 1) > 1)
               [~, idMax] = max(datenum(profHistoDate, 'yyyymmddHHMMSS'));
               profHistoDate = profHistoDate(idMax, :);
               profHistoQcTest = profHistoQcTest(idMax, :);
            end
            
            paramList = [];
            for idParam = 1:inputNParam
               paramName = deblank(stationParameters(:, idParam, idProf)');
               if (~isempty(paramName))
                  paramList{end+1} = paramName;
               end
            end
            
            g_negrft_reportData.fileType = [g_negrft_reportData.fileType {'PROF file'}];
            g_negrft_reportData.fileName = [g_negrft_reportData.fileName {a_ncFileName}];
            g_negrft_reportData.profParam = [g_negrft_reportData.profParam {paramList}];
            g_negrft_reportData.rtqcTestDate = [g_negrft_reportData.rtqcTestDate {deblank(profHistoDate)}];
            g_negrft_reportData.qcTestFailed = [g_negrft_reportData.qcTestFailed {deblank(profHistoQcTest)}];
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Decode RTQC results HEX code to get individual test results.
%
% SYNTAX :
%  [o_qcTestFlag] = get_qctest_flag(a_qcTestHex)
%
% INPUT PARAMETERS :
%   a_qcTestHex : HEX code
%
% OUTPUT PARAMETERS :
%   o_qcTestFlag : list of individual test results
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/04/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_qcTestFlag] = get_qctest_flag(a_qcTestHex)

% output parameters initialization
o_qcTestFlag = '';


for id = 1:length(a_qcTestHex)
   o_qcTestFlag = [o_qcTestFlag dec2bin(hex2dec(a_qcTestHex(id)), 4)];
end

o_qcTestFlag = fliplr(o_qcTestFlag);
o_qcTestFlag(1) = [];

return
