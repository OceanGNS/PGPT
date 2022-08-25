% ------------------------------------------------------------------------------
% Print information on SeaGlider input NetCDF files.
%
% SYNTAX :
%  nc_seaglider_nc_print_info(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      mandatory argument name:
%      'data' : identify the deployment (i.e. the sub-directory of the
%               DATA_DIRECTORY directory) to process
%      not mandatory argument name:
%      'nbfiles' : number of NetCDF files to print (default value is '1')
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2020 - RNU - creation
% ------------------------------------------------------------------------------
function nc_seaglider_nc_print_info(varargin)

% directory of the EGO nc files
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\NC/';

% directory to store lop file
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';


% create log file
logFile = [LOG_DIRECTORY '/' 'nc_seaglider_nc_print_info_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
if (~isempty(DATA_DIRECTORY))
   if ~(exist(DATA_DIRECTORY, 'dir') == 7)
      fprintf('ERROR: DATA_DIRECTORY directory not found: %s\n', DATA_DIRECTORY);
      return
   end
end

dataToProcessDir = [];
nbFiles = 1;
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'data'))
            if (exist([DATA_DIRECTORY '/' varargin{id+1}], 'dir'))
               dataToProcessDir = [DATA_DIRECTORY '/' varargin{id+1}];
            else
               fprintf('WARNING: %s is not an existing directory => exit\n', varargin{id+1});
            end
         elseif (strcmpi(varargin{id}, 'nbfiles'))
            nbFiles = str2num(varargin{id+1});
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
else
   fprintf('ERROR: expecting ''data'' input parameter => exit\n');
end

if (isempty(dataToProcessDir))
   return
end

% process the files
ncFiles = dir([dataToProcessDir '/nc_sg/*.nc']);
for idF = 1:min(nbFiles, length(ncFiles))
   filePathName = [dataToProcessDir '/nc_sg/' ncFiles(idF).name];
   nc_seaglider_nc_print_info_file(filePathName, idF);
end

diary off;

return

% ------------------------------------------------------------------------------
% Print information on one SeaGlider input NetCDF files.
%
% SYNTAX :
%  nc_seaglider_nc_print_info_file(a_fileName, a_fileNum)
%
% INPUT PARAMETERS :
%   a_fileName : NetCDF file path name
%   a_fileName : NetCDF file number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2020 - RNU - creation
% ------------------------------------------------------------------------------
function nc_seaglider_nc_print_info_file(a_fileName, a_fileNum)

% list of managed sensors
managedSensorList = [ ...
   {'sbe41'} ...
   {'aa4831'} ...
   {'wlbbfl2'} ...
   ];

% print file name
[~, name, ext] = fileparts(a_fileName);
fileName = [name ext];
fprintf('\n########################################################################################################################\n');
fprintf('File #%d: %s\n', a_fileNum, fileName);

% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_fileName);
   return
end

% print instrument list
instrumentList = [];
if( gl_att_is_present(fCdf, '', 'instrument'))
   instrumentList = deblank(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'instrument'));
end
if (isempty(instrumentList))
   fprintf('WARNING: glider instrument list is not provided in this file\n');
else
   fprintf('instrument = ''%s''\n', instrumentList);
end

% print global attributes
fprintf('\n************************************************************************************************************************\n');
fprintf('GLOBAL ATTRBUTES:\n');
[nDims, nVars, nGAtts, unlimdimid] = netcdf.inq(fCdf);
globalVarId = netcdf.getConstant('NC_GLOBAL');
for idAtt = 0:nGAtts-1
   attName = netcdf.inqAttName(fCdf, globalVarId, idAtt);
   attValue = netcdf.getAtt(fCdf, globalVarId, attName);
   if (ischar(attValue))
      fprintf('   :%s = "%s"\n', attName, attValue);
   else
      fprintf('   :%s = %g\n', attName, attValue);
   end
end

% print calibration variables
fprintf('\n************************************************************************************************************************\n');
fprintf('CALIBRATION VARIABLES:\n');
for idVar = 0:nVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
   if (isempty(varDims) && strncmp(varName, 'sg_cal_', length('sg_cal_')))
      fprintf('   %s = %g\n', varName, netcdf.getVar(fCdf, idVar));
      for idAtt = 0:nbAtts-1
         attName = netcdf.inqAttName(fCdf, idVar, idAtt);
         attValue = netcdf.getAtt(fCdf, idVar, attName);
         fprintf('      %s:%s = "%s"\n', varName, attName, attValue);
      end
   end
