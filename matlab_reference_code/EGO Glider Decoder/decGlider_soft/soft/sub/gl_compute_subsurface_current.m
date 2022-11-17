% ------------------------------------------------------------------------------
% Compute subsurface current for a slocum glider.
% Mathlab implementation of the python code from Lucas Merckelbach
% (Lucas.Merckelbach@hzg.de).
%
% SYNTAX :
%  [o_subCurEst] = gl_compute_subsurface_current( ...
%    a_matDirPathName, a_csvFilePathName, a_printDataInCsv)
%
% INPUT PARAMETERS :
%   a_matDirPathName  : directory of the .mat files to process
%   a_csvFilePathName : file path name of the output .csv file which can be
%                       generated on demand
%   a_printDataInCsv  : print output CSV file flag
%
% OUTPUT PARAMETERS :
%   o_subCurEst : subsurface current estimates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Lucas Merckelbach (Lucas.Merckelbach@hzg.de)
%            Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/08/2013 - Lucas Merckelbach - Version 0.1
%   09/12/2014 - RNU - matlab implementation from python code
% ------------------------------------------------------------------------------
function [o_subCurEst] = gl_compute_subsurface_current( ...
   a_matDirPathName, a_csvFilePathName, a_printDataInCsv)

% output parameter initialization
o_subCurEst = [];

% if the interval between gps fixes is larger than this value, they are
% considered as seperate surfacing events.
MAX_GPS_FIX_INTERVAL_DAYS = 5/1440; % 5 minutes

% if the 75% percentile depth is larger than this value, the profile is
% considered as a proper dive.
MAX_DEPTH_CONSIDERED_AS_SURFACE_METERS = 5; % 5 meter
% MAX_DEPTH_CONSIDERED_AS_SURFACE_METERS = 1; % from Lucas Merckelbach

% all segments that are shorter than this time are not considered useful for
% water current calculations.
MIN_REQUIRED_SEGMENT_DURATION_DAYS = 20/1440; % 20 minutes
% MIN_REQUIRED_SEGMENT_DURATION_DAYS = 10/1440; % from Lucas Merckelbach

% the dive starts as soon as the observed depth is larger than this value and
% ends when there are no more depth readings larger than this value between two
% surface events.
DEPTH_CONSIDERED_AS_UNDERWATER_METERS = 1; % 1 meter

% if multiple water current calculations are reported, the one that is closest
% to this value is selected.
IDEAL_DRIFT_TIME_DAYS = 5/1440; % 5 minutes

% if the glider drifts for longer than this value, any depth averaged current
% calculations reported after this time are not considered anymore.
MAX_DRIFT_TIME_DAYS = 30/1440; % 30 minutes

DEG2M = 60*1852;

% retrieve the needed data from the .mat files
m_depth_time = [];
m_depth = [];
m_gps_time = [];
m_gps_lat = [];
m_gps_lon = [];
m_water_v_time = [];
m_water_vx = [];
m_water_vy = [];
fileInfo = dir([a_matDirPathName '*.mat']);
for idFile = 1:length(fileInfo)
   matInputFileName = fileInfo(idFile).name;
   matInputPathFileName = [a_matDirPathName matInputFileName];
   
   rawData = load(matInputPathFileName);
   rawData = rawData.rawData;
   
   if (isfield(rawData.vars_currents_time, 'm_present_time') && ...
         isfield(rawData.vars_currents_time, 'm_depth') && ...
         isfield(rawData.vars_currents_time, 'm_gps_lat') && ...
         isfield(rawData.vars_currents_time, 'm_gps_lon') && ...
         isfield(rawData.vars_currents_time, 'm_water_vx') && ...
         isfield(rawData.vars_currents_time, 'm_water_vy'))
      
      tabPresentTime = rawData.vars_currents_time.m_present_time';
      tabDepth = rawData.vars_currents_time.m_depth';
      tabGpsLat = rawData.vars_currents_time.m_gps_lat';
      tabGpsLon = rawData.vars_currents_time.m_gps_lon';
      % convert lat and lon in decimal degrees
      tabGpsLat = fix(tabGpsLat/100)+(tabGpsLat-fix(tabGpsLat/100)*100)/60;
      tabGpsLon = fix(tabGpsLon/100)+(tabGpsLon-fix(tabGpsLon/100)*100)/60;
      tabWaterVx = rawData.vars_currents_time.m_water_vx';
      tabWaterVy = rawData.vars_currents_time.m_water_vy';
      
      idOk = find(~isnan(tabPresentTime) & ~isnan(tabDepth));
      m_depth_time = [m_depth_time; tabPresentTime(idOk)];
      m_depth = [m_depth; tabDepth(idOk)];
      
      idOk = find(~isnan(tabPresentTime) & ~isnan(tabGpsLat) & ~isnan(tabGpsLon));
      m_gps_time = [m_gps_time; tabPresentTime(idOk)];
      m_gps_lat = [m_gps_lat; tabGpsLat(idOk)];
      m_gps_lon = [m_gps_lon; tabGpsLon(idOk)];
      
      idOk = find(~isnan(tabPresentTime) & ~isnan(tabWaterVx) & ~isnan(tabWaterVy));
      m_water_v_time = [m_water_v_time; tabPresentTime(idOk)];
      m_water_vx = [m_water_vx; tabWaterVx(idOk)];
      m_water_vy = [m_water_vy; tabWaterVy(idOk)];
   end
