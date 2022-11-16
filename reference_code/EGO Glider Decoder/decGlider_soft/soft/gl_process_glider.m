% ------------------------------------------------------------------------------
% Process glider raw data to generate an EGO NetCDF file.
%
% SYNTAX :
%  gl_process_glider(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments 
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DATA_DIRECTORY directory) to process
%      'glidertype' : specify the type of the glider to process (should be
%      one of the following types: 'seaglider', 'slocum', 'seaexplorer')
%
% OUTPUT PARAMETERS :
%
% EXAMPLES : 
% gl_process_glider('glidertype', 'seaglider', 'data', 'GL_20130624_SG558_fram_jun2013')
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function gl_process_glider(varargin)

% configuration values initialization
if (gl_init_config_values == 1)
   return
end

% default values initialization
gl_init_default_values;

% global configuration values
global g_decGl_inputDataTopDir;
global g_decGl_outputLogDir;
global g_decGl_computeSlocumCurrentFlag;
global g_decGl_generateProfileFlag;
global g_decGl_applyRtqcFlag;

% process the data of a given deployment
global g_decGl_dataToProcessDir;
g_decGl_dataToProcessDir = [];

% type of the glider to process
global g_decGl_gliderType;
g_decGl_gliderType = [];

% real time processing
global g_decGl_realtimeFlag;
g_decGl_realtimeFlag = 0;


% create log file
logFile = [g_decGl_outputLogDir '/' 'gl_process_glider_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
stop = 0;
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            g_decGl_dataToProcessDir = [g_decGl_inputDataTopDir '/' varargin{id+1}];
            if (~exist(g_decGl_dataToProcessDir, 'dir'))
               fprintf('ERROR: %s is not an existing directory => exit\n', varargin{id+1});
               stop = 1;
            end
         elseif (strcmpi(varargin{id}, 'glidertype'))
            if (strcmpi(varargin{id+1}, 'seaglider') || ...
                  strcmpi(varargin{id+1}, 'slocum') || ...
                  strcmpi(varargin{id+1}, 'seaexplorer'))
               g_decGl_gliderType = lower(varargin{id+1});
            else
               fprintf('ERROR: %s is not an expected glider type (expecting ''seaglider'' or ''slocum'' or ''seaexplorer'') => exit\n', varargin{id+1});
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

% check mandatory parameters
stop = 0;
if (isempty(g_decGl_dataToProcessDir))
   fprintf('ERROR: ''data'' parameter is mandatory => exit\n');
   stop = 1;
end
if (isempty(g_decGl_gliderType))
   fprintf('ERROR: ''glidertype'' parameter is mandatory => exit\n');
   stop = 1;
end
if (stop)
   return
end

% print the arguments understanding
fprintf('INFO: process the deployment stored in the %s directory\n', g_decGl_dataToProcessDir);
fprintf('INFO: the glider to process is a %s\n', g_decGl_gliderType);

% process glider data
gl_process_glider_deployment( ...
   g_decGl_dataToProcessDir, ...
   g_decGl_computeSlocumCurrentFlag, ...
   g_decGl_generateProfileFlag, ...
   g_decGl_applyRtqcFlag);

diary off;

return
