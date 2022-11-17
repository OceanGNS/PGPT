% ------------------------------------------------------------------------------
% Retrieve the name list of variables which have a given attribute value.
%
% SYNTAX :
%  [o_varNameList] = gl_var_list_using_att(a_ncId, a_attName, a_attValue)
%
% INPUT PARAMETERS :
%   a_ncId     : NetCDF file Id
%   a_attName  : name of the concerned attribute name
%   a_attValue : name of the concerned attribute value
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
%   01/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varNameList] = gl_var_list_using_att(a_ncId, a_attName, a_attValue)

o_varNameList = [];

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar = 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   
   for idAtt = 0:nbAtts-1
      attName = netcdf.inqAttName(a_ncId, idVar, idAtt);
      if (strcmp(attName, a_attName))
         attValue = deblank(netcdf.getAtt(a_ncId, idVar, attName));
         if (strcmp(attValue, a_attValue))
            o_varNameList{end+1} = varName;
         end
      end
   end
end

return