end

% chronologically sort the retrieved data
[m_depth_time, idSort] = sort(m_depth_time);
m_depth = m_depth(idSort);

[m_gps_time, idSort] = sort(m_gps_time);
m_gps_lat = m_gps_lat(idSort);
m_gps_lon = m_gps_lon(idSort);

[m_water_v_time, idSort] = sort(m_water_v_time);
m_water_vx = m_water_vx(idSort);
m_water_vy = m_water_vy(idSort);

% convert EPOCH 1970 dates to Julian 1950 dates
epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
m_depth_time = m_depth_time/86400 + epoch_offset;
m_gps_time = m_gps_time/86400 + epoch_offset;
m_water_v_time = m_water_v_time/86400 + epoch_offset;

% create surface location sets
tabLocSet = [];
% MAX_GPS_FIX_INTERVAL_DAYS threshold is used to create location sets
idSplit = find(diff(m_gps_time) > MAX_GPS_FIX_INTERVAL_DAYS);
idStart = 1;
for id = 1:length(idSplit)+1
   if (id <= length(idSplit))
      idStop = idSplit(id);
   else
      idStop = length(m_gps_time);
   end
   
   % create a new location set
   locSet = gl_get_loc_set_init_struct;
   locSet.gps_times = m_gps_time(idStart:idStop);
   locSet.gps_latitudes = m_gps_lat(idStart:idStop);
   locSet.gps_longitudes = m_gps_lon(idStart:idStop);
   locSet.time = mean(m_gps_time(idStart:idStop));
   
   tabLocSet = [tabLocSet locSet];

   idStart = idStop + 1;
end

