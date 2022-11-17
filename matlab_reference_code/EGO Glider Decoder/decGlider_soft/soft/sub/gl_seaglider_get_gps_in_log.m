% ------------------------------------------------------------------------------
% Read the GPS data (from a p*.log file) and store it in a structure.
%
% SYNTAX :
%  [o_structure] = gl_seaglider_get_gps_in_log(a_sgLogFilePathName)
%
% INPUT PARAMETERS :
%   a_sgLogFilePathName : p*.log file path name
%
% OUTPUT PARAMETERS :
%   o_structure : output structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_structure] = gl_seaglider_get_gps_in_log(a_sgLogFilePathName)

% output data initialization
o_structure = [];

% check inputs
if ~(exist(a_sgLogFilePathName, 'file') == 2)
   fprintf('INFO: Log file not found: %s\n', a_sgLogFilePathName);
   return
end

% open the file
fIdIn = fopen(a_sgLogFilePathName, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_sgLogFilePathName);
   return
end

% read the data and get GPS information
decode_GPS = @(x) sign(x).*(fix(abs(x)/100)+ mod(abs(x),100)./60);
decode_time = @(x,y) datenum(mod(x,100) + 2000,floor(mod(x,10000)/100),floor(x/10000),...
   floor(y./10000),floor(mod(y,10000)/100),mod(y,100));
o_structure.latitude = [];
o_structure.longitude = [];
o_structure.time = [];
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
while (1)
   line = fgetl(fIdIn);
   if (line == -1)
      break
   end
   if (strncmp(line, '$GPS', length('$GPS')))
      idF = strfind(line, ',');
      line2 = line(idF(1)+1:end);
      [id, count, errmsg, nextIndex] = sscanf(line2, '%d,%d,%f,%f,%g,%g,%g,%g');
      if (isempty(errmsg) && (count == 8))
         % store the data
         o_structure.latitude(end+1) = decode_GPS(id(3));
         o_structure.longitude(end+1) = decode_GPS(id(4));
         o_structure.time(end+1) = (decode_time(id(1), id(2)) - epoch_offset)*86400;
      end
   end
end
fclose(fIdIn);

return