end

% print GPS variables
gpsDimName = 'gps_info';
if (gl_dim_is_present(fCdf, gpsDimName))
   gpsVarList =  gl_var_list_using_dim(fCdf, gpsDimName);
   fprintf('\n************************************************************************************************************************\n');
   fprintf('GPS VARIABLES:\n');
   for idV = 1:length(gpsVarList)
      idVar = netcdf.inqVarID(fCdf, gpsVarList{idV});
      [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
      dimList = [];
      for idDim = varDims
         [dimname, dimlen] = netcdf.inqDim(fCdf, idDim);
         dimList{end+1} = dimname;
      end
      dimListStr = sprintf('%s, ', dimList{:});
      fprintf('   %s(%s)\n', varName, dimListStr(1:end-2));
      for idAtt = 0:nbAtts-1
         attName = netcdf.inqAttName(fCdf, idVar, idAtt);
         attValue = netcdf.getAtt(fCdf, idVar, attName);
         fprintf('      %s:%s = "%s"\n', varName, attName, attValue);
      end
   end
else
   fprintf('WARNING: cannot find GPS dimension (''%s'')\n', gpsDimName);
end

% print CTD variables
ctdDimName = 'ctd_data_point';
if (gl_dim_is_present(fCdf, ctdDimName))
   ctdVarList =  gl_var_list_using_dim(fCdf, ctdDimName);
   fprintf('\n************************************************************************************************************************\n');
   fprintf('CTD VARIABLES:\n');
   for idV = 1:length(ctdVarList)
      idVar = netcdf.inqVarID(fCdf, ctdVarList{idV});
      [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
      dimList = [];
      for idDim = varDims
         [dimname, dimlen] = netcdf.inqDim(fCdf, idDim);
         dimList{end+1} = dimname;
      end
      dimListStr = sprintf('%s, ', dimList{:});
      fprintf('   %s(%s)\n', varName, dimListStr(1:end-2));
      for idAtt = 0:nbAtts-1
         attName = netcdf.inqAttName(fCdf, idVar, idAtt);
         attValue = netcdf.getAtt(fCdf, idVar, attName);
         fprintf('      %s:%s = "%s"\n', varName, attName, attValue);
      end
   end
else
   fprintf('WARNING: cannot find CTD dimension (''%s'')\n', ctdDimName);
end

% print other sensor variables
sensorList = strsplit(instrumentList, ' ');
for idS = 1:length(sensorList)
   sensorName = sensorList{idS};
   if (ismember(sensorName, managedSensorList))
      
      if (gl_var_is_present(fCdf, sensorName))
         
         fprintf('\n************************************************************************************************************************\n');
         fprintf('SENSOR: %s\n', sensorName);
         idVar = netcdf.inqVarID(fCdf, sensorName);
         [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
         for idAtt = 0:nbAtts-1
            attName = netcdf.inqAttName(fCdf, idVar, idAtt);
            attValue = netcdf.getAtt(fCdf, idVar, attName);
            fprintf('   %s:%s = "%s"\n', varName, attName, attValue);
         end
         
         sensorVarList = gl_var_list_using_att(fCdf, 'instrument', sensorName);
         fprintf('\n   SENSOR VARIABLES:\n');
         for idV = 1:length(sensorVarList)
            idVar = netcdf.inqVarID(fCdf, sensorVarList{idV});
            [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
            dimList = [];
            for idDim = varDims
               [dimname, dimlen] = netcdf.inqDim(fCdf, idDim);
               dimList{end+1} = dimname;
            end
            dimListStr = sprintf('%s, ', dimList{:});
            fprintf('      %s(%s)\n', varName, dimListStr(1:end-2));
            for idAtt = 0:nbAtts-1
               attName = netcdf.inqAttName(fCdf, idVar, idAtt);
               attValue = netcdf.getAtt(fCdf, idVar, attName);
               fprintf('            %s:%s = "%s"\n', varName, attName, attValue);
            end
         end
      else
         fprintf('WARNING: variable ''%s'' is missing\n', sensorName);
      end
   else
      fprintf('WARNING: don''t know how to manage sensor ''%s''\n', sensorName);
      continue
   end
end

netcdf.close(fCdf);

return
