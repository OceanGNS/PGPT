% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from EGO NetCDF file.
%
% SYNTAX :
%  gl_generate_prof_from_socib_ego_file_HD(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments (all mandatory)
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'glidertype' : specify the type of the glider to process
%      'egofile'    : input EGO nc file (file path name)
%      'outputdir'  : directory to store output profiles
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
% gl_generate_prof_from_socib_ego_file_HD('data', 'campe_mooset02_13', 'glidertype', 'slocum')
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2021 - RNU - creation
% ------------------------------------------------------------------------------
function gl_generate_prof_from_socib_ego_file_HD(varargin)

% CONFIGURATION - START %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory of the output profile files
OUTPUT_DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\SOCIB_20210707\profiles\';

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
TEST007_REGIONAL_RANGE = 0;
TEST009_SPIKE = 0;
TEST011_GRADIENT = 0;
TEST015_GREY_LIST = 0;
TEST019_DEEPEST_PRESSURE = 1;
TEST020_QUESTIONABLE_ARGOS_POSITION = 0;
TEST025_MEDD = 0;
TEST057_DOXY = 0;

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

% default values initialization
gl_init_default_values;


% create log file
tic;
logFile = [LOG_DIRECTORY '/' 'gl_generate_prof_from_socib_ego_file_HD_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
egoFilePathName = [];
profOutputDirName = OUTPUT_DATA_DIRECTORY;
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'egofile'))
            egoFilePathName = varargin{id+1};
         elseif (strcmpi(varargin{id}, 'glidertype'))
            if (strcmpi(varargin{id+1}, 'seaglider') || ...
                  strcmpi(varargin{id+1}, 'slocum') || ...
                  strcmpi(varargin{id+1}, 'seaexplorer'))
               g_decGl_gliderType = lower(varargin{id+1});
            else
               fprintf('ERROR: %s is not an expected glider type (expecting ''seaglider'' or ''slocum'' or ''seaexplorer'') => exit\n', varargin{id+1});
            end
         elseif (strcmpi(varargin{id}, 'outputdir'))
            profOutputDirName = varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
      
      if (isempty(g_decGl_gliderType) || isempty(profOutputDirName) || isempty(profOutputDirName))
         fprintf('ERROR: missing mandatory arguments\n');
         fprintf('INFO: expected mandatory arguments\n');
         fprintf('      ''glidertype'' : glider type \n');
         fprintf('      ''egofile''    : input EGO nc file (file path name)\n');
         fprintf('      ''outputdir''  : directory to store output profiles\n');
         return
      end
   end
end

% print the arguments understanding
fprintf('\nINFO: EGO file to process: %s\n', egoFilePathName);
fprintf('INFO: output directory: %s\n\n', profOutputDirName);

% check inputs
if ~(exist(egoFilePathName, 'file') == 2)
   fprintf('ERROR: EGO file not found: %s\n', egoFilePathName);
   return
end
if ~(exist(profOutputDirName, 'dir') == 7)
   [status, ~, ~] = mkdir(profOutputDirName);
   if (status == 1)
      fprintf('INFO: directory created: %s\n', profOutputDirName);
   else
      fprintf('ERROR: cannot create directory: %s\n', egoFilePathName);
      return
   end
end

% create output directory for the current file
[~, egoFileName, ~] = fileparts(egoFilePathName);
profOutputDirName = [profOutputDirName '/' egoFileName '/'];
if ~(exist(profOutputDirName, 'dir') == 7)
   [status, ~, ~] = mkdir(profOutputDirName);
   if (status == 1)
      fprintf('INFO: directory created: %s\n', profOutputDirName);
   else
      fprintf('ERROR: Cannot create directory: %s\n', egoFilePathName);
      return
   end
end

% update PHASE and PHASE_NUMBER in EGO file
fprintf('- Updating PHASE and PHASE_NUMBER in EGO file ''%s''\n', egoFileName);
gl_set_phase_socib_HD(egoFilePathName);

% apply RTQC tests on output EGO file data
testDoneList = [];
testFailedList = [];
if (APPLY_RTQC_TESTS == 1)
   
   fprintf('- Applying RTQC tests to EGO file ''%s''\n', egoFileName);
   
   [testDoneList, testFailedList] = gl_add_rtqc_to_ego_file(egoFilePathName);
