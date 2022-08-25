% ------------------------------------------------------------------------------
% This decodes slocum data from a single yo .m and .dat text format and places
% it in a matlab structure for subsequent conversion to EGO netcdf format
% by EGO routines.
%
% SYNTAX :
%  [o_matFileCreated] = gl_decode_slocum_dat( ...
%    a_mVectorFileNameIn, a_matFileNameOut, a_computeCurrents)
%
% INPUT PARAMETERS :
%   a_mVectorFileNameIn     : name of the .m file from a yo
%   a_matFileNameOut  : name of the output .mat file containing the structure
%   a_computeCurrents : compute subsurface currents from slocum glider data
%
% OUTPUT PARAMETERS :
%   o_matFileCreated : output created .mat file flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_matFileCreated] = gl_decode_slocum_dat( ...
   a_mVectorFileNameIn, a_mSensorFileNameIn, a_matFileNameOut, a_computeCurrents)

% output parameter initialization
o_matFileCreated = 0;

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_egoVarName;
global g_decGl_gliderVarPathName;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;

% QC flag values
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;


% check if the file exists
if (~exist(a_mVectorFileNameIn, 'file'))
   fprintf('ERROR: File not found : %s\n', a_mVectorFileNameIn);
   return
end

% initialize output structure variable
rawData = struct( ...
   'source_vector', {a_mVectorFileNameIn}, ...
   'source_sensor', {a_mSensorFileNameIn}, ...
   'vars_time_gps', struct('latitude', [], 'longitude', [], 'time', []), ...
   'vars_m_time', [], ...
   'vars_sci_time', [] ...
   );

if (isempty(a_mSensorFileNameIn))
   fileList = {a_mVectorFileNameIn};
else
   fileList = [{a_mVectorFileNameIn} {a_mSensorFileNameIn}];
end

for idFile = 1:length(fileList)

   fileToProcess = fileList{idFile};

   % read segment data
   currentSegmentData = gl_slocum_read_data(fileToProcess);

   % BE CAREFUL: for slocum glider, we should not consider the case of the JSON
   % links to EGO variable (i.e. glider parameter name specified in the JSON file
   % may not have the same name in the .m file, the case may differ)
   g_decGl_gliderVarName = lower(g_decGl_gliderVarName);
   fNames = fieldnames(currentSegmentData);
   for id = 1:length(fNames)
      if (~strcmp(fNames{id}, lower(fNames{id})))
         currentSegmentData.(lower(fNames{id})) = currentSegmentData.(fNames{id});
         currentSegmentData = rmfield(currentSegmentData, fNames{id});
      end
   end

   % fill output structure variable
   missingParam = [];
   fieldsToDismiss = {'data'};
   fNames = setdiff(fieldnames(currentSegmentData), fieldsToDismiss);

   data = currentSegmentData.data;
   for id = 1:length(fNames)
      fName = fNames{id};
      if (size(data, 2) >= currentSegmentData.(fName))
         idFUs = strfind(fName, '_');
         rawData.(['vars_' (fName(1:idFUs(1)-1)) '_time']).(fName) = data(:, currentSegmentData.(fName))';
      else
         missingParam{end+1} = fName;
      end
   end
   if (~isempty(missingParam))
      paramList = sprintf(' %s,', missingParam{:});
      fprintf('WARNING: Data are missing in file %s for parameters:%s\n', ...
         fileToProcess, paramList(1:end-1));
   end
end

% vars_m_time and vars_sci_time data should have the same dimension
if (length(fileList) > 1)
   if (isfield(rawData.vars_m_time, 'm_present_time') && ...
         isfield(rawData.vars_sci_time, 'sci_m_present_time'))

      mTime = round(rawData.vars_m_time.m_present_time);
      sciTime = round(rawData.vars_sci_time.sci_m_present_time);
      timeAll = unique([mTime sciTime]);

      mTimeId = [];
      for id = 1:length(mTime)
         idF = find(timeAll == mTime(id));
         mTimeId = [mTimeId idF];
      end

      mTimeData = nan(length(fieldnames(rawData.vars_m_time)), length(timeAll));
      mTimeLabels = fieldnames(rawData.vars_m_time);
      for idF = 1:length(mTimeLabels)
         if (strcmp(mTimeLabels{idF}, 'm_present_time'))
            mTimeData(idF, :) = timeAll';
         else
            mTimeData(idF, mTimeId) = rawData.vars_m_time.(mTimeLabels{idF});
         end
      end

      for idF = 1:length(mTimeLabels)
         rawData.vars_m_time.(mTimeLabels{idF}) = mTimeData(idF, :);
      end

      sciTimeId = [];
      for id = 1:length(sciTime)
         idF = find(timeAll == sciTime(id));
         sciTimeId = [sciTimeId idF];
      end

      sciTimeData = nan(length(fieldnames(rawData.vars_sci_time)), length(timeAll));
      sciTimeLabels = fieldnames(rawData.vars_sci_time);
      for idF = 1:length(sciTimeLabels)
         if (strcmp(sciTimeLabels{idF}, 'sci_m_present_time'))
            sciTimeData(idF, sciTimeId) = sciTime';
         else
            sciTimeData(idF, sciTimeId) = rawData.vars_sci_time.(sciTimeLabels{idF});
         end
      end

      for idF = 1:length(sciTimeLabels)
         rawData.vars_sci_time.(sciTimeLabels{idF}) = sciTimeData(idF, :);
      end
   end
