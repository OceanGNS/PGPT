% ------------------------------------------------------------------------------
% Process glider raw data to generate an EGO NetCDF file.
%
% SYNTAX :
%  gl_process_glider_rt(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               g_decGl_inputDataTopDir directory) to process
%      'glidertype' : specify the type of the glider to process (should be
%      one of the following types: 'seaglider', 'slocum', 'seaexplorer')
%      'xmlreport' : give the name of the XML report (should begin with
%                    'co0417_')
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
% gl_process_glider_rt('glidertype', 'seaglider', 'data',
% 'GL_20130624_SG558_fram_jun2013', 'xmlreport', 'co0417_user_choice.xml')
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function gl_process_glider_rt(varargin)

% configuration values initialization
if (gl_init_config_values == 1)
   return
end

% default values initialization
gl_init_default_values;

% global configuration values
global g_decGl_inputDataTopDir;
global g_decGl_outputLogDir;
global g_decGl_outputXmlDir;
global g_decGl_computeSlocumCurrentFlag;
global g_decGl_generateProfileFlag;
global g_decGl_applyRtqcFlag;

% process the data of a given deployment
global g_decGl_dataToProcessDir;
g_decGl_dataToProcessDir = [];

% type of the glider to process
global g_decGl_gliderType;
g_decGl_gliderType = [];

% name of the XML report
global g_decGl_xmlReportFileName;
g_decGl_xmlReportFileName = [];

% real time processing
global g_decGl_realtimeFlag;
g_decGl_realtimeFlag = 1;

% DOM node of XML report
global g_decGl_xmlReportDOMNode;

% report information structure
global g_decGl_reportData;
g_decGl_reportData = [];


logFileName = [];

try
   
   % startTime
   ticStartTime = tic;
   
   % store the start time of the run
   currentTime = datestr(now, 'yyyymmddTHHMMSS.FFF');
   
   % init the XML report
   gl_init_xml_report(currentTime);
      
   % check input arguments
   if (nargin > 0)
      if (rem(nargin, 2) ~= 0)
         fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
         diary off;
         return
      else
         for id = 1:2:nargin
            if (strcmpi(varargin{id}, 'data'))
               if (exist([g_decGl_inputDataTopDir '/' varargin{id+1}], 'dir'))
                  g_decGl_dataToProcessDir = [g_decGl_inputDataTopDir '/' varargin{id+1}];
               else
                  fprintf('WARNING: %s is not an existing directory => exit\n', varargin{id+1});
                  return
               end
            elseif (strcmpi(varargin{id}, 'glidertype'))
               if (strcmpi(varargin{id+1}, 'seaglider') || ...
                     strcmpi(varargin{id+1}, 'slocum') || ...
                     strcmpi(varargin{id+1}, 'seaexplorer'))
                  g_decGl_gliderType = lower(varargin{id+1});
               else
                  fprintf('WARNING: %s is not an expected glider type (expecting ''seaglider'' or ''slocum'' or ''seaexplorer'') => exit\n', varargin{id+1});
                  return
               end
            elseif (strcmpi(varargin{id}, 'xmlreport'))
               g_decGl_xmlReportFileName = varargin{id+1};
            else
               fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
            end
         end
      end
   end
   
   % check mandatory parameters
   if (isempty(g_decGl_dataToProcessDir))
      fprintf('ERROR: ''data'' parameter is mandatory => exit\n');
      return
   end
   if (isempty(g_decGl_gliderType))
      fprintf('ERROR: ''glidertype'' parameter is mandatory => exit\n');
      return
   end
   
   % create log file
   if (~isempty(g_decGl_xmlReportFileName))
      logFileName = [g_decGl_outputLogDir '/gl_process_glider_rt_' g_decGl_xmlReportFileName(8:end-4) '.log'];
   else
      logFileName = [g_decGl_outputLogDir '/gl_process_glider_rt_' currentTime '.log'];
   end
   diary(logFileName);
   
   % create the XML report path file name
   if (~isempty(g_decGl_xmlReportFileName))
      xmlFileName = [g_decGl_outputXmlDir '/' g_decGl_xmlReportFileName];
   else
      xmlFileName = [g_decGl_outputXmlDir '/co0417_' currentTime '.xml'];
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
   
   % finalize XML report
   [status] = gl_finalize_xml_report(ticStartTime, logFileName, []);
   
catch
      
   % finalize XML report
   [status] = gl_finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% save the XML report
xmlwrite(xmlFileName, g_decGl_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return
