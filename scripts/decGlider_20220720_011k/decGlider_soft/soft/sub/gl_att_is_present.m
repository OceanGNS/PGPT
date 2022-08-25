% ------------------------------------------------------------------------------
% Recherche d'un attribut associé à une variable (par son nom) dans un fichier
% NetCDF.
%
% SYNTAX :
%  [o_present] = gl_att_is_present(a_ncId, a_varName, a_attName)
%
% INPUT PARAMETERS :
%   a_ncId    : Id du fichier NetCDF
%   a_varName : nom de la variable contenant l'attribut ([] pour un attribut
%               global)
%   a_attName : nom de l'attribut recherché
%
% OUTPUT PARAMETERS :
%   o_present : 1 si l'attribut est présente (0 sinon)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   28/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = gl_att_is_present(a_ncId, a_varName, a_attName)

o_present = 0;

varId = [];
if (isempty(a_varName))
   varId = netcdf.getConstant('NC_GLOBAL');
   [nbDims, nbVars, nbAtts, unlimId] = netcdf.inq(a_ncId);
else
   if (gl_var_is_present(a_ncId, a_varName))
      varId = netcdf.inqVarID(a_ncId, a_varName);
      [varName, xType, dimIds, nbAtts] = netcdf.inqVar(a_ncId, varId);
   end
end

if (~isempty(varId))
   
   for idAtt = 0:nbAtts-1
      attName = netcdf.inqAttName(a_ncId, varId, idAtt);
      if (strcmp(attName, a_attName))
         o_present = 1;
         break
      end
   end
   
end

return
