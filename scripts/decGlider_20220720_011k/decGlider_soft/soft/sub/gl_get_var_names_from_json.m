% ------------------------------------------------------------------------------
% Read, in the json deployment file, the list of glider variable names and their
% associated EGO variable names and format calibration data for DOXY.
%
% SYNTAX :
%  [o_gliderVarName, o_gliderAdjVarName, o_gliderVarPathName, ...
%    o_egoVarName, o_calibData, o_processingId] = ...
%    gl_get_var_names_from_json(a_jsonDeployFileName)
%
% INPUT PARAMETERS :
%   a_jsonPathFileName : file name of the json deployment file
%
% OUTPUT PARAMETERS :
%   o_gliderVarName     : names of the glider variables
%   o_gliderAdjVarName  : names of the glider adjusted variables
%   o_gliderVarPathName : path and names of the glider variables
%   o_egoVarName        : names of the EGO variables
%   o_calibData         : calibration information
%   o_processingId      : processing Id (for DOXY processing only)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/04/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gliderVarName, o_gliderAdjVarName, o_gliderVarPathName, ...
   o_egoVarName, o_calibData, o_processingId] = ...
   gl_get_var_names_from_json(a_jsonDeployFileName)

% output parameter initialization
o_gliderVarName = [];
o_gliderAdjVarName = [];
o_gliderVarPathName = [];
o_egoVarName = [];
o_calibData = [];
o_processingId = [];
paramSensor = [];

paramListAll = [];
metaData = gl_load_json(a_jsonDeployFileName);

% collect glider parameters
if (isfield(metaData, 'parametersList'))
   paramList = metaData.parametersList;
   for idP = 1:length(paramList)
      if (length(paramList) == 1)
         paramStruct = paramList;
      elseif (isstruct(paramList))
         paramStruct = paramList(idP);
      else
         paramStruct = paramList{idP};
      end
      paramListAll{end+1} = paramStruct;
   end
end

% collect coordinate variables
if (isfield(metaData, 'coordinate_variables'))
   paramList = metaData.coordinate_variables;
   for idP = 1:length(paramList)
      if (length(paramList) == 1)
         paramStruct = paramList;
      elseif (isstruct(paramList))
         paramStruct = paramList(idP);
      else
         paramStruct = paramList{idP};
      end
      paramListAll{end+1} = paramStruct;
   end
end

for idP = 1:length(paramListAll)
   paramStruct = paramListAll{idP};
   if (isfield(paramStruct, 'variable_name'))
      varNameOri = paramStruct.variable_name;
      sep = strfind(varNameOri, '.');
      if (~isempty(sep))
         varPathName = varNameOri(sep(1)+1:end);
         varName = varNameOri(sep(end)+1:end);
         o_gliderVarPathName{end+1} = varPathName;
         o_gliderVarName{end+1} = varName;
      else
         o_gliderVarPathName{end+1} = '';
         o_gliderVarName{end+1} = '';
      end
   else
      o_gliderVarPathName{end+1} = '';
      o_gliderVarName{end+1} = '';
   end
   if (isfield(paramStruct, 'adjusted_variable_name'))
      varAdjNameOri = paramStruct.adjusted_variable_name;
      sep = strfind(varAdjNameOri, '.');
      if (~isempty(sep))
         varAdjName = varAdjNameOri(sep(end)+1:end);
         o_gliderAdjVarName{end+1} = varAdjName;
      else
         o_gliderAdjVarName{end+1} = '';
      end
   else
      o_gliderAdjVarName{end+1} = '';
   end
   if (isfield(paramStruct, 'ego_variable_name'))
      o_egoVarName{end+1} = paramStruct.ego_variable_name;
   else
      o_egoVarName{end+1} = '';
   end
   if (isfield(paramStruct, 'calib_coef'))
      o_calibData{end+1} = paramStruct.calib_coef;
   else
      o_calibData{end+1} = '';
   end
   if (isfield(paramStruct, 'processing_id'))
      o_processingId{end+1} = paramStruct.processing_id;
   else
      o_processingId{end+1} = '';
   end
   if (isfield(paramStruct, 'parameter_sensor'))
      paramSensor{end+1} = paramStruct.parameter_sensor;
   else
      paramSensor{end+1} = '';
   end
end

