% ------------------------------------------------------------------------------
% Read a 'gli' or 'pl1' file from a sea explorer and store the data in a matlab
% structure.
% 
% SYNTAX :
%  [o_matFileCreated] = gl_decode_seaexplorer( ...
%    a_fileNameIn, a_matFileNameOut, a_gzFileFlag, a_lastFileFlag)
% 
% INPUT PARAMETERS :
%   a_fileNameIn   : name of the 'gli' or 'pl1' file of data
%   a_matFileNameOut : name of the output .mat file containing the structure
%   a_gzFileFlag     : 1 if it is a .gz file, 0 otherwise
%   a_lastFileFlag   : 1 if it is the last file of the Yo, 0 otherwise
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
%   09/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_matFileCreated] = gl_decode_seaexplorer( ...
   a_fileNameIn, a_matFileNameOut, a_gzFileFlag, a_lastFileFlag)

% output parameter initialization
o_matFileCreated = 0;

% sea Explorer GPS locations
global g_decGl_seaExplorerGpsData;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_egoVarName;
global g_decGl_gliderVarPathName;

% QC flag values
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;


% check if the file exists
if (~exist(a_fileNameIn, 'file'))
   fprintf('ERROR: File not found : %s\n', a_fileNameIn);
   return
end

% file type = 0 if gli file, 1 if pl1 file, 2 if pld1 raw
[~, inputFileName, ~] = fileparts(a_fileNameIn) ;
if (contains(inputFileName, '.gli.'))
   fileType = 0;
elseif (contains(inputFileName, '.pld1.raw'))
   fileType = 2;
elseif (contains(inputFileName, '.pl1.') || contains(inputFileName, '.pld1.'))
   fileType = 1;
end

% the data are stored in 2 files (gli and pl1) but we will save only one .mat
% file
[pathMatFileNameOut, matFileNameOut, ext] = fileparts(a_matFileNameOut) ;
if (fileType == 0)
   matFileNameOut = regexprep(matFileNameOut, '.gli.sub', '');
   matFileNameOut = regexprep(matFileNameOut, '.gli', '');
elseif (fileType == 1)
   matFileNameOut = regexprep(matFileNameOut, '.pld1.sub', '');
   matFileNameOut = regexprep(matFileNameOut, '.pl1', '');
else
   matFileNameOut = regexprep(matFileNameOut, '.pld1.raw', '');
end
a_matFileNameOut = [pathMatFileNameOut '/' matFileNameOut ext];

if (a_gzFileFlag == 1)
   % unziped the 2 files in the 'tmp' directory
   [pathZipFileName, fileName, ext] = fileparts(a_fileNameIn) ;
   filePathName = regexprep(pathZipFileName, '/gz', '/tmp');
   gunzip(a_fileNameIn, filePathName);
   movefile([filePathName '/' fileName], [filePathName '/' fileName '.csv']);
   inputFileName = [fileName '.csv'];
   inputPathFileName = [filePathName '/' inputFileName];
else
   inputPathFileName = a_fileNameIn;
end

% initialize output structure variable
if (~exist(a_matFileNameOut, 'dir') && exist(a_matFileNameOut, 'file'))
   rawData = load(a_matFileNameOut);
   rawData = rawData.rawData;
else
   rawData = struct( ...
      'source_gli', '', ...
      'source_pld1', '', ...
      'vars_m_time', [], ...
      'vars_sci_time', [], ...
      'vars_misc', [], ...
      'vars_time_gps', struct('latitude', [], 'longitude', [], 'time', []));
end
if (fileType == 0)
   rawData.source_gli = a_fileNameIn;
else
   rawData.source_pld1 = a_fileNameIn;
end

% find the glider variable names for the TIME, LATITUDE and LONGITUDE
latGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'LATITUDE'))};
lonGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'LONGITUDE'))};

dataStruct = gl_read_seaexplorer_csv(inputPathFileName);
infoName = fieldnames(dataStruct);
if (fileType == 0)
   
   % store the 'gli' file data in the data structure ('vars_m_time' field)
   for idF = 1:length(infoName)
      if ((strcmp(infoName{idF}, 'Lat')) || (strcmp(infoName{idF}, 'Lon')))
         
         % convert lat and lon in decimal degrees
         data = dataStruct.(infoName{idF});
         data = fix(data/100)+(data-fix(data/100)*100)/60;
         
         rawData.vars_m_time.(infoName{idF}) = data;
         
      else
         rawData.vars_m_time.(infoName{idF}) = dataStruct.(infoName{idF});
      end
   end
   
else
   
   % store the 'pld1' file data in the data structure (vars_sci_time field)
   for idF = 1:length(infoName)

      % replace supposed fill value (9999) with nan
      data = dataStruct.(infoName{idF});
      data(data == 9999) = nan;

      % store data
      if (((strcmp(infoName{idF}, 'NAV_LATITUDE')) || (strcmp(infoName{idF}, 'NAV_LONGITUDE'))) || ...
            ((strcmp(infoName{idF}, latGliderVarName)) || (strcmp(infoName{idF}, lonGliderVarName))))
         
         % convert lat and lon in decimal degrees
         data = fix(data/100)+(data-fix(data/100)*100)/60;
         
         rawData.vars_sci_time.(infoName{idF}) = data;
         
      else
         rawData.vars_sci_time.(infoName{idF}) = data;
      end
   end
