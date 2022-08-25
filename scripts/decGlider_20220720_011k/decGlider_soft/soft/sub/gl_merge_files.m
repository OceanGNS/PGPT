% ------------------------------------------------------------------------------
% Merge data of multiple EGO netCDF files into a unique file.
%
% SYNTAX :
%  [o_ok] = gl_merge_files(a_ncFinalOutputPathFile, a_ncDirPathName)
%
% INPUT PARAMETERS :
%   a_ncFinalOutputPathFile : output EGO file path name
%   a_ncDirPathName         : directory of input EGO files
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if merge process succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = gl_merge_files(a_ncFinalOutputPathFile, a_ncDirPathName)

% output parameters initialization
o_ok = 0;

% real time processing
global g_decGl_realtimeFlag;

% report information structure
global g_decGl_reportStruct;


% create the list of individual EGO NetCDF file to be merged
timeInfo = gl_get_netcdf_param_attributes('TIME');
ncFiles = dir([a_ncDirPathName '/*.nc']);
fileNameList = cell(1, length(ncFiles));
fileDateList = double(zeros(1, length(ncFiles)));
idDel = [];
for idF = 1:length(ncFiles)
   % retrieve TIME data from individual EGO NetCDF file
   [ncEgoData] = gl_get_data_from_nc_file([a_ncDirPathName '/' ncFiles(idF).name], {'TIME'});
   time = gl_get_data_from_name('TIME', ncEgoData)';
   time(time == timeInfo.fillValue) = [];
   if (~isempty(time))
      fileNameList{idF} = ncFiles(idF).name;
      fileDateList(idF) = median(time);
   else
      idDel = [idDel idF];
   end
end
fileNameList(idDel) = [];
fileDateList(idDel) = [];
[~, idSort] = sort(fileDateList);
fileNameList = fileNameList(idSort);
if (isempty(fileNameList))
   o_ok = 1;
   return
end

% collect data (indexed with TIME, TIME_GPS or TIME_CURRENT) from individual
% EGO NetCDF files
dataDimNames = [{'TIME'} {'TIME_GPS'} {'TIME_CURRENT'}];
ncData = [];
varNameList = [];
phaseNumberOffset = 0;
for idF = 1:length(fileNameList)

   newStruct = struct( ...
      'file_name', fileNameList{idF}, ...
      'TIME_DIM', 0, ...
      'TIME_GPS_DIM', 0, ...
      'TIME_CURRENT_DIM', 0, ...
      'TIME', [], ...
      'TIME_GPS', [], ...
      'TIME_CURRENT', []);

   ncFilePathName = [a_ncDirPathName '/' fileNameList{idF}];

   fCdfIn = netcdf.open(ncFilePathName, 'NC_NOWRITE');
   if (isempty(fCdfIn))
      fprintf('ERROR: Unable to open file: %s\n', ncFilePathName);
      return
   end

   for IdD = 1:length(dataDimNames)
      
      % do not consider 'empty variables' data
      if (gl_var_is_present(fCdfIn, dataDimNames{IdD}))
         dataDim = netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, dataDimNames{IdD}));
         if (length(dataDim) == 1)
            fillValue = netcdf.getAtt(fCdfIn, netcdf.inqVarID(fCdfIn, dataDimNames{IdD}), '_FillValue');
            if (dataDim == fillValue)
               continue
            end
         end
      end
      
      varNames = gl_var_list_using_dim(fCdfIn, dataDimNames{IdD});
      for idV = 1:length(varNames)
         varName = varNames{idV};
         data = netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName));
         
         % PHASE_NUMBER values should be updated
         if (strcmp(varName, 'PHASE_NUMBER'))
            fillValue = netcdf.getAtt(fCdfIn, netcdf.inqVarID(fCdfIn, 'PHASE_NUMBER'), '_FillValue');
            idNotFillVal = find(data ~= fillValue);
            if (~isempty(idNotFillVal))
               data(idNotFillVal) = data(idNotFillVal) + phaseNumberOffset;
               phaseNumberOffset = max(data(idNotFillVal)) + 1;
            end
         end
         
         newStruct.([dataDimNames{IdD} '_DIM']) = length(data);
         newStruct.(dataDimNames{IdD}){end+1} = varNames{idV};
         newStruct.(dataDimNames{IdD}){end+1} = data;
      end
      varNameList = [varNameList varNames];
   end
   
   netcdf.close(fCdfIn);

   ncData = [ncData newStruct];
