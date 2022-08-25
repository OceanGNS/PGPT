% ------------------------------------------------------------------------------
% Used in "gl_trace_parameter" tool.
% Read .nc deployment file and set global variables for "gl_trace_parameter"
% tool.
%
% SYNTAX :
%  gl_get_data_from_nc_for_gl_trace_parameter(a_ncFilePathName)
%
% INPUT PARAMETERS :
%   a_ncFilePathName : input .nc file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2022 - RNU - creation
% ------------------------------------------------------------------------------
function gl_get_data_from_nc_for_gl_trace_parameter(a_ncFilePathName)

% default values
global g_decGl_janFirst1950InMatlab;

global g_GTP_PARAM_NAME_1;
global g_GTP_PARAM_NAME_2;
global g_GTP_PARAM_1_WORK_DATA;
global g_GTP_PARAM_2_WORK_DATA;
global g_GTP_TIME_WORK_DATA;
global g_GTP_PARAM_1_WORK_DATA_QC;
global g_GTP_PARAM_2_WORK_DATA_QC;
global g_GTP_TIME_WORK_DATA_QC;
global g_GTP_PARAM_1_WORK_DATA_UNIT;
global g_GTP_PARAM_2_WORK_DATA_UNIT;
global g_GTP_TIME_WORK_DATA_UNIT;


% list of variables to retrieve from NetCDF file
paramList = [ ...
   {'TIME'} ...
   {'TIME_QC'} ...
   {g_GTP_PARAM_NAME_1} ...
   {g_GTP_PARAM_NAME_2} ...
   ];
wantedVars = [];
for idParam = 1:length(paramList)
   param = paramList{idParam};
   wantedVars = [wantedVars ...
      {param} {[param '_QC']}];
end

% retrieve variables from NetCDF file
[ncData] = gl_get_data_from_nc_file(a_ncFilePathName, wantedVars);
if (~isempty(ncData))

   time = gl_get_data_from_name('TIME', ncData);
   timeQc = gl_get_data_from_name('TIME_QC', ncData);

   param1 = gl_get_data_from_name(g_GTP_PARAM_NAME_1, ncData);
   if (isempty(param1))
      fprintf('WARNING: ''%s'' parameter not found in file :%s\n', ...
         g_GTP_PARAM_NAME_1, a_ncFilePathName)
   end
   param1Qc = gl_get_data_from_name([g_GTP_PARAM_NAME_1 '_QC'], ncData);

   param2 = gl_get_data_from_name(g_GTP_PARAM_NAME_2, ncData);
   if (isempty(param1))
      fprintf('WARNING: ''%s'' parameter not found in file :%s\n', ...
         g_GTP_PARAM_NAME_2, a_ncFilePathName)
   end
   param2Qc = gl_get_data_from_name([g_GTP_PARAM_NAME_2 '_QC'], ncData);
end

% set data
paramInfo = gl_get_netcdf_param_attributes('TIME');
idFv = find(time == paramInfo.fillValue);
time(idFv) = [];
timeQc(idFv) = [];
param1(idFv) = [];
param1Qc(idFv) = [];
param2(idFv) = [];
param2Qc(idFv) = [];
g_GTP_TIME_WORK_DATA_UNIT = paramInfo.units;
g_GTP_TIME_WORK_DATA = gl_epoch_2_julian(time) + g_decGl_janFirst1950InMatlab;
g_GTP_TIME_WORK_DATA_QC = timeQc;

paramInfo = gl_get_netcdf_param_attributes(g_GTP_PARAM_NAME_1);
idFv = find(param1 == paramInfo.fillValue);
param1(idFv) = nan;
param1Qc(idFv) = nan;
g_GTP_PARAM_1_WORK_DATA_UNIT = paramInfo.units;
g_GTP_PARAM_1_WORK_DATA = param1;
g_GTP_PARAM_1_WORK_DATA_QC = param1Qc;

paramInfo = gl_get_netcdf_param_attributes(g_GTP_PARAM_NAME_2);
idFv = find(param2 == paramInfo.fillValue);
param2(idFv) = nan;
param2Qc(idFv) = nan;
g_GTP_PARAM_2_WORK_DATA_UNIT = paramInfo.units;
g_GTP_PARAM_2_WORK_DATA = param2;
g_GTP_PARAM_2_WORK_DATA_QC = param2Qc;

return
