% ------------------------------------------------------------------------------
% Merge NetCDF data of seaglider.
%
% SYNTAX :
%  [o_sgStructure] = gl_seaglider_merge_nc_data(a_sgStructure)
%
% INPUT PARAMETERS :
%   a_sgStructure      : seaglider input structure
%
% OUTPUT PARAMETERS :
%   o_sgStructure : seaglider output structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sgStructure] = gl_seaglider_merge_nc_data(a_sgStructure)

% output data initialization
o_sgStructure = [];

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_gliderAdjVarName;
global g_decGl_gliderVarPathName;
global g_decGl_egoVarName;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;

% QC flag values
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;

% default values
global g_decGl_janFirst1950InMatlab;
global g_decGl_janFirst200InEpoch;


% retrieve measurements and associated times
inputDataStruct = [];
for idVar = 1:length(g_decGl_gliderVarPathName)
   if (strncmp(g_decGl_gliderVarPathName{idVar}, 'vars_time.', length('vars_time.')))
      varName = g_decGl_gliderVarName{idVar};
      varAdjName = g_decGl_gliderAdjVarName{idVar};
      varDim = [];
      varTime = [];
      if (isfield(a_sgStructure.VAR, varName))
         varDim = fieldnames(a_sgStructure.VAR.(varName).DIM);
         varDim = varDim{:};
         if (strcmp(varDim, 'sg_data_point'))
            varTime = 'time';
         elseif ((length(varDim) > 11) && strcmp(varDim(end-10:end), '_data_point'))
            varTime = [varDim(1:end-11) '_time'];
         end
         if (~isfield(a_sgStructure.VAR, varTime))
            varTime = [];
         end
         if (strcmp(varTime, varName))
            continue
         end
         
         if (~isempty(varTime))
            if (~isfield(inputDataStruct, varDim))
               inputDataStruct.(varDim) = [];
               inputDataStruct.(varDim).TIME = [];
               inputDataStruct.(varDim).VAR = [];
            end
            if (isempty(inputDataStruct.(varDim).TIME))
               dataVal = a_sgStructure.VAR.(varTime).DATA;
               if (isfield(a_sgStructure.VAR.(varTime).ATT, 'FillValue'))
                  dataVal(find(dataVal == a_sgStructure.VAR.(varTime).ATT.FillValue)) = nan;
               end
               % EPOCH timestamps can be inconsistent
               dataVal(find((dataVal < g_decGl_janFirst200InEpoch) | ...
                  (dataVal > gl_julian_2_epoch(gl_now_utc-g_decGl_janFirst1950InMatlab)))) = nan;
               inputDataStruct.(varDim).TIME = dataVal;
            end
            if (~isfield(inputDataStruct.(varDim).VAR, varName))
               dataVal = a_sgStructure.VAR.(varName).DATA;
               if (isfield(a_sgStructure.VAR.(varName).ATT, 'FillValue'))
                  dataVal(find(dataVal == a_sgStructure.VAR.(varName).ATT.FillValue)) = nan;
               end
               % data measurements can be out of range (to be stored in a single
               % variable type)
               dataVal(~isfinite(single(dataVal))) = nan;
               inputDataStruct.(varDim).VAR.(varName) = dataVal;
               
               % retrieve also QC values if exist
               varNameQc = [varName '_qc'];
               if (isfield(a_sgStructure.VAR, varNameQc))
                  inputDataStruct.(varDim).VAR.(varNameQc) = a_sgStructure.VAR.(varNameQc).DATA;
               end
            else
               fprintf('ERROR: NetCDF var ''%s'' encountered twice => ignored\n', varName);
            end
            if (~isempty(varAdjName))
               if (~isfield(inputDataStruct.(varDim).VAR, varAdjName))
                  dataValAdj = a_sgStructure.VAR.(varAdjName).DATA;
                  if (isfield(a_sgStructure.VAR.(varAdjName).ATT, 'FillValue'))
                     dataValAdj(find(dataValAdj == a_sgStructure.VAR.(varAdjName).ATT.FillValue)) = nan;
                  end
                  % data measurements can be out of range (to be stored in a single
                  % variable type)
                  dataValAdj(~isfinite(single(dataValAdj))) = nan;
                  inputDataStruct.(varDim).VAR.(varAdjName) = dataValAdj;
                  
                  % retrieve also QC values if exist
                  varAdjNameQc = [varAdjName '_qc'];
                  if (isfield(a_sgStructure.VAR, varAdjNameQc))
                     inputDataStruct.(varDim).VAR.(varAdjNameQc) = a_sgStructure.VAR.(varAdjNameQc).DATA;
                  end
               else
                  fprintf('ERROR: NetCDF var ''%s'' encountered twice => ignored\n', varName);
               end
            end
         else
            fprintf('ERROR: No time associated to NetCDF var ''%s'' => ignored\n', varName);
         end
      else
         fprintf('INFO: ''%s'' parameter is missing in NetCDF file\n', varName);
      end
   end
