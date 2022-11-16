% ------------------------------------------------------------------------------
% Trac� des immersions et vitesses verticales de gliders
%
% SYNTAX :
%   gl_trace_imm_vs_time_socib_HD
%
% INPUT PARAMETERS :
%   varargin : �ventuellement la liste du r�pertoire racine des r�pertoires de
%   donn�es
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   22/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function gl_trace_imm_vs_time_socib_HD(varargin)

global g_GLIDER_DATA_DIR_LIST_GTIVT;
global g_gliderDirNumber_GTIVT;
global g_FIG_GLIDER_PRES_HANDLE;


% default values initialization
gl_init_default_values;

fprintf('Available commands:\n');
fprintf('   h                : write help and current configuration\n');
fprintf('   Left/Right arrow : previous/next directory\n');
fprintf('   Up/Down arrow    : previous/next EGO NetCDF file\n');
fprintf('   Escape           : exit\n');

if (nargin == 0)
   % le r�pertoire pris en compte est le r�pertoire par d�faut
   gliderTopDirName = 'C:\Users\jprannou\_DATA\GLIDER\SOCIB_20210707\';
else
   % le r�pertoire pris en compte est celui fourni en param�tre
   gliderTopDirName = char(varargin);
end

if (~exist(gliderTopDirName, 'dir'))
   fprintf('R�pertoire inexistant: %s => stop!\n', gliderTopDirName);
   return
end

fprintf('Top directory: %s\n', gliderTopDirName);

% liste des sous-repertoires de donn�es gliders
g_GLIDER_DATA_DIR_LIST_GTIVT = [];
dirInfo = dir(gliderTopDirName);
for dirNum = 1:length(dirInfo)
   if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
      dirName = dirInfo(dirNum).name;
      dirPathName = [gliderTopDirName '/' dirName '/'];
      if (exist(dirPathName, 'dir'))
         g_GLIDER_DATA_DIR_LIST_GTIVT{end + 1} = dirPathName;
      end
   end
end

% pour forcer le chargement des donn�es du premier glider
g_gliderDirNumber_GTIVT = -1;

close(findobj('Name', 'Glider immersion vs time'));
warning off;

% cr�ation de la figure � laquelle on affecte une callback pour g�rer le
% d�filement des gliders et des fichiers
screenSize = get(0, 'ScreenSize');

g_FIG_GLIDER_PRES_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Glider immersion vs time', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90]);

% on lance le trac� des pressions du premier fichier du premier glider
trace_imm_vs_time(0, 0);

return

% ------------------------------------------------------------------------------
% Trac� des immersions et vitesses verticales de gliders
%
% SYNTAX :
%   trace_imm_vs_time(a_gliderDirNumber, a_gliderFileNumber)
%
% INPUT PARAMETERS :
%   a_gliderDirNumber  : num�ro du r�pertoire du glider � tracer
%   a_gliderFileNumber : num�ro du fichier glider � tracer
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   22/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function trace_imm_vs_time(a_gliderDirNumber, a_gliderFileNumber)

global g_GLIDER_DATA_DIR_LIST_GTIVT;
global g_GLIDER_DATA_FILE_LIST_GTIVT;

global g_gliderDirNumber_GTIVT;
global g_gliderFileNumber_GTIVT;

global g_FIG_GLIDER_PRES_HANDLE;

global g_time_GTIVT;
global g_pres_GTIVT;
global g_phase_GTIVT;
global g_timeVel_GTIVT;
global g_presVel_GTIVT;

global g_decGl_phaseSurfDrift;
global g_decGl_phaseSubSurfDrift;

% trac� des donn�es demand�es
figure(g_FIG_GLIDER_PRES_HANDLE);
clf;