% format DOXY calibration information
for idP = 1:length(o_calibData)
   if (~isempty(o_calibData{idP}))
      if (ismember(paramSensor{idP}, [{'OPTODE_DOXY'} {'IDO_DOXY'}]))
         
         caseValue = o_processingId{idP};
         switch (caseValue)
            
            case '201_202_202'
               tabPhaseCoef = [];
               for id = 0:3
                  fieldName = ['PhaseCoef' num2str(id)];
                  if (isfield(o_calibData{idP}, fieldName))
                     tabPhaseCoef(id+1) = o_calibData{idP}.(fieldName);
                  else
                     fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                        fieldName, caseValue);
                     tabPhaseCoef = [];
                     break
                  end
               end
               
               tabDoxyCoef = [];
               for idI = 0:4
                  for idJ = 0:3
                     fieldName = ['CCoef' num2str(idI) num2str(idJ)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(idI+1, idJ+1) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        break
                     end
                  end
               end
               
               if (~isempty(tabPhaseCoef) && ~isempty(tabDoxyCoef))
                  o_calibData{idP}.TabPhaseCoef = tabPhaseCoef;
                  o_calibData{idP}.TabDoxyCoef = tabDoxyCoef;
               end
               
            case {'202_205_302', '202_205_303'}
               
               tabDoxyCoef = [];
               stop = 0;
               for id = 0:3
                  fieldName = ['PhaseCoef' num2str(id)];
                  if (isfield(o_calibData{idP}, fieldName))
                     tabDoxyCoef(1, id+1) = o_calibData{idP}.(fieldName);
                  else
                     fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                        fieldName, caseValue);
                     tabDoxyCoef = [];
                     stop = 1;
                     break
                  end
               end
               if (~stop)
                  for id = 0:5
                     fieldName = ['TempCoef' num2str(id)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(2, id+1) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        stop = 1;
                        break
                     end
                  end
               end
               if (~stop)
                  for id = 0:13
                     fieldName = ['FoilCoefA' num2str(id)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(3, id+1) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        stop = 1;
                        break
                     end
                  end
               end
               if (~stop)
                  for id = 0:13
                     fieldName = ['FoilCoefB' num2str(id)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(3, id+15) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        stop = 1;
                        break
                     end
                  end
               end
               if (~stop)
                  for id = 0:27
                     fieldName = ['FoilPolyDegT' num2str(id)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(4, id+1) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        stop = 1;
                        break
                     end
                  end
               end
               if (~stop)
                  for id = 0:27
                     fieldName = ['FoilPolyDegO' num2str(id)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(5, id+1) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        stop = 1;
                        break
                     end
                  end
               end
               if (strcmp(caseValue, '202_205_303'))
                  if (~stop)
                     for id = 0:1
                        fieldName = ['ConcCoef' num2str(id)];
                        if (isfield(o_calibData{idP}, fieldName))
                           tabDoxyCoef(6, id+1) = o_calibData{idP}.(fieldName);
                        else
                           fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                              fieldName, caseValue);
                           tabDoxyCoef = [];
                           stop = 1;
                           break
                        end
                     end
                  end
               end
               
               if (~isempty(tabDoxyCoef))
                  o_calibData{idP}.TabDoxyCoef = tabDoxyCoef;
               end
               
            case {'202_205_304', '202_204_304'}
               
               tabDoxyCoef = [];
               stop = 0;
               for id = 0:3
                  fieldName = ['PhaseCoef' num2str(id)];
                  if (isfield(o_calibData{idP}, fieldName))
                     tabDoxyCoef(1, id+1) = o_calibData{idP}.(fieldName);
                  else
                     fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                        fieldName, caseValue);
                     tabDoxyCoef = [];
                     stop = 1;
                     break
                  end
               end
               if (~stop)
                  for id = 0:6
                     fieldName = ['SVUFoilCoef' num2str(id)];
                     if (isfield(o_calibData{idP}, fieldName))
                        tabDoxyCoef(2, id+1) = o_calibData{idP}.(fieldName);
                     else
                        fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                           fieldName, caseValue);
                        tabDoxyCoef = [];
                        stop = 1;
                        break
                     end
                  end
               end
               
               if (~isempty(tabDoxyCoef))
                  o_calibData{idP}.TabDoxyCoef = tabDoxyCoef;
               end
               
            case {'102_207_206'}
               
               tabDoxyCoef = [];
               coefNameList = [{'Soc'} {'FOffset'} {'CoefA'} {'CoefB'} {'CoefC'} {'CoefE'}];
               for id = 1:length(coefNameList)
                  fieldName = coefNameList{id};
                  if (isfield(o_calibData{idP}, fieldName))
                     tabDoxyCoef = [tabDoxyCoef o_calibData{idP}.(fieldName)];
                  else
                     fprintf('ERROR: inconsistent CALIBRATION_COEFFICIENT information (''%s'' is missing for case ''%s'')\n', ...
                        fieldName, caseValue);
                     tabDoxyCoef = [];
                     break
                  end
               end
               
               if (~isempty(tabDoxyCoef))
                  o_calibData{idP}.SbeTabDoxyCoef = tabDoxyCoef;
               end
         end
      end
   end
end

return