end

mergedDataStruct = [];
if (~isempty(inputDataStruct))
   
   % retrieve glider variable name for TIME
   timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};
   
   % create the final time data set
   mergedDataStruct.(timeGliderVarName) = [];
   fNames = fieldnames(inputDataStruct);
   for idF = 1:length(fNames)
      mergedDataStruct.(timeGliderVarName) = cat(2, ...
         mergedDataStruct.(timeGliderVarName), (inputDataStruct.(fNames{idF}).TIME)');
   end
   mergedDataStruct.(timeGliderVarName) = unique(mergedDataStruct.(timeGliderVarName));
   
   % insert measurements in final data set
   fDimNames = fieldnames(inputDataStruct);
   for idF1 = 1:length(fDimNames)
      dimName = fDimNames{idF1};
      timeVar = inputDataStruct.(dimName).TIME;
      varId = ones(1, length(timeVar))*-1;
      for id = 1:length(timeVar)
         idF = find(timeVar(id) == mergedDataStruct.(timeGliderVarName), 1);
         if (~isempty(idF))
            varId(id) = idF;
         end
      end
      fVarNames = fieldnames(inputDataStruct.(dimName).VAR);
      for idF2 = 1:length(fVarNames)
         varName = fVarNames{idF2};
         mergedDataStruct.(varName) = nan(size(mergedDataStruct.(timeGliderVarName)));
         if (~any(varId == -1))
            mergedDataStruct.(varName)(varId) = (inputDataStruct.(dimName).VAR.(varName))';
         else
            fprintf('WARNING: ''%s'' parameter no imported (''ctd_time'' data not reliable)\n', varName);
         end
      end
   end
   
   % clean measurements (delete timestamps when all measurements = Nan)
   excludedEgoVarList = [{'TIME_GPS'} {'LATITUDE_GPS'} {'LONGITUDE_GPS'}];
   dataAll = [];
   for idV = 1:length(g_decGl_egoVarName)
      if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
            ~strcmp(g_decGl_egoVarName{idV}, 'TIME') && ...
            ~isempty(g_decGl_gliderVarName{idV}))
         if (isfield(mergedDataStruct, g_decGl_gliderVarName{idV}))
            dataAll = cat(1, dataAll, mergedDataStruct.(g_decGl_gliderVarName{idV}));
         end
      end
   end
   idDel = find(sum(isnan(dataAll), 1) == size(dataAll, 1));
   if (~isempty(idDel))
      for idV = 1:length(g_decGl_egoVarName)
         if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
               ~isempty(g_decGl_gliderVarName{idV}))
            if (isfield(mergedDataStruct, g_decGl_gliderVarName{idV}))
               mergedDataStruct.(g_decGl_gliderVarName{idV})(idDel) = [];
            end
         end
      end
   end
   
   % interpolate PRES measurements for all timestamps => needed for PHASE processing
   
   % find the glider variable names for TIME, PRES and PRES_QC
   timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};
   presGliderVarName = [];
   idF = find(strcmp(g_decGl_egoVarName, 'PRES'));
   if (~isempty(idF))
      presGliderVarName = g_decGl_gliderVarName{idF};
   end
   presQcGliderVarName = [];
   idF = find(strcmp(g_decGl_egoVarName, 'PRES_QC'));
   if (~isempty(idF))
      presQcGliderVarName = g_decGl_gliderVarName{idF};
   end
   
   % convert and interpolate PRES measurements
   if (~isempty(timeGliderVarName) && ~isempty(presGliderVarName))
      
      time = [];
      pres = [];
      if (isfield(mergedDataStruct, timeGliderVarName))
         time = mergedDataStruct.(timeGliderVarName);
      end
      if (isfield(mergedDataStruct, presGliderVarName))
         pres = mergedDataStruct.(presGliderVarName);
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
         
         mergedDataStruct.(presGliderVarName) = pres;
         if (~isempty(presQcGliderVarName))
            mergedDataStruct.(presQcGliderVarName) = pres_QC;
         else
            mergedDataStruct.PRES_QC = pres_qc;
            g_decGl_directEgoVarName{end+1} = 'vars_time.PRES_QC';
         end
      end
   end
else
   % no CTD data in the nc file
   fprintf('WARNING: no measurement data retrieved from current NetCDF file\n');
end

o_sgStructure = a_sgStructure;
o_sgStructure.nc = mergedDataStruct;

return
