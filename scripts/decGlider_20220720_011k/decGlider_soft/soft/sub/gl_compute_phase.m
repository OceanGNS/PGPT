% ------------------------------------------------------------------------------
% Compute PHASE and PHASE_NUMBER from PRES vs TIME data measured by a glider.
%
% SYNTAX :
%  [o_phaseData, o_phaseNumData] = gl_compute_phase( ...
%    a_timeData, a_presData, a_presFillVal)
%
% INPUT PARAMETERS :
%   a_timeData    : TIME data
%   a_presData    : PRES data
%   a_presFillVal : PRES fill value
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2015 - RNU - creation from gl_set_phase.m
% ------------------------------------------------------------------------------
function [o_phaseData, o_phaseNumData] = gl_compute_phase( ...
   a_timeData, a_presData, a_presFillVal)

% output data initialization
o_phaseData = [];
o_phaseNumData = [];

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
VERBOSE_MODE = 0;

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


% check data size
if (length(a_timeData) ~= length(a_presData))
   fprintf('ERROR: Time and immersion data must have the same size\n');
   return
end

% compute interpolated pressure values for all measurements
timeDataOri = a_timeData;
presDataOri = a_presData;

idPresFillVal = find(presDataOri == a_presFillVal);
if (~isempty(idPresFillVal))
   idPresOk = setdiff(1:length(presDataOri), idPresFillVal);
   if (length(idPresOk) > 1)
      presDataOri(idPresFillVal) = interp1q(timeDataOri(idPresOk), presDataOri(idPresOk), timeDataOri(idPresFillVal));
   end
end

% compute PHASE and PHASE_NUMBER parameters
presFillValId = find(presDataOri == a_presFillVal);

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
         vertVel = diff(presData)*100./diff(timeData);
         
         idDel = find(abs(vertVel) > MAX_VERTICAL_VELOCITY);
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
         vertVel = diff(presData)*100./diff(timeData);
         
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
               if (idM == length(modeNb))
                  break
               end
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
                  fprintf('Phase #%04d (%s):   %5d pts   %7.1f sec   %s   minP %7.1f dbar   maxP %7.1f dbar\n', ...
                     numPhase, gl_get_phase_name(phasePart(idStart)), ...
                     idStop-idStart+1, ...
                     timePart(idStop)-timePart(idStart), ...
                     gl_format_time2((timePart(idStop)-timePart(idStart))/3600), ...
                     min(pressPart(idStart:idStop)), max(pressPart(idStart:idStop)));
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
   
   % store PHASE and PHASE_NUMBER data in output variables
   o_phaseData = phaseDataFinalTotal;
   o_phaseNumData = phaseNumberDataFinalTotal;
end

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
