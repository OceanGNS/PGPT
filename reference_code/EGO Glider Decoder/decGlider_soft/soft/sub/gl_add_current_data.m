% ------------------------------------------------------------------------------
% Add subsurface current estimates in and existing EGO netCDF file.
%
% SYNTAX :
%  gl_add_current_data(a_subCurEst, a_ncFileName)
%
% INPUT PARAMETERS :
%   a_subCurEst  : subsurface current estimates data
%   a_ncFileName : EGO netCDF file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/12/2014 - RNU - creation
% ------------------------------------------------------------------------------
function gl_add_current_data(a_subCurEst, a_ncFileName)

% check the input file
if ~(~exist(a_ncFileName, 'dir') && exist(a_ncFileName, 'file'))
   fprintf('ERROR: file not found : %s\n', ...
      a_ncFileName);
   return
end

% get the input file structure
ncFileStruct = ncinfo(a_ncFileName);

% the output file will be a temporary NetCDF file
[pathstr, name, ext] = fileparts(a_ncFileName);
ncOutputFileName = [pathstr '/tmp/tmp_' datestr(now, 'yyyymmddTHHMMSS') '.nc'];

% create output NetCDF file with the file structure
ncwriteschema(ncOutputFileName, ncFileStruct);

% open the output file to update it
fCdfOut = netcdf.open(ncOutputFileName, 'NC_WRITE');
if (isempty(fCdfOut))
   fprintf('ERROR: Unable to open file: %s\n', ncOutputFileName);
   return
end

netcdf.reDef(fCdfOut);

globalVarId = netcdf.getConstant('NC_GLOBAL');

currentDate = datestr(gl_now_utc, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdfOut, globalVarId, 'date_update', currentDate);

attValue = [netcdf.getAtt(fCdfOut, globalVarId, 'history') '; ' ...
   currentDate ' ' ...
   sprintf('Appended sub-surface current estimates')];
netcdf.putAtt(fCdfOut, globalVarId, 'history', attValue);

% add current dimension and variables

nTimeCurDimId = netcdf.defDim(fCdfOut, 'TIME_CURRENT', length(a_subCurEst));

wCurTimeVarId = netcdf.defVar(fCdfOut, 'WATERCURRENTS_TIME', 'NC_DOUBLE', nTimeCurDimId);
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'long_name', 'Epoch time of the sub-surface current estimate');
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'standard_name', 'time');
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'units', 'seconds since 1970-01-01T00:00:00Z');
netcdf.putAtt(fCdfOut, wCurTimeVarId, '_FillValue', double(9999999999));
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'valid_min', double(0));
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'valid_max', double(90000));
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'comment', '');
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'axis', 'T');
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'sdn_parameter_urn', 'SDN:P01::ELTMEP01');
netcdf.putAtt(fCdfOut, wCurTimeVarId, 'sdn_uom_urn', 'SDN:P06::UTBB');

wCurLatitudeVarId = netcdf.defVar(fCdfOut, 'WATERCURRENTS_LATITUDE', 'NC_DOUBLE', nTimeCurDimId);
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, 'long_name', 'Latitude of the sub-surface current estimate');
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, 'standard_name', 'latitude');
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, 'units', 'degree_north');
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, '_FillValue', double(99999));
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, 'valid_min', double(-90));
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, 'valid_max', double(90));
netcdf.putAtt(fCdfOut, wCurLatitudeVarId, 'axis', 'Y');

wCurLongitudeVarId = netcdf.defVar(fCdfOut, 'WATERCURRENTS_LONGITUDE', 'NC_DOUBLE', nTimeCurDimId);
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, 'long_name', 'Longitude of the sub-surface current estimate');
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, 'standard_name', 'longitude');
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, 'units', 'degree_east');
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, '_FillValue', double(99999));
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, 'valid_min', double(-180));
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, 'valid_max', double(180));
netcdf.putAtt(fCdfOut, wCurLongitudeVarId, 'axis', 'X');

wCurDepthVarId = netcdf.defVar(fCdfOut, 'WATERCURRENTS_DEPTH', 'NC_FLOAT', nTimeCurDimId);
netcdf.putAtt(fCdfOut, wCurDepthVarId, 'long_name', 'Depth of the sub-surface current estimate');
netcdf.putAtt(fCdfOut, wCurDepthVarId, 'standard_name', 'depth');
netcdf.putAtt(fCdfOut, wCurDepthVarId, 'units', 'm');
netcdf.putAtt(fCdfOut, wCurDepthVarId, '_FillValue', single(99999));

wCurUVarId = netcdf.defVar(fCdfOut, 'WATERCURRENTS_U', 'NC_FLOAT', nTimeCurDimId);
netcdf.putAtt(fCdfOut, wCurUVarId, 'long_name', 'Eastward component of the sub-surface current estimate');
netcdf.putAtt(fCdfOut, wCurUVarId, 'standard_name', 'eastward_sea_water_velocity');
netcdf.putAtt(fCdfOut, wCurUVarId, 'units', 'cm/s');
netcdf.putAtt(fCdfOut, wCurUVarId, '_FillValue', single(99999));

wCurVVarId = netcdf.defVar(fCdfOut, 'WATERCURRENTS_V', 'NC_FLOAT', nTimeCurDimId);
netcdf.putAtt(fCdfOut, wCurVVarId, 'long_name', 'Northward component of the sub-surface current estimate');
netcdf.putAtt(fCdfOut, wCurVVarId, 'standard_name', 'northward_sea_water_velocity');
netcdf.putAtt(fCdfOut, wCurVVarId, 'units', 'cm/s');
netcdf.putAtt(fCdfOut, wCurVVarId, '_FillValue', single(99999));

netcdf.endDef(fCdfOut);

% open input NetCDF file
fCdfIn = netcdf.open(a_ncFileName, 'NC_NOWRITE');
if (isempty(fCdfIn))
   fprintf('ERROR: Unable to open file: %s\n', a_ncFileName);
   return
end

varNameWithTimeDim = gl_var_list_using_dim(fCdfOut, 'TIME');

% copy the data in the output file
for idVar = 1:length(ncFileStruct.Variables)
   varName = ncFileStruct.Variables(idVar).Name;
   if (~isempty(find(strcmp(varName, varNameWithTimeDim) == 1, 1)))
      % because TIME is the UNLIMITED dimension, it is not reported through
      % ncwriteschema
      netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), ...
         0, length(netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName))), netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName)));
   else
      netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), ...
         netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName)));
   end
end

netcdf.close(fCdfIn);

% convert Julian 1950 to EPOCH 1970 dates
epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
julD = [a_subCurEst.time];
epochTime = (julD - epoch_offset)*86400;

% append the current data to the output file

netcdf.putVar(fCdfOut, wCurTimeVarId, epochTime);
netcdf.putVar(fCdfOut, wCurLatitudeVarId, [a_subCurEst.lat]);
netcdf.putVar(fCdfOut, wCurLongitudeVarId, [a_subCurEst.lon]);
netcdf.putVar(fCdfOut, wCurDepthVarId, [a_subCurEst.mean_depth]);
netcdf.putVar(fCdfOut, wCurUVarId, [a_subCurEst.water_vx]*100);
netcdf.putVar(fCdfOut, wCurVVarId, [a_subCurEst.water_vy]*100);

netcdf.close(fCdfOut);

movefile(ncOutputFileName, a_ncFileName);

return