end

% generate the profiles
fprintf('- Generating profile files from EGO file ''%s''\n', egoFileName);
[generatedFileList] = gl_generate_prof(egoFilePathName, profOutputDirName, ...
   APPLY_RTQC_TESTS, testDoneList, testFailedList);

% apply RTQC tests on output profile files data
if (APPLY_RTQC_TESTS == 1)
   fprintf('- Applying RTQC tests to generated profiles data\n');
   
   for idF = 1:length(generatedFileList)
      gl_add_rtqc_to_profile_file(generatedFileList{idF});
   end
end

ellapsedTime = toc;
fprintf('Done (%.1f min)\n', ellapsedTime/60);

diary off;

return

% ------------------------------------------------------------------------------
% Compute and add PHASE and PHASE_NUMBER parameter in an EGO netCDF file.
%
% SYNTAX :
%  gl_set_phase_socib_HD(a_ncFileName)
%
% INPUT PARAMETERS :
%   a_ncFileName : EGO netCDF file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2013 - RNU - creation
%   14/04/2014 - TCA - NB bin for profiles set to 10 instead of 1
% ------------------------------------------------------------------------------
function gl_set_phase_socib_HD(a_ncFileName)

% PHASE codes
global g_decGl_phaseSurfDrift;
global g_decGl_phaseDescent;
global g_decGl_phaseSubSurfDrift;
global g_decGl_phaseInflexion;
global g_decGl_phaseAscent;
global g_decGl_phaseGrounded;
global g_decGl_phaseInconsistant;
global g_decGl_phaseDefault;


% verbose mode flag
VERBOSE_MODE = 1;

% main parameters of the algorithm

% maximal pressure for the measurements (in dbar)
MAX_PRESSURE = 2500;

% maximal vertical velocity between 2 measurements (in cm/s)
MAX_VERTICAL_VELOCITY = 100;

% part of the data set needed to define the list of main modes 
PART_OF_POINTS_FOR_MODE_SELECTION_PERCENT = 80;

% part of the minimum main mode used to define the threshold for ascent/descent
% measurements
PART_OF_MIN_MODE_FOR_THRESHOLD = 1/4;

% minimum length of a profile
NB_BIN_FOR_PROFILE = 10;

% part of the measurements used to detect that the glider profiles in only one
% direction
MONO_DIRECTION_PROFILE_THRESHOLD = 70/100;

% maximum immersion for a glider at the surface
THRESHOLD_PRES_FOR_SURF = 2;

% maximal duration (in minutes) of an inflexion
MAX_DURATION_OF_INFLEXION = 10;


% check if the file exists
if (~exist(a_ncFileName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_ncFileName);
   return
end

% open NetCDF file
fCdf = netcdf.open(a_ncFileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncFileName);
   return
end

% retrieve immersion data
immVarId = [];
presFillValId = [];
if (gl_var_is_present(fCdf, 'DEPTH'))
   presDataOri = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPTH'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'DEPTH'), '_FillValue');
   presFillValId = find(presDataOri == fillVal);
   immVarId = netcdf.inqVarID(fCdf, 'DEPTH');
elseif (gl_var_is_present(fCdf, 'PRES'))
   presDataOri = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
   fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
   presFillValId = find(presDataOri == fillVal);
   immVarId = netcdf.inqVarID(fCdf, 'PRES');
else
   fprintf('ERROR: Variable %s (nor %s) not present in file : %s\n', ...
      'PRES', 'DEPTH', a_ncFileName);
   netcdf.close(fCdf);
   return
end

% retrieve time data
[varname, xtype, immDimId, natts] = netcdf.inqVar(fCdf, immVarId);
if (size(immDimId, 2) ~= 1)
   fprintf('ERROR: Inconcistent dimension for immersion variable in file : %s\n', ...
      a_ncFileName);
   netcdf.close(fCdf);
   return
end
[timeVar, dimlen] = netcdf.inqDim(fCdf, immDimId);
if (gl_var_is_present(fCdf, timeVar))
   timeDataOri = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, timeVar));
else
   fprintf('ERROR: Variable %s not present in file : %s\n', ...
      timeVar, a_ncFileName);
   netcdf.close(fCdf);
   return
