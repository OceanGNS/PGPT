% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from EGO NetCDF file.
%
% SYNTAX :
%  gl_generate_prof_from_ego_file(varargin)
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
% gl_generate_prof_from_ego_file('data', 'campe_mooset02_13', 'glidertype', 'slocum')
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2018 - RNU - creation
% ------------------------------------------------------------------------------
function gl_generate_prof_from_ego_file(varargin)

% CONFIGURATION - START %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% tests RNU
% top directory of the deployment directories
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\FORMAT_1.4\';

% directory to store log files
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';

% flag to apply RTQC tests on output EGO file data (and profile files if
% generated)
APPLY_RTQC_TESTS = 1;

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

% exploitation coriolis
% top directory of the deployment directories
% DATA_DIRECTORY = '/home/coriolis_exp/spool/co01/co0121/co012104/co01210402/deployment';

% directory to store log files
% LOG_DIRECTORY = '/home/coriolis_exp/log';

% flag to apply RTQC tests on output EGO file data (and profile files if
% generated)
% APPLY_RTQC_TESTS = 1;

% RTQC test to perform on EGO file data
% TEST002_IMPOSSIBLE_DATE = 1;
% TEST003_IMPOSSIBLE_LOCATION = 1;
% TEST004_POSITION_ON_LAND = 1;
% TEST006_GLOBAL_RANGE = 1;
% TEST007_REGIONAL_RANGE = 1;
% TEST009_SPIKE = 1;
% TEST011_GRADIENT = 1;
% TEST015_GREY_LIST = 1;
% TEST019_DEEPEST_PRESSURE = 1;
% TEST020_QUESTIONABLE_ARGOS_POSITION = 1;
% TEST025_MEDD = 1;
% TEST057_DOXY = 1;

% additional information needed for some RTQC test
% TEST004_GEBCO_FILE = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2020\GEBCO_2020.nc';
% TEST015_GREY_LIST_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\ar_greylist.txt';

% RTQC test to perform on profile file data
% TEST008_PRESSURE_INCREASING = 1;
% TEST012_DIGIT_ROLLOVER = 1;
% TEST013_STUCK_VALUE = 1;
% TEST014_DENSITY_INVERSION = 1;

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

% default values initialization
gl_init_default_values;


% create log file
tic;
logFile = [LOG_DIRECTORY '/' 'gl_generate_prof_from_ego_file_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
deploymentDir = '';
deploymentName = '';
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
               deploymentDir = [DATA_DIRECTORY '/' varargin{id+1}];
               deploymentName = varargin{id+1};
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

if (isempty(deploymentName))
   fprintf('ERROR: ''data'' input parameter is mandatory => exit\n');
   diary off;
   return
end

if (isempty(gliderType))
   fprintf('ERROR: ''glidertype'' input parameter is mandatory => exit\n');
   diary off;
   return
end

% look for input EGO file
ncFiles = dir([deploymentDir '/' deploymentName '*.nc']);
if (length(ncFiles) == 1)
   
   egoFileName = ncFiles(1).name;
   egoFileFilePathName = [deploymentDir '/' egoFileName];
   
   fprintf('INFO: processing EGO file ''%s'':\n', egoFileName);
   
   % apply RTQC tests on output EGO file data
   testDoneList = [];
   testFailedList = [];
   if (APPLY_RTQC_TESTS == 1)
      
      fprintf('- Applying RTQC tests to EGO file ''%s''\n', egoFileName);
      
      [testDoneList, testFailedList] = gl_add_rtqc_to_ego_file(egoFileFilePathName);
   end
   
   % interpolate measurement locations of the final EGO file
   gl_update_meas_loc(egoFileFilePathName, APPLY_RTQC_TESTS);
   
   % generate the Argo profiles from EGO NetCDF file contents according to
   % PHASE and PHASE_NUMBER parameters
      
   fprintf('- Generating NetCDF Argo profile files from NetCDF EGO file ''%s''\n', egoFileName);
   
   % create the 'profile' directory
   profDirPathName = [deploymentDir '/profiles/'];
   if (exist(profDirPathName, 'dir'))
      fprintf('INFO: removing directory %s\n', profDirPathName);
      rmdir(profDirPathName, 's')
   end
   mkdir(profDirPathName);

   % generate the profiles
   [generatedFileList] = gl_generate_prof(egoFileFilePathName, profDirPathName, ...
      APPLY_RTQC_TESTS, testDoneList, testFailedList);
   
   % apply RTQC tests on output profile files data
   if (APPLY_RTQC_TESTS == 1)
      
      fprintf('- Applying RTQC tests to generated profiles data\n');
      
      for idF = 1:length(generatedFileList)
         gl_add_rtqc_to_profile_file(generatedFileList{idF});
      end
   end
   
else
   if (isempty(ncFiles))
      fprintf('ERROR: cannot find EGO file in ''%s'' directory => exit\n', deploymentDir);
      diary off;
      return
   else
      fprintf('ERROR: more than one EGO file in ''%s'' directory => exit\n', deploymentDir);
      diary off;
      return
   end
end

ellapsedTime = toc;
fprintf('Done (%.1f min)\n', ellapsedTime/60);

diary off;

return
