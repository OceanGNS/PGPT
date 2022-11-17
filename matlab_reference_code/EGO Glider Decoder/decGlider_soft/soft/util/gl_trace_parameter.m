% ------------------------------------------------------------------------------
% Plot glider measurements.
%
% SYNTAX :
%   gl_trace_parameter
%
% INPUT PARAMETERS :
%   varargin :
%      optional : top directory of Glider deployments
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function gl_trace_parameter(varargin)

% parameters to plot
PARAM_NAMES = {'PRES';'TEMP'};
% PARAM_NAMES = {'PRES';'PSAL'};
% PARAM_NAMES = {'PSAL';'PSAL3'};
% PARAM_NAMES = {'PRES';'DOXY'};
% PARAM_NAMES = {'DOXY';'DOXY2'};

% default top directory of Glider deployments
GLIDER_DATA_TOP_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\FORMAT_1.4\';

% directory used to save .pdf files
DIR_SAVE_FIG = 'C:\Users\jprannou\_RNU\Glider\work\fig\';

% minimum time duration of the plot (in days)
NB_DAYS_IN_SET = 0.5;


global g_GTP_FIG_HANDLE;
global g_GTP_GLIDER_DATA_DIR_LIST;
global g_GTP_CURRENT_GLIDER_ID;
global g_GTP_CURRENT_GLIDER_DIR;
global g_GTP_PARAM_NAME_1;
global g_GTP_PARAM_NAME_2;
global g_GTP_NB_DAYS_IN_SET;
global g_GTP_NB_SET_IN_SEQUENCE;
global g_GTP_NB_SET_IN_SEQUENCE_DEFAULT;
global g_GTP_NB_SET_IN_SEQUENCE_CHANGED;
global g_GTP_SEQUENCE_NUMBER;
global g_GTP_DIR_SAVE_FIG;
global g_GTP_RELOAD_DATA;
global g_GTP_PLOT_ALL;
global g_GTP_PLOT_GOOD_QC_ONLY;
global g_GTP_PRINT_FIGURE;
global g_GTP_ZOOM_COUNT;

% check inputs
if (isempty(PARAM_NAMES))
   fprintf('ERROR: No parameter names set\n')
   return
elseif (length(PARAM_NAMES) > 2)
   fprintf('WARNING: Only 2 first parameter names are considered\n')
end

% set inputs
g_GTP_NB_DAYS_IN_SET = NB_DAYS_IN_SET;
g_GTP_DIR_SAVE_FIG = DIR_SAVE_FIG;
g_GTP_PARAM_NAME_1 = '';
g_GTP_PARAM_NAME_2 = '';
for idP = 1:min(length(PARAM_NAMES), 2)
   if (idP == 1)
      g_GTP_PARAM_NAME_1 = PARAM_NAMES{idP};
   else
      g_GTP_PARAM_NAME_2 = PARAM_NAMES{idP};
   end
end

% list of drifters to plot
if (nargin == 0)
   % use default glider deployment directory
   gliderTopDirName = GLIDER_DATA_TOP_DIRECTORY;
else
   % use glider deployment directory provided as input parameter
   gliderTopDirName = char(varargin);
end

if (~exist(gliderTopDirName, 'dir'))
   fprintf('Directory not found: %s => stop!\n', gliderTopDirName);
   return
end

fprintf('Glider data top directory: %s\n', gliderTopDirName);

% default values initialization
gl_init_default_values;

% create the list of glider deployment directories
g_GTP_GLIDER_DATA_DIR_LIST = [];
dirInfo = dir(gliderTopDirName);
for dirNum = 1:length(dirInfo)
   if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
      dirName = dirInfo(dirNum).name;
      dirPathName = [gliderTopDirName '/' dirName '/'];
      if (exist(dirPathName, 'dir'))
         g_GTP_GLIDER_DATA_DIR_LIST{end + 1} = dirPathName;
      end
   end
end

% close previous figures
close(findobj('Name', 'Glider parameter'));
warning off;

% create the figure with associated callback
screenSize = get(0, 'ScreenSize');
g_GTP_FIG_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Glider parameter', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90]);

% assign a callback to manage zoom actions
zoomMode = zoom(g_GTP_FIG_HANDLE);
set(zoomMode, 'ActionPostCallback', @after_zoom);

% assign a callback to manage data cursor label
dataCursor = datacursormode(g_GTP_FIG_HANDLE);
set(dataCursor, 'UpdateFcn', @update_cursor_label);

% display help in command window
display_help;

% select first drifter of the list
g_GTP_CURRENT_GLIDER_ID = 0;
g_GTP_CURRENT_GLIDER_DIR = g_GTP_GLIDER_DATA_DIR_LIST{g_GTP_CURRENT_GLIDER_ID+1};

% set initial number of sets in a sequence
g_GTP_NB_SET_IN_SEQUENCE_DEFAULT = 5;
g_GTP_NB_SET_IN_SEQUENCE = g_GTP_NB_SET_IN_SEQUENCE_DEFAULT;

% plot first sequence of data
g_GTP_SEQUENCE_NUMBER = 0;

% plot all times
g_GTP_PLOT_ALL = 1;

