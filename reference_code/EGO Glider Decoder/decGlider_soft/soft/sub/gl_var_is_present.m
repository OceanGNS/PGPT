% ------------------------------------------------------------------------------
% Recherche d'une variable (par son nom) dans un fichier NetCDF.
%
% SYNTAX :
%  [o_present] = gl_var_is_present(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : Id du fichier NetCDF
%   a_varName : nom de la variable recherchée
%
% OUTPUT PARAMETERS :
%   o_present : 1 si la variable est présente (0 sinon)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   18/12/2006 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = gl_var_is_present(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar = 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break
   end
end

return
