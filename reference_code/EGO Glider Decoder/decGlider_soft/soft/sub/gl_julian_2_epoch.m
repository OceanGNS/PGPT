% ------------------------------------------------------------------------------
% Convert a julian 1950 date in an epoch one
%
% SYNTAX :
%   [o_epochDate] = gl_julian_2_epoch(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian date to convert
%
% OUTPUT PARAMETERS :
%   o_epochDate : epoch converted date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   20/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_epochDate] = gl_julian_2_epoch(a_julDay)

% default values
global g_decGl_dateDef;
global g_decGl_epochDateDef;

if (isempty(g_decGl_dateDef))
   g_decGl_dateDef = 99999.99999999;
end

if (isempty(g_decGl_epochDateDef))
   g_decGl_epochDateDef = 9999999999.0;
end

o_epochDate = ones(length(a_julDay), 1)*g_decGl_epochDateDef;
idNoDef = find(a_julDay ~= g_decGl_dateDef);
if (~isempty(idNoDef))
   epochOffset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
   o_epochDate(idNoDef) = (a_julDay(idNoDef) - epochOffset) * 86400;
end

return
