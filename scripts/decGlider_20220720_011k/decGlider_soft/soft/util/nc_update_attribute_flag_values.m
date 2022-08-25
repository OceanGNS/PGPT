% ------------------------------------------------------------------------------
% Update the EGO format of NetCDF files.
% The default behaviour is :
%    - to process all the deployments (the directories) stored in the
%      DIR_INPUT_NC_FILES directory this behaviour can be modified by input
%      arguments.
%
% SYNTAX :
%   nc_update_attribute_flag_values or 
%   nc_update_attribute_flag_values('data', 'crate_mooset00_38')
%
% INPUT PARAMETERS :
%   varargin : input arguments
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DIR_INPUT_NC_FILES directory) to process
%      if no argument is provided: all the deployments of the
%      DIR_INPUT_NC_FILES directory are processed
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/19/2017 - RNU - V 01aa: update 'flag_values' attributes (replace string
%                              enumeration with list of allowed values).
% ------------------------------------------------------------------------------
function nc_update_attribute_flag_values(varargin)

% top directory of the deployment directories
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY/';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\Glider\work\';

% default values initialization
gl_init_default_values;

% program version
global g_couf_ncUpdateEGOFormatVersion;
g_couf_ncUpdateEGOFormatVersion = '01aa';

% list of updated files
global g_couf_updatedFileList;
g_couf_updatedFileList = [];


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_update_attribute_flag_values_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check input arguments
dataToProcessDir = [];
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            if (exist([DIR_INPUT_NC_FILES '/' varargin{id+1}], 'dir'))
               dataToProcessDir = [DIR_INPUT_NC_FILES '/' varargin{id+1}];
            else
               fprintf('WARNING: %s is not an existing directory => ignored\n', varargin{id+1});
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
end

% convert glider data
if (isempty(dataToProcessDir))
   % update all the deployments of the DIR_INPUT_NC_FILES directory
   dirInfo = dir(DIR_INPUT_NC_FILES);
   for dirNum = 1:length(dirInfo)
      if ~(strcmp(dirInfo(dirNum).name, '.') || strcmp(dirInfo(dirNum).name, '..'))
         dirName = dirInfo(dirNum).name;
         
         nc_update_attribute_flag_values_file([DIR_INPUT_NC_FILES '/' dirName]);
      end
   end
else
   % convert the data of this deployment
   nc_update_attribute_flag_values_file(dataToProcessDir);
end

fprintf('\nLIST OF UPDATED FILES:\n');
if (~isempty(g_couf_updatedFileList))
   for idFile = 1:length(g_couf_updatedFileList)
      fprintf('%s\n', g_couf_updatedFileList{idFile});
   end
else
   fprintf('NONE\n');
end
fprintf('\n');

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Update NetCDF EGO files of a provided directory.
%
% SYNTAX :
%  nc_update_attribute_flag_values_file(a_dirName)
%
% INPUT PARAMETERS :
%   a_dirName : directory of the EGO file(s)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/19/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_update_attribute_flag_values_file(a_dirName)

% program version
global g_couf_ncUpdateEGOFormatVersion;

% list of updated files
global g_couf_updatedFileList;


