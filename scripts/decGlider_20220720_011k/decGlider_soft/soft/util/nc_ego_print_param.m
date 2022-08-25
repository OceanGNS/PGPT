% ------------------------------------------------------------------------------
% Print information on NetCDF file parameters. All the variable with a given
% dimension (TIME by default) are considered.
% The tool can also create initial mapping files (list of variables) that should
% be updated to link glider varaiable names to EGO ones.
%
% SYNTAX :
%  nc_ego_print_param(varargin)
%
% INPUT PARAMETERS :
%   varargin : input arguments (all mandatory)
%      must be provided in pairs i.e. ('argument_name', 'argument_value')
%      expected argument names:
%      'egofile' : input EGO nc file (file path name)
%      'egodir'  : directory of input EGO nc files
%      'dimname' : name of the dimension of the considered variables
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_print_param(varargin)

% directory of the EGO nc files
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\data_processing\mantis_25670_ego_files_from_bodc\bodc/';
% DATA_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\data_processing\mantis_25832_ego_files_from_socib\EGO_socib/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\TMP\test/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\VALIDATION_DOXY\crate_mooset00_38/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\TEST\GL_20150206_Ardbeg_Mission3/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\TEST\sg564_0213/';
DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\GLIDER\FORMAT_1.4/';

% directory to store lop file
LOG_DIRECTORY = 'C:\Users\jprannou\_RNU\Glider\work\log\';

% generate mapping files
GENERATE_MAP_FILES = 1;


% create log file
logFile = [LOG_DIRECTORY '/' 'nc_ego_print_param_' datestr(now, 'yyyymmddTHHMMSS.FFF') '.log'];
diary(logFile);

% check input arguments
egoFilePathName = [];
egoFileDirName = [];
dimName = 'TIME';
if (nargin > 0)
   if (rem(nargin, 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      diary off;
      return
   else
      for id = 1:2:nargin
         if (strcmpi(varargin{id}, 'egofile'))
            egoFilePathName = varargin{id+1};
         elseif (strcmpi(varargin{id}, 'egodir'))
            egoFileDirName = varargin{id+1};
         elseif (strcmpi(varargin{id}, 'dimname'))
            dimName = varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', varargin{id});
         end
      end
   end
end

% print the arguments understanding
fprintf('\nINFO: EGO file to check: ');
if (isempty(egoFileDirName) && isempty(egoFilePathName))
   egoFileDirName = DATA_DIRECTORY;
end
if (~isempty(egoFileDirName))
   fprintf('all files of the directory: %s\n', egoFileDirName);
else
   fprintf('file: %s\n', egoFilePathName);
end
fprintf('INFO: variables with dimension: %s\n', dimName);

% check inputs
if (~isempty(egoFileDirName))
   if ~(exist(egoFileDirName, 'dir') == 7)
      fprintf('ERROR: EGO dir not found: %s\n', egoFileDirName);
      return
   end
else
   if ~(exist(egoFilePathName, 'file') == 2)
      fprintf('ERROR: EGO file not found: %s\n', egoFilePathName);
      return
   end
end

% process the files
if (~isempty(egoFileDirName))
   ncFiles = dir([egoFileDirName '/*.nc']);
   for idF = 1:length(ncFiles)
      filePathName = [egoFileDirName '/' ncFiles(idF).name];
      nc_ego_print_param_file(filePathName, dimName, GENERATE_MAP_FILES);
   end
else
   nc_ego_print_param_file(egoFilePathName, dimName, GENERATE_MAP_FILES);
end

diary off;

return

% ------------------------------------------------------------------------------
% Print information for one NetCDF files.
%
% SYNTAX :
%  nc_ego_print_param_file(a_fileName, a_dimName, a_generateMapFileFlag)
%
% INPUT PARAMETERS :
%   a_fileName            : EGO NetCDF file path name
%   a_dimName             : name of the dimension of the considered variables
%   a_generateMapFileFlag : flag to generate initial mapping files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_ego_print_param_file(a_fileName, a_dimName, a_generateMapFileFlag)

% print file name
[~, name, ext] = fileparts(a_fileName);
fileName = [name ext];
fprintf('\nFile: %s\n', fileName);

% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_fileName);
   return
end

% retrieve the WMO number of the glider
wmo = [];
if( gl_att_is_present(fCdf, '', 'wmo_platform_code'))
   wmo = deblank(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'wmo_platform_code'));
end
if (isempty(wmo))
   fprintf('WARNING: glider WMO number is not provided in this file\n');
else
   fprintf('INFO: glider WMO number is ''%s''\n', wmo);
end

% info from the file
[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);

% retrieve the Id of the dimension
dimId = -1;
for idDim = 0:nbDims-1
   [dimName, dimLen] = netcdf.inqDim(fCdf, idDim);
   if (strcmp(dimName, a_dimName))
      dimId = idDim;
   end
end
if (dimId == -1)
   fprintf('''%s'' no present in file\n', a_dimName);
   netcdf.close(fCdf);
   return
end

% retrieve the variable names with this dimension
varNameList = [];
for idVar = 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
   if (sum(ismember(dimId, varDims)) > 0)
      varNameList{end+1} = varName;
   end
end

idDel = [];
for idVar = 1:length(varNameList)
   varName = varNameList{idVar};
   if (strcmp(varName(end-2:end), '_QC') || ...
         ((length(varName) > 12) && strcmp(varName(end-11:end), '_UNCERTAINTY')))
      idDel(end+1) = idVar;
   end
end
varNameList(idDel) = [];
varNameList = sort(varNameList);

% create the map file
if (a_generateMapFileFlag == 1)
   mapFileName = [a_fileName(1:end-3) '_map_ori.txt'];
   fidOut = fopen(mapFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create mapping file: %s\n', mapFileName);
   end
end

% output
for idVar = 1:length(varNameList)
   longName = [];
   standardName = [];
   units = [];

   varName = varNameList{idVar};
   varId = netcdf.inqVarID(fCdf, varName);
   [~, ~, ~, nbAtts] = netcdf.inqVar(fCdf, varId);
   for idAtt = 0:nbAtts-1
      attName = netcdf.inqAttName(fCdf, varId, idAtt);
      if (strcmp(attName, 'long_name'))
         longName = netcdf.getAtt(fCdf, varId, attName);
      elseif (strcmp(attName, 'standard_name'))
         standardName = netcdf.getAtt(fCdf, varId, attName);
      elseif (strcmp(attName, 'units'))
         units = netcdf.getAtt(fCdf, varId, attName);
      end
   end
   
   fprintf('Var #%02d: %s ( ''%s'' | ''%s'' | ''%s'')\n', ...
      idVar, varName, longName, standardName, units);
   if (a_generateMapFileFlag == 1)
      fprintf(fidOut, '%s\t\n', varName);
   end
end

if (a_generateMapFileFlag == 1)
   fclose(fidOut);
end

netcdf.close(fCdf);

return
