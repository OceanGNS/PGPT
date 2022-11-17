% ------------------------------------------------------------------------------
% Parse GPS data collected in a bpo file.
%
% SYNTAX :
%  [o_structure] = gl_parse_gps_data(a_structure)
%
% INPUT PARAMETERS :
%   a_structure : input GPS data structure (from bpo file)
%
% OUTPUT PARAMETERS :
%   a_structure : output parsed GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_structure] = gl_parse_gps_data(a_structure)

% output data initialization
o_structure = [];

lat = [];
lon = [];
date = [];
fNames = fieldnames(a_structure);
for idF = 1:length(fNames)
   if (strncmp(fNames{idF}, 'GPS', 3))
      data = strtrim(char(a_structure.(fNames{idF})));
      c = strfind(data, ')');
      if (~isempty(c))
         [id, count, errmsg, nextIndex] = sscanf(data(1:c), '(%f %f)');
         if (isempty(errmsg) && (count == 2))
            lat = [lat id(1)];
            lon = [lon id(2)];
            date = [date datenum(data(c+1:end), 'mm/dd/yy HH:MM:SS')];
         end
      end
   end
end

if (~isempty(lat))
   % store the data
   o_structure.latitude = lat;
   o_structure.longitude = lon;
   epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
   o_structure.time = (date - epoch_offset)*86400;
end

return
