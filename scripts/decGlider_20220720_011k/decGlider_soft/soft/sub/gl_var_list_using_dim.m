% ------------------------------------------------------------------------------
% Retrieve the name list of variables which have a given dim in their
% dimensions
%
% SYNTAX :
%  [o_varNameList] = gl_var_list_using_dim(a_ncId, a_dimName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_dimName : name of the concerned dimension
%
% OUTPUT PARAMETERS :
%   o_varNameList : variable name list
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varNameList] = gl_var_list_using_dim(a_ncId, a_dimName)

o_varNameList = [];

if (~gl_dim_is_present(a_ncId, a_dimName))
   return
end

dimId = netcdf.inqDimID(a_ncId, a_dimName);

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar = 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (~isempty(find(varDims == dimId, 1)))
      o_varNameList{end+1} = varName;
   end
end

return
