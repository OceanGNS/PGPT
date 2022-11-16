% ------------------------------------------------------------------------------
% Check that a path exists in a structure and retrieve the corresponding data.
%
% SYNTAX :
%  [o_fieldExists, o_fieldContents] = gl_check_field(a_struct, a_fields)
%
% INPUT PARAMETERS :
%   a_struct : data or meta-data structure
%   a_fields : path to access the data
%
% OUTPUT PARAMETERS :
%   o_fieldExists   : existing path flag (1 if exists, 0 otherwise)
%   o_fieldContents : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fieldExists, o_fieldContents] = gl_check_field(a_struct, a_fields)

% output data initialization
o_fieldExists = 0;
o_fieldContents = [];

remain = a_fields;
struct = a_struct;
while (1)
   [field, remain] = strtok(remain, '.');
   if (isempty(field))
      o_fieldExists = 1;
      o_fieldContents = struct;
      break
   end
   if (~isfield(struct, field))
      break
   end
   struct = struct.(field);
end

return