if ((a_gliderDirNumber ~= g_gliderDirNumber_GTIVT) || (a_gliderFileNumber ~= g_gliderFileNumber_GTIVT))
   
   if (a_gliderDirNumber ~= g_gliderDirNumber_GTIVT)
      % r�pertoire � prendre en compte
      gliderDirName = char(g_GLIDER_DATA_DIR_LIST_GTIVT(a_gliderDirNumber+1));
      % fichiers netCDF du r�pertoire
      g_GLIDER_DATA_FILE_LIST_GTIVT = [];
      files = dir([gliderDirName '*.nc']);
      for fileNum = 1:length(files)
         filePathName = [gliderDirName '/' files(fileNum).name];
         if (~exist(filePathName, 'dir') && exist(filePathName, 'file'))
            g_GLIDER_DATA_FILE_LIST_GTIVT{end + 1} = filePathName;
         end
      end
      
      fprintf('Considering directory: %s (%d files)\n', ...
         char(g_GLIDER_DATA_DIR_LIST_GTIVT(a_gliderDirNumber+1)), ...
         length(g_GLIDER_DATA_FILE_LIST_GTIVT));
      
      % on repart au premier fichier du r�pertoire
      a_gliderFileNumber = 0;
   end
            
   g_gliderDirNumber_GTIVT = a_gliderDirNumber;
   g_gliderFileNumber_GTIVT = a_gliderFileNumber;

   if (isempty(g_GLIDER_DATA_FILE_LIST_GTIVT))
      fprintf('Empty directory: %s\n', char(g_GLIDER_DATA_DIR_LIST_GTIVT(a_gliderDirNumber+1)));
      return
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % lecture et stockage des donn�es associ�es � ce fichier de ce glider
   
   g_time_GTIVT = [];
   g_pres_GTIVT = [];
   g_phase_GTIVT = [];
   g_timeVel_GTIVT = [];
   g_presVel_GTIVT = [];
   
   gliderFileName = char(g_GLIDER_DATA_FILE_LIST_GTIVT(a_gliderFileNumber+1));
   
   % check if the file exists
   if (~exist(gliderFileName, 'file'))
      fprintf('WARNING: File not found : %s\n', gliderFileName);
      return
   end
   
   % open NetCDF file
   fCdf = netcdf.open(gliderFileName, 'NC_WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', gliderFileName);
      return
   end
   
   % retrieve immersion data
   immVarId = [];
   if (gl_var_is_present(fCdf, 'DEPTH'))
      g_pres_GTIVT = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPTH'));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'DEPTH'), '_FillValue');
      g_pres_GTIVT(g_pres_GTIVT == fillVal) = nan;
      immVarId = netcdf.inqVarID(fCdf, 'DEPTH');
   elseif (gl_var_is_present(fCdf, 'PRES'))
      g_pres_GTIVT = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
      g_pres_GTIVT(g_pres_GTIVT == fillVal) = nan;
      immVarId = netcdf.inqVarID(fCdf, 'PRES');
   else
      fprintf('ERROR: Variable %s (nor %s) not present in file : %s\n', ...
         'PRES', 'DEPTH', gliderFileName);
      netcdf.close(fCdf);
      return
   end

   % retrieve time data
   [varname, xtype, immDimId, natts] = netcdf.inqVar(fCdf, immVarId);
   if (size(immDimId, 2) ~= 1)
      fprintf('ERROR: Inconcistent dimension for immersion variable in file : %s\n', ...
         gliderFileName);
      netcdf.close(fCdf);
      return
   end
   [timeVar, dimlen] = netcdf.inqDim(fCdf, immDimId);
   if (gl_var_is_present(fCdf, timeVar))
      g_time_GTIVT = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, timeVar));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, timeVar), '_FillValue');
      g_time_GTIVT(g_time_GTIVT == fillVal) = nan;
   else
      fprintf('ERROR: Variable %s not present in file : %s\n', ...
         timeVar, gliderFileName);
      netcdf.close(fCdf);
      return
   end
   
   % retrieve phase data
   if (gl_var_is_present(fCdf, 'PHASE'))
      g_phase_GTIVT = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE'));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PHASE'), '_FillValue');
      g_phase_GTIVT(g_phase_GTIVT == fillVal) = nan;
   else
      fprintf('ERROR: Variable %s not present in file : %s\n', ...
         'PHASE', gliderFileName);
      return
   end
   
   % retrieve phase number
   if (gl_var_is_present(fCdf, 'PHASE_NUMBER'))
      phaseNum = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'));
      fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'), '_FillValue');
      phaseNum(phaseNum == fillVal) = nan;
   else
      fprintf('ERROR: Variable %s not present in file : %s\n', ...
         'PHASE', gliderFileName);
      return
   end
   
   netcdf.close(fCdf);
   
   g_timeVel_GTIVT = g_time_GTIVT(2:end);
   g_presVel_GTIVT = diff(g_pres_GTIVT)*100./diff(g_time_GTIVT);
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trac� des donn�es

