% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE files.
%
% SYNTAX :
%  [o_generatedFiles] = gl_create_nc_mono_prof_files_3_0( ...
%    a_tabProfiles, a_metaData, a_outputDirName, a_baseFileName)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : decoded profiles
%   a_metaData      : additional meta-data
%   a_outputDirName : directory of the generated NetCDF files
%   a_baseFileName  : base file name of the generated NetCDF files
%
% OUTPUT PARAMETERS :
%   o_generatedFiles : list of generated profile file path names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_generatedFiles] = gl_create_nc_mono_prof_files_3_0( ...
   a_tabProfiles, a_metaData, a_outputDirName, a_baseFileName)

o_generatedFiles = [];

% current float WMO number
global g_decGl_floatNum;

% global default values
global g_decGl_ncDateDef;

% real time processing
global g_decGl_realtimeFlag;

% report information structure
global g_decGl_reportStruct;

% decoder version
global g_decGl_decoderVersion;

% RTQC program version
global g_decGl_rtqcVersion;


% verbose mode flag
VERBOSE_MODE = 0;

% no data to save
if (isempty(a_tabProfiles))
   return
end

% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.cycleNumber profile.profileNumber direction 0 profile.primarySamplingProfileFlag]];
end

for idProf = 1:length(a_tabProfiles)

   if (profInfo(idProf, 4) == 0)
      profile = a_tabProfiles(idProf);
      cycleNumber = profile.cycleNumber;
      profileNumber = profile.profileNumber;
      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end
      
      % find if it is a multi-profile cycle
      profNumList = profInfo(find(profInfo(:, 1) == cycleNumber), 2);
      dirList = profInfo(find(profInfo(:, 1) == cycleNumber), 3);
      multiProf = 0;
      if ((length(unique(profNumList)) > 2) || ...
            ((length(unique(profNumList)) == 2) && (length(unique(dirList)) == 1)))
         multiProf = 1;
      end
      
      % list of profiles to store in the current profile file
      if (multiProf == 0)
         idProfInFile = find((profInfo(:, 1) == cycleNumber) & ...
            (profInfo(:, 2) == profileNumber) & ...
            (profInfo(:, 3) == direction));
      else
         idProfInFile = find((profInfo(:, 1) == cycleNumber) & ...
            (profInfo(:, 2) == profileNumber));
      end
      nbProfInFile = length(idProfInFile);
      
      % put the primary sampling profile on top of the list
      idPrimary = find(profInfo(idProfInFile, 5) == 1);
      if (~isempty(idPrimary))
         if (length(idPrimary) > 1)
            idPrimary2 = find(profInfo(idProfInFile(idPrimary), 3) == 2);
            idPrimary = idPrimary(idPrimary2);
         end
         idProfInFile = [idProfInFile(idPrimary); idProfInFile];
         idProfInFile(idPrimary+1) = [];
      else
         fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no primary sampling profile\n', ...
            g_decGl_floatNum, cycleNumber, profileNumber);
      end
      
      % create the profile parameters list and compute the number of levels
      % and sublevels
      profParamName = [];
      nbProfLevels = 0;
      nbProfSubLevels = 0;
      for idP = 1:nbProfInFile
         prof = a_tabProfiles(idProfInFile(idP));
         parameterList = prof.paramList;
         profileData = prof.data;
         for idParam = 1:length(parameterList)
            
            if ((length(parameterList(idParam).name) > 9) && strcmp(parameterList(idParam).name(end-8:end), '_ADJUSTED'))
               continue
            end
            
            profParamName = [profParamName; {parameterList(idParam).name}];
         end
         nbProfLevels = max(nbProfLevels, size(profileData, 1));
         if (~isempty(prof.paramNumberWithSubLevels))
            nbProfSubLevels = max(nbProfSubLevels, ...
               max(prof.paramNumberOfSubLevels));
         end
      end
      profUniqueParamName = unique(profParamName);
      nbProfParam = length(profUniqueParamName);

      % create output file pathname
      outputDirName = [a_outputDirName '/'];
      if (~exist(outputDirName, 'dir'))
         mkdir(outputDirName);
      end
            
      if (multiProf == 0)
         if (direction == 1)
            ncFileName = sprintf('R%s_%03dD.nc', ...
               a_baseFileName, cycleNumber);
         else
            ncFileName = sprintf('R%s_%03d.nc', ...
               a_baseFileName, cycleNumber);
         end
      else
         ncFileName = sprintf('R%s_%03d_%02d.nc', ...
            a_baseFileName, cycleNumber, profileNumber);
      end
      ncPathFileName = [outputDirName  ncFileName];

      if (VERBOSE_MODE == 1)
         fprintf('Creating NetCDF MONO-PROFILE file (%s) ...\n', ncFileName);
      end

      % create and open NetCDF file
      fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
      if (isempty(fCdf))
         fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
         return
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % DEFINE MODE BEGIN
      if (VERBOSE_MODE == 1)
         fprintf('START DEFINE MODE\n');
      end
      
      % create dimensions
      dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
      string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
      string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
      string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
      string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
      string10DimId = netcdf.defDim(fCdf, 'STRING10', 10);
      string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
      string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
      string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

      nProfDimId = netcdf.defDim(fCdf, 'N_PROF', nbProfInFile);
      nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbProfParam);
      nLevelsDimId = netcdf.defDim(fCdf, 'N_LEVELS', nbProfLevels);
      if (nbProfSubLevels ~= 0)
         nSubLevelsDimId = netcdf.defDim(fCdf, 'N_SUBLEVELS', nbProfSubLevels);
      end
      nCalibDimId = netcdf.defDim(fCdf, 'N_CALIB', 1);
      nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', netcdf.getConstant('NC_UNLIMITED'));
      
      if (VERBOSE_MODE == 1)
         fprintf('N_PROF = %d\n', nbProfInFile);
         fprintf('N_PARAM = %d\n', nbProfParam);
         fprintf('N_LEVELS = %d\n', nbProfLevels);
         fprintf('N_SUBLEVELS = %d\n', nbProfSubLevels);
      end
      
      % create global attributes
      globalVarId = netcdf.getConstant('NC_GLOBAL');
      netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
      netcdf.putAtt(fCdf, globalVarId, 'institution', 'CORIOLIS');
      netcdf.putAtt(fCdf, globalVarId, 'source', 'Glider');
      currentDate = gl_now_utc;
      netcdf.putAtt(fCdf, globalVarId, 'history', datestr(currentDate, 'yyyy-mm-ddTHH:MM:SSZ creation'));
      netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
