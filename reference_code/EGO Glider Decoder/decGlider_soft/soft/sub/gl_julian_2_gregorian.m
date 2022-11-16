% ------------------------------------------------------------------------------
% Convert a julian 1950 date in a gregorian date ('yyyy/mm/dd HH:MM:SS' format)
%
% SYNTAX :
%   [o_gregorianDate] = gl_julian_2_gregorian(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian date to convert
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorian converted date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/01/2007 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = gl_julian_2_gregorian(a_julDay)

% default values
global g_decGl_dateDef;
global g_decGl_ncDateDef;
global g_decGl_janFirst1950InMatlab;

if (isempty(g_decGl_dateDef))
   g_decGl_dateDef = 99999.99999999;
end
if (isempty(g_decGl_ncDateDef))
   g_decGl_ncDateDef = 999999;
end

if (isempty(g_decGl_janFirst1950InMatlab))
   g_decGl_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
end

o_gregorianDate = repmat('9999/99/99 99:99:99', length(a_julDay), 1);
idNoDef = find((a_julDay ~= g_decGl_dateDef) & (a_julDay ~= g_decGl_ncDateDef));
if (~isempty(idNoDef))
   o_gregorianDate(idNoDef, :) = datestr(a_julDay(idNoDef)+ g_decGl_janFirst1950InMatlab, 'yyyy/mm/dd HH:MM:SS');
end

% OBSOLETE
% global g_dateDef;
% g_dateDef = 99999.99999999;
% global g_dateGregStr;
% g_dateGregStr = '9999/99/99 99:99:99';
% 
% o_gregorianDate = [];
% 
% [dayNum, day, month, year, hour, min, sec] = gl_format_juld(a_julDay);
% 
% for idDate = 1:length(dayNum)
%    if (a_julDay(idDate) ~= g_dateDef)
%       o_gregorianDate = [o_gregorianDate; sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
%          year(idDate), month(idDate), day(idDate), hour(idDate), min(idDate), sec(idDate))];
%    else
%       o_gregorianDate = [o_gregorianDate; g_dateGregStr];
%    end
% end

return
