% ------------------------------------------------------------------------------
% This decodes seaglider data from a single yo NetCDF text format and places
% it in a matlab structure for subsequent conversion to EGO netcdf format
% by EGO routines.
%
% SYNTAX :
% gl_decode_seaglider_nc(a_ncFileNameIn, a_matFileNameOut)
%
% INPUT PARAMETERS :
%   a_ncFileNameIn   : name of the input NetCDF file from a yo
%   a_matFileNameOut : name of the output .mat file containing the structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function gl_decode_seaglider_nc(a_ncFileNameIn, a_matFileNameOut)

% read data from the .nc file
rawDataFull = gl_seaglider_netcdf_nc2matlab(a_ncFileNameIn);

% merge parameter measurements on the same time axis
rawDataFull = gl_seaglider_merge_nc_data(rawDataFull);

% output structure
rawData = [];
rawData.source = rawDataFull.source;
rawData.vars_time = rawDataFull.nc;
rawData.vars_time_gps = get_gps_data(rawDataFull);

% compute and add derived parameters
rawData = gl_add_derived_parameters(rawData);

save(a_matFileNameOut, 'rawData');

return

% ------------------------------------------------------------------------------
% Parse GPS data collected in a NetCDF file.
%
% SYNTAX :
%  [o_structure] = gl_parse_gps_data(a_structure)
%
% INPUT PARAMETERS :
%   a_structure : input GPS data structure (from NetCDF file)
%
% OUTPUT PARAMETERS :
%   a_structure : output parsed GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_structure] = get_gps_data(a_structure)

% output data initialization
o_structure = [];

if (isfield(a_structure.VAR, 'log_gps_time') && ...
      isfield(a_structure.VAR, 'log_gps_lon') && ...
      isfield(a_structure.VAR, 'log_gps_lat'))
   o_structure.time = (a_structure.VAR.log_gps_time.DATA)';
   o_structure.longitude = (a_structure.VAR.log_gps_lon.DATA)';
   o_structure.latitude = (a_structure.VAR.log_gps_lat.DATA)';
end

return
