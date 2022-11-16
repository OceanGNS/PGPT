% ------------------------------------------------------------------------------
% Generate KML (in fact KMZ) file from an EGO NetCDF file (and, if associated
% profiles exist, a second KMZ file with profiles locations).
%
% SYNTAX :
%   nc_ego_2_kml(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DATA_DIRECTORY directory) to process. If 'data' argument is not
%               set, all the deployments of the DATA_DIRECTORY are processed.
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_2_kml(varargin)

% input top directory of the deployments
DATA_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\data_processing\new_20150924/';
DATA_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\data_processing\RTQC/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\generated_deployments/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY\FORMAT_1.4/';
% DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\SOCIB_20210707/';

% output log file directory
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';

% output KML (KMZ) file directory
KML_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';

% base directory of glider data (i.e. containing one directory for each glider
% deployment)
global g_decGl_inputDataTopDir;
g_decGl_inputDataTopDir = DATA_DIRECTORY;

% process the data of a given deployment
global g_decGl_dataToProcessDir;
g_decGl_dataToProcessDir = [];

% default values initialization
gl_init_default_values;


% create log file
logFile = [LOG_DIRECTORY '/' 'nc_ego_2_kml_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmp(lower(varargin{id}), 'data'))
            if (exist([DATA_DIRECTORY '/' varargin{id+1}], 'dir'))
               g_decGl_dataToProcessDir = [DATA_DIRECTORY '/' varargin{id+1}];
            else
               fprintf('WARNING: %s is not an existing directory => ignored\n', varargin{id+1});
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
end

% print the arguments understanding
if (isempty(g_decGl_dataToProcessDir))
   fprintf('INFO: convert all the deployment nc files of the %s top-directory\n', g_decGl_inputDataTopDir);
else
   fprintf('INFO: convert the deployment nc file stored in the %s directory\n', g_decGl_dataToProcessDir);
end

% process glider data
if (isempty(g_decGl_dataToProcessDir))
   % convert all the deployments of the DATA_DIRECTORY directory
   dirInfo = dir(g_decGl_inputDataTopDir);
   for dirNum = 1:length(dirInfo)
      if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
         dirName = dirInfo(dirNum).name;
         
         % convert the data of this deployment
         nc_ego_2_kml_for_deployment([g_decGl_inputDataTopDir '/' dirName '/'], KML_DIRECTORY);
      end
   end
elseif (~isempty(g_decGl_dataToProcessDir))
   % convert the data of this deployment
   nc_ego_2_kml_for_deployment(g_decGl_dataToProcessDir, KML_DIRECTORY);
end

diary off;

return

% ------------------------------------------------------------------------------
% Generate KML (in fact KMZ) file from one EGO NetCDF file (and, if associated
% profiles exist, a second KMZ file with profiles locations).
%
% SYNTAX :
%  nc_ego_2_kml_for_deployment(a_deploymentDirName, a_outputKmlDirName)
%
% INPUT PARAMETERS :
%   a_deploymentDirName : directory of the deployment
%   a_outputKmlDirName  : directory of the output KMZ file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_2_kml_for_deployment(a_deploymentDirName, a_outputKmlDirName)

dirNcFiles = dir([a_deploymentDirName '/*.nc']);
for idFile = 1:length(dirNcFiles)
   
   ncFile = dirNcFiles(idFile).name;
   fprintf('Converting file: %s\n', ncFile);
   ncFilePathName = [a_deploymentDirName '/' ncFile];
   nc_ego_2_kml_for_deployment_file(ncFilePathName, a_outputKmlDirName);
end

profileDirName = [a_deploymentDirName '/profiles/'];
if (exist(profileDirName, 'dir') == 7)
   nc_ego_2_kml_for_deployment_profile_files(profileDirName, ncFilePathName, a_outputKmlDirName);
end

return

% ------------------------------------------------------------------------------
% Generate KML (in fact KMZ) file from one EGO NetCDF file.
%
% SYNTAX :
%  nc_ego_2_kml_for_deployment_file(a_deploymentFilePathName, a_outputKmlDirName)
%
% INPUT PARAMETERS :
%   a_deploymentFilePathName : file of the deployment
%   a_outputKmlDirName       : directory of the output KMZ file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_2_kml_for_deployment_file(a_deploymentFilePathName, a_outputKmlDirName)

% julian 1950 to gregorian date offset
referenceDateStr = '1950-01-01 00:00:00';
referenceDate = datenum(referenceDateStr, 'yyyy-mm-dd HH:MM:SS');

% PHASE codes
global g_decGl_phaseSurfDrift;
global g_decGl_phaseDescent;
global g_decGl_phaseSubSurfDrift;
global g_decGl_phaseInflexion;
global g_decGl_phaseAscent;
global g_decGl_phaseGrounded;
global g_decGl_phaseInconsistant;


% time threshold to use GPS fixes or interpolated (at each time stamp) fixes for
% profile location
MAX_NB_HOURS_TO_USE_GPS_LOC = 1;


% retrieve the data of the EGO NetCDF file
wantedVars = [ ...
   {'TIME_GPS'} ...
   {'LATITUDE_GPS'} ...
   {'LONGITUDE_GPS'} ...
   {'TIME'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'PHASE'} ...
   {'PHASE_NUMBER'}
   ];
[ncData] = gl_get_data_from_nc_file(a_deploymentFilePathName, wantedVars);

idVal = find(strcmp('TIME_GPS', ncData) == 1, 1);
timeGps = ncData{idVal+1};
% convert time (EPOCH 1970) to Julian Day 1950
epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
juldGps = timeGps/86400 + epoch_offset;
idVal = find(strcmp('LATITUDE_GPS', ncData) == 1, 1);
latitudeGps = ncData{idVal+1};
idVal = find(strcmp('LONGITUDE_GPS', ncData) == 1, 1);
longitudeGps = ncData{idVal+1};

idBad = find((juldGps == 999999) | (latitudeGps == 99999) | (longitudeGps == 99999));
juldGps(idBad) = [];
latitudeGps(idBad) = [];
longitudeGps(idBad) = [];
[juldGps, idSort] = sort(juldGps);
latitudeGps = latitudeGps(idSort);
longitudeGps = longitudeGps(idSort);

idVal = find(strcmp('TIME', ncData) == 1, 1);
time = ncData{idVal+1};
juld = time/86400 + epoch_offset;
idVal = find(strcmp('LATITUDE', ncData) == 1, 1);
latitude = ncData{idVal+1};
idVal = find(strcmp('LONGITUDE', ncData) == 1, 1);
longitude = ncData{idVal+1};
idVal = find(strcmp('POSITION_QC', ncData) == 1, 1);
positionQc = ncData{idVal+1};
idVal = find(strcmp('PHASE', ncData) == 1, 1);
phaseData = ncData{idVal+1};
idVal = find(strcmp('PHASE_NUMBER', ncData) == 1, 1);
phaseNumData = ncData{idVal+1};

% create the output KML file
[~, egoNcFile, ~] = fileparts(a_deploymentFilePathName);
kmlFileName = [egoNcFile '_' datestr(now, 'yyyymmddTHHMMSS') '.kml'];
kmzFileName = [kmlFileName(1:end-4) '.kmz'];
outputFileName = [a_outputKmlDirName '/' kmlFileName];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Error while creating file %s\n', outputFileName);
   return
end

% KML file header
description = 'Surface GPS trajectory generated from EGO file contents';
ge_put_header1(fidOut, description, kmlFileName);

% GPS locations
kmlStrLoc = [];
kmlStrLoc = [kmlStrLoc, ...
   9, '<Folder>', 10, ...
   9, 9, '<name> GPS locations </name>', 10, ...
   9, 9, '<visibility> 0 </visibility>', 10, ...
   ];

for idPos = 1:length(juldGps)
   posDescription = [];
   posDescription = [posDescription, ...
      sprintf('POSITION (lon, lat): %8.3f, %7.3f\n', longitudeGps(idPos), latitudeGps(idPos))];
   posDescription = [posDescription, ...
      sprintf('DATE : %s\n', gl_julian_2_gregorian(juldGps(idPos)))];
   
   timeSpanStart = datestr(juldGps(idPos)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
   
   kmlStrLoc = [kmlStrLoc, ge_create_pos( ...
      longitudeGps(idPos), latitudeGps(idPos), ...
      posDescription, ...
      sprintf('%d', idPos), ...
      '#GPS_POS', ...
      timeSpanStart, '')];
   
   %    fprintf('%03d: %s (%8.3f, %7.3f)\n', ...
   %       idPos, gl_julian_2_gregorian(juldGps(idPos)), ...
   %       longitudeGps(idPos), latitudeGps(idPos));
end

kmlStrLoc = [kmlStrLoc, ...
   9, '</Folder>', 10, ...
   ];

% GPS surface trajectory
kmlStrTraj = [];
kmlStrTraj = [kmlStrTraj, ...
   9, '<Folder>', 10, ...
   9, 9, '<name> GPS trajectory </name>', 10, ...
   9, 9, '<visibility> 1 </visibility>', 10, ...
   ];

kmlStrTraj = [kmlStrTraj, ge_create_line( ...
   longitudeGps, latitudeGps, juldGps+referenceDate, ...
   '#GPS_TRAJ')];

kmlStrTraj = [kmlStrTraj, ...
   9, '</Folder>', 10, ...
   ];

% compute the indices of the profile measurements
tabStart = [];
tabStop = [];
tabDir = [];
idSplit = find(diff(phaseNumData) ~= 0);
idStart = 1;
for id = 1:length(idSplit)+1
   if (id <= length(idSplit))
      idStop = idSplit(id);
   else
      idStop = length(phaseData);
   end
   phase = unique(phaseData(idStart:idStop));
   if ((phase == g_decGl_phaseDescent) || (phase == g_decGl_phaseAscent))
      tabStart = [tabStart; idStart];
      tabStop = [tabStop; idStop];
      if (phase == g_decGl_phaseDescent)
         tabDir = [tabDir 'D'];
      else
         tabDir = [tabDir 'A'];
      end
   end
   idStart = idStop + 1;
end

% profile locations
kmlStrProfLoc = [];
if (~isempty(longitude))
   kmlStrProfLoc = [kmlStrProfLoc, ...
      9, '<Folder>', 10, ...
      9, 9, '<name> Profile locations </name>', 10, ...
      9, 9, '<visibility> 0 </visibility>', 10, ...
      ];
   
   for idProf = 1:length(tabStart)
      
      idStart = tabStart(idProf);
      idStop = tabStop(idProf);
      
      measPosDate = [];
      if (~isempty(juld))
         
         measPosDate = juld(idStart:idStop);
         measPosLon = longitude(idStart:idStop);
         measPosLat = latitude(idStart:idStop);
         
         idDel = find((measPosDate == 999999) | (measPosLon == 99999) | (measPosLat == 99999));
         measPosDate(idDel) = [];
         measPosLon(idDel) = [];
         measPosLat(idDel) = [];
      end
      
      if (~isempty(measPosDate))
         if (tabDir(idProf) == 'D')
            style = '#PROF_DESC_POS';
         else
            style = '#PROF_ASC_POS';
         end
         dateRef = mean(measPosDate);
         lonRef = mean(measPosLon);
         latRef = mean(measPosLat);
         
         posDescription = [];
         posDescription = [posDescription, ...
            sprintf('JULD: %s\n', gl_julian_2_gregorian(dateRef))];
         posDescription = [posDescription, ...
            sprintf('LOCATION (lon, lat): %8.3f, %7.3f\n', lonRef, latRef)];
         posDescription = [posDescription, ...
            sprintf('PROFILE NUMBER : %d\n', idProf)];
         posDescription = [posDescription, ...
            sprintf('DIRECTION : %c\n', tabDir(idProf))];
         timeSpanStart = datestr(dateRef+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         kmlStrProfLoc = [kmlStrProfLoc, ge_create_pos( ...
            lonRef, latRef, ...
            posDescription, ...
            sprintf('%d_%c', idProf, tabDir(idProf)), ...
            style, ...
            timeSpanStart, '')];
      end
   end
   
   kmlStrProfLoc = [kmlStrProfLoc, ...
      9, '</Folder>', 10, ...
      ];
end

% sub-surface trajectory
kmlStrSubTraj = [];
if (~isempty(longitude))
   kmlStrSubTraj = [kmlStrSubTraj, ...
      9, '<Folder>', 10, ...
      9, 9, '<name> Sub-surface trajectory </name>', 10, ...
      9, 9, '<visibility> 0 </visibility>', 10, ...
      ];
   
   % % sub-surface measurements
   % kmlStrSubMeas = [];
   % kmlStrSubMeas = [kmlStrSubMeas, ...
   %    9, '<Folder>', 10, ...
   %    9, 9, '<name> Sub-surface measurements </name>', 10, ...
   %    9, 9, '<visibility> 0 </visibility>', 10, ...
   %    ];
   
   phaseName = [ ...
      {'Surface drift'}, ...
      {'Descent'}, ...
      {'Sub-surface drift'}, ...
      {'Inflexion'}, ...
      {'Ascent'}, ...
      {'Grounded'}, ...
      {'Inconsistent'} ...
      ];
   phaseList = [ ...
      g_decGl_phaseSurfDrift, ...
      g_decGl_phaseDescent, ...
      g_decGl_phaseSubSurfDrift, ...
      g_decGl_phaseInflexion, ...
      g_decGl_phaseAscent, ...
      g_decGl_phaseGrounded, ...
      g_decGl_phaseInconsistant ...
      ];
   
   idBad = find((juld == 999999) | (latitude == 99999) | (longitude == 99999));
   juld(idBad) = [];
   latitude(idBad) = [];
   longitude(idBad) = [];
   positionQc(idBad) = [];
   phaseData(idBad) = [];
   phaseNumData(idBad) = [];
   [juld, idSort] = sort(juld);
   latitude = latitude(idSort);
   longitude = longitude(idSort);
   positionQc = positionQc(idSort);
   phaseData = phaseData(idSort);
   phaseNumData = phaseNumData(idSort);
   
   for idPhase = 1:length(phaseList)
      
      idForPhase = find(phaseData == phaseList(idPhase));
      idCut = find(diff(phaseNumData(idForPhase)) ~= 0);
      
      if (~isempty(idForPhase))
         
         kmlStrSubTraj = [kmlStrSubTraj, ...
            9, 9, '<Folder>', 10, ...
            9, 9, 9, '<name> ' phaseName{idPhase} '</name>', 10, ...
            9, 9, 9, '<visibility> 0 </visibility>', 10, ...
            ];
         
         %       kmlStrSubMeas = [kmlStrSubMeas, ...
         %          9, 9, '<Folder>', 10, ...
         %          9, 9, 9, '<name> ' phaseName{idPhase} '</name>', 10, ...
         %          9, 9, 9, '<visibility> 1 </visibility>', 10, ...
         %          ];
         
         idStart = idForPhase(1);
         for idC = 1:length(idCut)
            idEnd = idForPhase(idCut(idC));
            kmlStrSubTraj = [kmlStrSubTraj, ge_create_line( ...
               longitude(idStart:idEnd), latitude(idStart:idEnd), juld(idStart:idEnd)+referenceDate, ...
               ['#SUB_TRAJ_' num2str(phaseList(idPhase))])];
            %          fprintf('PHASE: %d, PHASE_NUM: %d\n', ...
            %             unique(phase(idStart:idEnd)), unique(phaseNumData(idStart:idEnd)));
            
            %          for idPos = idStart:idEnd
            %             timeSpanStart = datestr(juld(idPos)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
            %             kmlStrSubMeas = [kmlStrSubMeas, ge_create_pos( ...
            %                longitude(idPos), latitude(idPos), ...
            %                '', ...
            %                '', ...
            %                ['#SUB_TRAJ_MEAS_' num2str(phaseList(idPhase))], ...
            %                timeSpanStart, '')];
            %          end
            
            idStart = idForPhase(idCut(idC)+1);
         end
         idEnd = idForPhase(end);
         kmlStrSubTraj = [kmlStrSubTraj, ge_create_line( ...
            longitude(idStart:idEnd), latitude(idStart:idEnd), juld(idStart:idEnd)+referenceDate, ...
            ['#SUB_TRAJ_' num2str(phaseList(idPhase))])];
         %       fprintf('PHASE: %d, PHASE_NUM: %d\n', ...
         %          unique(phase(idStart:idEnd)), unique(phaseNumData(idStart:idEnd)));
         
         %       for idPos = idStart:idEnd
         %          timeSpanStart = datestr(juld(idPos)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         %          kmlStrSubMeas = [kmlStrSubMeas, ge_create_pos( ...
         %             longitude(idPos), latitude(idPos), ...
         %             '', ...
         %             '', ...
         %             ['#SUB_TRAJ_MEAS_' num2str(phaseList(idPhase))], ...
         %             timeSpanStart, '')];
         %       end
         
         %       kmlStrSubMeas = [kmlStrSubMeas, ...
         %          9, 9, '</Folder>', 10, ...
         %          ];
         
         kmlStrSubTraj = [kmlStrSubTraj, ...
            9, 9, '</Folder>', 10, ...
            ];
      end
   end
   
   % kmlStrSubMeas = [kmlStrSubMeas, ...
   %    9, '</Folder>', 10, ...
   %    ];
   
   kmlStrSubTraj = [kmlStrSubTraj, ...
      9, '</Folder>', 10, ...
      ];
end

fprintf(fidOut, '%s\n', kmlStrLoc);
fprintf(fidOut, '%s\n', kmlStrTraj);
fprintf(fidOut, '%s\n', kmlStrProfLoc);
% fprintf(fidOut, '%s\n', kmlStrSubMeas);
fprintf(fidOut, '%s\n', kmlStrSubTraj);

% KML file finalization
footer = [ ...
   '</Document>', 10, ...
   '</kml>', 10];

fprintf(fidOut,'%s',footer);
fclose(fidOut);

% KMZ file generation
zip([a_outputKmlDirName '/' kmzFileName], [a_outputKmlDirName '/' kmlFileName]);
movefile([a_outputKmlDirName '/' kmzFileName '.zip'], [a_outputKmlDirName '/' kmzFileName]);
delete([a_outputKmlDirName '/' kmlFileName]);

return

% ------------------------------------------------------------------------------
% Generate KML (in fact KMZ) file from profile files.
%
% SYNTAX :
%  nc_ego_2_kml_for_deployment_profile_files(a_profileDirName, a_deploymentFilePathName, a_outputKmlDirName)
%
% INPUT PARAMETERS :
%   a_profileDirName         : directory of the profile files
%   a_deploymentFilePathName : file of the deployment
%   a_outputKmlDirName       : directory of the output KMZ file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/19/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_2_kml_for_deployment_profile_files(a_profileDirName, a_deploymentFilePathName, a_outputKmlDirName)

% julian 1950 to gregorian date offset
referenceDateStr = '1950-01-01 00:00:00';
referenceDate = datenum(referenceDateStr, 'yyyy-mm-dd HH:MM:SS');


dirNcFiles = dir([a_profileDirName '/*.nc']);

if (~isempty(dirNcFiles))
   
   % create the output KML file
   [~, egoNcFile, ~] = fileparts(a_deploymentFilePathName);
   kmlFileName = ['profiles_from_' egoNcFile '_' datestr(now, 'yyyymmddTHHMMSS') '.kml'];
   kmzFileName = [kmlFileName(1:end-4) '.kmz'];
   outputFileName = [a_outputKmlDirName '/' kmlFileName];
   
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('Error while creating file %s\n', outputFileName);
      return
   end
   
   % KML file header
   description = 'Profiles generated from EGO file contents';
   ge_put_header2(fidOut, description, kmlFileName);
   
   % profile locations
   kmlStrProfLoc = [];
   kmlStrProfLoc = [kmlStrProfLoc, ...
      9, '<Folder>', 10, ...
      9, 9, '<name> Profile locations </name>', 10, ...
      9, 9, '<visibility> 0 </visibility>', 10, ...
      ];
   
   % profile trajectory
   kmlStrProfTraj = [];
   kmlStrProfTraj = [kmlStrProfTraj, ...
      9, '<Folder>', 10, ...
      9, 9, '<name> Profile trajectory </name>', 10, ...
      9, 9, '<visibility> 1 </visibility>', 10, ...
      ];
   
   profTrajJuld = [];
   profTrajLon = [];
   profTrajLat = [];
   for idFile = 1:length(dirNcFiles)
      
      ncFile = dirNcFiles(idFile).name;
      fprintf('Converting file: %s\n', ncFile);
      ncFilePathName = [a_profileDirName '/' ncFile];
      
      % retrieve the data of the EGO NetCDF file
      wantedVars = [ ...
         {'JULD_LOCATION'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'POSITION_QC'} ...
         {'JULD'} ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'PRES'} ...
         ];
      [ncData] = gl_get_data_from_nc_file(ncFilePathName, wantedVars);
      
      idVal = find(strcmp('JULD_LOCATION', ncData) == 1, 1);
      juldLocation = ncData{idVal+1};
      idVal = find(strcmp('LATITUDE', ncData) == 1, 1);
      latitude = ncData{idVal+1};
      idVal = find(strcmp('LONGITUDE', ncData) == 1, 1);
      longitude = ncData{idVal+1};
      idVal = find(strcmp('POSITION_QC', ncData) == 1, 1);
      positionQc = ncData{idVal+1};
      idVal = find(strcmp('JULD', ncData) == 1, 1);
      juld = ncData{idVal+1};
      idVal = find(strcmp('CYCLE_NUMBER', ncData) == 1, 1);
      cycleNumber = ncData{idVal+1};
      idVal = find(strcmp('DIRECTION', ncData) == 1, 1);
      direction = ncData{idVal+1};
      idVal = find(strcmp('PRES', ncData) == 1, 1);
      pres = ncData{idVal+1};
      
      idBad = find((juldLocation == 999999) | (latitude == 99999) | (longitude == 99999));
      juldLocation(idBad) = [];
      latitude(idBad) = [];
      longitude(idBad) = [];
      positionQc(idBad) = [];
      juld(idBad) = [];
      cycleNumber(idBad) = [];
      direction(idBad) = [];
      pres(:, idBad) = [];
      
      for idProf = 1:length(juld)
         posDescription = [];
         posDescription = [posDescription, ...
            sprintf('JULD LOCATION : %s\n', gl_julian_2_gregorian(juldLocation(idProf)))];
         posDescription = [posDescription, ...
            sprintf('LOCATION (lon, lat): %8.3f, %7.3f\n', longitude(idProf), latitude(idProf))];
         posDescription = [posDescription, ...
            sprintf('POSITION QC : %c\n', positionQc(idProf))];
         posDescription = [posDescription, ...
            sprintf('JULD : %s\n', gl_julian_2_gregorian(juld(idProf)))];
         posDescription = [posDescription, ...
            sprintf('CYCLE NUMBER : %d\n', cycleNumber(idProf))];
         posDescription = [posDescription, ...
            sprintf('DIRECTION : %c\n', direction(idProf))];
         profPres = pres(:, idProf);
         profPres(find(profPres == 99999)) = [];
         posDescription = [posDescription, ...
            sprintf('PRES range : %.1f - %.1f\n', min(profPres), max(profPres))];
         
         timeSpanStart = datestr(juldLocation(idProf)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         
         style = '#PROFILE_POS_GPS';
         if (positionQc(idProf) == '8')
            style = '#PROFILE_POS_INTERP';
         end
         kmlStrProfLoc = [kmlStrProfLoc, ge_create_pos( ...
            longitude(idProf), latitude(idProf), ...
            posDescription, ...
            sprintf('%d_%c', cycleNumber(idProf), direction(idProf)), ...
            style, ...
            timeSpanStart, '')];
      end
      
      profTrajJuld = [profTrajJuld; juldLocation];
      profTrajLon = [profTrajLon; longitude];
      profTrajLat = [profTrajLat; latitude];
   end
   
   [profTrajJuld, idSort] = sort(profTrajJuld);
   profTrajLat = profTrajLat(idSort);
   profTrajLon = profTrajLon(idSort);
   
   kmlStrProfTraj = [kmlStrProfTraj, ge_create_line( ...
      profTrajLon, profTrajLat, profTrajJuld+referenceDate, ...
      '#PROF_TRAJ')];
   
   kmlStrProfTraj = [kmlStrProfTraj, ...
      9, '</Folder>', 10, ...
      ];
   
   kmlStrProfLoc = [kmlStrProfLoc, ...
      9, '</Folder>', 10, ...
      ];
   
   fprintf(fidOut, '%s\n', kmlStrProfTraj);
   fprintf(fidOut, '%s\n', kmlStrProfLoc);
   
   % KML file finalization
   footer = [ ...
      '</Document>', 10, ...
      '</kml>', 10];
   
   fprintf(fidOut,'%s',footer);
   fclose(fidOut);
   
   % KMZ file generation
   zip([a_outputKmlDirName '/' kmzFileName], [a_outputKmlDirName '/' kmlFileName]);
   movefile([a_outputKmlDirName '/' kmzFileName '.zip'], [a_outputKmlDirName '/' kmzFileName]);
   delete([a_outputKmlDirName '/' kmlFileName]);
   
end

return