time_GTIVT_tmp = g_time_GTIVT;
pres_GTIVT_tmp = g_pres_GTIVT;
phase_GTIVT_tmp = g_phase_GTIVT;
timeVel_GTIVT_tmp = g_timeVel_GTIVT;
presVel_GTIVT_tmp = g_presVel_GTIVT;

stop = 0;
stopId = 1;
while (~stop)
   
   startId = stopId;
   stopId = find(ismember(phase_GTIVT_tmp, [g_decGl_phaseSurfDrift g_decGl_phaseSubSurfDrift]) & (phaseNum > phaseNum(startId)), 1, 'first');
   if (isempty(stopId))
      stopId = length(time_GTIVT_tmp);
      stop = 1;
   end
   
   g_time_GTIVT = time_GTIVT_tmp(startId:stopId);
   g_pres_GTIVT = pres_GTIVT_tmp(startId:stopId);
   g_phase_GTIVT = phase_GTIVT_tmp(startId:stopId);
   g_timeVel_GTIVT = timeVel_GTIVT_tmp(startId:stopId-1);
   g_presVel_GTIVT = presVel_GTIVT_tmp(startId:stopId-1);
   
   presAxes = [];
   if (~isempty(g_time_GTIVT) && ~isempty(g_pres_GTIVT))
      yColor = g_phase_GTIVT;
      
      trans = find(diff(yColor) ~= 0);
      if (~isempty(trans))
         idStart = 1;
         for id = 1:length(trans)+1
            if (id <= length(trans))
               idStop = trans(id);
            else
               idStop = length(g_time_GTIVT);
            end
            xPresT = g_time_GTIVT(idStart:idStop);
            yPresT = g_pres_GTIVT(idStart:idStop);
            yColorT = yColor(idStart:idStop);
            
            presAxes = subplot(2, 1, 1);
            plot(presAxes, xPresT, yPresT, 'Color', get_color(yColorT), 'LineStyle', '-', 'Marker', '.');
            hold on;
            
            idStart = idStop + 1;
         end
      else
         idStart = 1;
         idStop = length(g_time_GTIVT);
         xPresT = g_time_GTIVT(idStart:idStop);
         yPresT = g_pres_GTIVT(idStart:idStop);
         yColorT = g_phase_GTIVT(idStart:idStop);
         
         presAxes = subplot(2, 1, 1);
         plot(presAxes, xPresT, yPresT, 'Color', get_color(yColorT), 'LineStyle', '-', 'Marker', '.');
         hold on;
      end
      
      minTime = min(g_time_GTIVT);
      maxTime = max(g_time_GTIVT);
      
      minPres = min(g_pres_GTIVT);
      maxPres = max(g_pres_GTIVT);
   end
   
   velAxes = [];
   if (~isempty(g_timeVel_GTIVT) && ~isempty(g_presVel_GTIVT))
      yColor = g_phase_GTIVT(2:end);
      
      trans = find(diff(yColor) ~= 0);
      if (~isempty(trans))
         idStart = 1;
         for id = 1:length(trans)+1
            if (id <= length(trans))
               idStop = trans(id);
            else
               idStop = length(g_timeVel_GTIVT);
            end
            xVelT = g_timeVel_GTIVT(idStart:idStop);
            yVelT = g_presVel_GTIVT(idStart:idStop);
            yColorT = yColor(idStart:idStop);
            
            velAxes = subplot(2, 1, 2);
            plot(velAxes, xVelT, yVelT, 'Color', get_color(yColorT), 'LineStyle', '-', 'Marker', '.');
            hold on;
            
            idStart = idStop + 1;
         end
      else
         idStart = 1;
         idStop = length(g_timeVel_GTIVT);
         xVelT = g_timeVel_GTIVT(idStart:idStop);
         yVelT = g_presVel_GTIVT(idStart:idStop);
         yColorT = yColor(idStart:idStop);
         
         velAxes = subplot(2, 1, 2);
         plot(velAxes, xVelT, yVelT, 'Color', get_color(yColorT), 'LineStyle', '-', 'Marker', '.');
         hold on;
      end
      
      minVel = min(g_presVel_GTIVT);
      maxVel = max(g_presVel_GTIVT);
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % finition des trac�s
   
   if (~isempty(presAxes))
      
      % pressions croissantes vers le bas
      set(presAxes, 'YDir', 'reverse');
      
      % gestion des bornes de l'axe
      minPres = 5*floor(minPres/5);
      if (minPres == 0)
         minPres = -1;
      end
      maxPres = 5*ceil(maxPres/5);
      if (maxPres == 0)
         maxPres = 1;
      end
      set(presAxes, 'Ylim', [minPres maxPres]);
      
      % titre de l'axe
      set(get(presAxes, 'YLabel'), 'String', 'Pressure (dbar)');
      
      % axe des abscisses (temps)
      minTime = 600*floor(minTime/600);
      maxTime = 600*ceil(maxTime/600);
      if (minTime == maxTime)
         minTime = minTime - 600;
         maxTime = maxTime + 600;
      end
      
      set(presAxes, 'Xlim', [minTime maxTime]);
      
      % gestion des labels de l'axe des abscisses (Dates)
      deltaTick = round((maxTime - minTime)/10);
      xTick = [];
      for idX = minTime:deltaTick:maxTime
         xTick = [xTick idX];
      end
      set(presAxes, 'XTick', xTick);
      
      xTick = get(presAxes, 'XTick');
      xTick = epoch2datenum(xTick);
      if (max(xTick) - min(xTick) > 2)
         xTickLabel = datestr(xTick, 'dd/mm/yyyy');
      else
         xTickLabel = datestr(xTick, 'dd/mm/yyyy HH:MM:SS');
      end
      [lig, col] = size(xTickLabel);
      xTickLabel(2:2:lig, 1:col) = ' ';
      set(presAxes, 'XTickLabel', xTickLabel);
      
   end
   
   if (~isempty(velAxes))
      
      % gestion des bornes de l'axe
      minVel = floor(minVel);
      if (minVel == 0)
         minVel = -1;
      end
      maxVel = ceil(maxVel);
      if (maxVel == 0)
         maxVel = 1;
      end
      set(velAxes, 'Ylim', [minVel maxVel]);
      
      % titre de l'axe
      set(get(velAxes, 'YLabel'), 'String', 'Vertical speed (cm/s)');
      
      % axe des abscisses (temps)
      set(velAxes, 'Xlim', [minTime maxTime]);
      
      % gestion des labels de l'axe des abscisses (Dates)
      deltaTick = round((maxTime - minTime)/10);
      xTick = [];
      for idX = minTime:deltaTick:maxTime
         xTick = [xTick idX];
      end
      set(velAxes, 'XTick', xTick);
      
      xTick = get(velAxes, 'XTick');
      xTick = epoch2datenum(xTick);
      if (max(xTick) - min(xTick) > 2)
         xTickLabel = datestr(xTick, 'dd/mm/yyyy');
      else
         xTickLabel = datestr(xTick, 'dd/mm/yyyy HH:MM:SS');
      end
      [lig, col] = size(xTickLabel);
      xTickLabel(2:2:lig, 1:col) = ' ';
      set(velAxes, 'XTickLabel', xTickLabel);
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % titre du trac�
   
   set(0,'DefaulttextInterpreter','none');
   [pathstr, name, ext] = fileparts(gliderFileName) ;
   if (~isempty(g_time_GTIVT) && ~isempty(g_pres_GTIVT))
      label = sprintf('%02d/%02d : glider file %s', ...
         a_gliderFileNumber+1, ...
         length(g_GLIDER_DATA_FILE_LIST_GTIVT), ...
         [name ext]);
   else
      label = sprintf('%02d/%02d : no data in glider file %s', ...
         a_gliderFileNumber+1, ...
         length(g_GLIDER_DATA_FILE_LIST_GTIVT), ...
         [name ext]);
   end
   
   if ((~isempty(presAxes)) || (~isempty(velAxes)))
      title(presAxes, label, 'FontSize', 14);
   else
      title(label, 'FontSize', 14);
   end
   
   fprintf('Press any key to plot next set ... ');
   pause();
   fprintf('ok let''s plot\n');
