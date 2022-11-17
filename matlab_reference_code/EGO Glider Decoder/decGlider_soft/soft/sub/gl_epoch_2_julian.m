% ------------------------------------------------------------------------------
% Convert an epoch data to a julian 1950 one
%
% SYNTAX :
%  [o_julDay] = gl_epoch_2_julian(a_epochDate)
%
% INPUT PARAMETERS :
%   a_epochDate : epoch date to convert
%
% OUTPUT PARAMETERS :
%   o_julDay : julian converted date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   20/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julDay] = gl_epoch_2_julian(a_epochDate)

% default values
global g_decGl_dateDef;
global g_decGl_epochDateDef;

if (isempty(g_decGl_dateDef))
   g_decGl_dateDef = 99999.99999999;
end

if (isempty(g_decGl_epochDateDef))
   g_decGl_epochDateDef = 9999999999.0;
end

o_julDay = ones(length(a_epochDate), 1)*g_decGl_dateDef;
idNoDef = find(a_epochDate ~= g_decGl_epochDateDef);
if (~isempty(idNoDef))
   epochOffset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
   o_julDay(idNoDef) = (a_epochDate(idNoDef)/86400) + epochOffset;
end

return
