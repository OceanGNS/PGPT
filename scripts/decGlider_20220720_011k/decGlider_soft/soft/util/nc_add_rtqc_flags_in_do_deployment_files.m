% ------------------------------------------------------------------------------
% If DOXY (or DOXY2) parameter is present in EGO file of a given deployment:
%   1- apply RTQC tests to EGO file data
%   2- generate profile files from EGO file data
%   3- apply RTQC tests to generated profile files data
%
% SYNTAX :
%  nc_add_rtqc_flags_in_do_deployment_files(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments (all mandatory)
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DATA_DIRECTORY directory) to process
%      'glidertype' : specify the type of the glider to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
% nc_add_rtqc_flags_in_do_deployment_files('data', 'crate_mooset00_38', 'glidertype', 'slocum')
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function nc_add_rtqc_flags_in_do_deployment_files(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% only to check or to do the job
DO_IT = 1;

% top directory of the deployment directories
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY\FORMAT_1.4\';

% directory to store the log file
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\';

% list of RTQC tests to perform

% RTQC test to perform on EGO file data
TEST002_IMPOSSIBLE_DATE = 1;
TEST003_IMPOSSIBLE_LOCATION = 1;
TEST004_POSITION_ON_LAND = 1;
TEST006_GLOBAL_RANGE = 1;
TEST007_REGIONAL_RANGE = 1;
TEST009_SPIKE = 1;
TEST011_GRADIENT = 1;
TEST015_GREY_LIST = 1;
TEST019_DEEPEST_PRESSURE = 1;
TEST020_QUESTIONABLE_ARGOS_POSITION = 1;
TEST025_MEDD = 0;
TEST057_DOXY = 1;

% additional information needed for some RTQC test
TEST004_GEBCO_FILE = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2020\GEBCO_2020.nc';
TEST015_GREY_LIST_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\ar_greylist.txt';

% RTQC test to perform on profile file data
TEST008_PRESSURE_INCREASING = 1;
TEST012_DIGIT_ROLLOVER = 1;
TEST013_STUCK_VALUE = 1;
TEST014_DENSITY_INVERSION = 1;

% CONFIGURATION - END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% type of the glider to process
global g_decGl_gliderType;
g_decGl_gliderType = [];

% real time processing
global g_decGl_realtimeFlag;
g_decGl_realtimeFlag = 0;

% RTQC configuration values
global g_decGl_rtqcTest2;
g_decGl_rtqcTest2 = TEST002_IMPOSSIBLE_DATE;
global g_decGl_rtqcTest3;
g_decGl_rtqcTest3 = TEST003_IMPOSSIBLE_LOCATION;
global g_decGl_rtqcTest4;
g_decGl_rtqcTest4 = TEST004_POSITION_ON_LAND;
global g_decGl_rtqcTest6;
g_decGl_rtqcTest6 = TEST006_GLOBAL_RANGE;
global g_decGl_rtqcTest7;
g_decGl_rtqcTest7 = TEST007_REGIONAL_RANGE;
global g_decGl_rtqcTest9;
g_decGl_rtqcTest9 = TEST009_SPIKE;
global g_decGl_rtqcTest11;
g_decGl_rtqcTest11 = TEST011_GRADIENT;
global g_decGl_rtqcTest15;
g_decGl_rtqcTest15 = TEST015_GREY_LIST;
global g_decGl_rtqcTest19;
g_decGl_rtqcTest19 = TEST019_DEEPEST_PRESSURE;
global g_decGl_rtqcTest20;
g_decGl_rtqcTest20 = TEST020_QUESTIONABLE_ARGOS_POSITION;
global g_decGl_rtqcTest25;
g_decGl_rtqcTest25 = TEST025_MEDD;
global g_decGl_rtqcTest57;
g_decGl_rtqcTest57 = TEST057_DOXY;

global g_decGl_rtqcGebcoFile;
g_decGl_rtqcGebcoFile = TEST004_GEBCO_FILE;
global g_decGl_rtqcGreyList;
g_decGl_rtqcGreyList = TEST015_GREY_LIST_FILE;

global g_decGl_rtqcTest8;
g_decGl_rtqcTest8 = TEST008_PRESSURE_INCREASING;
global g_decGl_rtqcTest12;
g_decGl_rtqcTest12 = TEST012_DIGIT_ROLLOVER;
global g_decGl_rtqcTest13;
g_decGl_rtqcTest13 = TEST013_STUCK_VALUE;
global g_decGl_rtqcTest14;
g_decGl_rtqcTest14 = TEST014_DENSITY_INVERSION;

% list of updated files
global g_copq_updatedFileList;
g_copq_updatedFileList = [];

% update or not the files
global g_copq_doItFlag;
g_copq_doItFlag = DO_IT;

% default values initialization
gl_init_default_values;


% create and start log file recording
logFile = [LOG_DIRECTORY '/' 'nc_add_rtqc_flags_in_do_deployment_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check input arguments
dataToProcessDir = [];
deploymentToProcess = [];
gliderType = '';
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            if (exist([DATA_DIRECTORY '/' varargin{id+1}], 'dir'))
               dataToProcessDir = [DATA_DIRECTORY '/' varargin{id+1}];
               deploymentToProcess = varargin{id+1};
            else
               fprintf('ERROR: %s is not an existing directory => exit\n', varargin{id+1});
               diary off;
               return
            end
         elseif (strcmpi(varargin{id}, 'glidertype'))
            if (strcmpi(varargin{id+1}, 'seaglider') || ...
                  strcmpi(varargin{id+1}, 'slocum') || ...
                  strcmpi(varargin{id+1}, 'seaexplorer'))
               gliderType = lower(varargin{id+1});
            else
               fprintf('WARNING: %s is not an expected glider type (expecting ''seaglider'' or ''slocum'' or ''seaexplorer'') => exit\n', varargin{id+1});
               diary off;
               return
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
else
   fprintf('ERROR: ''data'' and ''glidertype'' input parameters are mandatory => exit\n');
   diary off;
   return
end
g_decGl_gliderType = gliderType;

if (isempty(deploymentToProcess))
   fprintf('ERROR: ''data'' input parameter is mandatory => exit\n');
   diary off;
   return
end

if (isempty(gliderType))
   fprintf('ERROR: ''glidertype'' input parameter is mandatory => exit\n');
   diary off;
   return
end

% process deployment data
process_deployment(dataToProcessDir, deploymentToProcess);

if (g_copq_doItFlag == 1)
   fprintf('\nLIST OF UPDATED FILES:\n');
else
   fprintf('\nLIST OF FILES THAT SHOULD BE UPDATED:\n');
end
if (~isempty(g_copq_updatedFileList))
   for idFile = 1:length(g_copq_updatedFileList)
      fprintf('%s\n', g_copq_updatedFileList{idFile});
   end
else
   fprintf('NONE\n');
end
fprintf('\n');

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one deployment.
%
% SYNTAX :
%  process_deployment(a_dirName, a_deploymentToProcess)
%
% INPUT PARAMETERS :
%   a_dirName             : directory of the deployment
%   a_deploymentToProcess : name of the deployment
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function process_deployment(a_dirName, a_deploymentToProcess)

% list of updated files
global g_copq_updatedFileList;

% update or not the files
global g_copq_doItFlag;


% process EGO file
ncFiles = dir([a_dirName '/' a_deploymentToProcess '_R.nc']);
for idF = 1:length(ncFiles)
   ncFileName = ncFiles(idF).name;
   [~, name, ext] = fileparts(ncFileName);
   inputFilePathName = [a_dirName '/' name ext];
   
   % check if the file need to be updated
   updateNeeded = 0;
   
   % open NetCDF file
   fCdf = netcdf.open(inputFilePathName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', inputFilePathName);
      return
   end
   
   [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
   
   for idVar = 0:nbVars-1
      [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
      if (strcmp(varName, 'DOXY') || strcmp(varName, 'DOXY2'))
         updateNeeded = 1;
         break
      end
   end
   
   netcdf.close(fCdf);
   
   % update the file
   if (updateNeeded == 1)
      
      fprintf('File %s:\n', inputFilePathName)
      
      % process EGO file
      if (g_copq_doItFlag == 1)
         
         fprintf('\nApplying RTQC tests to EGO file data\n');
         
         [testDoneList, testFailedList] = gl_add_rtqc_to_ego_file(inputFilePathName);
      end
      
      g_copq_updatedFileList{end+1} = inputFilePathName;
      
      if (g_copq_doItFlag == 1)
         
         fprintf('\nGenerating NetCDF Argo profile files from EGO final NetCDF file\n');
         
         profDirPathName = [a_dirName '/profiles/'];
         if (exist(profDirPathName, 'dir'))
            fprintf('INFO: removing directory %s\n', profDirPathName);
            rmdir(profDirPathName, 's')
         end
         mkdir(profDirPathName);

         [generatedFileList] = gl_generate_prof(inputFilePathName, profDirPathName, ...
            1, testDoneList, testFailedList);
         
         % apply RTQC tests on output profile files data
         
         fprintf('\nApplying RTQC tests to profile files data\n');
         
         for idFile = 1:length(generatedFileList)
            gl_add_rtqc_to_profile_file(generatedFileList{idFile});
            
            g_copq_updatedFileList{end+1} = generatedFileList{idFile};
         end
      end
   end
end

return