ncFiles = dir([a_dirName '/*.nc']);
for idF = 1:length(ncFiles)
   ncFileName = ncFiles(idF).name;
   [~, name, ext] = fileparts(ncFileName);
   inputFilePathName = [a_dirName '/' name ext];
   
   % check if the file need to be updated
   updateNeeded = 0;
   
   % open NetCDF file
   fCdf = netcdf.open(inputFilePathName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', inputFilePathName);
      return
   end
   
   [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
   
   for idVar = 0:nbVars-1
      [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
      for idAtt = 0:nbAtts-1
         attName = netcdf.inqAttName(fCdf, netcdf.inqVarID(fCdf, varName), idAtt);
         if (strcmp(attName, 'flag_values'))
            attValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName);
            if (ischar(attValue))
               updateNeeded = 1;
               break
            end
         end
      end
      if (updateNeeded == 1)
         break
      end
   end
   
   netcdf.close(fCdf);
   
   % update the file
   if (updateNeeded == 1)
      
      fprintf('File %s:\n', inputFilePathName)
      
      % open NetCDF file
      fCdf = netcdf.open(inputFilePathName, 'NC_WRITE');
      if (isempty(fCdf))
         fprintf('ERROR: Unable to open NetCDF input file: %s\n', inputFilePathName);
         return
      end
      
      netcdf.reDef(fCdf);
      
      [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
      
      for idVar = 0:nbVars-1
         [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
         for idAtt = 0:nbAtts-1
            attName = netcdf.inqAttName(fCdf, netcdf.inqVarID(fCdf, varName), idAtt);
            if (strcmp(attName, 'flag_values'))
               attValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName);
               if (ischar(attValue))
                  %                fprintf('varName: %s\n', varName);
                  switch (varName)
                     case {'POSITIONING_METHOD'}
                        newAttValue = [0, 1, 2];
                     case {'PHASE'}
                        newAttValue = [0, 1, 2, 3, 4, 5, 6];
                     case { ...
                           'TIME_QC', ...
                           'JULD_QC', ...
                           'POSITION_QC' ...
                           'TIME_GPS_QC', ...
                           'POSITION_GPS_QC' ...
                           'DEPLOYMENT_START_QC', ...
                           'DEPLOYMENT_END_QC', ...
                           }
                        newAttValue = [0, 1, 2, 3, 4, 5, 8, 9];
                     otherwise
                        if (~isempty(gl_get_ego_var_attributes(varName(1:end-3))))
                           newAttValue = [0, 1, 2, 3, 4, 5, 8, 9];
                        else
                           fprintf('ERROR: Don''t know haow to update ''flag_values'' attribute for variable : %s\n', varName);
                           return
                        end
                  end
                  fprintf('   - Updating att ''%s'' of var ''%s'': %s => %s\n', ...
                     attName, varName, attValue, num2str(newAttValue));
                  netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, uint8(newAttValue));
               end
            end
         end
      end
      
      netcdf.close(fCdf);
      
      % update history information
      
      % modify the N_HISTORY dimension of the EGO file
      [ok] = gl_update_n_history_dim_in_ego_file(inputFilePathName, 1);
      if (ok == 0)
         fprintf('RTQC_ERROR: Unable to update the N_HISTORY dimension of the NetCDF file: %s\n', inputFilePathName);
         return
      end
      
      % date of the file update
      dateUpdate = datestr(gl_now_utc, 'yyyymmddHHMMSS');
      
      % update the EGO file
            
      % open the file to update
      fCdf = netcdf.open(inputFilePathName, 'NC_WRITE');
      if (isempty(fCdf))
         fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', inputFilePathName);
         return
      end
      
      % update miscellaneous information
      
      % update the 'date_update' et 'history' global attributes
      netcdf.reDef(fCdf);
      globalVarId = netcdf.getConstant('NC_GLOBAL');
      
      currentDate = datestr(gl_now_utc, 'yyyy-mm-ddTHH:MM:SSZ');
      netcdf.putAtt(fCdf, globalVarId, 'date_update', currentDate);
      
      attValue = [netcdf.getAtt(fCdf, globalVarId, 'history') '; ' ...
         currentDate ' ' ...
         'Coriolis COUF software (V ' g_couf_ncUpdateEGOFormatVersion ')'];
      netcdf.putAtt(fCdf, globalVarId, 'history', attValue);
      netcdf.endDef(fCdf);
      
      % update history information
      [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
      histoInstitution = 'IF';
      histoSoftware = 'COUF';
      histoSoftwareRelease = g_couf_ncUpdateEGOFormatVersion;
      
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoInstitution)]), histoInstitution');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoSoftware)]), histoSoftware');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoSoftwareRelease)]), histoSoftwareRelease');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(dateUpdate)]), dateUpdate');
      
      netcdf.close(fCdf);
      
      g_couf_updatedFileList{end+1} = inputFilePathName;
   end
end

return