end

return

% ------------------------------------------------------------------------------
% Callback de gestion des trac�s:
%   - Left/Right arrow : previous/next directory
%   - Up/Down arrow    : previous/next EGO NetCDF file
%   - up/down Arrow : fichier glider pr�c�dent/suivant
%   - Escape           : exit
%
% SYNTAX :
%   change_plot(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src        : objet source
%   a_eventData  : �v�nement d�clencheur
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   22/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_GLIDER_DATA_DIR_LIST_GTIVT;
global g_GLIDER_DATA_FILE_LIST_GTIVT;

global g_gliderDirNumber_GTIVT;
global g_gliderFileNumber_GTIVT;

global g_FIG_GLIDER_PRES_HANDLE;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit
if (strcmp(a_eventData.Key, 'escape'))
   set(g_FIG_GLIDER_PRES_HANDLE, 'KeyPressFcn', '');
   close(g_FIG_GLIDER_PRES_HANDLE);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next directory
elseif (strcmp(a_eventData.Key, 'rightarrow'))
   if (length(g_GLIDER_DATA_DIR_LIST_GTIVT) > 1)
      trace_imm_vs_time( ...
         mod(g_gliderDirNumber_GTIVT+1, length(g_GLIDER_DATA_DIR_LIST_GTIVT)), ...
         0);
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous directory
elseif (strcmp(a_eventData.Key, 'leftarrow'))
   if (length(g_GLIDER_DATA_DIR_LIST_GTIVT) > 1)
      trace_imm_vs_time( ...
         mod(g_gliderDirNumber_GTIVT-1, length(g_GLIDER_DATA_DIR_LIST_GTIVT)), ...
         0);
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous EGO file
elseif (strcmp(a_eventData.Key, 'uparrow'))
   if (length(g_GLIDER_DATA_FILE_LIST_GTIVT) > 1)
      trace_imm_vs_time( ...
         g_gliderDirNumber_GTIVT, ...
         mod(g_gliderFileNumber_GTIVT-1, length(g_GLIDER_DATA_FILE_LIST_GTIVT)));
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next EGO file
elseif (strcmp(a_eventData.Key, 'downarrow'))
   if (length(g_GLIDER_DATA_FILE_LIST_GTIVT) > 1)
      trace_imm_vs_time( ...
         g_gliderDirNumber_GTIVT, ...
         mod(g_gliderFileNumber_GTIVT+1, length(g_GLIDER_DATA_FILE_LIST_GTIVT)));
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write help
elseif (strcmp(a_eventData.Key, 'h'))
   fprintf('\n');
   fprintf('Available commands:\n');
   fprintf('   h                : write help and current configuration\n');
   fprintf('   Left/Right arrow : previous/next directory\n');
   fprintf('   Up/Down arrow    : previous/next EGO NetCDF file\n');
   fprintf('   Escape           : exit\n');
   fprintf('\n');
end

return

% ------------------------------------------------------------------------------
% R�cup�ration du code couleur associ� � chaque phase
%
% SYNTAX :
% [o_color] = get_color(a_phaseVal)
%
% INPUT PARAMETERS :
%   a_phaseVal : indice de la phase
%
% OUTPUT PARAMETERS :
%   o_color : couleur associ� � la phase
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   22/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_color] = get_color(a_phaseVal)

% PHASE codes
global g_decGl_phaseSurfDrift;
global g_decGl_phaseDescent;
global g_decGl_phaseSubSurfDrift;
global g_decGl_phaseInflexion;
global g_decGl_phaseAscent;
global g_decGl_phaseInconsistant;
global g_decGl_phaseDefault;

o_color = [];

phaseVal = unique(a_phaseVal);
if (length(phaseVal) ~= 1)
   fprintf('ERROR: many phase values!\n');
   return
end

switch phaseVal
   case g_decGl_phaseSurfDrift
      o_color = 'g';
   case g_decGl_phaseDescent
      o_color = [102 204 204]/255;
   case g_decGl_phaseSubSurfDrift
      o_color = 'c';
   case g_decGl_phaseInflexion
      o_color = 'm';
   case g_decGl_phaseAscent
      o_color = [255 102 102]/255;
   case g_decGl_phaseInconsistant
      o_color = 'r';
   case g_decGl_phaseDefault
      o_color = 'k';
   otherwise
      fprintf('Undefined color for this phase value!\n');
end

return
