% ------------------------------------------------------------------------------
% Interpolate PTS measurement at provided TIME values.
%
% SYNTAX :
%  [o_ctdIntData] = gl_compute_interpolated_CTD_measurements( ...
%    a_timeData, a_ctdMeasData, a_intTimeData)
%
% INPUT PARAMETERS :
%   a_timeData    : TIME measurements
%   a_ctdMeasData : CTD measurements
%   a_intTimeData : TIME values where PTS measurements should be interpolated
%
% OUTPUT PARAMETERS :
%   o_ctdIntData : PTS interpolated data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/26/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdIntData] = gl_compute_interpolated_CTD_measurements( ...
   a_timeData, a_ctdMeasData, a_intTimeData)

% output parameters initialization
o_ctdIntData = [];


if (isempty(a_timeData) || isempty(a_ctdMeasData) || isempty(a_intTimeData))
   return
end

% interpolate the P, T and S measurements at the output time instant
idNoDefInput = find(~isnan(a_ctdMeasData(:, 1)) & ~isnan(a_ctdMeasData(:, 2)) & ~isnan(a_ctdMeasData(:, 2)));
if (length(idNoDefInput) > 1)

   presIntData = interp1(a_timeData(idNoDefInput), ...
      a_ctdMeasData(idNoDefInput, 1), ...
      a_intTimeData, 'linear');
   tempIntData = interp1(a_timeData(idNoDefInput), ...
      a_ctdMeasData(idNoDefInput, 2), ...
      a_intTimeData, 'linear');
   psalIntData = interp1(a_timeData(idNoDefInput), ...
      a_ctdMeasData(idNoDefInput, 3), ...
      a_intTimeData, 'linear');
   
   % output parameters
   o_ctdIntData = cat(2, presIntData, tempIntData, psalIntData);
   
elseif ((length(idNoDefInput) == 1) && (length(a_intTimeData) == 1) && ...
      (a_timeData(idNoDefInput) == a_intTimeData))
   
   o_ctdIntData = a_ctdMeasData;

end

return
