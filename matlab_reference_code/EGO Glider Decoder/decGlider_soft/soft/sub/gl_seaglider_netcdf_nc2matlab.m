% ------------------------------------------------------------------------------
% Reads the seaglider NetCDF file.
%
% SYNTAX :
%  [o_sgStructure] = gl_seaglider_netcdf_nc2matlab(a_ncFilePathname)
%
% INPUT PARAMETERS :
%   a_ncFilePathname : NetCDF file path name
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
function [o_sgStructure] = gl_seaglider_netcdf_nc2matlab(a_ncFilePathname)

% output data initialization
o_sgStructure = [];


% check inputs
if ~(exist(a_ncFilePathname, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_ncFilePathname);
   return
end

% open NetCDF file
fCdf = netcdf.open(a_ncFilePathname, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncFilePathname);
   return
end

% store NetCDF data
[nDims, nVars, nGAtts, unlimdimid] = netcdf.inq(fCdf);

o_sgStructure.DIM = [];
for idDim = 0:nDims-1
   [dimName, dimLen] = netcdf.inqDim(fCdf, idDim);
   o_sgStructure.DIM.(dimName) = dimLen;
end

o_sgStructure.ATT = [];
globalVarId = netcdf.getConstant('NC_GLOBAL');
for idAtt = 0:nGAtts-1
   attName = netcdf.inqAttName(fCdf, globalVarId, idAtt);
   attValue = netcdf.getAtt(fCdf, globalVarId, attName);
   o_sgStructure.ATT.(attName) = attValue;
end

o_sgStructure.VAR = [];
for idVar = 0:nVars-1
   [varName, xType, dimIds, nAtts] = netcdf.inqVar(fCdf, idVar);
   o_sgStructure.VAR.(varName) = [];
   o_sgStructure.VAR.(varName).ATT = [];
   o_sgStructure.VAR.(varName).DIM = [];
   o_sgStructure.VAR.(varName).DATA = [];
   for idAtt = 0:nAtts-1
      attName = netcdf.inqAttName(fCdf, idVar, idAtt);
      attValue = netcdf.getAtt(fCdf, idVar, attName);
      if (strcmp(attName, '_FillValue'))
         attName = attName(2:end);
      end
      o_sgStructure.VAR.(varName).ATT.(attName) = attValue;
   end
   for idDim = dimIds
      [dimName, dimLen] = netcdf.inqDim(fCdf, idDim);
      o_sgStructure.VAR.(varName).DIM.(dimName) = dimLen;
   end
   o_sgStructure.VAR.(varName).DATA = netcdf.getVar(fCdf, idVar);
end

netcdf.close(fCdf);

% assign source file names
o_sgStructure.source = a_ncFilePathname;

return