% plot all data qualities
g_GTP_PLOT_GOOD_QC_ONLY = 0;

% drifter data should be loaded
g_GTP_RELOAD_DATA = 1;

% don't print figure
g_GTP_PRINT_FIGURE = 0;

g_GTP_ZOOM_COUNT = 0;
g_GTP_NB_SET_IN_SEQUENCE_CHANGED = 0;

% plot data
plot_glider_param;

% display current configuration
display_current_config;

return

% ------------------------------------------------------------------------------
% Plot one Glider deployment measurements.
%
% SYNTAX :
%   plot_glider_param
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function plot_glider_param

global g_GTP_GLIDER_DATA_DIR_LIST;
global g_GTP_CURRENT_GLIDER_ID;
global g_GTP_CURRENT_GLIDER_DIR;
global g_GTP_CURRENT_GLIDER_FILE;
global g_GTP_CURRENT_GLIDER_NAME;
global g_GTP_PARAM_NAME_1;
global g_GTP_PARAM_NAME_2;
global g_GTP_NB_DAYS_IN_SET;
global g_GTP_NB_SET_IN_SEQUENCE;
global g_GTP_SEQUENCE_NUMBER;
global g_GTP_CURRENT_GLIDER_START_TIME;
global g_GTP_CURRENT_GLIDER_END_TIME;
global g_GTP_CURRENT_GLIDER_DATA_SPAN;
global g_GTP_CURRENT_GLIDER_NB_SEQUENCE;
global g_GTP_NB_SET_IN_SEQUENCE_CHANGED;
global g_GTP_PARAM_1_WORK_DATA;
global g_GTP_PARAM_2_WORK_DATA;
global g_GTP_TIME_WORK_DATA;
global g_GTP_PARAM_1_WORK_DATA_QC;
global g_GTP_PARAM_2_WORK_DATA_QC;
global g_GTP_PARAM_1_WORK_DATA_UNIT;
global g_GTP_PARAM_2_WORK_DATA_UNIT;
global g_GTP_TIME_WORK_DATA_UNIT;
global g_GTP_PLOT_START_TIME;
global g_GTP_PLOT_END_TIME;
global g_GTP_DIR_SAVE_FIG;
global g_GTP_RELOAD_DATA;
global g_GTP_PLOT_ALL;
global g_GTP_PLOT_GOOD_QC_ONLY;
global g_GTP_PRINT_FIGURE;
global g_GTP_PARAM_AXES_1;
global g_GTP_PARAM_AXES_2;
global g_GTP_ZOOM_COUNT;


% load input data
if (g_GTP_RELOAD_DATA)

   % empty global variables used to store input data
   empty_vars;

   % find deployment file
   g_GTP_CURRENT_GLIDER_FILE = [];
   stop = 0;
   while (~stop)
      files = dir([g_GTP_CURRENT_GLIDER_DIR '*.nc']);
      if (~isempty(files))
         g_GTP_CURRENT_GLIDER_FILE = [g_GTP_CURRENT_GLIDER_DIR '/' files(1).name];
         g_GTP_CURRENT_GLIDER_NAME = files(1).name;
         g_GTP_CURRENT_GLIDER_NAME(end-2:end) = [];
         stop = 1;
      else
         fprintf('\nWARNING: No NetCDF file in %s\n', g_GTP_CURRENT_GLIDER_DIR);
         stop = 1;
      end
   end
   if (isempty(g_GTP_CURRENT_GLIDER_FILE))

      % empty global variables used to store input data
      empty_vars;

      % clear figure and set title
      clf;
      label = sprintf('NO DEPLOYMENT FILE IN %s', ...
         g_GTP_CURRENT_GLIDER_DIR);
      title(label, 'FontSize', 14, 'Interpreter', 'none');
      return
   end

   % load deployment data
   gl_get_data_from_nc_for_gl_trace_parameter(g_GTP_CURRENT_GLIDER_FILE);

   g_GTP_CURRENT_GLIDER_START_TIME = g_GTP_TIME_WORK_DATA(1);
   g_GTP_CURRENT_GLIDER_END_TIME = g_GTP_TIME_WORK_DATA(end);
   g_GTP_CURRENT_GLIDER_DATA_SPAN = ceil(g_GTP_CURRENT_GLIDER_END_TIME-g_GTP_CURRENT_GLIDER_START_TIME);
   g_GTP_CURRENT_GLIDER_NB_SEQUENCE = ceil(g_GTP_CURRENT_GLIDER_DATA_SPAN/(g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET));
   g_GTP_RELOAD_DATA = 0;
end

if (g_GTP_PRINT_FIGURE == 1)
   fileName =  ...
      sprintf('gl_race_parameter_%s_%s_%s_%s_%s.pdf', ...
      g_GTP_CURRENT_GLIDER_NAME, ...
      g_GTP_PARAM_NAME_1, ...
      g_GTP_PARAM_NAME_2, ...
      datestr(g_GTP_PLOT_START_TIME, 'yyyymmddTHHMMSS'), ...
      datestr(g_GTP_PLOT_END_TIME, 'yyyymmddTHHMMSS'));
   filePathName = [g_GTP_DIR_SAVE_FIG '/' fileName];
   orient landscape;
   print('-bestfit', '-dpdf', filePathName);
   fprintf('Plot figure in file: %s\n', filePathName);
   g_GTP_PRINT_FIGURE = 0;
   return
