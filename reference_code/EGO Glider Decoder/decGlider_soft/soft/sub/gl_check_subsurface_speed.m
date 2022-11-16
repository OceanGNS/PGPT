% ------------------------------------------------------------------------------
% Check subsurface position against surface ones (for horizontal velocity less
% than 3 m/s).
%
% SYNTAX :
%  [o_failedIds] = gl_check_subsurface_speed( ...
%    a_subSurfLocDate, a_subSurfLocLon, a_subSurfLocLat, ...
%    a_surfLocDate, a_surfLocLon, a_surfLocLat)
%
% INPUT PARAMETERS :
%   a_subSurfLocDate : subsurface location dates
%   a_subSurfLocLon  : subsurface location longitudes
%   a_subSurfLocLat  : subsurface location latitudes
%   a_surfLocDate    : surface location dates
%   a_surfLocLon     : surface location longitudes
%   a_surfLocLat     : surface location latitudes
%
% OUTPUT PARAMETERS :
%   o_failedIds : ids of subsurface locations that failed the test
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/20/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_failedIds] = gl_check_subsurface_speed( ...
   a_subSurfLocDate, a_subSurfLocLon, a_subSurfLocLat, ...
   a_surfLocDate, a_surfLocLon, a_surfLocLat)

% output parameters initialization
o_failedIds = [];


if (isempty(a_surfLocDate))
   o_failedIds = 1:length(a_subSurfLocDate);
end

% maximal surface velocity (m/s)
MAX_VEL = 3;

for idP = 1:length(a_subSurfLocDate)
   
   % look for a surface location to use to check the current subsurface one
   idSurf = find (abs(a_surfLocDate - a_subSurfLocDate(idP)) > 10/1440);
   if (~isempty(idSurf))
      
      [~, idMin] = min(abs(a_surfLocDate(idSurf) - a_subSurfLocDate(idP)));
      
      % compute the horizontal velocity between both locations
      distance = distance_lpo([a_subSurfLocLat(idP) a_surfLocLat(idSurf(idMin))], [a_subSurfLocLon(idP) a_surfLocLon(idSurf(idMin))]);
      speed = distance/(abs(a_subSurfLocDate(idP) - a_surfLocDate(idSurf(idMin)))*86400);
      
      if (speed > MAX_VEL)
         o_failedIds = [o_failedIds idP];
      end
   else
      
      [~, idMax] = max(abs(a_surfLocDate - a_subSurfLocDate(idP)));
      diffTime = abs(a_subSurfLocDate(idP) - a_surfLocDate(idMax))*86400;
      if (diffTime < 1)
         diffTime = 1;
      end
      
      % compute the horizontal velocity between both locations
      distance = distance_lpo([a_subSurfLocLat(idP) a_surfLocLat(idMax)], [a_subSurfLocLon(idP) a_surfLocLon(idMax)]);
      speed = distance/diffTime;
      
      if (speed > MAX_VEL)
         o_failedIds = [o_failedIds idP];
      end
   end
end

return