% create dives
tabDive = [];
if (length(tabLocSet) > 1)
   
   locSet1 = tabLocSet(1);
   for idLs = 2:length(tabLocSet)
      locSet2 = tabLocSet(idLs);
   
      idF = find((m_depth_time >= mean(locSet1.gps_times)) & ...
         (m_depth_time <= mean(locSet2.gps_times)));
      if (~isempty(idF))
         % check that dive is deep enough
         depth_sorted = sort(m_depth(idF));
         idCheck = fix(length(idF)*0.75);
         if (idCheck == 0)
            idCheck = 1;
         end
         if (depth_sorted(idCheck) >= MAX_DEPTH_CONSIDERED_AS_SURFACE_METERS)
            
            %          idF2 = find(m_depth(idF) >= MAX_DEPTH_CONSIDERED_AS_SURFACE_METERS);
            %          if (length(idF2)/length(idF) >= 0.75)
            
            % check that dive is timely long enough
            if (m_depth_time(idF(end)) - m_depth_time(idF(1)) >= MIN_REQUIRED_SEGMENT_DURATION_DAYS)
               
               % set the position of the surface location set
               locSet1.lat = locSet1.gps_latitudes(end);
               locSet1.lon = locSet1.gps_longitudes(end);
               
               locSet2.lat = locSet2.gps_latitudes(1);
               locSet2.lon = locSet2.gps_longitudes(1);
               
               % create a new dive
               dive = gl_get_dive_init_struct;
               dive.dive_loc_set = locSet1;
               dive.resurface_loc_set = locSet2;
               dive.depth_times = m_depth_time(idF);
               dive.depth = m_depth(idF);
               dive.segment_duration = m_depth_time(idF(end)) - m_depth_time(idF(1));

               tabDive = [tabDive dive];
            end
         end
      end
      
      locSet1 = locSet2;
   end
   
   % set dive times
   if (~isempty(tabDive))
      
      for idD = 1:length(tabDive)
         dive = tabDive(idD);
         
         idF = find(dive.depth > DEPTH_CONSIDERED_AS_UNDERWATER_METERS);
         dive.dive_time = dive.depth_times(idF(1));
         dive.resurface_time = dive.depth_times(idF(end));
         
         tabDive(idD) = dive;
      end
   
      % compute currents
      if (length(tabDive) > 1)
         
         dive1 = tabDive(1);
         idDel = length(tabDive);
         for idD = 2:length(tabDive)
            dive2 = tabDive(idD);
            
            idF = find((m_water_v_time >= dive1.resurface_time) & ...
               (m_water_v_time <= dive2.dive_time));
            if (~isempty(idF))
               
               % select the best current estimate
               [idMax, valMax] = gl_goodness_of_estimate(dive1, m_water_v_time(idF), ...
                  IDEAL_DRIFT_TIME_DAYS, MAX_DRIFT_TIME_DAYS);
               
               if (valMax >= 0.01)
                  tabDive(idD-1).water_vx = m_water_vx(idF(idMax));
                  tabDive(idD-1).water_vy = m_water_vy(idF(idMax));
               else
                  idDel = [idDel idD-1];
               end
            else
               idDel = [idDel idD-1];
            end
            
            dive1 = dive2;
         end
         tabDive(idDel) = [];
         
         for idD = 1:length(tabDive)
            dive = tabDive(idD);

            tabDive(idD).lat = (dive.dive_loc_set.lat + dive.resurface_loc_set.lat)*0.5;
            tabDive(idD).lon = (dive.dive_loc_set.lon + dive.resurface_loc_set.lon)*0.5;
            tabDive(idD).time = (dive.dive_time + dive.resurface_time)*0.5;
            
            tabDive(idD).integration_time = (dive.resurface_time - dive.dive_time)*86400;
            tabDive(idD).mean_depth = mean(dive.depth);

            d_lat = dive.resurface_loc_set.lat - dive.dive_loc_set.lat;
            d_lon = dive.resurface_loc_set.lon - dive.dive_loc_set.lon;
            y_dist = d_lat*DEG2M;
            x_dist = d_lon*DEG2M*cosd(tabDive(idD).lat);
            tabDive(idD).glider_speed = sqrt(x_dist^2 + y_dist^2)/tabDive(idD).integration_time;
            tabDive(idD).glider_direction = 90 - atan2d(y_dist, x_dist);

            % to account for the effect of the angle of attack in the
            % calculation of the horizontal speed.
            % BEGIN
            %             du = cosd(tabDive(idD).glider_direction)*0.06;
            %             dv = sind(tabDive(idD).glider_direction)*0.06;
            %             tabDive(idD).water_vx = tabDive(idD).water_vx - du;
            %             tabDive(idD).water_vy = tabDive(idD).water_vy - dv;
            % END
            
            dive = tabDive(idD);

            tabDive(idD).speed = sqrt(dive.water_vx^2 + dive.water_vy^2);
            tabDive(idD).direction = 90 - atan2d(dive.water_vy, dive.water_vx);
            tabDive(idD).east_current = dive.water_vx;
            tabDive(idD).north_current = dive.water_vy;

         end
         
         if (a_printDataInCsv)
            gl_print_subsurface_current_in_csv(tabDive, a_csvFilePathName);
         end
      else
         tabDive = [];
      end
   end
end

o_subCurEst = tabDive;

return

% ------------------------------------------------------------------------------
% print subsurface current information in a .csv file.
%
% SYNTAX :
%  gl_print_subsurface_current_in_csv(a_subCurEst, a_csvFilePathName)
%
% INPUT PARAMETERS :
%   a_subCurEst       : subsurface current information
%   a_csvFilePathName : file path name of the output .csv file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/12/2014 - RNU - matlab implementation from python code
% ------------------------------------------------------------------------------
function gl_print_subsurface_current_in_csv(a_subCurEst, a_csvFilePathName)

