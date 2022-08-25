% ------------------------------------------------------------------------------
% Retrieve attribute values from NetCDF file.
%
% SYNTAX :
%  [o_ncAtt] = gl_get_att_from_nc_file(a_ncPathFileName, a_attVar, a_wantedAtts)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_attVar         : NetCDF variable of the attribute (should be set empty to
%                      retrieve a global attribute)
%   a_wantedAtts     : NetCDF attribute names
%
% OUTPUT PARAMETERS :
%   o_ncAtt : NetCDF attribute values
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncAtt] = gl_get_att_from_nc_file(a_ncPathFileName, a_attVar, a_wantedAtts)

% output parameters initialization
o_ncAtt = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   if (isempty(a_attVar))
      
      % retrieve global attributes from NetCDF file
      for idAtt = 1:length(a_wantedAtts)
         attName = a_wantedAtts{idAtt};
         
         if (gl_att_is_present(fCdf, [], attName))
            attValue = netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), attName);
            o_ncAtt = [o_ncAtt {attName} {attValue}];
         else
            o_ncAtt = [o_ncAtt {attName} {[]}];
         end
      end
   else
      
      % retrieve variable attributes from NetCDF file
      if (gl_var_is_present(fCdf, a_attVar))
         
         for idAtt = 1:length(a_wantedAtts)
            attName = a_wantedAtts{idAtt};
            
            if (gl_att_is_present(fCdf, a_attVar, attName))
               attValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, a_attVar), attName);
               o_ncAtt = [o_ncAtt {attName} {attValue}];
            else
               o_ncAtt = [o_ncAtt {attName} {[]}];
            end
         end
      else
         
         for idAtt = 1:length(a_wantedAtts)
            attName = a_wantedAtts{idAtt};
            o_ncAtt = [o_ncAtt {attName} {[]}];
         end
      end
   end
   
   netcdf.close(fCdf);
end

return
