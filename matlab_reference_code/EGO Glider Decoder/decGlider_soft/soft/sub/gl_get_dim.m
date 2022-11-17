% ------------------------------------------------------------------------------
% Retrieve a dimension information from a data or meta-data structure.
%
% SYNTAX :
%  [o_dim] = gl_get_dim(a_struct, a_fields)
%
% INPUT PARAMETERS :
%   a_struct : data or meta-data structure
%   a_fields : path to access the data for wich dimension information is needed
%
% OUTPUT PARAMETERS :
%   o_dim : retrieved dimension (empty if path is not accessible, set to 0 if
%           data is empty).
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dim] = gl_get_dim(a_struct, a_fields)

% output data initialization
o_dim = [];

% check existing path and rerieve the data
[fieldExists, varData] = gl_check_field(a_struct, a_fields);

% get the data dimension
if (fieldExists == 1)
   if (~isempty(varData))
      if (iscell(varData))
         o_dim = length(varData);
      elseif (ischar(varData))
         o_dim = size(varData, 1);
      else
         o_dim = size(varData, 2);
      end
   else
      o_dim = 0;
   end
end

return
