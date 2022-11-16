% ------------------------------------------------------------------------------
% Recursively check fields in a structure.
%
% SYNTAX :
%  [o_bool] = gl_is_field_recursive(a_struct, a_fields)
%
% INPUT PARAMETERS :
%   a_struct : structure to check
%   a_fields : fields to check
%
% OUTPUT PARAMETERS :
%   o_bool : 1 if final field exists, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bool] = gl_is_field_recursive(a_struct, a_fields)

% output data initialization
o_bool = 1;


idP = strfind(a_fields, '.');
start = 1;
subPath = [];
for id = 1:length(idP)+1
   if (id == length(idP)+1)
      curField = a_fields(start:end);
   else
      curField = a_fields(start:idP(id)-1);
   end
   if (isempty(subPath))
      if (~isfield(a_struct, curField))
         o_bool = 0;
         break
      end
      subPath = curField;
   else
      if (~isfield(a_struct.(subPath), curField))
         o_bool = 0;
         break
      end
      subPath = [subPath '.' curField];
   end
   if (id < length(idP)+1)
      start = idP(id)+1;
   end
end

return
