% ------------------------------------------------------------------------------
% Create netCDF variables described in a definition structure and the associated
% _QC, _ADJUSTED, _ADJUSTED_QC and _ADJUSTED_ERROR variables.
%
% SYNTAX :
%  [o_ncFileId, o_tabVarName, o_tabVarId, o_tabVarInput, o_adjVarList] = ...
%    gl_create_nc_vars_with_qc(a_ncFileId, ...
%    a_varDefStruct, a_varQcDefStruct, a_varAdjErrDefStruct, ...
%    a_tabVarName, a_tabVarId, a_tabVarInput)
%
% INPUT PARAMETERS :
%   a_ncFileId           : input netCDF file Id
%   a_varDefStruct       : variable definition structure
%   a_varQcDefStruct     : variable _QC definition structure
%   a_varAdjErrDefStruct : variable _ADJUSTED_ERROR definition structure
%   a_tabVarName         : input variable names
%   a_tabVarId           : input variable netCDF Ids
%   a_tabVarInput        : input variable filling rules
%
% OUTPUT PARAMETERS :
%   o_ncFileId    : output netCDF file Id
%   o_tabVarName  : output variable names
%   o_tabVarId    : output variable netCDF Ids
%   o_tabVarInput : output variable filling rules
%   o_adjVarList  : list of variables with adjusted data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncFileId, o_tabVarName, o_tabVarId, o_tabVarInput, o_adjVarList] = ...
   gl_create_nc_vars_with_qc(a_ncFileId, ...
   a_varDefStruct, a_varQcDefStruct, a_varAdjErrDefStruct, ...
   a_tabVarName, a_tabVarId, a_tabVarInput)

% output data initialization
o_ncFileId = a_ncFileId;
o_tabVarName = a_tabVarName;
o_tabVarId = a_tabVarId;
o_tabVarInput = a_tabVarInput;
o_adjVarList = [];


% parameter attributes added by the decoder
decoderAttParamList = [ ...
   {'processing_id'} ...
   {'parameter_sensor'} ...
   {'calib_coef'} ...
   {'adjusted_variable_name'} ...
   ];