%       netcdf.putAtt(fCdf, globalVarId, 'comment', 'free text');
      netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.0');
      netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.0 CF-1.6');
      netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');
%       netcdf.putAtt(fCdf, globalVarId, 'dac_decoder_version', ...
%          sprintf('Argo Coriolis Matlab decoder V%s', ...
%          g_decGl_decoderVersion));
%       netcdf.putAtt(fCdf, globalVarId, 'dac_format_id', get_dac_format_version(a_decoderId));

      % create misc variables
      dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string16DimId);
      netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
      netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');

      formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
      netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
      netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');

      handbookVersionVarId = netcdf.defVar(fCdf, 'HANDBOOK_VERSION', 'NC_CHAR', string4DimId);
      netcdf.putAtt(fCdf, handbookVersionVarId, 'long_name', 'Data handbook version');
      netcdf.putAtt(fCdf, handbookVersionVarId, '_FillValue', ' ');

      referenceDateTimeVarId = netcdf.defVar(fCdf, 'REFERENCE_DATE_TIME', 'NC_CHAR', dateTimeDimId);
      netcdf.putAtt(fCdf, referenceDateTimeVarId, 'long_name', 'Date of reference for Julian days');
      netcdf.putAtt(fCdf, referenceDateTimeVarId, 'conventions', 'YYYYMMDDHHMISS');
      netcdf.putAtt(fCdf, referenceDateTimeVarId, '_FillValue', ' ');

      dateCreationVarId = netcdf.defVar(fCdf, 'DATE_CREATION', 'NC_CHAR', dateTimeDimId);
      netcdf.putAtt(fCdf, dateCreationVarId, 'long_name', 'Date of file creation');
      netcdf.putAtt(fCdf, dateCreationVarId, 'conventions', 'YYYYMMDDHHMISS');
      netcdf.putAtt(fCdf, dateCreationVarId, '_FillValue', ' ');

      dateUpdateVarId = netcdf.defVar(fCdf, 'DATE_UPDATE', 'NC_CHAR', dateTimeDimId);
      netcdf.putAtt(fCdf, dateUpdateVarId, 'long_name', 'Date of update of this file');
      netcdf.putAtt(fCdf, dateUpdateVarId, 'conventions', 'YYYYMMDDHHMISS');
      netcdf.putAtt(fCdf, dateUpdateVarId, '_FillValue', ' ');

      % create profile variables
      platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
      netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
      netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
      netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');

      projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
      netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Name of the project');
      netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');

      piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
      netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
      netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');

      stationParametersVarId = netcdf.defVar(fCdf, 'STATION_PARAMETERS', 'NC_CHAR', fliplr([nProfDimId nParamDimId string64DimId]));
      netcdf.putAtt(fCdf, stationParametersVarId, 'long_name', 'List of available parameters for the station');
      netcdf.putAtt(fCdf, stationParametersVarId, 'conventions', 'Argo reference table 3');
      netcdf.putAtt(fCdf, stationParametersVarId, '_FillValue', ' ');

      cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nProfDimId);
      netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number');
      netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0..N, 0 : launch cycle (if exists), 1 : first complete cycle');
      netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));

      if (multiProf == 1)
         profileNumberVarId = netcdf.defVar(fCdf, 'PROFILE_NUMBER', 'NC_INT', nProfDimId);
         netcdf.putAtt(fCdf, profileNumberVarId, 'long_name', 'Float profile number');
         netcdf.putAtt(fCdf, profileNumberVarId, 'conventions', 'Number of the profile within the current cycle, the first profile of the cycle is numbered 1 whatever its direction');
         netcdf.putAtt(fCdf, profileNumberVarId, '_FillValue', int32(99999));
      end

      directionVarId = netcdf.defVar(fCdf, 'DIRECTION', 'NC_CHAR', nProfDimId);
      netcdf.putAtt(fCdf, directionVarId, 'long_name', 'Direction of the station profiles');
      netcdf.putAtt(fCdf, directionVarId, 'conventions', 'A: ascending profiles, D: descending profiles');
      netcdf.putAtt(fCdf, directionVarId, '_FillValue', ' ');

      dataCenterVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', fliplr([nProfDimId string2DimId]));
      netcdf.putAtt(fCdf, dataCenterVarId, 'long_name', 'Data centre in charge of float data processing');
      netcdf.putAtt(fCdf, dataCenterVarId, 'conventions', 'Argo reference table 4');
      netcdf.putAtt(fCdf, dataCenterVarId, '_FillValue', ' ');
                     
      dcReferenceVarId = netcdf.defVar(fCdf, 'DC_REFERENCE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
      netcdf.putAtt(fCdf, dcReferenceVarId, 'long_name', 'Station unique identifier in data centre');
      netcdf.putAtt(fCdf, dcReferenceVarId, 'conventions', 'Data centre convention');
      netcdf.putAtt(fCdf, dcReferenceVarId, '_FillValue', ' ');

      dataStateIndicatorVarId = netcdf.defVar(fCdf, 'DATA_STATE_INDICATOR', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'long_name', 'Degree of processing the data have passed through');
      netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'conventions', 'Argo reference table 6');
      netcdf.putAtt(fCdf, dataStateIndicatorVarId, '_FillValue', ' ');

      dataModeVarId = netcdf.defVar(fCdf, 'DATA_MODE', 'NC_CHAR', nProfDimId);
      netcdf.putAtt(fCdf, dataModeVarId, 'long_name', 'Delayed mode or real time data');
      netcdf.putAtt(fCdf, dataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
      netcdf.putAtt(fCdf, dataModeVarId, '_FillValue', ' ');

      instReferenceVarId = netcdf.defVar(fCdf, 'INST_REFERENCE', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
      netcdf.putAtt(fCdf, instReferenceVarId, 'long_name', 'Instrument type');
      netcdf.putAtt(fCdf, instReferenceVarId, 'conventions', 'Brand, type, serial number');
      netcdf.putAtt(fCdf, instReferenceVarId, '_FillValue', ' ');

      firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', fliplr([nProfDimId string10DimId]));
      netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Instrument firmware version');
      %       netcdf.putAtt(fCdf, firmwareVersionVarId, 'conventions', '');
      netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');

      wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
      netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
      netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');

      juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nProfDimId);
      netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of the station relative to REFERENCE_DATE_TIME');
      netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
      netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
      netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of the day)');
      netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
      netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');

      juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nProfDimId);
      netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
      netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');

      juldLocationVarId = netcdf.defVar(fCdf, 'JULD_LOCATION', 'NC_DOUBLE', nProfDimId);
      netcdf.putAtt(fCdf, juldLocationVarId, 'long_name', 'Julian day (UTC) of the location relative to REFERENCE_DATE_TIME');
      netcdf.putAtt(fCdf, juldLocationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
      netcdf.putAtt(fCdf, juldLocationVarId, 'conventions', 'Relative julian days with decimal part (as parts of the day)');
      netcdf.putAtt(fCdf, juldLocationVarId, '_FillValue', double(999999));

      latitudeVarId = netcdf.defVar(fCdf, 'LATITUDE', 'NC_DOUBLE', nProfDimId);
      netcdf.putAtt(fCdf, latitudeVarId, 'long_name', 'Latitude of the station, best estimate');
      netcdf.putAtt(fCdf, latitudeVarId, 'standard_name', 'latitude');
      netcdf.putAtt(fCdf, latitudeVarId, 'units', 'degree_north');
      netcdf.putAtt(fCdf, latitudeVarId, '_FillValue', double(99999));
      netcdf.putAtt(fCdf, latitudeVarId, 'valid_min', double(-90));
      netcdf.putAtt(fCdf, latitudeVarId, 'valid_max', double(90));
      netcdf.putAtt(fCdf, latitudeVarId, 'axis', 'Y');

      longitudeVarId = netcdf.defVar(fCdf, 'LONGITUDE', 'NC_DOUBLE', nProfDimId);
      netcdf.putAtt(fCdf, longitudeVarId, 'long_name', 'Longitude of the station, best estimate');
      netcdf.putAtt(fCdf, longitudeVarId, 'standard_name', 'longitude');
      netcdf.putAtt(fCdf, longitudeVarId, 'units', 'degree_east');
      netcdf.putAtt(fCdf, longitudeVarId, '_FillValue', double(99999));
      netcdf.putAtt(fCdf, longitudeVarId, 'valid_min', double(-180));
      netcdf.putAtt(fCdf, longitudeVarId, 'valid_max', double(180));
      netcdf.putAtt(fCdf, longitudeVarId, 'axis', 'X');

      positionQcVarId = netcdf.defVar(fCdf, 'POSITION_QC', 'NC_CHAR', nProfDimId);
      netcdf.putAtt(fCdf, positionQcVarId, 'long_name', 'Quality on position (latitude and longitude)');
      netcdf.putAtt(fCdf, positionQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, positionQcVarId, '_FillValue', ' ');

      positioningSystemVarId = netcdf.defVar(fCdf, 'POSITIONING_SYSTEM', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
      netcdf.putAtt(fCdf, positioningSystemVarId, 'long_name', 'Positioning system');
      netcdf.putAtt(fCdf, positioningSystemVarId, '_FillValue', ' ');

      % global quality of PARAM profile
      for idParam = 1:length(profUniqueParamName)
         profParamName = profUniqueParamName{idParam};
         ncParamName = sprintf('PROFILE_%s_QC', profParamName);

         profileParamQcVarId = netcdf.defVar(fCdf, ncParamName, 'NC_CHAR', nProfDimId);
         netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', profParamName));
         netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
         netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
      end

      verticalSamplingSchemeVarId = netcdf.defVar(fCdf, 'VERTICAL_SAMPLING_SCHEME', 'NC_CHAR', fliplr([nProfDimId string256DimId]));
      netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'long_name', 'Vertical sampling scheme');
      netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'conventions', 'Argo reference table 16');
      netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, '_FillValue', ' ');

      % add profile data
      for idP = 1:nbProfInFile
         prof = a_tabProfiles(idProfInFile(idP));

         % profile parameter data
         parameterList = prof.paramList;
         for idParam = 1:length(parameterList)

            % find if this parameter has sublevels
            paramWithSubLevels = 0;
            if (~isempty(prof.paramNumberWithSubLevels))
               idParamWithSubLevels = find(prof.paramNumberWithSubLevels == idParam);
               if (~isempty(idParamWithSubLevels))
                  paramWithSubLevels = 1;
               end
            end

            profParam = parameterList(idParam);

            % parameter variable and attributes
            profParamName = profParam.name;
            
            if ((length(profParamName) > 9) && strcmp(profParamName(end-8:end), '_ADJUSTED'))
               continue
            end
            
            if (~gl_var_is_present(fCdf, profParamName))
               doubleType = 0;
               if (strncmp(profParamName, 'CNT_IR', length('CNT_IR')) == 1)
                  doubleType = 1;
               end
               if (paramWithSubLevels == 0)
                  if (doubleType == 0)
                     profParamVarId = netcdf.defVar(fCdf, profParamName, 'NC_FLOAT', fliplr([nProfDimId nLevelsDimId]));
                  else
                     profParamVarId = netcdf.defVar(fCdf, profParamName, 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId]));
                  end
               else
                  if (doubleType == 0)
                     profParamVarId = netcdf.defVar(fCdf, profParamName, 'NC_FLOAT', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
                  else
                     profParamVarId = netcdf.defVar(fCdf, profParamName, 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
                  end
               end
               netcdf.putAtt(fCdf, profParamVarId, 'long_name', profParam.longName);
               netcdf.putAtt(fCdf, profParamVarId, 'standard_name', profParam.standardName);
               netcdf.putAtt(fCdf, profParamVarId, '_FillValue', profParam.fillValue);
               netcdf.putAtt(fCdf, profParamVarId, 'units', profParam.units);
               netcdf.putAtt(fCdf, profParamVarId, 'valid_min', profParam.validMin);
               netcdf.putAtt(fCdf, profParamVarId, 'valid_max', profParam.validMax);
               netcdf.putAtt(fCdf, profParamVarId, 'C_format', profParam.cFormat);
               netcdf.putAtt(fCdf, profParamVarId, 'FORTRAN_format', profParam.fortranFormat);
               netcdf.putAtt(fCdf, profParamVarId, 'resolution', profParam.resolution);
            end
            
            % parameter QC variable and attributes
            profParamQcName = sprintf('%s_QC', profParam.name);
            if (~gl_var_is_present(fCdf, profParamQcName))
               if (paramWithSubLevels == 0)
                  profParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
               else
                  profParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
               end
               netcdf.putAtt(fCdf, profParamQcVarId, 'long_name', 'quality flag');
               netcdf.putAtt(fCdf, profParamQcVarId, 'conventions', 'Argo reference table 2');
               netcdf.putAtt(fCdf, profParamQcVarId, '_FillValue', ' ');
            end
            
            % parameter adjusted variable and attributes
            profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
            if (~gl_var_is_present(fCdf, profParamAdjName))
               if (paramWithSubLevels == 0)
                  if (doubleType == 0)
                     profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, 'NC_FLOAT', fliplr([nProfDimId nLevelsDimId]));
                  else
                     profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId]));
                  end
               else
                  if (doubleType == 0)
                     profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, 'NC_FLOAT', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
                  else
                     profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
                  end
               end
               netcdf.putAtt(fCdf, profParamAdjVarId, 'long_name', profParam.longName);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'standard_name', profParam.standardName);
               netcdf.putAtt(fCdf, profParamAdjVarId, '_FillValue', profParam.fillValue);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'units', profParam.units);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_min', profParam.validMin);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_max', profParam.validMax);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'C_format', profParam.cFormat);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'FORTRAN_format', profParam.fortranFormat);
               netcdf.putAtt(fCdf, profParamAdjVarId, 'resolution', profParam.resolution);
            end
            
            % parameter adjusted QC variable and attributes
            profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
            if (~gl_var_is_present(fCdf, profParamAdjQcName))
               if (paramWithSubLevels == 0)
                  profParamAdjQcVarId = netcdf.defVar(fCdf, profParamAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
               else
                  profParamAdjQcVarId = netcdf.defVar(fCdf, profParamAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
               end
               netcdf.putAtt(fCdf, profParamAdjQcVarId, 'long_name', 'quality flag');
               netcdf.putAtt(fCdf, profParamAdjQcVarId, 'conventions', 'Argo reference table 2');
               netcdf.putAtt(fCdf, profParamAdjQcVarId, '_FillValue', ' ');
            end
            
            % parameter adjusted error variable and attributes
            profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
            if (~gl_var_is_present(fCdf, profParamAdjErrName))
               if (paramWithSubLevels == 0)
                  if (doubleType == 0)
                     profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, 'NC_FLOAT', fliplr([nProfDimId nLevelsDimId]));
                  else
                     profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId]));
                  end
               else
                  if (doubleType == 0)
                     profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, 'NC_FLOAT', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
                  else
                     profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId nSubLevelsDimId]));
                  end
               end
               netcdf.putAtt(fCdf, profParamAdjErrVarId, 'long_name', profParam.longName);
               netcdf.putAtt(fCdf, profParamAdjErrVarId, '_FillValue', profParam.fillValue);
               netcdf.putAtt(fCdf, profParamAdjErrVarId, 'units', profParam.units);
               netcdf.putAtt(fCdf, profParamAdjErrVarId, 'C_format', profParam.cFormat);
               netcdf.putAtt(fCdf, profParamAdjErrVarId, 'FORTRAN_format', profParam.fortranFormat);
               netcdf.putAtt(fCdf, profParamAdjErrVarId, 'resolution', profParam.resolution);
            end
         end
      end

      % calibration information
      parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string16DimId]));
      netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'List of parameters with calibration information');
      netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Argo reference table 3');
      netcdf.putAtt(fCdf, parameterVarId, '_FillValue', ' ');

      scientificCalibEquationVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_EQUATION', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
      netcdf.putAtt(fCdf, scientificCalibEquationVarId, 'long_name', 'Calibration equation for this parameter');
      netcdf.putAtt(fCdf, scientificCalibEquationVarId, '_FillValue', ' ');

      scientificCalibCoefficientVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
      netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, 'long_name', 'Calibration coefficients for this equation');
      netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, '_FillValue', ' ');

      scientificCalibCommentVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COMMENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
      netcdf.putAtt(fCdf, scientificCalibCommentVarId, 'long_name', 'Comment applying to this parameter calibration');
      netcdf.putAtt(fCdf, scientificCalibCommentVarId, '_FillValue', ' ');

      scientificCalibDateVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_DATE', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId dateTimeDimId]));
      netcdf.putAtt(fCdf, scientificCalibDateVarId, 'long_name', 'Date of calibration');
      netcdf.putAtt(fCdf, scientificCalibDateVarId, '_FillValue', ' ');

      parameterDataModeVarId = netcdf.defVar(fCdf, 'PARAMETER_DATA_MODE', 'NC_CHAR', fliplr([nProfDimId nParamDimId]));
      netcdf.putAtt(fCdf, parameterDataModeVarId, 'long_name', 'Delayed mode or real time data');
      netcdf.putAtt(fCdf, parameterDataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
      netcdf.putAtt(fCdf, parameterDataModeVarId, '_FillValue', ' ');

      % history information
      historyInstitutionVarId = netcdf.defVar(fCdf, 'HISTORY_INSTITUTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, historyInstitutionVarId, 'long_name', 'Institution which performed action');
      netcdf.putAtt(fCdf, historyInstitutionVarId, 'conventions', 'Argo reference table 4');
      netcdf.putAtt(fCdf, historyInstitutionVarId, '_FillValue', ' ');

      historyStepVarId = netcdf.defVar(fCdf, 'HISTORY_STEP', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, historyStepVarId, 'long_name', 'Step in data processing');
      netcdf.putAtt(fCdf, historyStepVarId, 'conventions', 'Argo reference table 12');
      netcdf.putAtt(fCdf, historyStepVarId, '_FillValue', ' ');

      historySoftwareVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, historySoftwareVarId, 'long_name', 'Name of software which performed action');
      netcdf.putAtt(fCdf, historySoftwareVarId, 'conventions', 'Institution dependent');
      netcdf.putAtt(fCdf, historySoftwareVarId, '_FillValue', ' ');

      historySoftwareReleaseVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE_RELEASE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'long_name', 'Version/release of software which performed action');
      netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'conventions', 'Institution dependent');
      netcdf.putAtt(fCdf, historySoftwareReleaseVarId, '_FillValue', ' ');

      historyReferenceVarId = netcdf.defVar(fCdf, 'HISTORY_REFERENCE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string64DimId]));
      netcdf.putAtt(fCdf, historyReferenceVarId, 'long_name', 'Reference of database');
      netcdf.putAtt(fCdf, historyReferenceVarId, 'conventions', 'Institution dependent');
      netcdf.putAtt(fCdf, historyReferenceVarId, '_FillValue', ' ');

      historyDateVarId = netcdf.defVar(fCdf, 'HISTORY_DATE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId dateTimeDimId]));
      netcdf.putAtt(fCdf, historyDateVarId, 'long_name', 'Date the history record was created');
      netcdf.putAtt(fCdf, historyDateVarId, 'conventions', 'YYYYMMDDHHMISS');
      netcdf.putAtt(fCdf, historyDateVarId, '_FillValue', ' ');

      historyActionVarId = netcdf.defVar(fCdf, 'HISTORY_ACTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
      netcdf.putAtt(fCdf, historyActionVarId, 'long_name', 'Action performed on data');
      netcdf.putAtt(fCdf, historyActionVarId, 'conventions', 'Argo reference table 7');
      netcdf.putAtt(fCdf, historyActionVarId, '_FillValue', ' ');

      historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
      netcdf.putAtt(fCdf, historyParameterVarId, 'long_name', 'Station parameter action is performed on');
      netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Argo reference table 3');
      netcdf.putAtt(fCdf, historyParameterVarId, '_FillValue', ' ');

      historyStartPresVarId = netcdf.defVar(fCdf, 'HISTORY_START_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
      netcdf.putAtt(fCdf, historyStartPresVarId, 'long_name', 'Start pressure action applied on');
      netcdf.putAtt(fCdf, historyStartPresVarId, '_FillValue', single(99999));
      netcdf.putAtt(fCdf, historyStartPresVarId, 'units', 'decibar');

      historyStopPresVarId = netcdf.defVar(fCdf, 'HISTORY_STOP_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
      netcdf.putAtt(fCdf, historyStopPresVarId, 'long_name', 'Stop pressure action applied on');
      netcdf.putAtt(fCdf, historyStopPresVarId, '_FillValue', single(99999));
      netcdf.putAtt(fCdf, historyStopPresVarId, 'units', 'decibar');

      historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
      netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
      netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));

      historyQcTestVarId = netcdf.defVar(fCdf, 'HISTORY_QCTEST', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
      netcdf.putAtt(fCdf, historyQcTestVarId, 'long_name', 'Documentation of tests performed, tests failed (in hex form)');
      netcdf.putAtt(fCdf, historyQcTestVarId, 'conventions', 'Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
      netcdf.putAtt(fCdf, historyQcTestVarId, '_FillValue', ' ');
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % DEFINE MODE END
      if (VERBOSE_MODE == 1)
         fprintf('STOP DEFINE MODE\n');
      end
      
      netcdf.endDef(fCdf);

      valueStr = 'Argo profile';
      netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);

      valueStr = '3.0';
      netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);

      valueStr = '3.0';
      netcdf.putVar(fCdf, handbookVersionVarId, 0, length(valueStr), valueStr);

      netcdf.putVar(fCdf, referenceDateTimeVarId, '19500101000000');

      netcdf.putVar(fCdf, dateCreationVarId, datestr(currentDate, 'yyyymmddHHMMSS'));

      netcdf.putVar(fCdf, dateUpdateVarId, datestr(currentDate, 'yyyymmddHHMMSS'));

      % create profile variables
      idVal = find(strcmp('PLATFORM_NUMBER', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      valueStr = [valueStr blanks(8-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, platformNumberVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      idVal = find(strcmp('PROJECT_NAME', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      valueStr = [valueStr blanks(64-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, projectNameVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      idVal = find(strcmp('PI_NAME', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      valueStr = [valueStr blanks(64-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, piNameVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      for idP = 1:nbProfInFile
         prof = a_tabProfiles(idProfInFile(idP));
         parameterList = prof.paramList;
         idParam2 = 1;
         for idParam = 1:length(parameterList)
            valueStr = parameterList(idParam).name;
            
            if ((length(valueStr) > 9) && strcmp(valueStr(end-8:end), '_ADJUSTED'))
               continue
            end

            if (length(valueStr) > 64)
               fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> 64)\n', ...
                  g_decGl_floatNum, valueStr);
            end
            
            netcdf.putVar(fCdf, stationParametersVarId, ...
               fliplr([idP-1 idParam2-1  0]), fliplr([1 1 length(valueStr)]), valueStr');
            idParam2 = idParam2 + 1;
         end
      end
      
      netcdf.putVar(fCdf, cycleNumberVarId, 0, nbProfInFile, ones(1, nbProfInFile)*cycleNumber);
      
      idVal = find(strcmp('DATA_CENTRE', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      netcdf.putVar(fCdf, dataCenterVarId, fliplr([0 0]), fliplr([nbProfInFile length(valueStr)]), repmat(valueStr, nbProfInFile, 1)');

      valueStr = '1A';
      valueStr = [valueStr blanks(4-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, dataStateIndicatorVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      idVal = find(strcmp('INST_REFERENCE', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      valueStr = [valueStr blanks(64-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, instReferenceVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      idVal = find(strcmp('FIRMWARE_VERSION', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      valueStr = [valueStr blanks(10-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, firmwareVersionVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      idVal = find(strcmp('WMO_INST_TYPE', a_metaData) == 1);
      if (~isempty(idVal))
         valueStr = char(a_metaData{idVal+1});
      else
         valueStr = ' ';
      end
      valueStr = [valueStr blanks(4-length(valueStr))];
      tabValue = repmat(valueStr, nbProfInFile, 1);
      netcdf.putVar(fCdf, wmoInstTypeVarId, permute(tabValue, fliplr(1:ndims(tabValue))));

      % add profile data
      for idP = 1:nbProfInFile
         if (VERBOSE_MODE == 1)
            fprintf('Add profile #%d/%d data\n', idP, nbProfInFile);
         end
         
         profPos = idP-1;
         prof = a_tabProfiles(idProfInFile(idP));
         
         % profile number
         if (multiProf == 1)
            netcdf.putVar(fCdf, profileNumberVarId, profPos, 1, prof.profileNumber);
         end
               
         % profile direction
         netcdf.putVar(fCdf, directionVarId, profPos, 1, prof.direction);
         
         % profile data mode
         if (any(prof.paramDataMode ~= 'R'))
            netcdf.putVar(fCdf, dataModeVarId, 0, nbProfInFile, repmat('A', 1, nbProfInFile));
         else
            netcdf.putVar(fCdf, dataModeVarId, 0, nbProfInFile, repmat('R', 1, nbProfInFile));
         end
         
         % profile parameter data mode
         netcdf.putVar(fCdf, parameterDataModeVarId, fliplr([0 0]), fliplr([1 length(prof.paramDataMode)]), prof.paramDataMode');

         % profile date
         profDate = prof.date;
         if (profDate ~= g_decGl_ncDateDef)
            netcdf.putVar(fCdf, juldVarId, profPos, 1, profDate);
            netcdf.putVar(fCdf, juldQcVarId, profPos, 1, prof.dateQc);
         else
            netcdf.putVar(fCdf, juldVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, juldVarId, '_FillValue'));
            netcdf.putVar(fCdf, juldQcVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, juldQcVarId, '_FillValue'));
         end
         
         % profile location
         profLocationDate = prof.locationDate;
         profLocationLon = prof.locationLon;
         profLocationLat = prof.locationLat;
         profLocationQc = prof.locationQc;
         profPosSystem = prof.posSystem;
         if (profLocationDate ~= g_decGl_ncDateDef)
            netcdf.putVar(fCdf, juldLocationVarId, profPos, 1, profLocationDate);
            netcdf.putVar(fCdf, latitudeVarId, profPos, 1, profLocationLat);
            netcdf.putVar(fCdf, longitudeVarId, profPos, 1, profLocationLon);
            netcdf.putVar(fCdf, positionQcVarId, profPos, 1, profLocationQc);
            netcdf.putVar(fCdf, positioningSystemVarId, fliplr([profPos 0]), fliplr([1 length(profPosSystem)]), profPosSystem');
         else
            netcdf.putVar(fCdf, juldLocationVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, juldLocationVarId, '_FillValue'));
            netcdf.putVar(fCdf, latitudeVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, latitudeVarId, '_FillValue'));
            netcdf.putVar(fCdf, longitudeVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, longitudeVarId, '_FillValue'));
            netcdf.putVar(fCdf, positionQcVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, positionQcVarId, '_FillValue'));
            netcdf.putVar(fCdf, positioningSystemVarId, fliplr([profPos 0]), fliplr([1 1]), ...
               netcdf.getAtt(fCdf, positioningSystemVarId, '_FillValue'));
         end

         % global quality of PARAM profile
         parameterList = prof.paramList;
         for idParam = 1:length(parameterList)
            profParamName = parameterList(idParam).name;
            
            if ((length(profParamName) > 9) && strcmp(profParamName(end-8:end), '_ADJUSTED'))
               continue
            end
            
            ncParamName = sprintf('PROFILE_%s_QC', profParamName);

            profileParamQcVarId = netcdf.inqVarID(fCdf, ncParamName);
            netcdf.putVar(fCdf, profileParamQcVarId, profPos, 1, ...
               netcdf.getAtt(fCdf, profileParamQcVarId, '_FillValue'));
         end

         % vertical sampling scheme
         vertSampScheme = prof.vertSamplingScheme;
         netcdf.putVar(fCdf, verticalSamplingSchemeVarId, fliplr([profPos 0]), fliplr([1 length(vertSampScheme)]), vertSampScheme');

         % profile parameter data
         offsetInDataArray = 0;
         parameterList = prof.paramList;
         for idParam = 1:length(parameterList)

            % find if this parameter has sublevels
            paramWithSubLevels = 0;
            if (~isempty(prof.paramNumberWithSubLevels))
               idParamWithSubLevels = find(prof.paramNumberWithSubLevels == idParam);
               if (~isempty(idParamWithSubLevels))
                  paramWithSubLevels = 1;
               end
            end
            
            profParam = parameterList(idParam);
            
            % parameter variable and attributes
            
            profParamName = profParam.name;
            profParamVarId = netcdf.inqVarID(fCdf, profParamName);
            
            if ~((length(profParamName) > 9) && strcmp(profParamName(end-8:end), '_ADJUSTED'))
            
               % parameter QC variable and attributes
               profParamQcName = sprintf('%s_QC', profParam.name);
               profParamQcVarId = netcdf.inqVarID(fCdf, profParamQcName);
               
               % parameter adjusted variable and attributes
               profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
               profParamAdjVarId = netcdf.inqVarID(fCdf, profParamAdjName);
               
               % parameter adjusted QC variable and attributes
               profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
               profParamAdjQcVarId = netcdf.inqVarID(fCdf, profParamAdjQcName);
               
               % parameter adjusted error variable and attributes
               profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
               profParamAdjErrVarId = netcdf.inqVarID(fCdf, profParamAdjErrName);
               
               % parameter data
               if (nbProfSubLevels == 0)
                  % there is no sublevels for all the profiles of this file
                  paramData = prof.data(:, idParam);
                  paramDataQc = prof.dataQc(:, idParam);
                  paramDataAdj = prof.dataAdj(:, idParam);
                  paramDataAdjQc = prof.dataAdjQc(:, idParam);
                  if (prof.direction == 'A')
                     measIds = fliplr([1:length(paramData)]);
                  else
                     measIds = [1:length(paramData)];
                  end
                  netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                  netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj(measIds));
                  
                  netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQc)]), paramDataQc(measIds));
                  netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdjQc)]), paramDataAdjQc(measIds));
               else
                  % some profiles have sublevels
                  if (isempty(prof.paramNumberWithSubLevels))
                     % there is no sublevels for this profile
                     paramData = prof.data(:, idParam);
                     paramDataQc = prof.dataQc(:, idParam);
                     paramDataAdj = prof.dataAdj(:, idParam);
                     paramDataAdjQc = prof.dataAdjQc(:, idParam);
                     if (prof.direction == 'A')
                        measIds = fliplr([1:length(paramData)]);
                     else
                        measIds = [1:length(paramData)];
                     end
                     netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                     netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj(measIds));
                     
                     netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQc)]), paramDataQc(measIds));
                     netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdjQc)]), paramDataAdjQc(measIds));
                  else
                     % there are sublevels for this profile
                     idParamWithSubLevels = find(prof.paramNumberWithSubLevels == idParam);
                     if (isempty(idParamWithSubLevels))
                        % this parameter has no sublevels
                        paramData = prof.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        paramDataQc = prof.dataQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        paramDataAdj = prof.dataAdj(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        paramDataAdjQc = prof.dataAdjQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        if (prof.direction == 'A')
                           measIds = fliplr([1:length(paramData)]);
                        else
                           measIds = [1:length(paramData)];
                        end
                        netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                        netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj(measIds));
                        
                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQc)]), paramDataQc(measIds));
                        netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdjQc)]), paramDataAdjQc(measIds));
                     else
                        % this parameter has sublevels
                        nbSubLevels = prof.paramNumberOfSubLevels(idParamWithSubLevels);
                        paramData = prof.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        paramDataQc = prof.dataQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        paramDataAdj = prof.dataAdj(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        paramDataAdjQc = prof.dataAdjQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        if (prof.direction == 'A')
                           measIds = fliplr([1:size(paramData, 1)]);
                        else
                           measIds = [1:size(paramData, 1)];
                        end
                        netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramData(measIds, :)');
                        netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramDataAdj(measIds, :)');
                        
                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramDataQc(measIds, :)');
                        netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramDataAdjQc(measIds, :)');
                        offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
                     end
                  end
               end
            else
               % parameter data
               if (nbProfSubLevels == 0)
                  % there is no sublevels for all the profiles of this file
                  paramData = prof.data(:, idParam);
                  paramDataQc = prof.dataQc(:, idParam);
                  paramDataAdj = prof.dataAdj(:, idParam);
                  paramDataAdjQc = prof.dataAdjQc(:, idParam);
                  if (prof.direction == 'A')
                     measIds = fliplr([1:length(paramData)]);
                  else
                     measIds = [1:length(paramData)];
                  end
                  netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                  netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj(measIds));
                  
                  netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQc)]), paramDataQc(measIds));
                  netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdjQc)]), paramDataAdjQc(measIds));
               else
                  % some profiles have sublevels
                  if (isempty(prof.paramNumberWithSubLevels))
                     % there is no sublevels for this profile
                     paramData = prof.data(:, idParam);
                     paramDataQc = prof.dataQc(:, idParam);
                     paramDataAdj = prof.dataAdj(:, idParam);
                     paramDataAdjQc = prof.dataAdjQc(:, idParam);
                     if (prof.direction == 'A')
                        measIds = fliplr([1:length(paramData)]);
                     else
                        measIds = [1:length(paramData)];
                     end
                     netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                     netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj(measIds));
                     
                     netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQc)]), paramDataQc(measIds));
                     netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdjQc)]), paramDataAdjQc(measIds));
                  else
                     % there are sublevels for this profile
                     idParamWithSubLevels = find(prof.paramNumberWithSubLevels == idParam);
                     if (isempty(idParamWithSubLevels))
                        % this parameter has no sublevels
                        paramData = prof.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        paramDataQc = prof.dataQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        paramDataAdj = prof.dataAdj(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        paramDataAdjQc = prof.dataAdjQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray));
                        if (prof.direction == 'A')
                           measIds = fliplr([1:length(paramData)]);
                        else
                           measIds = [1:length(paramData)];
                        end
                        netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                        netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj(measIds));
                        
                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQc)]), paramData(measIds));
                        netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataAdjQc)]), paramDataAdjQc(measIds));
                     else
                        % this parameter has sublevels
                        nbSubLevels = prof.paramNumberOfSubLevels(idParamWithSubLevels);
                        paramData = prof.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        paramDataQc = prof.dataQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        paramDataAdj = prof.dataAdj(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        paramDataAdjQc = prof.dataAdjQc(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        if (prof.direction == 'A')
                           measIds = fliplr([1:size(paramData, 1)]);
                        else
                           measIds = [1:size(paramData, 1)];
                        end
                        netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramData(measIds, :)');
                        netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramDataAdj(measIds, :)');
                        
                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramDataQc(measIds, :)');
                        netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0 0]), fliplr([1 length(measIds) nbSubLevels]), paramDataAdjQc(measIds, :)');
                        offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
                     end
                  end
               end
            end
         end
         
         % fill historical information
         nHistory = 0;
         value = 'IF';
         netcdf.putVar(fCdf, historyInstitutionVarId, ...
            fliplr([nHistory profPos 0]), fliplr([1 1 length(value)]), value');
         value = 'ARFM';
         netcdf.putVar(fCdf, historyStepVarId, ...
            fliplr([nHistory profPos 0]), fliplr([1 1 length(value)]), value');
         value = 'CODG';
         netcdf.putVar(fCdf, historySoftwareVarId, ...
            fliplr([nHistory profPos 0]), fliplr([1 1 length(value)]), value');
         value = g_decGl_decoderVersion;
         netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
            fliplr([nHistory profPos 0]), fliplr([1 1 length(value)]), value');
         value = datestr(currentDate, 'yyyymmddHHMMSS');
         netcdf.putVar(fCdf, historyDateVarId, ...
            fliplr([nHistory profPos 0]), fliplr([1 1 length(value)]), value');
         
         % fill RTQC reports
         if (~isempty(prof.testDoneList))
            testDone = sum(prof.testDoneList, 2);
            testDoneList = zeros(size(prof.testDoneList, 1), 1);
            idLev = find(testDone > 0);
            testDoneList(idLev) = 1;
            
            testFailed = sum(prof.testFailedList, 2);
            testFailedList = zeros(size(prof.testFailedList, 1), 1);
            idLev = find(testFailed > 0);
            testFailedList(idLev) = 1;
            
            % compute the report hex values
            testDoneHex = gl_compute_qctest_hex(find(testDoneList == 1));
            testFailedHex = gl_compute_qctest_hex(find(testFailedList == 1));

            % update history information
            nHistory = nHistory + 1;
            histoInstitution = 'IF';
            histoStep = 'ARGQ';
            histoSoftware = 'COQC';
            histoSoftwareRelease = g_decGl_rtqcVersion;
            dateUpdate = datestr(currentDate, 'yyyymmddHHMMSS');
                        
            for idHisto = 1:2
               if (idHisto == 1)
                  histoAction = 'QCP$';
                  histoQcTest = testDoneHex;
               else
                  nHistory = nHistory + 1;
                  histoAction = 'QCF$';
                  histoQcTest = testFailedHex;
               end
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(histoInstitution)]), histoInstitution');
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(histoStep)]), histoStep');
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(histoSoftware)]), histoSoftware');
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(histoSoftwareRelease)]), histoSoftwareRelease');
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(dateUpdate)]), dateUpdate');
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(histoAction)]), histoAction');
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
                  fliplr([nHistory profPos 0]), ...
                  fliplr([1 1 length(histoQcTest)]), histoQcTest');
            end
         end
         
         profInfo(idProfInFile(idP), 4) = 1;
      end
            
      netcdf.close(fCdf);
      
      if (g_decGl_realtimeFlag == 1)
         % store information for the XML report
         g_decGl_reportStruct.outputFiles = [g_decGl_reportStruct.outputFiles ...
            {ncPathFileName}];
      end
      
      o_generatedFiles = [o_generatedFiles {ncPathFileName}];

   end
end

fprintf('... NetCDF MONO-PROFILE files created\n');

return