end
varNameList = unique(varNameList);

% retrieve the file schema
outputFileSchema = ncinfo([a_ncDirPathName '/' fileNameList{1}]);

% set the dimensions of the final file
if (ismember('TIME', {outputFileSchema.Dimensions.Name}))
   % update the file schema with the correct final dimension
   outputFileSchema = gl_update_dim_in_nc_schema(outputFileSchema, ...
      'TIME', max(sum([ncData.TIME_DIM]), 1));
end
if (ismember('TIME_GPS', {outputFileSchema.Dimensions.Name}))
   % update the file schema with the correct final dimension
   outputFileSchema = gl_update_dim_in_nc_schema(outputFileSchema, ...
      'TIME_GPS', max(sum([ncData.TIME_GPS_DIM]), 1));
end
if (ismember('TIME_CURRENT', {outputFileSchema.Dimensions.Name}))
   % update the file schema with the correct final dimension
   outputFileSchema = gl_update_dim_in_nc_schema(outputFileSchema, ...
      'TIME_CURRENT', max(sum([ncData.TIME_CURRENT_DIM]), 1));
end

% create the merged file
[filePath, fileName, ~] = fileparts(a_ncFinalOutputPathFile);
ncTempPathFileName = [filePath '/tmp/tmp_' fileName '_' datestr(now, 'yyyymmddTHHMMSS') '.nc'];
ncwriteschema(ncTempPathFileName, outputFileSchema);

% fill the merged file
fCdfOut = netcdf.open(ncTempPathFileName, 'NC_WRITE');
if (isempty(fCdfOut))
   fprintf('ERROR: Unable to open file: %s\n', ncTempPathFileName);
   return
end

% duplicate data from the first individual file
fCdfIn = netcdf.open([a_ncDirPathName '/' fileNameList{1}], 'NC_NOWRITE');
if (isempty(fCdfIn))
   fprintf('ERROR: Unable to open file: %s\n', [a_ncDirPathName '/' fileNameList{1}]);
   return
end

% copy the data in the output file
for idVar = 1:length(outputFileSchema.Variables)
   varName = outputFileSchema.Variables(idVar).Name;
   if (~ismember(varName, varNameList))
      netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), ...
         netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName)));
   end
end

netcdf.close(fCdfIn);

% copy the data (indexed with TIME, TIME_GPS or TIME_CURRENT) in the output file
idTime = 0;
idTimeGps = 0;
idTimeCurrent = 0;
for idS = 1:length(ncData)
   dataStruct = ncData(idS);
   if (dataStruct.TIME_DIM > 0)
      dataVar = dataStruct.TIME;
      for idV = 1:2:length(dataVar)
         netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, dataVar{idV}), ...
            idTime, length(dataVar{idV+1}), dataVar{idV+1});
      end
      idTime = idTime + dataStruct.TIME_DIM;
   end
   if (dataStruct.TIME_GPS_DIM > 0)
      dataVar = dataStruct.TIME_GPS;
      for idV = 1:2:length(dataVar)
         netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, dataVar{idV}), ...
            idTimeGps, length(dataVar{idV+1}), dataVar{idV+1});
      end
      idTimeGps = idTimeGps + dataStruct.TIME_GPS_DIM;
   end
   if (dataStruct.TIME_CURRENT_DIM > 0)
      dataVar = dataStruct.TIME_CURRENT;
      for idV = 1:2:length(dataVar)
         netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, dataVar{idV}), ...
            idTimeCurrent, length(dataVar{idV+1}), dataVar{idV+1});
      end
      idTimeCurrent = idTimeCurrent + dataStruct.TIME_CURRENT_DIM;
   end
end

% retrieve data to update global attributes
time = [];
if (gl_var_is_present(fCdfOut, 'TIME'))
   time = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'TIME'));
   if (gl_att_is_present(fCdfOut, 'TIME', '_FillValue'))
      fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'TIME'), '_FillValue');
      time(find(time == fillVal)) = [];
   end
end
timeGps = [];
if (gl_var_is_present(fCdfOut, 'TIME_GPS'))
   timeGps = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'TIME_GPS'));
   if (gl_att_is_present(fCdfOut, 'TIME_GPS', '_FillValue'))
      fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'TIME_GPS'), '_FillValue');
      timeGps(find(timeGps == fillVal)) = [];
   end