end

if (a_lastFileFlag)
   
   % extract the GPS locations from 'gli' file
   lat1 = [];
   lon1 = [];
   date1 = [];
   if (isfield(rawData.vars_m_time, 'Timestamp') && ...
         isfield(rawData.vars_m_time, 'Lat') && ...
         isfield(rawData.vars_m_time, 'Lon') && ...
         isfield(rawData.vars_m_time, 'NavState'))
      
      state = rawData.vars_m_time.NavState;
      idGps = find(state == 116);
      
      lat1 = rawData.vars_m_time.Lat(idGps);
      lon1 = rawData.vars_m_time.Lon(idGps);
      date1 = rawData.vars_m_time.Timestamp(idGps);
   else
      if (fileType ~= 2)
         fprintf('WARNING: ''Timestamp'', ''Lat'', ''Lon'', ''NavState'' information are expected in ''gli'' files to seclect GPS locations\n');
      end
   end
   
   lat2 = [];
   lon2 = [];
   date2 = [];
   if (isfield(rawData.vars_sci_time, 'PLD_REALTIMECLOCK') && ...
         isfield(rawData.vars_sci_time, 'NAV_LATITUDE') && ...
         isfield(rawData.vars_sci_time, 'NAV_LONGITUDE') && ...
         isfield(rawData.vars_sci_time, 'NAV_RESOURCE'))
      
      state = rawData.vars_sci_time.NAV_RESOURCE;
      idGps = find(state == 116);
      
      lat2 = rawData.vars_sci_time.NAV_LATITUDE(idGps);
      lon2 = rawData.vars_sci_time.NAV_LONGITUDE(idGps);
      date2 = rawData.vars_sci_time.PLD_REALTIMECLOCK(idGps);
   else
      fprintf('WARNING: ''PLD_REALTIMECLOCK'', ''NAV_LATITUDE'', ''NAV_LONGITUDE'', ''NAV_RESOURCE'' information are expected in ''pld1'' files to seclect GPS locations\n');
   end
   
   lat = [lat1 lat2];
   lon = [lon1 lon2];
   date = [date1 date2];

   % remove (lat, lon) = (0, 0) locations
   idDel = find((lat == 0) & (lon == 0));
   lat(idDel) = [];
   lon(idDel) = [];
   date(idDel) = [];

   % store all GPS locations
   if (~isempty(g_decGl_seaExplorerGpsData))
      lat = [lat g_decGl_seaExplorerGpsData.lat];
      lon = [lon g_decGl_seaExplorerGpsData.lon];
      date = [date g_decGl_seaExplorerGpsData.date];
   end
   
   latBis = fix(lat*1000)/1000;
   lonBis = fix(lon*1000)/1000;
   
   [~, idPos, ~] = unique([lonBis' latBis'], 'rows');
   
   [~, idSorted] = sort(date(idPos));
   
   g_decGl_seaExplorerGpsData = struct( ...
      'lat', lat(idPos(idSorted)), ...
      'lon', lon(idPos(idSorted)), ...
      'date', date(idPos(idSorted)));

   %    [~, idUnique, ~] = unique(round(date));
   %
   %    g_decGl_seaExplorerGpsData = struct( ...
   %       'lat', lat(idUnique), ...
   %       'lon', lon(idUnique), ...
   %       'date', date(idUnique));
   
   % store GPS locations to the current file
   fileDates = [];
   if (isfield(rawData.vars_m_time, 'Timestamp'))
      fileDates = [fileDates rawData.vars_m_time.Timestamp];
   end
   if (isfield(rawData.vars_sci_time, 'PLD_REALTIMECLOCK'))
      fileDates = [fileDates rawData.vars_sci_time.PLD_REALTIMECLOCK];
   end
   
   gpsDates = g_decGl_seaExplorerGpsData.date;
   idDates = find((gpsDates >= min(fileDates)) & (gpsDates <= max(fileDates)));
   
   % store GPS data for the current file
   rawData.vars_time_gps.latitude = g_decGl_seaExplorerGpsData.lat(idDates);
   rawData.vars_time_gps.longitude = g_decGl_seaExplorerGpsData.lon(idDates);
   rawData.vars_time_gps.time = g_decGl_seaExplorerGpsData.date(idDates);   
   
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
      fprintf('WARNING: Duplicated times in %s => deleted data: ', a_mFileNameIn);
      fprintf('#%d ', idDel);
      fprintf('\n');
   end
   
   % interpolate PRES measurements for all timestamps => needed for PHASE processing
   
   % find the glider variable names for TIME, PRES and PRES_QC
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
   
end

% save the structure as a .mat file
save(a_matFileNameOut,'rawData');
o_matFileCreated = 1;

end