end

% select start/end times to plot
if (g_GTP_ZOOM_COUNT == 0)

   if (g_GTP_PLOT_ALL == 1)
      g_GTP_PLOT_START_TIME = g_GTP_CURRENT_GLIDER_START_TIME;
      g_GTP_PLOT_END_TIME = g_GTP_CURRENT_GLIDER_END_TIME;
   elseif (g_GTP_NB_SET_IN_SEQUENCE_CHANGED == 0)
      g_GTP_PLOT_START_TIME = g_GTP_CURRENT_GLIDER_START_TIME + ...
         g_GTP_SEQUENCE_NUMBER*g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET;
      g_GTP_PLOT_END_TIME = g_GTP_CURRENT_GLIDER_START_TIME + ...
         (g_GTP_SEQUENCE_NUMBER+1)*g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET;
   else
      g_GTP_PLOT_END_TIME = g_GTP_PLOT_END_TIME + ...
         g_GTP_NB_SET_IN_SEQUENCE_CHANGED*g_GTP_NB_DAYS_IN_SET;
      g_GTP_NB_SET_IN_SEQUENCE_CHANGED = 0;
   end
end

startIdToPlot = find(g_GTP_TIME_WORK_DATA <= g_GTP_PLOT_START_TIME, 1, 'last');
if (isempty(startIdToPlot))
   startIdToPlot = 1;
end
endIdToPlot = find(g_GTP_TIME_WORK_DATA >= g_GTP_PLOT_END_TIME, 1, 'first');
if (isempty(endIdToPlot))
   endIdToPlot = length(g_GTP_TIME_WORK_DATA);
end

% preparation of data
yParam1Data = [];
xMin = [];
xMax = [];
if (~isempty(g_GTP_PARAM_1_WORK_DATA))
   xParam1Data = g_GTP_TIME_WORK_DATA(startIdToPlot:endIdToPlot);
   yParam1Data = g_GTP_PARAM_1_WORK_DATA(startIdToPlot:endIdToPlot);
   yParam1DataQc = g_GTP_PARAM_1_WORK_DATA_QC(startIdToPlot:endIdToPlot);

   xMin = min(xParam1Data);
   xMax = max(xParam1Data);

   if (g_GTP_PLOT_GOOD_QC_ONLY == 1)
      idToDel = find((yParam1DataQc == 3) | (yParam1DataQc == 4));
      xParam1Data(idToDel) = [];
      yParam1Data(idToDel) = [];
      yParam1DataQc(idToDel) = [];
   end
end
yParam2Data = [];
if (~isempty(g_GTP_PARAM_2_WORK_DATA))
   xParam2Data = g_GTP_TIME_WORK_DATA(startIdToPlot:endIdToPlot);
   yParam2Data = g_GTP_PARAM_2_WORK_DATA(startIdToPlot:endIdToPlot);
   yParam2DataQc = g_GTP_PARAM_2_WORK_DATA_QC(startIdToPlot:endIdToPlot);

   if (~isempty(xMin))
      xMin = min(xMin, min(xParam2Data));
      xMax = max(xMax, max(xParam2Data));
   else
      xMin = min(xParam2Data);
      xMax = max(xParam2Data);
   end

   if (g_GTP_PLOT_GOOD_QC_ONLY == 1)
      idToDel = find((yParam2DataQc == 3) | (yParam2DataQc == 4));
      xParam2Data(idToDel) = [];
      yParam2Data(idToDel) = [];
      yParam2DataQc(idToDel) = [];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot of data

clf;

% color for QC
qc0Color = 'b';
qc1Color = 'g';
qc2Color = [0.4667, 0.6745, 0.1882];
qc3Color = 'm';
qc4Color = 'r';

