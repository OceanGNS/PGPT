% ------------------------------------------------------------------------------
% Create netCDF variables described in a definition structure.
%
% SYNTAX :
%  [o_ncFileId, o_tabVarName, o_tabVarId, o_tabVarInput] = ...
%    gl_create_nc_vars(a_ncFileId, a_varDefStruct, ...
%    a_tabVarName, a_tabVarId, a_tabVarInput)
%
% INPUT PARAMETERS :
%   a_ncFileId     : input netCDF file Id
%   a_varDefStruct : variable definition structure
%   a_tabVarName   : input variable names
%   a_tabVarId     : input variable netCDF Ids
%   a_tabVarInput  : input variable filling rules
%
% OUTPUT PARAMETERS :
%   o_ncFileId    : output netCDF file Id
%   o_tabVarName  : output variable names
%   o_tabVarId    : output variable netCDF Ids
%   o_tabVarInput : output variable filling rules
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncFileId, o_tabVarName, o_tabVarId, o_tabVarInput] = ...
   gl_create_nc_vars(a_ncFileId, a_varDefStruct, ...
   a_tabVarName, a_tabVarId, a_tabVarInput)

% output data initialization
o_ncFileId = a_ncFileId;
o_tabVarName = a_tabVarName;
o_tabVarId = a_tabVarId;
o_tabVarInput = a_tabVarInput;

% Matlab version (before or after R2017A)
global g_decGl_matlabVersionBeforeR2017A;


% create nc variables
for idStruct = 1:length(a_varDefStruct)
   if (iscell(a_varDefStruct))
      varStruct = a_varDefStruct{idStruct};
   else
      varStruct = a_varDefStruct(idStruct);
   end
   
   % fields #1 to #4 to define the variable
   fieldNames = fieldnames(varStruct);
   varInput = varStruct.(fieldNames{1});
   varName = varStruct.(fieldNames{2});
   dimNames = varStruct.(fieldNames{3});
   typeName = varStruct.(fieldNames{4});
   if (g_decGl_matlabVersionBeforeR2017A)
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
            netcdf.inqDimID(o_ncFileId, varStruct.(fieldNames{3})));
      end
   else
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
      elseif (isstring(dimNames))
         dims = [];
         for id = length(dimNames):-1:1
            dims = [dims ...
               netcdf.inqDimID(o_ncFileId, char(dimNames(id)))];
         end
         varId = netcdf.defVar(o_ncFileId, ...
            varName, ...
            typeName, ...
            dims);
      else
         varId = netcdf.defVar(o_ncFileId, ...
            varName, ...
            typeName, ...
            netcdf.inqDimID(o_ncFileId, varStruct.(fieldNames{3})));
      end
   end
   
   o_tabVarName{end+1} = varName;
   o_tabVarId{end+1} = varId;
   o_tabVarInput{end+1} = varInput;
   
   % other fields to define the variable attributes
   for id = 5:length(fieldNames)
      attName = fieldNames{id};
      attName = strrep(attName, 'x0x5F_', '_'); % if created by loadjson
      attName = strrep(attName, 'x_', '_'); % if created by jsondecode
      attValue = varStruct.(fieldNames{id});
      if (~ischar(attValue))
         type = varStruct.(fieldNames{4});
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
      netcdf.putAtt(o_ncFileId, varId, attName, attValue);
   end
end

return
