% ------------------------------------------------------------------------------
% Interpolate GPS locations at provided TIME values.
%
% SYNTAX :
%  [o_latIntGps, o_lonIntGps] = gl_compute_interpolated_GPS_locations( ...
%    a_timeGps, a_latitudeGps, a_longitudeGps, a_intTimeData)
%
% INPUT PARAMETERS :
%   a_timeGps      : TIME_GPS data
%   a_latitudeGps  : LATITUDE_GPS data
%   a_longitudeGps : LONGITUDE_GPS data
%   a_intTimeData  : TIME values where GPS locations should be interpolated
%
% OUTPUT PARAMETERS :
%   o_latIntGps : interpolated latitudes
%   o_lonIntGps : interpolated longitudes
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_latIntGps, o_lonIntGps] = gl_compute_interpolated_GPS_locations( ...
   a_timeGps, a_latitudeGps, a_longitudeGps, a_intTimeData)

% output parameters initialization
o_latIntGps = [];
o_lonIntGps = [];


if (isempty(a_timeGps) || isempty(a_latitudeGps) || isempty(a_longitudeGps) || isempty(a_intTimeData))
   return
end

% interpolate the GPS locations at the output time instant
idNoDefInput = find(~isnan(a_latitudeGps) & ~isnan(a_longitudeGps));
if (length(idNoDefInput) > 1)

   % time data should be unique
   [timeGps, idUnique, ~] = unique(a_timeGps(idNoDefInput));
   latitudeGps = a_latitudeGps(idNoDefInput(idUnique));
   longitudeGps = a_longitudeGps(idNoDefInput(idUnique));
   
   o_latIntGps = interp1(timeGps, latitudeGps, a_intTimeData, 'linear');
   o_lonIntGps = interp1(timeGps, longitudeGps, a_intTimeData, 'linear');
   
   if (all(isnan(o_latIntGps)))
      % all GPS times are before or after measurement times
      if (all(max(timeGps) < a_intTimeData))
         % before
         [~, idMax] = max(timeGps);
         o_latIntGps = ones(size(a_intTimeData))*latitudeGps(idMax);
         o_lonIntGps = ones(size(a_intTimeData))*longitudeGps(idMax);
      else
         % after
         [~, idMin] = min(timeGps);
         o_latIntGps = ones(size(a_intTimeData))*latitudeGps(idMin);
         o_lonIntGps = ones(size(a_intTimeData))*longitudeGps(idMin);
      end
   end
end

return