end
time = [time; timeGps];
latitude = [];
if (gl_var_is_present(fCdfOut, 'LATITUDE'))
   latitude = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'LATITUDE'));
   fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'LATITUDE'), '_FillValue');
   latitude(find(latitude == fillVal)) = [];
end
if (gl_var_is_present(fCdfOut, 'LATITUDE_GPS'))
   latitudeGps = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'LATITUDE_GPS'));
   fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'LATITUDE_GPS'), '_FillValue');
   latitudeGps(find(latitudeGps == fillVal)) = [];
   latitude = [latitude; latitudeGps];
end
longitude = [];
if (gl_var_is_present(fCdfOut, 'LONGITUDE'))
   longitude = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'LONGITUDE'));
   fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'LONGITUDE'), '_FillValue');
   longitude(find(longitude == fillVal)) = [];
end
if (gl_var_is_present(fCdfOut, 'LONGITUDE_GPS'))
   longitudeGps = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'LONGITUDE_GPS'));
   fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'LONGITUDE_GPS'), '_FillValue');
   longitudeGps(find(longitudeGps == fillVal)) = [];
   longitude = [longitude; longitudeGps];
end
depth = [];
if (gl_var_is_present(fCdfOut, 'DEPTH'))
   depth = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'DEPTH'));
   fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'DEPTH'), '_FillValue');
   depth(find(depth == fillVal)) = [];
end
pres = [];
if (gl_var_is_present(fCdfOut, 'PRES'))
   pres = netcdf.getVar(fCdfOut, netcdf.inqVarID(fCdfOut, 'PRES'));
   fillVal = netcdf.getAtt(fCdfOut, netcdf.inqVarID(fCdfOut, 'PRES'), '_FillValue');
   pres(find(pres == fillVal)) = [];
end
depth = [depth; pres];

% update global attributes
netcdf.reDef(fCdfOut);

globalVarId = netcdf.getConstant('NC_GLOBAL');

attValue = datestr(gl_now_utc, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdfOut, globalVarId, 'date_update', attValue);

attValue = netcdf.getAtt(fCdfOut, globalVarId, 'history');
for idS = 1:length(ncData)
   dataStruct = ncData(idS);
   attValue = [attValue '; ' ...
      datestr(gl_now_utc, 'yyyy-mm-ddTHH:MM:SSZ') ' ' ...
      sprintf('Appended data from %s file', dataStruct.file_name)];
end
netcdf.putAtt(fCdfOut, globalVarId, 'history', attValue);

attValue = num2str(min(latitude));
netcdf.putAtt(fCdfOut, globalVarId, 'geospatial_lat_min', attValue);

attValue = num2str(max(latitude));
netcdf.putAtt(fCdfOut, globalVarId, 'geospatial_lat_max', attValue);

attValue = num2str(min(longitude));
netcdf.putAtt(fCdfOut, globalVarId, 'geospatial_lon_min', attValue);

attValue = num2str(max(longitude));
netcdf.putAtt(fCdfOut, globalVarId, 'geospatial_lon_max', attValue);

attValue = num2str(min(depth));
netcdf.putAtt(fCdfOut, globalVarId, 'geospatial_vertical_min', attValue);

attValue = num2str(max(depth));
netcdf.putAtt(fCdfOut, globalVarId, 'geospatial_vertical_max', attValue);

epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
attValue = datestr((min(time)/86400) + epoch_offset, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdfOut, globalVarId, 'time_coverage_start', attValue);

attValue = datestr((max(time)/86400) + epoch_offset, 'yyyy-mm-ddTHH:MM:SSZ');
netcdf.putAtt(fCdfOut, globalVarId, 'time_coverage_end', attValue);

netcdf.close(fCdfOut);

movefile(ncTempPathFileName, a_ncFinalOutputPathFile);

if (g_decGl_realtimeFlag == 1)
   % store information for the XML report
   for idS = 1:length(ncData)
      dataStruct = ncData(idS);
      g_decGl_reportStruct.inputFiles = [g_decGl_reportStruct.inputFiles ...
         {[a_ncDirPathName '/' dataStruct.file_name]}];
   end
   g_decGl_reportStruct.outputFiles = [g_decGl_reportStruct.outputFiles ...
      {a_ncFinalOutputPathFile}];
end

o_ok = 1;

return