paramListStruct = a_varDefStruct;
for idParamStruct = 1:length(paramListStruct)
   if (iscell(paramListStruct))
      varStruct = paramListStruct{idParamStruct};
   else
      varStruct = paramListStruct(idParamStruct);
   end
   
   egoVarName = varStruct.ego_variable_name;
   if ((length(egoVarName) > 9) && strcmp(egoVarName(end-8:end), '_ADJUSTED'))
      continue % <PARAM>_ADJUSTED ignored (variables created with <PARAM>)
   end
   
   % retrieve param type ('c', 'i' or 'b')
   paramInfo = gl_get_netcdf_param_attributes(varStruct.ego_variable_name);
   paramType = paramInfo.paramType;
            
   % 5 loops for <PARAM>, <PARAM>_QC, <PARAM>_ADJUSTED, <PARAM>_ADJUSTED_QC and
   % <PARAM>_ADJUSTED_ERROR
   for idLoop = 1:5
      
      % don't generate <PARAM>_ADJUSTED, <PARAM>_ADJUSTED_QC and
      % <PARAM>_ADJUSTED_ERROR for 'i' parameters
      if (paramType == 'i')
         if (idLoop > 2)
            break
         end
      end
      
      if ((idLoop == 1) || (idLoop == 3)) % <PARAM> & <PARAM>_ADJUSTED
         
         % fields #1 to #4 to define the variable
         fieldNames = fieldnames(varStruct);
         varInput = varStruct.variable_name;
         varName = varStruct.ego_variable_name; % <PARAM>
         if (idLoop == 3) % <PARAM>_ADJUSTED
            varName = [varName '_ADJUSTED'];
         end
         dimNames = varStruct.dim;
         typeName = varStruct.typeof;
         if (isempty(dimNames))
            varId = netcdf.defVar(o_ncFileId, ...
               varName, ...
               typeName, ...
               []);
         elseif (iscell(dimNames))
            dims = [];
            for id = length(dimNames):-1:1
               dims = [dims ...
                  netcdf.inqDimID(o_ncFileId, char(dimNames{id}))];
            end
            varId = netcdf.defVar(o_ncFileId, ...
               varName, ...
               typeName, ...
               dims);
         elseif (size(dimNames, 1) > 1)
            dims = [];
            for id = size(dimNames, 1):-1:1
               dims = [dims ...
                  netcdf.inqDimID(o_ncFileId, dimNames(id, :))];
            end
            varId = netcdf.defVar(o_ncFileId, ...
               varName, ...
               typeName, ...
               dims);
         else
            varId = netcdf.defVar(o_ncFileId, ...
               varName, ...
               typeName, ...
               netcdf.inqDimID(o_ncFileId, varStruct.dim));
         end
         
         o_tabVarName{end+1} = varName;
         o_tabVarId{end+1} = varId;
         if (idLoop == 1) % <PARAM>
            o_tabVarInput{end+1} = varInput;
         else % <PARAM>_ADJUSTED
            o_tabVarInput{end+1} = '';
         end
         
         % other fields to define the variable attributes
         for id = 5:length(fieldNames)
            attName = fieldNames{id};
            if (ismember(attName, decoderAttParamList))
               % do not consider attributes added by the decoder
               continue
            end
            if (ismember(attName, [{'valid_min'} {'valid_max'}]) && isempty(varStruct.(fieldNames{id})))
               % do not set empty "valid_min" or "valid_max" attributes
               continue
            end
            attName = strrep(attName, 'x0x5F_', '_'); % if created by loadjson
            attName = strrep(attName, 'x_', '_'); % if created by jsondecode
            attValue = varStruct.(fieldNames{id});
            
            % update glider_original_parameter_name for <PARAM>_ADJUSTED
            % when copied from input NetCDF SeaGlider file
            if (idLoop == 3)
               if (strcmp(attName, 'glider_original_parameter_name'))
                  if (isfield(varStruct, 'adjusted_variable_name'))
                     if (~isempty(varStruct.adjusted_variable_name))
                        attValue = varStruct.adjusted_variable_name;
                        sep = strfind(attValue, '.');
                        if (~isempty(sep))
                           attValue = attValue(sep(end)+1:end);
                        end
                     end
                  end
               end
            end
            
            if (~ischar(attValue))
               type = varStruct.typeof;
               switch (type)
                  case 'byte'
                     attValue = int8(attValue);
                  case 'int'
                     attValue = int32(attValue);
                  case 'float'
                     attValue = single(attValue);
                  case 'double'
                     attValue = double(attValue);
                  otherwise
                     fprintf('ERROR: create_nc_var: don''t know how to convert %s type\n', type);
               end
            end
            netcdf.putAtt(o_ncFileId, varId, attName, attValue);
         end
         
      elseif ((idLoop == 2) || (idLoop == 4)) % <PARAM>_QC & <PARAM>_ADJUSTED_QC
         
         % fields #1 to #4 to define the variable
         fieldNamesQc = fieldnames(a_varQcDefStruct);
         varName = varStruct.ego_variable_name;
         if (strcmp(varName(end-2:end), '_QC') == 0)
            if (idLoop == 2) % <PARAM>_QC
               varNameQc = [varStruct.ego_variable_name a_varQcDefStruct.ego_variable_name];
            else % <PARAM>_ADJUSTED_QC
               varNameQc = [varStruct.ego_variable_name '_ADJUSTED' a_varQcDefStruct.ego_variable_name];
            end
            if (gl_var_is_present(o_ncFileId, varNameQc) == 0)
               varQcId = netcdf.defVar(o_ncFileId, ...
                  varNameQc, ...
                  a_varQcDefStruct.typeof, ...
                  netcdf.inqDimID(o_ncFileId, a_varQcDefStruct.dim));
            else
               continue
            end
         else
            continue
         end
         
         % other fields to define the variable attributes
         for id = 5:length(fieldNamesQc)
            attName = fieldNamesQc{id};
            attName = strrep(attName, 'x0x5F_', '_'); % if created by loadjson
            attName = strrep(attName, 'x_', '_'); % if created by jsondecode
            attValue = a_varQcDefStruct.(fieldNamesQc{id});
            if (~ischar(attValue))
               type = a_varQcDefStruct.typeof;
               switch (type)
                  case 'byte'
                     attValue = int8(attValue);
                  case 'int'
                     attValue = int32(attValue);
                  case 'float'
                     attValue = single(attValue);
                  case 'double'
                     attValue = double(attValue);
                  otherwise
                     fprintf('ERROR: don''t know how to convert %s type\n', type);
               end
            end
            netcdf.putAtt(o_ncFileId, varQcId, attName, attValue);
         end
         
      else % <PARAM>_ADJUSTED_ERROR
         
         % fields #1 to #4 to define the variable
         fieldNames = fieldnames(varStruct);
         fieldNamesAdjErr = fieldnames(a_varAdjErrDefStruct);
         varName = varStruct.ego_variable_name;
         if (strcmp(varName(end-2:end), '_QC') == 0)
            varNameAdjErr = [varStruct.ego_variable_name a_varAdjErrDefStruct.(fieldNamesAdjErr{2})];
            varAdjErrId = netcdf.defVar(o_ncFileId, ...
               varNameAdjErr, ...
               a_varAdjErrDefStruct.(fieldNamesAdjErr{4}), ...
               netcdf.inqDimID(o_ncFileId, a_varAdjErrDefStruct.(fieldNamesAdjErr{3})));
         else
            continue
         end
         
         % other fields to define the variable attributes
         for id = 5:length(fieldNamesAdjErr)
            attName = fieldNamesAdjErr{id};
            attName = strrep(attName, 'x0x5F_', '_'); % if created by loadjson
            attName = strrep(attName, 'x_', '_'); % if created by jsondecode
            attValue = a_varAdjErrDefStruct.(fieldNamesAdjErr{id});
            if (isempty(attValue))
               % empty attributes (presently _FillValue and units) are copied from
               % corresponding parameter ones
               netcdf.copyAtt(o_ncFileId, netcdf.inqVarID(o_ncFileId, varName), attName, o_ncFileId, varAdjErrId)
            else
               if (~ischar(attValue))
                  type = a_varAdjErrDefStruct.(fieldNamesAdjErr{4});
                  switch (type)
                     case 'byte'
                        attValue = int8(attValue);
                     case 'int'
                        attValue = int32(attValue);
                     case 'float'
                        attValue = single(attValue);
                     case 'double'
                        attValue = double(attValue);
                     otherwise
                        fprintf('ERROR: don''t know how to convert %s type\n', type);
                  end
               end
               netcdf.putAtt(o_ncFileId, varAdjErrId, attName, attValue);
            end
         end
      end
   end
end

% set o_tabVarInput for <PARAMA>_ADJUSTED data retrieved from glider data
paramListStruct = a_varDefStruct;
for idParamStruct = 1:length(paramListStruct)
   if (iscell(paramListStruct))
      varStruct = paramListStruct{idParamStruct};
   else
      varStruct = paramListStruct(idParamStruct);
   end
   
   egoVarName = varStruct.ego_variable_name;
   if ((length(egoVarName) > 9) && strcmp(egoVarName(end-8:end), '_ADJUSTED'))
      idF = find(strcmp(o_tabVarName, egoVarName) == 1, 1);
      if (~isempty(idF))
         o_tabVarInput{idF} = varStruct.variable_name;
         o_adjVarList{end+1} = egoVarName(1:end-9);
      else
         fprintf('ERROR: cannot retrieve ''%s'' variable to set input data\n', ...
            egoVarName);
      end
   end
end

return