end

% preserve data used to estimate subsurface currents in a dedicated field
% ('vars_currents_time')
% this is needed because used measurements will be cleaned (see below) and thus,
% some of the data needed to process currents may not have the same length
if (a_computeCurrents == 1)
   rawData.vars_currents_time = [];
   if (isfield(rawData.vars_m_time, 'm_present_time') && ...
         isfield(rawData.vars_m_time, 'm_depth') && ...
         isfield(rawData.vars_m_time, 'm_gps_lat') && ...
         isfield(rawData.vars_m_time, 'm_gps_lon') && ...
         isfield(rawData.vars_m_time, 'm_water_vx') && ...
         isfield(rawData.vars_m_time, 'm_water_vy'))
      rawData.vars_currents_time.m_present_time = rawData.vars_m_time.m_present_time;
      rawData.vars_currents_time.m_depth = rawData.vars_m_time.m_depth;
      rawData.vars_currents_time.m_gps_lat = rawData.vars_m_time.m_gps_lat;
      rawData.vars_currents_time.m_gps_lon = rawData.vars_m_time.m_gps_lon;
      rawData.vars_currents_time.m_water_vx = rawData.vars_m_time.m_water_vx;
      rawData.vars_currents_time.m_water_vy = rawData.vars_m_time.m_water_vy;
   end
end

% extract GPS locations and store them in 'vars_time_gps' field
if (isfield(rawData.vars_m_time, 'm_present_time') && ...
      isfield(rawData.vars_m_time, 'm_gps_lat') && ...
      isfield(rawData.vars_m_time, 'm_gps_lon'))
   
   lat = rawData.vars_m_time.m_gps_lat;
   lon = rawData.vars_m_time.m_gps_lon;
   date = rawData.vars_m_time.m_present_time;
   idNan = find(isnan(lat) | isnan(lon));
   lat(idNan) = [];
   lon(idNan) = [];
   date(idNan) = [];
   
   % convert lat and lon in decimal degrees
   lat = fix(lat/100)+(lat-fix(lat/100)*100)/60;
   lon = fix(lon/100)+(lon-fix(lon/100)*100)/60;

   rawData.vars_time_gps.latitude = lat;
   rawData.vars_time_gps.longitude = lon;

   rawData.vars_time_gps.time = date;
end

% convert LATITUDE and LONGITUDE coordinate variables in decimal degrees

% find the glider variable names for LATITUDE and LONGITUDE
latGliderVarName = g_decGl_gliderVarPathName{find(strcmp(g_decGl_egoVarName, 'LATITUDE'))};
lonGliderVarName = g_decGl_gliderVarPathName{find(strcmp(g_decGl_egoVarName, 'LONGITUDE'))};

% retrieve and convert lat and lon
if (~isempty(latGliderVarName) && ~isempty(lonGliderVarName))
   
   latitude = [];
   longitude = [];
   if (gl_is_field_recursive(rawData, latGliderVarName))
      eval(['latitude = rawData.' latGliderVarName ';']);
   end
   if (gl_is_field_recursive(rawData, lonGliderVarName))
      eval(['longitude = rawData.' lonGliderVarName ';']);
   end
   
   if (~isempty(latitude) && ~isempty(longitude))
      
      % be sure that latitude and longitude are provided for the same index
      % see ifm03_2011_098_0_10_sbd.dat file of "ifm03_depl07" deployment for
      % such error
      idDel = find((isnan(latitude) & ~isnan(longitude)) | (~isnan(latitude) & isnan(longitude)));
      if (~isempty(idDel))
         fprintf('WARNING: %d lat/lon without associated lat/lon in %s => locations ignored\n', ...
            length(idDel)/2, a_mVectorFileNameIn);
         latitude(idDel) = nan;
         longitude(idDel) = nan;
      end
      
      % convert lat and lon in decimal degrees
      latitude = fix(latitude/100)+(latitude-fix(latitude/100)*100)/60;
      longitude = fix(longitude/100)+(longitude-fix(longitude/100)*100)/60;
      
      eval(['rawData.' latGliderVarName ' = latitude;']);
      eval(['rawData.' lonGliderVarName ' = longitude;']);
   end
