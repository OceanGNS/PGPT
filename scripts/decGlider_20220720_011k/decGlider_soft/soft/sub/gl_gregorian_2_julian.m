% ------------------------------------------------------------------------------
% Convert a gregorian date to a julian 1950 date.
%
% SYNTAX :
%   [o_julDay] = gl_gregorian_2_julian(a_gregorianDate)
%
% INPUT PARAMETERS :
%   a_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or 
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% OUTPUT PARAMETERS :
%   o_julDay : julian 1950 date
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julDay] = gl_gregorian_2_julian(a_gregorianDate)

% default values
global g_decGl_dateDef;
global g_decGl_janFirst1950InMatlab;

if (isempty(g_decGl_dateDef))
   g_decGl_dateDef = 99999.99999999;
end
if (isempty(g_decGl_janFirst1950InMatlab))
   g_decGl_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
end

% output parameters initialization
o_julDay = g_decGl_dateDef;

if (~strcmp(deblank(a_gregorianDate(:)), ''))

   if (length(a_gregorianDate) == 16)
      a_gregorianDate = [a_gregorianDate ':00'];
   end
   
   res = sscanf(a_gregorianDate, '%d/%d/%d %d:%d:%d');
   if ((res(1) ~= 9999) && (res(2) ~= 99) && (res(3) ~= 99) && ...
         (res(4) ~= 99) && (res(5) ~= 99))

      o_julDay = datenum(a_gregorianDate, 'yyyy/mm/dd HH:MM:SS') - g_decGl_janFirst1950InMatlab;
   end
end

return