param1Axes = [];
markerSize = 3;
g_GTP_PARAM_AXES_1 = param1Axes;
if (~isempty(yParam1Data))

   param1Axes = subplot('Position', [0.1300    0.6020    0.7750    0.3230]);
   g_GTP_PARAM_AXES_1 = param1Axes;

   id = find(~isnan(yParam1Data));
   plot(param1Axes, xParam1Data(id), yParam1Data(id), 'k-');
   hold on;

   % marker points in terms of QC
   if (~any(yParam1DataQc ~= 0))

      % no QC on data
      col = 'b';
      plotHdl = plot(param1Axes, xParam1Data(idIn1), yParam1Data(idIn1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', col, 'MarkerEdgeColor', col);
      hold on;

   else

      % QC on data
      id1 = find((yParam1DataQc == 0) & ~isnan(yParam1Data));
      plotHdl = plot(param1Axes, xParam1Data(id1), yParam1Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc0Color, 'MarkerEdgeColor', qc0Color, 'UserData', yParam1DataQc(id1));
      hold on;
      id1 = find((yParam1DataQc == 1) & ~isnan(yParam1Data));
      plotHdl = plot(param1Axes, xParam1Data(id1), yParam1Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc1Color, 'MarkerEdgeColor', qc1Color, 'UserData', yParam1DataQc(id1));
      hold on;
      id1 = find((yParam1DataQc == 2) & ~isnan(yParam1Data));
      plotHdl = plot(param1Axes, xParam1Data(id1), yParam1Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc2Color, 'MarkerEdgeColor', qc2Color, 'UserData', yParam1DataQc(id1));
      hold on;
      id1 = find((yParam1DataQc == 3) & ~isnan(yParam1Data));
      plotHdl = plot(param1Axes, xParam1Data(id1), yParam1Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc3Color, 'MarkerEdgeColor', qc3Color, 'UserData', yParam1DataQc(id1));
      hold on;
      id1 = find((yParam1DataQc == 4) & ~isnan(yParam1Data));
      plotHdl = plot(param1Axes, xParam1Data(id1), yParam1Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc4Color, 'MarkerEdgeColor', qc4Color, 'UserData', yParam1DataQc(id1));
      hold on;

   end
end

param2Axes = [];
g_GTP_PARAM_AXES_2 = param2Axes;
if (~isempty(yParam2Data))

   param2Axes = subplot('Position', [0.1300    0.1282    0.7750    0.3230]);
   g_GTP_PARAM_AXES_2 = param2Axes;

   id = find(~isnan(yParam2Data));
   plot(param2Axes, xParam2Data(id), yParam2Data(id), 'k-');
   hold on;

   % marker points in terms of QC
   if (~any(yParam2DataQc ~= 0))

      % no QC on data
      col = 'b';
      plotHdl = plot(param2Axes, xParam2Data, yParam2Data, 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', col, 'MarkerEdgeColor', col);
      hold on;

   else

      % QC on data
      id1 = find((yParam2DataQc == 0) & ~isnan(yParam2Data));
      plotHdl = plot(param2Axes, xParam2Data(id1), yParam2Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc0Color, 'MarkerEdgeColor', qc0Color, 'UserData', yParam2DataQc(id1));
      hold on;
      id1 = find((yParam2DataQc == 1) & ~isnan(yParam2Data));
      plotHdl = plot(param2Axes, xParam2Data(id1), yParam2Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc1Color, 'MarkerEdgeColor', qc1Color, 'UserData', yParam2DataQc(id1));
      hold on;
      id1 = find((yParam2DataQc == 2) & ~isnan(yParam2Data));
      plotHdl = plot(param2Axes, xParam2Data(id1), yParam2Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc2Color, 'MarkerEdgeColor', qc2Color, 'UserData', yParam2DataQc(id1));
      hold on;
      id1 = find((yParam2DataQc == 3) & ~isnan(yParam2Data));
      plotHdl = plot(param2Axes, xParam2Data(id1), yParam2Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc3Color, 'MarkerEdgeColor', qc3Color, 'UserData', yParam2DataQc(id1));
      hold on;
      id1 = find((yParam2DataQc == 4) & ~isnan(yParam2Data));
      plotHdl = plot(param2Axes, xParam2Data(id1), yParam2Data(id1), 'o', 'MarkerSize', markerSize, 'MarkerFaceColor', qc4Color, 'MarkerEdgeColor', qc4Color, 'UserData', yParam2DataQc(id1));
      hold on;

   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot finalization

if (~isempty(param1Axes))

   % management of parameter axis boundaries
   ymin = min(yParam1Data);
   ymax = max(yParam1Data);
   if (ymin == ymax)
      ymin = ymin - 1;
      ymax = ymax + 1;
   end
   set(param1Axes, 'Ylim', [ymin-((ymax-ymin)/10) ymax+((ymax-ymin)/10)]);

   % titre de l'axe vertical
   set(get(param1Axes, 'YLabel'), 'String', [g_GTP_PARAM_NAME_1 ' (' g_GTP_PARAM_1_WORK_DATA_UNIT ')'], 'Interpreter', 'none');

   % management of time axis boundaries
   if (xMin == xMax)
      xMin = xMin - 1;
      xMax = xMax + 1;
   end
   set(param1Axes, 'Xlim', [xMin xMax]);
   xlabel(param1Axes, ['TIME (' g_GTP_TIME_WORK_DATA_UNIT ')']);

   % time ticks management
   xTick = get(param1Axes, 'XTick');
   if (max(xTick) - min(xTick) > 1)
      xTickLabel = datestr(xTick, 'dd/mm/yyyy');
   else
      xTickLabel = datestr(xTick, 'dd/mm/yyyy  HH:MM:SS');
      xTickLabel(1:2:end, :) = ' ';
   end
   set(param1Axes, 'XTickLabel', xTickLabel);
end

if (~isempty(param2Axes))

   % management of parameter axis boundaries
   ymin = min(yParam2Data);
   ymax = max(yParam2Data);
   if (ymin == ymax)
      ymin = ymin - 1;
      ymax = ymax + 1;
   end
   set(param2Axes, 'Ylim', [ymin-((ymax-ymin)/10) ymax+((ymax-ymin)/10)]);

   % titre de l'axe vertical
   set(get(param2Axes, 'YLabel'), 'String', [g_GTP_PARAM_NAME_2 ' (' g_GTP_PARAM_2_WORK_DATA_UNIT ')'], 'Interpreter', 'none');

   % management of time axis boundaries
   if (xMin == xMax)
      xMin = xMin - 1;
      xMax = xMax + 1;
   end
   set(param2Axes, 'Xlim', [xMin xMax]);
   xlabel(param2Axes, ['TIME (' g_GTP_TIME_WORK_DATA_UNIT ')']);

   % time ticks management
   xTick = get(param2Axes, 'XTick');
   if (max(xTick) - min(xTick) > 1)
      xTickLabel = datestr(xTick, 'dd/mm/yyyy');
   else
      xTickLabel = datestr(xTick, 'dd/mm/yyyy  HH:MM:SS');
      xTickLabel(1:2:end, :) = ' ';
   end
   set(param2Axes, 'XTickLabel', xTickLabel);
end

% increasing pressures
if (ismember(g_GTP_PARAM_NAME_1, [{'PRES'}, {'PRES2'}]))
   set(param1Axes, 'YDir', 'reverse');
end
if (ismember(g_GTP_PARAM_NAME_2, [{'PRES'}, {'PRES2'}]))
   set(param2Axes, 'YDir', 'reverse');
end

% plot title
if (g_GTP_PLOT_ALL == 0)
   label = sprintf('DEPLOYMENT %s: (%02d/%02d) - (SEQ: %d/%d)', ...
      g_GTP_CURRENT_GLIDER_NAME, ...
      g_GTP_CURRENT_GLIDER_ID+1, ...
      length(g_GTP_GLIDER_DATA_DIR_LIST), ...
      g_GTP_SEQUENCE_NUMBER+1, ...
      g_GTP_CURRENT_GLIDER_NB_SEQUENCE);
elseif (g_GTP_PLOT_ALL == 1)
   label = sprintf('DEPLOYMENT %s: (%02d/%02d) - (SEQ: ALL DEPLOYMENT DATA)', ...
      g_GTP_CURRENT_GLIDER_NAME, ...
      g_GTP_CURRENT_GLIDER_ID+1, ...
      length(g_GTP_GLIDER_DATA_DIR_LIST));
end

if (isempty(param1Axes))
   param1Axes = subplot('Position', [0.1300    0.6020    0.7750    0.3230]);
end
title(param1Axes, label, 'FontSize', 14, 'Interpreter', 'none');

return

% ------------------------------------------------------------------------------
% Management of 'KeyPressFcn' callback
%
% SYNTAX :
%   change_plot(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src       : focused object when event occurred
%   a_eventData : event information
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_GTP_FIG_HANDLE;
global g_GTP_GLIDER_DATA_DIR_LIST;
global g_GTP_CURRENT_GLIDER_ID;
global g_GTP_CURRENT_GLIDER_DIR;
global g_GTP_NB_DAYS_IN_SET;
global g_GTP_NB_SET_IN_SEQUENCE;
global g_GTP_NB_SET_IN_SEQUENCE_DEFAULT;
global g_GTP_SEQUENCE_NUMBER;
global g_GTP_CURRENT_GLIDER_NB_SEQUENCE;
global g_GTP_NB_SET_IN_SEQUENCE_CHANGED;
global g_GTP_CURRENT_GLIDER_DATA_SPAN;
global g_GTP_CURRENT_GLIDER_START_TIME;
global g_GTP_PLOT_START_TIME;
global g_GTP_RELOAD_DATA;
global g_GTP_PLOT_ALL;
global g_GTP_PLOT_GOOD_QC_ONLY;
global g_GTP_PRINT_FIGURE;
global g_GTP_ZOOM_COUNT;

if (strcmp(a_eventData.Key, 'escape'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % close figure
   fprintf('\nClosing figure ... bye\n');
   set(g_GTP_FIG_HANDLE, 'KeyPressFcn', '');
   close(g_GTP_FIG_HANDLE);

elseif (strcmp(a_eventData.Key, 'rightarrow'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot next deployment of the list
   if (length(g_GTP_GLIDER_DATA_DIR_LIST) > 1)
      g_GTP_CURRENT_GLIDER_ID = mod(g_GTP_CURRENT_GLIDER_ID+1, length(g_GTP_GLIDER_DATA_DIR_LIST));
      g_GTP_CURRENT_GLIDER_DIR = g_GTP_GLIDER_DATA_DIR_LIST{g_GTP_CURRENT_GLIDER_ID+1};
      g_GTP_RELOAD_DATA = 1;
      g_GTP_SEQUENCE_NUMBER = 0;
      g_GTP_ZOOM_COUNT = 0;
      plot_glider_param;
      display_current_config;
   end

elseif (strcmp(a_eventData.Key, 'leftarrow'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot previous deployment of the list
   if (length(g_GTP_GLIDER_DATA_DIR_LIST) > 1)
      g_GTP_CURRENT_GLIDER_ID = mod(g_GTP_CURRENT_GLIDER_ID-1, length(g_GTP_GLIDER_DATA_DIR_LIST));
      g_GTP_CURRENT_GLIDER_DIR = g_GTP_GLIDER_DATA_DIR_LIST{g_GTP_CURRENT_GLIDER_ID+1};
      g_GTP_RELOAD_DATA = 1;
      g_GTP_SEQUENCE_NUMBER = 0;
      g_GTP_ZOOM_COUNT = 0;
      plot_glider_param;
      display_current_config;
   end

elseif (strcmp(a_eventData.Key, 'downarrow'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot next time sequence of the current deployment
   if ((g_GTP_PLOT_ALL == 0) && (g_GTP_ZOOM_COUNT == 0))
      if (g_GTP_CURRENT_GLIDER_NB_SEQUENCE > 1)
         g_GTP_SEQUENCE_NUMBER = floor((g_GTP_PLOT_START_TIME-g_GTP_CURRENT_GLIDER_START_TIME)/(g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET));
         g_GTP_SEQUENCE_NUMBER = mod(g_GTP_SEQUENCE_NUMBER+1, g_GTP_CURRENT_GLIDER_NB_SEQUENCE);
         plot_glider_param;
         display_current_config;
      end
   end

elseif (strcmp(a_eventData.Key, 'uparrow'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot previous time sequence of the current deployment
   if ((g_GTP_PLOT_ALL == 0) && (g_GTP_ZOOM_COUNT == 0))
      if (g_GTP_CURRENT_GLIDER_NB_SEQUENCE > 1)
         g_GTP_SEQUENCE_NUMBER = floor((g_GTP_PLOT_START_TIME-g_GTP_CURRENT_GLIDER_START_TIME)/(g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET));
         g_GTP_SEQUENCE_NUMBER = mod(g_GTP_SEQUENCE_NUMBER-1, g_GTP_CURRENT_GLIDER_NB_SEQUENCE);
         plot_glider_param;
         display_current_config;
      end
   end

elseif (strcmp(a_eventData.Key, 'a'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot all mission data
   if (g_GTP_ZOOM_COUNT == 0)
      if (g_GTP_PLOT_ALL == 1)
         g_GTP_PLOT_ALL = 0;
      else
         g_GTP_PLOT_ALL = 1;
      end
      plot_glider_param;
      display_current_config;
   end

elseif (strcmp(a_eventData.Key, 'd'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot default configuration
   if (g_GTP_ZOOM_COUNT == 0)
      g_GTP_PLOT_ALL = 0;
      g_GTP_RELOAD_DATA = 0;
      g_GTP_NB_SET_IN_SEQUENCE = g_GTP_NB_SET_IN_SEQUENCE_DEFAULT;
      g_GTP_SEQUENCE_NUMBER = 0;
      g_GTP_CURRENT_GLIDER_NB_SEQUENCE = ceil(g_GTP_CURRENT_GLIDER_DATA_SPAN/(g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET));
      plot_glider_param;
      display_current_config;
   end

elseif (strcmp(a_eventData.Character, '+'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % add one set in time sequence
   if ((g_GTP_PLOT_ALL == 0) && (g_GTP_ZOOM_COUNT == 0))
      g_GTP_NB_SET_IN_SEQUENCE = g_GTP_NB_SET_IN_SEQUENCE + 1;
      g_GTP_CURRENT_GLIDER_NB_SEQUENCE = ceil(g_GTP_CURRENT_GLIDER_DATA_SPAN/(g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET));
      g_GTP_NB_SET_IN_SEQUENCE_CHANGED = 1;
      plot_glider_param;
      display_current_config;
   end

elseif (strcmp(a_eventData.Character, '-'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % remove one set in time sequence
   if ((g_GTP_PLOT_ALL == 0) && (g_GTP_ZOOM_COUNT == 0))
      if (g_GTP_NB_SET_IN_SEQUENCE > 1)
         g_GTP_NB_SET_IN_SEQUENCE = g_GTP_NB_SET_IN_SEQUENCE - 1;
         g_GTP_CURRENT_GLIDER_NB_SEQUENCE = ceil(g_GTP_CURRENT_GLIDER_DATA_SPAN/(g_GTP_NB_SET_IN_SEQUENCE*g_GTP_NB_DAYS_IN_SET));
         g_GTP_NB_SET_IN_SEQUENCE_CHANGED = -1;
      end
      plot_glider_param;
      display_current_config;
   end

elseif (strcmp(a_eventData.Key, 'q'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % don't plot bad measurements (QC = 3 or 4)
   if (g_GTP_PLOT_GOOD_QC_ONLY == 0)
      g_GTP_PLOT_GOOD_QC_ONLY = 1;
   else
      g_GTP_PLOT_GOOD_QC_ONLY = 0;
   end
   plot_glider_param;
   display_current_config;

elseif (strcmp(a_eventData.Key, 'p'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % print figure in .pdf file
   g_GTP_PRINT_FIGURE = 1;
   plot_glider_param;

elseif (strcmp(a_eventData.Key, 'c'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % print current configuration
   display_current_config;

elseif (strcmp(a_eventData.Key, 'h'))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % print help
   display_help;

end

return

% ------------------------------------------------------------------------------
% Display help information on available commands.
%
% SYNTAX :
%   display_help
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function display_help

fprintf('Plot management:\n');
fprintf('   Right Arrow : next deployment of the list\n');
fprintf('   Left Arrow  : previous deployment of the list\n');
fprintf('   Down Arrow  : next time sequence for the current deployment\n');
fprintf('   Up Arrow    : previous time sequence for the current deployment\n');
fprintf('   a           : plot all deployment times\n');
fprintf('   d           : back to default configuration\n');
fprintf('   +           : add one set to current time sequence\n');
fprintf('   -           : remove one set from current time sequence\n');
fprintf('   q           : don''t plot bad measurements (QC = 3 or 4)\n');
fprintf('   p           : print figure in PDF file\n');
fprintf('   c           : display current configuration\n');
fprintf('   h           : display help\n');
fprintf('Escape: exit\n\n');

return

% ------------------------------------------------------------------------------
% Display current visualization configuration.
%
% SYNTAX :
%   display_current_config
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function display_current_config

% default values
global g_decGl_janFirst1950InMatlab;

global g_GTP_GLIDER_DATA_DIR_LIST;
global g_GTP_CURRENT_GLIDER_FILE;
global g_GTP_CURRENT_GLIDER_ID;
global g_GTP_NB_DAYS_IN_SET;
global g_GTP_NB_SET_IN_SEQUENCE;
global g_GTP_SEQUENCE_NUMBER;
global g_GTP_CURRENT_GLIDER_START_TIME;
global g_GTP_CURRENT_GLIDER_END_TIME;
global g_GTP_CURRENT_GLIDER_NB_SEQUENCE;
global g_GTP_PLOT_START_TIME;
global g_GTP_PLOT_END_TIME;
global g_GTP_PLOT_ALL;
global g_GTP_PLOT_GOOD_QC_ONLY;
global g_GTP_ZOOM_COUNT;

fprintf('\nCurrent configuration:\n');
fprintf('CURRENT_DEPLOYMENT_ID     : %d (over %d)\n', g_GTP_CURRENT_GLIDER_ID+1, length(g_GTP_GLIDER_DATA_DIR_LIST));
fprintf('CURRENT_DEPLOYMENT_FILE   : %s\n', g_GTP_CURRENT_GLIDER_FILE);
fprintf('DATA_START_TIME           : %s\n', gl_julian_2_gregorian(g_GTP_CURRENT_GLIDER_START_TIME-g_decGl_janFirst1950InMatlab));
fprintf('DATA_END_TIME             : %s\n', gl_julian_2_gregorian(g_GTP_CURRENT_GLIDER_END_TIME-g_decGl_janFirst1950InMatlab));
fprintf('DATA_SPAN_DAYS            : %.1f\n', g_GTP_CURRENT_GLIDER_END_TIME-g_GTP_CURRENT_GLIDER_START_TIME);
fprintf('PLOT_START_TIME           : %s\n', gl_julian_2_gregorian(g_GTP_PLOT_START_TIME-g_decGl_janFirst1950InMatlab));
fprintf('PLOT_END_TIME             : %s\n', gl_julian_2_gregorian(g_GTP_PLOT_END_TIME-g_decGl_janFirst1950InMatlab));
fprintf('PLOT_ALL_DEPLOYMENT_TIMES : %d\n', g_GTP_PLOT_ALL);
if (g_GTP_PLOT_ALL == 0)
   fprintf('NB_DAYS_IN_SET            : %.1f\n', g_GTP_NB_DAYS_IN_SET);
   fprintf('NB_SET_IN_SEQUENCE        : %d\n', g_GTP_NB_SET_IN_SEQUENCE);
   fprintf('NB_DAYS_TO_PLOT           : %.1f\n', g_GTP_NB_DAYS_IN_SET*g_GTP_NB_SET_IN_SEQUENCE);
   fprintf('CURRENT_SEQUENCE_NUMBER   : %d (over %d)\n', g_GTP_SEQUENCE_NUMBER+1, g_GTP_CURRENT_GLIDER_NB_SEQUENCE);
end
fprintf('PLOT_GOOD_QC_ONLY         : %d\n', g_GTP_PLOT_GOOD_QC_ONLY);
fprintf('ZOOM_COUNT                : %d\n', g_GTP_ZOOM_COUNT);

return

% ------------------------------------------------------------------------------
% Management time tick labels after a zoom + update of Xlim of the other plot.
%
% SYNTAX :
%   after_zoom(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src       : focused object when event occurred
%   a_eventData : event information
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function after_zoom(a_src, a_eventData)

global g_GTP_PARAM_AXES_1;
global g_GTP_PARAM_AXES_2;
global g_GTP_PLOT_START_TIME;
global g_GTP_PLOT_END_TIME;
global g_GTP_ZOOM_COUNT;


% update start/stop times
xLim = get(a_eventData.Axes, 'XLim');
g_GTP_PLOT_START_TIME = xLim(1);
g_GTP_PLOT_END_TIME = xLim(2);

% update tick labels of the focused plot
xTick = get(a_eventData.Axes, 'XTick');
if (max(xTick) - min(xTick) > 1)
   xTickLabel = datestr(xTick, 'dd/mm/yyyy');
else
   xTickLabel = datestr(xTick, 'dd/mm/yyyy  HH:MM:SS');
   xTickLabel(1:2:end, :) = ' ';
end
set(a_eventData.Axes, 'XTickLabel', xTickLabel);

% update 'Xlim' and tick labels of the other plot
otherAxes = [];
if (a_eventData.Axes == g_GTP_PARAM_AXES_1)
   if (~isempty(g_GTP_PARAM_AXES_2))
      otherAxes = g_GTP_PARAM_AXES_2;
   end
elseif (a_eventData.Axes == g_GTP_PARAM_AXES_2)
   if (~isempty(g_GTP_PARAM_AXES_1))
      otherAxes = g_GTP_PARAM_AXES_1;
   end
end

if (~isempty(otherAxes))
   set(otherAxes, 'Xlim', get(a_eventData.Axes, 'Xlim'));
   xTick = get(otherAxes, 'XTick');
   if (max(xTick) - min(xTick) > 1)
      xTickLabel = datestr(xTick, 'dd/mm/yyyy');
   else
      xTickLabel = datestr(xTick, 'dd/mm/yyyy  HH:MM:SS');
      xTickLabel(1:2:end, :) = ' ';
   end
   set(otherAxes, 'XTickLabel', xTickLabel);
end

pointerInfo = get(a_src, 'PointerShapeCData');
zoomIn = -1;
if (size(pointerInfo, 1) == 32)
   if (~any(pointerInfo(16, 10:22) ~= 1))
      zoomIn = 1;
   elseif (~any(pointerInfo(15, 12:18) ~= 1))
      zoomIn = 0;
   end
else
   if (pointerInfo(4, 6) == 1)
      zoomIn = 1;
   elseif (pointerInfo(4, 6) == 2)
      zoomIn = 0;
   end
end
if (zoomIn == 1)
   g_GTP_ZOOM_COUNT = g_GTP_ZOOM_COUNT + 1;
elseif (zoomIn == 0)
   if (g_GTP_ZOOM_COUNT > 0)
      g_GTP_ZOOM_COUNT = g_GTP_ZOOM_COUNT - 1;
   end
end

display_current_config;

return

% ------------------------------------------------------------------------------
% Update data cursor label.
%
% SYNTAX :
%  [o_label] = update_cursor_label(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src       : focused object when event occurred
%   a_eventData : event information
%
% OUTPUT PARAMETERS :
%   o_label : new cursor label to display
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_label] = update_cursor_label(a_src, a_eventData)

global g_GTP_PARAM_1_WORK_DATA_UNIT;
global g_GTP_PARAM_2_WORK_DATA_UNIT;
global g_GTP_PARAM_AXES_1;
global g_GTP_PARAM_AXES_2;


% find parent subplot to set unit to be displayed
if (a_src.Parent == g_GTP_PARAM_AXES_1)
   unit = g_GTP_PARAM_1_WORK_DATA_UNIT;
elseif (a_src.Parent == g_GTP_PARAM_AXES_2)
   unit = g_GTP_PARAM_2_WORK_DATA_UNIT;
end

xPos = a_eventData.Position(1);
yPos = a_eventData.Position(2);
xDataList = a_eventData.Target.XData;
yDataList = a_eventData.Target.YData;
qcDataList = a_eventData.Target.UserData;
qcValue = '';
if (~isempty(qcDataList))
   idPoint = find((xDataList == xPos) & (yDataList == yPos));
   qcValue = qcDataList(idPoint);
end


% update cursor label
cursorPos = get(a_eventData, 'Position');
xLabel = datestr(cursorPos(1), 'dd/mm/yyyy HH:MM:SS');
yLabel = [num2str(cursorPos(2)) ' ' unit];
if (~isempty(qcValue))
   zLabel = sprintf('Qc value : %d', qcValue);
   o_label = {xLabel, yLabel, zLabel};
else
   o_label = {xLabel, yLabel};
end

return

% ------------------------------------------------------------------------------
% Empty global variables used to store input data.
%
% SYNTAX :
%  empty_vars
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function empty_vars

global g_GTP_PARAM_1_WORK_DATA;
global g_GTP_PARAM_2_WORK_DATA;
global g_GTP_TIME_WORK_DATA;
global g_GTP_PARAM_1_WORK_DATA_QC;
global g_GTP_PARAM_2_WORK_DATA_QC;
global g_GTP_TIME_WORK_DATA_QC;
global g_GTP_PARAM_1_WORK_DATA_UNIT;
global g_GTP_PARAM_2_WORK_DATA_UNIT;
global g_GTP_TIME_WORK_DATA_UNIT;

g_GTP_TIME_WORK_DATA_UNIT = '';
g_GTP_TIME_WORK_DATA = [];
g_GTP_TIME_WORK_DATA_QC = [];
g_GTP_PARAM_1_WORK_DATA_UNIT = '';
g_GTP_PARAM_1_WORK_DATA = [];
g_GTP_PARAM_1_WORK_DATA_QC = [];
g_GTP_PARAM_2_WORK_DATA_UNIT = '';
g_GTP_PARAM_2_WORK_DATA = [];
g_GTP_PARAM_2_WORK_DATA_QC = [];

return