end

% clean measurements (delete timestamps when all measurements = Nan)
excludedEgoVarList = [{'TIME_GPS'} {'LATITUDE_GPS'} {'LONGITUDE_GPS'}];
dataAll = [];
for idV = 1:length(g_decGl_egoVarName)
   if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
         ~strcmp(g_decGl_egoVarName{idV}, 'TIME') && ...
         ~isempty(g_decGl_gliderVarPathName{idV}))
      if (gl_is_field_recursive(rawData, g_decGl_gliderVarPathName{idV}))
         eval(['data = rawData.' g_decGl_gliderVarPathName{idV} ';']);
         dataAll = [dataAll; data];
      end
   end
end
idDel = find(sum(isnan(dataAll), 1) == size(dataAll, 1));
if (~isempty(idDel))
   for idV = 1:length(g_decGl_egoVarName)
      if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
            ~isempty(g_decGl_gliderVarPathName{idV}))
         if (gl_is_field_recursive(rawData, g_decGl_gliderVarPathName{idV}))
            eval(['data = rawData.' g_decGl_gliderVarPathName{idV} ';']);
            data(idDel) = [];
            eval(['rawData.' g_decGl_gliderVarPathName{idV} ' = data;']);
         end
      end
   end
end

% delete timely duplicated measurements
timeGliderVarName = g_decGl_gliderVarPathName{find(strcmp(g_decGl_egoVarName, 'TIME'))};
time = [];
if (gl_is_field_recursive(rawData, timeGliderVarName))
   eval(['time = rawData.' timeGliderVarName ';']);
end
if (~isempty(find(diff(time) == 0, 1)))
   idDel = find(diff(time) == 0);
   for idV = 1:length(g_decGl_egoVarName)
      if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
            ~isempty(g_decGl_gliderVarPathName{idV}))
         if (gl_is_field_recursive(rawData, g_decGl_gliderVarPathName{idV}))
            eval(['data = rawData.' g_decGl_gliderVarPathName{idV} ';']);
            data(idDel) = [];
            eval(['rawData.' g_decGl_gliderVarPathName{idV} ' = data;']);
         end
      end
   end
   fprintf('WARNING: Duplicated times in %s => deleted data: ', a_mVectorFileNameIn);
   fprintf('#%d ', idDel);
   fprintf('\n');
end

% - convert PRES in dbar => PRES are provided in bars !
% - interpolate PRES measurements for all timestamps => needed for PHASE processing

% find the glider variable names for TIME, PRES and PRES
timeGliderVarName = g_decGl_gliderVarPathName{find(strcmp(g_decGl_egoVarName, 'TIME'))};
presGliderVarName = [];
idF = find(strcmp(g_decGl_egoVarName, 'PRES'));
if (~isempty(idF))
   presGliderVarName = g_decGl_gliderVarPathName{idF};
end
presQcGliderVarName = [];
idF = find(strcmp(g_decGl_egoVarName, 'PRES_QC'));
if (~isempty(idF))
   presQcGliderVarName = g_decGl_gliderVarPathName{idF};
end

% convert and interpolate PRES measurements
if (~isempty(timeGliderVarName) && ~isempty(presGliderVarName))
   
   time = [];
   pres = [];
   if (gl_is_field_recursive(rawData, timeGliderVarName))
      eval(['time = rawData.' timeGliderVarName ';']);
   end
   if (gl_is_field_recursive(rawData, presGliderVarName))
      eval(['pres = rawData.' presGliderVarName ';']);
   end
   
   if (~isempty(time) && ~isempty(pres))
      
      pres = pres*10; % 2015/04/16: sci_water_pressure is in bars !
      pres_qc = zeros(1, length(pres));
      
      idNan = find(isnan(pres));
      if (~isempty(idNan))
         idNotNan = setdiff(1:length(pres), idNan);
         if (length(idNotNan) > 1)
            pres(idNan) = interp1q(time(idNotNan)', pres(idNotNan)', time(idNan)')';
            pres_qc(idNan) = g_decGl_qcInterpolated;
            pres_qc(find(isnan(pres))) = g_decGl_qcMissing;
         end
      end
      
      eval(['rawData.' presGliderVarName ' = pres;']);
      if (~isempty(presQcGliderVarName))
         eval(['rawData.' presQcGliderVarName ' = pres_qc;']);
      else
         rawData.vars_sci_time.PRES_QC = pres_qc;
         g_decGl_directEgoVarName{end+1} = 'vars_sci_time.PRES_QC';
      end
   end
end

% compute and add derived parameters
rawData = gl_add_derived_parameters(rawData);

% save the structure as a .mat file
save(a_matFileNameOut, 'rawData');
o_matFileCreated = 1;

return