% create the CSV output file
fidOut = fopen(a_csvFilePathName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: cannot create file %s\n', a_csvFilePathName);
   return
end

header = ['Dive #; Date; Lon; Lat; Mean depth (m); Speed (m/s); Direction; ' ...
   'Dive date; Resurface date; Dive East cur. (m/s); Dive North cur. (m/s); Dive integ. time; Glider speed (m/s); Glider dir.; Segment duration (s)'];
fprintf(fidOut, '%s\n', header);

for idD = 1:length(a_subCurEst)
   dive = a_subCurEst(idD);

   fprintf(fidOut, '%d; %s; %f; %f; %f; %f; %f; %s; %s; %f; %f; %s; %f; %f; %s\n', ...
      idD, ...
      gl_julian_2_gregorian(dive.time), dive.lon, dive.lat, dive.mean_depth, ...
      dive.speed, dive.direction, ...
      gl_julian_2_gregorian(dive.dive_time), gl_julian_2_gregorian(dive.resurface_time), ...
      dive.east_current, dive.north_current, format_time_current(dive.integration_time/3600), dive.glider_speed, dive.glider_direction, ...
      format_time_current(dive.segment_duration*24));
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Returns the goodness of the water current estimate, defined as a number
% between 0 and 1, 1 being good.
% The goodness is determined from the function
% 
%             f = e/tau*exp(-t_drift/tau)
% 
%             where e = 2.72... 
%                   tau = ideal drift time
%                   t_drift actual drift time
%
% SYNTAX :
%  [o_idMax, o_valMax] = gl_goodness_of_estimate(a_dive, a_waterVTimes, ...
%    a_idealDriftTime, a_maxDriftTime)
%
% INPUT PARAMETERS :
%   a_dive           : dive
%   a_waterVTimes    : times of the Vx and Vy glider data asociated to the dive
%   a_idealDriftTime : ideal drift time (see IDEAL_DRIFT_TIME_DAYS)
%   a_maxDriftTime   : max drift time (see MAX_DRIFT_TIME_DAYS)
%
% OUTPUT PARAMETERS :
%   o_idMax  : id of the max goodness
%   o_valMax : value of the max goodness
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Lucas Merckelbach (Lucas.Merckelbach@hzg.de)
%            Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/08/2013 - Lucas Merckelbach - Version 0.1
%   09/12/2014 - RNU - matlab implementation from python code
% ------------------------------------------------------------------------------
function [o_idMax, o_valMax] = gl_goodness_of_estimate(a_dive, a_waterVTimes, ...
   a_idealDriftTime, a_maxDriftTime)

driftTimes = a_waterVTimes - a_dive.resurface_time;
f = exp(1)/a_idealDriftTime*driftTimes.*exp(-driftTimes/a_idealDriftTime);
f0 = exp(1)/a_idealDriftTime*a_maxDriftTime*exp(-a_maxDriftTime/a_idealDriftTime);

values = f - driftTimes/a_maxDriftTime*f0;

[o_valMax, o_idMax] = max(values);

return

% ------------------------------------------------------------------------------
% Get the basic structure to store a set of surface locations.
%
% SYNTAX :
%  [o_locSetStruct] = gl_get_loc_set_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_locSetStruct : surface location set initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/12/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_locSetStruct] = gl_get_loc_set_init_struct

o_locSetStruct = struct( ...
   'gps_times', '', ...
   'gps_latitudes', '', ...
   'gps_longitudes', '', ...
   'time', '', ...
   'lat', '', ...
   'lon', '');

return

% ------------------------------------------------------------------------------
% Get the basic structure to store dive information.
%
% SYNTAX :
%  [o_diveStruct] = gl_get_dive_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_diveStruct : dive initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/12/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_diveStruct] = gl_get_dive_init_struct

o_diveStruct = struct( ...
   'dive_loc_set', '', ...
   'resurface_loc_set', '', ...
   'depth_times', '', ...
   'depth', '', ...
   'dive_time', '', ...
   'resurface_time', '', ...
   'water_vx', '', ...
   'water_vy', '', ...
   'lat', '', ...
   'lon', '', ...
   'time', '', ...
   'speed', '', ...
   'direction', '', ...
   'east_current', '', ...
   'north_current', '', ...
   'integration_time', '', ...
   'mean_depth', '', ...
   'glider_speed', '', ...
   'glider_direction', '', ...
   'segment_duration', '');

return

% ------------------------------------------------------------------------------
% Formatage d'une information horaire.
%
% SYNTAX :
%   format_time_current(a_time)
%
% INPUT PARAMETERS :
%   a_time : heure décimale
%
% OUTPUT PARAMETERS :
%   o_time : heure formatée
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/07/2008 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time_current(a_time)

if (a_time >= 0)
   sign = '+';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);

return