end

% check data size
if (length(timeDataOri) ~= length(presDataOri))
   fprintf('ERROR: Time and immersion data must have the same size\n');
   netcdf.close(fCdf);
   return
end

% check for PHASE and PHASE_NUMBER variables
if (~gl_var_is_present(fCdf, 'PHASE'))
   fprintf('ERROR: Variable %s not present in file : %s\n', ...
      'PHASE', a_ncFileName);
   netcdf.close(fCdf);
   return
end
if (~gl_var_is_present(fCdf, 'PHASE_NUMBER'))
   fprintf('ERROR: Variable %s not present in file : %s\n', ...
      'PHASE_NUMBER', a_ncFileName);
   netcdf.close(fCdf);
   return
end

% check PHASE and PHASE_NUMBER variable dimensions
if (length(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE'))) ~= ...
      length(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'))))
   fprintf('ERROR: PHASE and PHASE_NUMBER variables must have the same dimension\n');
   netcdf.close(fCdf);
   return
end
if (length(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE'))) ~= ...
      length(presDataOri))
   fprintf('ERROR: Time, immersion, PHASE and PHASE_NUMBER variables must have the same dimension\n');
   netcdf.close(fCdf);
   return
end

% compute PHASE and PHASE_NUMBER parameters
phaseDataFinalMin = int8(ones(length(timeDataOri)-length(presFillValId), 1))*g_decGl_phaseDefault;
phaseNumberDataFinalMin = ones(length(timeDataOri)-length(presFillValId), 1)*99999;
phaseDataFinalTotal = int8(ones(length(timeDataOri), 1))*g_decGl_phaseDefault;
phaseNumberDataFinalTotal = ones(length(timeDataOri), 1)*99999;

% do not consider measurements timely too close (they induce huge vertical
% speeds and possibly memory problems when computing the modes)
idDelInOri = [];
if (~isempty(timeDataOri) && ~isempty(presDataOri))
   
   timeData = timeDataOri;
   presData = presDataOri;
   timeData(presFillValId) = [];
   presData(presFillValId) = [];
   if (length(timeData) > 1)
      
      idDataOri = 1:length(timeData);
      idData = idDataOri;
      idDel = find(abs(presData) > MAX_PRESSURE);
      timeData(idDel) = [];
      presData(idDel) = [];
      idData(idDel) = [];

      if (length(timeData) > 1)
         % vertical velocities in cm/s
         vertVelTmp = diff(presData)*100./diff(timeData);
         
         idDel = find(abs(vertVelTmp) > MAX_VERTICAL_VELOCITY);
         timeData(idDel) = [];
         presData(idDel) = [];
         idData(idDel) = [];
      end
      
      idDelInOri = setdiff(idDataOri, idData);
   end

   if (~isempty(timeData) && ~isempty(presData))
      
      phaseData = int8(ones(length(timeData), 1))*g_decGl_phaseDefault;
      phaseNumberData = zeros(length(timeData), 1);
      
      if (length(timeData) > 2)
         
         if (VERBOSE_MODE == 1)
            fprintf('Sampling period (sec): mean %.1f stdev %.1f min %.1f max %.1f\n', ...
               mean(diff(timeData)), std(diff(timeData)), ...
               min(diff(timeData)), max(diff(timeData)));
         end
         
         % compute PHASE parameter
         
         % vertical velocities in cm/s
         
         % 1- nominal case for RT data
         %          vertVel = diff(presData)*100./diff(timeData);
         
         % 2- for HD data first try: compute vertical speeds each NB_POINTS_FOR_VERTICAL_SPEED points
         %          NB_POINTS_FOR_VERTICAL_SPEED = 50;
         %          for id = 1:NB_POINTS_FOR_VERTICAL_SPEED:length(presData)-1
         %             idStart = id;
         %             idStop = min(length(presData)-1, id+NB_POINTS_FOR_VERTICAL_SPEED-1);
         %             vertVel(idStart:idStop) = (presData(idStop)-presData(idStart))*100./(timeData(idStop)-timeData(idStart));
         %          end
         
         % 3- for HD data second try: compute vertical speeds each
         % MIN_NB_SECONDS_FOR_VERTICAL_SPEED seconds
         % icicic
         MIN_NB_SECONDS_FOR_VERTICAL_SPEED = 60;
         MAX_NB_SECONDS_FOR_VERTICAL_SPEED = 5*60;
         idStart = 1;
         idStop = idStart + 1;
         stop = 0;
         vertVel = nan(length(timeData)-1, 1);
         while (~stop)
            while ((idStop <= length(timeData)) && ((timeData(idStop)-timeData(idStart)) < MIN_NB_SECONDS_FOR_VERTICAL_SPEED))
               idStop = idStop + 1;
            end
            if (idStop > length(timeData))
               idStop = idStop - 1;
            end
            if ((timeData(idStop)-timeData(idStart)) > MAX_NB_SECONDS_FOR_VERTICAL_SPEED)
               if (idStop-idStart > 1)
                  idStop = idStop - 1;
               end
            end
            %             gl_julian_2_gregorian(gl_epoch_2_julian((timeData(idStart:idStop))))
            vertVel(idStart:idStop-1) = (presData(idStop)-presData(idStart))*100./(timeData(idStop)-timeData(idStart));
            %             timeData(idStop)-timeData(idStart)
            idStart = idStop;
            idStop = idStart + 1;
            if (idStop > length(timeData))
               stop = 1;
            end
         end
         
         % find and sort the modes of the velocity dataset
         [modeNb, modeVal] = hist(vertVel, [floor(min(vertVel)):0.5:ceil(max(vertVel))]);
         [modeNb, idSort] = sort(modeNb, 'descend');
         modeVal = modeVal(idSort);
         modeNb = modeNb*100/length(vertVel);
         
         % delete the mode 0, i.e. in the [-0.5; +0.5] bin
         idDel = find(modeVal == 0);
         nbForMode0 = sum(modeNb(idDel));
         modeNb(idDel) =[];
         modeVal(idDel) =[];
         
         % compute the vertical threshold used to identify ascent and descent data
         if (~isempty(modeVal))
            % find the main modes that gathered more than
            % PART_OF_POINTS_FOR_MODE_SELECTION_PERCENT % of the data set (taking
            % into account the data of mode 0)
            idM = 1;
            while (sum(modeNb(1:idM)) < PART_OF_POINTS_FOR_MODE_SELECTION_PERCENT-nbForMode0)
               idM = idM + 1;
            end
            
            if (VERBOSE_MODE == 1)
               %                fprintf('Modes:\n');
               %                for id = 1:idM
               %                   fprintf('-> %2d : %.1f %5.1f\n', ...
               %                      id, modeVal(id),modeNb(id));
               %                end
               %                for id = idM+1:min(length(modeVal), idM+3)
               %                   fprintf('   %2d : %.1f %5.1f\n', ...
               %                      id, modeVal(id),modeNb(id));
               %                end
            end
            
            % the vertical threshold is PART_OF_MIN_MODE_FOR_THRESHOLD of the
            % minimum of the main modes
            vertVelThreshold = min(abs(modeVal(1:idM)))*PART_OF_MIN_MODE_FOR_THRESHOLD;
            
            % use the threshold to identify ascent and descent data
            idModePos = find(vertVel > vertVelThreshold);
            idModeNeg = find(vertVel < -vertVelThreshold);
            phaseData(idModePos+1) = g_decGl_phaseDescent;
            phaseData(idModeNeg+1) = g_decGl_phaseAscent;
            if (VERBOSE_MODE == 1)
               fprintf('Threshold: %.1f (cm/s)\n', vertVelThreshold);
            end
            
            % try to set the phase of the first point of the time series
            if (phaseData(2) == g_decGl_phaseDescent) && (presData(1) < presData(2))
               phaseData(1) = g_decGl_phaseDescent;
            end
            if (phaseData(2) == g_decGl_phaseAscent) && (presData(1) > presData(2))
               phaseData(1) = g_decGl_phaseAscent;
            end
         end
         
         % set to g_decGl_phaseDefault the points of too short profiles (less than
         % NB_BIN_FOR_PROFILE levels)
         [tabStart, tabStop] = gl_get_intervals(find(phaseData == g_decGl_phaseDescent));
         for id = 1:length(tabStart)
            idStart = tabStart(id);
            idStop = tabStop(id);
            if (idStop-idStart+1 < NB_BIN_FOR_PROFILE)
               phaseData(idStart:idStop) = g_decGl_phaseDefault;
            end
         end
         [tabStart, tabStop] = gl_get_intervals(find(phaseData == g_decGl_phaseAscent));
         for id = 1:length(tabStart)
            idStart = tabStart(id);
            idStop = tabStop(id);
            if (idStop-idStart+1 < NB_BIN_FOR_PROFILE)
               phaseData(idStart:idStop) = g_decGl_phaseDefault;
            end
         end
         
         % for gliders which profile in only one direction: split the data
         % according to a threshold based on the descent/ascent min duration
         
         minDur = 31536000;
         idDescent = find(phaseData == g_decGl_phaseDescent);
         nbDescent = length(idDescent);
         idAscent = find(phaseData == g_decGl_phaseAscent);
         nbAscent = length(idAscent);
         profDir = 0;
         % the glider profile in only one direction if
         % MONO_DIRECTION_PROFILE_THRESHOLD of its data are in descent or ascent
         if (((nbDescent/length(phaseData)) > MONO_DIRECTION_PROFILE_THRESHOLD) || ...
               ((nbAscent/length(phaseData)) > MONO_DIRECTION_PROFILE_THRESHOLD))
            % one direction profiling glider
            
            % compute the min duration of the ascent/descent profile
            if (nbDescent > nbAscent)
               profDir = -1;
               trans = find(diff(presData(idDescent)) < 0);
               idStart = idDescent(1);
               for id = 1:length(trans)+1
                  if (id <= length(trans))
                     idStop = idDescent(trans(id));
                  else
                     idStop = idDescent(end);
                  end
                  
                  minDur = min(minDur, timeData(idStop)-timeData(idStart));
                  
                  if (id <= length(trans))
                     idStart = idDescent(trans(id)+1);
                  end
               end
            else
               profDir = 1;
               trans = find(diff(presData(idAscent)) > 0);
               idStart = idAscent(1);
               for id = 1:length(trans)+1
                  if (id <= length(trans))
                     idStop = idAscent(trans(id));
                  else
                     idStop = idAscent(end);
                  end
                  
                  minDur = min(minDur, timeData(idStop)-timeData(idStart));
                  
                  if (id <= length(trans))
                     idStart = idAscent(trans(id)+1);
                  end
               end
            end
         end
         
         % split the data with a minDur/2 threshold
         tabStart = [];
         tabStop = [];
         trans = find(diff(timeData) > minDur/2);
         idStart = 1;
         for id = 1:length(trans)+1
            if (id <= length(trans))
               idStop = trans(id);
            else
               idStop = length(timeData);
            end
            
            tabStart = [tabStart; idStart];
            tabStop = [tabStop; idStop];
            
            if (id <= length(trans))
               idStart = trans(id)+1;
            end
         end
         
         % process the splitted data set and find the PHASE of the remaining (PHASE
         % == g_decGl_phaseDefault) measurements
         for idPart = 1:length(tabStart)
            idPartStart = tabStart(idPart);
            idPartStop = tabStop(idPart);
            phasePart = phaseData(idPartStart:idPartStop);
            pressPart = presData(idPartStart:idPartStop);
            timePart = timeData(idPartStart:idPartStop);
            
            % process only slices of measurements with the same PHASE (==
            % g_decGl_phaseDefault)
            trans = find(diff(phasePart) ~= 0);
            idStart = 1;
            for id = 1:length(trans)+1
               if (id <= length(trans))
                  idStop = trans(id);
               else
                  idStop = length(phasePart);
               end
               idList = idStart:idStop;
               
               if (phasePart(idStart) == g_decGl_phaseDefault)
                  
                  if ((idPart == 1) && (id == 1))
                     % slice which begin the time series
                     
                     % surface drift if immersion is less than
                     % THRESHOLD_PRES_FOR_SURF dbars
                     idSurf = find(abs(pressPart(idList)) < THRESHOLD_PRES_FOR_SURF);
                     if (~isempty(idSurf))
                        if (isempty(find(diff(idSurf) ~= 1, 1)) && (idList(idSurf(end)) == idList(end)))
                           phasePart(idList(idSurf)) = g_decGl_phaseSurfDrift;
                        end
                     end
                     % otherwise: inconsistant measurements if descent profile or
                     % inflexion measurement if ascent profile
                     idNoSurf = find(abs(pressPart(idList)) >= THRESHOLD_PRES_FOR_SURF);
                     if (~isempty(idNoSurf))
                        if (isempty(find(diff(idNoSurf) ~= 1, 1)) && (idList(idNoSurf(1)) == idList(1)))
                           if (profDir <= 0)
                              phasePart(idList(idNoSurf)) = g_decGl_phaseInconsistant;
                           else
                              phasePart(idList(idNoSurf)) = g_decGl_phaseInflexion;
                           end
                        end
                     end
                     
                  else
                     
                     surfDrift = 0;
                     if ((idPart == length(tabStart)) && (id == length(trans)+1))
                        % surface drift at the end of the time series
                        idSurf = find(abs(pressPart(idList)) < THRESHOLD_PRES_FOR_SURF);
                        if (~isempty(idSurf))
                           if (isempty(find(diff(idSurf) ~= 1, 1)) && (idList(idSurf(1)) == idList(1)))
                              phasePart(idList(idSurf)) = g_decGl_phaseSurfDrift;
                              surfDrift = 1;
                           end
                        end
                     end
                     
                     if (surfDrift == 0)
                        % between beginning and end slices of the time series we
                        % can have:
                        % - inflexion measurements if the duration of the slice is
                        % less than MAX_DURATION_OF_INFLEXION
                        % - surface or subsurface drift depending of the immersion
                        % criteria (THRESHOLD_PRES_FOR_SURF threshold
                        phaseDuration = (timePart(idStop)-timePart(idStart))/60;
                        if (phaseDuration <= MAX_DURATION_OF_INFLEXION)
                           phasePart(idList) = g_decGl_phaseInflexion;
                        else
                           if (isempty(find(abs(pressPart(idList)) >= THRESHOLD_PRES_FOR_SURF, 1)))
                              phasePart(idList) = g_decGl_phaseSurfDrift;
                           else
                              phasePart(idList) = g_decGl_phaseSubSurfDrift;
                           end
                        end
                     end
                     
                  end
               end
               
               if (id <= length(trans))
                  idStart = trans(id)+1;
               end
            end
            
            phaseData(idPartStart:idPartStop) = phasePart;
         end
         
         % compute PHASE_NUMBER parameter
         numPhase = 0;
         for idPart = 1:length(tabStart)
            idPartStart = tabStart(idPart);
            idPartStop = tabStop(idPart);
            phasePart = phaseData(idPartStart:idPartStop);
            pressPart = presData(idPartStart:idPartStop);
            timePart = timeData(idPartStart:idPartStop);
            phaseNumberPart = phaseNumberData(idPartStart:idPartStop);
            
            trans = find(diff(phasePart) ~= 0);
            idStart = 1;
            for id = 1:length(trans)+1
               if (id <= length(trans))
                  idStop = trans(id);
               else
                  idStop = length(phasePart);
               end
               
               if (VERBOSE_MODE == 1)
                  fprintf('Phase #%04d (%s):   %5d pts   %7.1f sec   %s   minP %7.1f dbar   maxP %7.1f dbar   time span %s - %s   ', ...
                     numPhase, gl_get_phase_name(phasePart(idStart)), ...
                     idStop-idStart+1, ...
                     timePart(idStop)-timePart(idStart), ...
                     gl_format_time2((timePart(idStop)-timePart(idStart))/3600), ...
                     min(pressPart(idStart:idStop)), max(pressPart(idStart:idStop)), ...
                     gl_julian_2_gregorian(gl_epoch_2_julian((timePart(idStart)))), ...
                     gl_julian_2_gregorian(gl_epoch_2_julian((timePart(idStop)))) ...
                     );
                  if (ismember(phasePart(idStart), [g_decGl_phaseDescent g_decGl_phaseAscent]))
                     fprintf('startP %7.1f dbar   stopP %7.1f dbar', ...
                        pressPart(idStart), pressPart(idStop));
                  end
                  fprintf('\n');
               end
               
               phaseNumberPart(idStart:idStop) = numPhase;
               numPhase = numPhase + 1;
               
               if (id <= length(trans))
                  idStart = trans(id)+1;
               end
            end
            
            phaseNumberData(idPartStart:idPartStop) = phaseNumberPart;
         end
      end
   
      % complete the final PHASE and PHASE NUMBER data
      if (~isempty(idDelInOri))
         idNotDelInOri = setdiff(1:length(phaseDataFinalMin), idDelInOri);
         phaseDataFinalMin(idNotDelInOri) = phaseData;
         phaseNumberDataFinalMin(idNotDelInOri) = phaseNumberData;

         id = length(phaseDataFinalMin)-1;
         while (id > 0)
            if (phaseDataFinalMin(id) == g_decGl_phaseDefault)
               phaseDataFinalMin(id) = phaseDataFinalMin(id+1);
               phaseNumberDataFinalMin(id) = phaseNumberDataFinalMin(id+1);
            end
            id = id - 1;
         end
      else
         phaseDataFinalMin = phaseData;
         phaseNumberDataFinalMin = phaseNumberData;
      end
   end
   
   phaseDataFinalTotal(setdiff(1:length(timeDataOri), presFillValId)) = phaseDataFinalMin;
   phaseNumberDataFinalTotal(setdiff(1:length(timeDataOri), presFillValId)) = phaseNumberDataFinalMin;
   
   % store PHASE and PHASE_NUMBER data in the netCDF file
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE'), phaseDataFinalTotal);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'), phaseNumberDataFinalTotal);
end

netcdf.close(fCdf);

return

% ------------------------------------------------------------------------------
% Retrieve the start and stop indices of the measurements of a given phase.
%
% SYNTAX :
%  [o_tabStart o_tabStop] = gl_get_intervals(a_indices)
%
% INPUT PARAMETERS :
%   a_indices : indices of the measurements of a given phase
%
% OUTPUT PARAMETERS :
%   o_tabStart : start indices
%   o_tabStop  : stop indices
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabStart, o_tabStop] = gl_get_intervals(a_indices)

o_tabStart = [];
o_tabStop = [];

if (~isempty(a_indices))
   o_tabStart = [];
   o_tabStop = [];

   idStart = a_indices(1);
   trans = find(diff(a_indices) ~= 1);
   for id = 1:length(trans)+1
      if (id <= length(trans))
         idStop = a_indices(trans(id));
      else
         idStop = a_indices(end);
      end
      %          fprintf('idStart %d idStop %d\n', idStart, idStop);
      o_tabStart = [o_tabStart; idStart];
      o_tabStop = [o_tabStop; idStop];
      if (id <= length(trans))
         idStart = a_indices(trans(id)+1);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve the phase name for a given phase code.
%
% SYNTAX :
%  [o_phaseName] = gl_get_phase_name(a_phaseVal)
%
% INPUT PARAMETERS :
%   a_phaseVal : phase code
%
% OUTPUT PARAMETERS :
%   o_phaseName : phase name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseName] = gl_get_phase_name(a_phaseVal)

global g_decGl_phaseSurfDrift;
global g_decGl_phaseDescent;
global g_decGl_phaseSubSurfDrift;
global g_decGl_phaseInflexion;
global g_decGl_phaseAscent;
global g_decGl_phaseInconsistant;
global g_decGl_phaseDefault;

o_phaseName = [];

phaseVal = unique(a_phaseVal);
if (length(phaseVal) ~= 1)
   fprintf('ERROR: many phase values!\n');
   return
end

switch phaseVal
   case g_decGl_phaseSurfDrift
      o_phaseName = 'surface drift   ';
   case g_decGl_phaseDescent
      o_phaseName = 'descent         ';
   case g_decGl_phaseSubSurfDrift
      o_phaseName = 'subsurface drift';
   case g_decGl_phaseInflexion
      o_phaseName = 'inflexion       ';
   case g_decGl_phaseAscent
      o_phaseName = 'ascent          ';
   case g_decGl_phaseInconsistant
      o_phaseName = 'inconsistant    ';
   case g_decGl_phaseDefault
      o_phaseName = 'default value   ';
   otherwise
      fprintf('Undefined name for this phase value!\n');
end

return
