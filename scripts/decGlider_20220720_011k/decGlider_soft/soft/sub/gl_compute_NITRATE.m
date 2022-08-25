% ------------------------------------------------------------------------------
% Compute NITRATE from MOLAR_NITRATE.
%
% SYNTAX :
%  [o_nitrateValues] = gl_compute_NITRATE(a_timeValues, ...
%    a_ctdValues, a_molarNitrateValues, ...
%    a_timeGps, a_latitudeGps, a_longitudeGps)
%
% INPUT PARAMETERS :
%   a_timeValues         : time measurements
%   a_ctdValues          : CTD measurements
%   a_molarNitrateValues : MOLAR_NITRATE measurements
%   a_timeGps          : TIME_GPS data
%   a_latitudeGps      : LATITUDE_GPS data
%   a_longitudeGps     : LONGITUDE_GPS data
%
% OUTPUT PARAMETERS :
%   o_nitrateValues : output NITRATE data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nitrateValues] = gl_compute_NITRATE(a_timeValues, ...
   a_ctdValues, a_molarNitrateValues, ...
   a_timeGps, a_latitudeGps, a_longitudeGps)

   % output parameters initialization
o_nitrateValues = nan(size(a_molarNitrateValues));


molarNitrateNoDef = find(~isnan(a_molarNitrateValues));
if (~isempty(molarNitrateNoDef))
   
   molarNitrateTime = a_timeValues(molarNitrateNoDef);
   
   % interpolate the CTD data at the time of the NITRATE measurements
   ctdIntData = gl_compute_interpolated_CTD_measurements(a_timeValues, ...
      a_ctdValues, molarNitrateTime);
   
   if (~isempty(ctdIntData))
      
      % interpolate the GPS locations at the time of the OPTODE measurements
      [latIntGps, lonIntGps] =  gl_compute_interpolated_GPS_locations( ...
         a_timeGps, a_latitudeGps, a_longitudeGps, ...
         molarNitrateTime);
      
      if (~isempty(latIntGps))
         
         % compute NITRATE
         o_nitrateValues(molarNitrateNoDef) = gl_compute_NITRATE_values(a_molarNitrateValues(molarNitrateNoDef), ...
            ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), ...
            latIntGps, lonIntGps);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute NITRATE from MOLAR_NITRATE.
%
% SYNTAX :
%  [o_nitrateValues] = gl_compute_NITRATE_values(a_molarNitrateValues, ...
%    a_presValues, a_tempValues, a_psalValues, ...
%    a_latitude, a_longitude)
%
% INPUT PARAMETERS :
%   a_molarNitrateValues : MOLAR_NITRATE measurements
%   a_presValues         : PRES measurements
%   a_tempValues         : TEMP measurements
%   a_psalValues         : PSAL measurements
%   a_latitude           : measurement interpolated latitudes
%   a_longitude          : measurement interpolated longitudes
%
% OUTPUT PARAMETERS :
%   o_nitrateValues : output NITRATE data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nitrateValues] = gl_compute_NITRATE_values(a_molarNitrateValues, ...
   a_presValues, a_tempValues, a_psalValues, ...
   a_latitude, a_longitude)

% output parameters initialization
o_nitrateValues = nan(size(a_molarNitrateValues));


if (isempty(a_molarNitrateValues))
   return
end

idDef = find( ...
   isnan(a_molarNitrateValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues) | ...
   isnan(a_latitude) | (abs(a_latitude) > 180) | ...
   isnan(a_longitude) | (abs(a_longitude) > 90));
idNoDef = setdiff(1:length(o_nitrateValues), idDef);

if (~isempty(idNoDef))
   
   molarNitrateValues = a_molarNitrateValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   latitude = a_latitude(idNoDef);
   longitude = a_longitude(idNoDef);   
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, longitude, latitude);
   rho = rho/1000;
   
   nitrateValues = molarNitrateValues ./ rho;
   idNoNan = find(~isnan(nitrateValues));

   o_nitrateValues(idNoDef(idNoNan)) = nitrateValues(idNoNan);   
end

return
