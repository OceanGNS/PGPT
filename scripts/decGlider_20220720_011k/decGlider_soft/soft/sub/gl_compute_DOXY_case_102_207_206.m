% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (FREQUENCY_DOXY) according to Case 102_207_206 specifications.
%
% SYNTAX :
%  [o_doxyValues] = gl_compute_DOXY_case_102_207_206(a_timeValues, ...
%    a_ctdValues, a_frequencyDoxyValues, ...
%    a_timeGps, a_latitudeGps, a_longitudeGps)
%
% INPUT PARAMETERS :
%   a_timeValues          : time measurements
%   a_ctdValues           : CTD measurements
%   a_frequencyDoxyValues : FREQUENCY_DOXY measurements
%   a_timeGps             : TIME_GPS data
%   a_latitudeGps         : LATITUDE_GPS data
%   a_longitudeGps        : LONGITUDE_GPS data
%
% OUTPUT PARAMETERS :
%   o_doxyValues : computed DOXY values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/31/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = gl_compute_DOXY_case_102_207_206(a_timeValues, ...
   a_ctdValues, a_frequencyDoxyValues, ...
   a_timeGps, a_latitudeGps, a_longitudeGps)

   % output parameters initialization
o_doxyValues = nan(size(a_frequencyDoxyValues));


inputDoxyNoDef = find(~isnan(a_frequencyDoxyValues));
if (~isempty(inputDoxyNoDef))
   
   inputDoxyTime = a_timeValues(inputDoxyNoDef);
   
   % interpolate the CTD data at the time of the OPTODE measurements
   ctdIntData = gl_compute_interpolated_CTD_measurements(a_timeValues, ...
      a_ctdValues, inputDoxyTime);
   
   if (~isempty(ctdIntData))
      
      % interpolate the GPS locations at the time of the OPTODE measurements
      [latIntGps, lonIntGps] =  gl_compute_interpolated_GPS_locations( ...
         a_timeGps, a_latitudeGps, a_longitudeGps, ...
         inputDoxyTime);
      
      if (~isempty(latIntGps))
         
         % compute DOXY
         o_doxyValues(inputDoxyNoDef) = compute_DOXY_102_207_206( ...
            a_frequencyDoxyValues(inputDoxyNoDef), ...
            ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), ...
            latIntGps, lonIntGps);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (FREQUENCY_DOXY) according to Case 102_207_206 specifications.
%
% SYNTAX :
%  [o_doxyValues] = compute_DOXY_102_207_206( ...
%    a_frequencyDoxyValues, ...
%    a_presValues, a_tempValues, a_psalValues, ...
%    a_latitude, a_longitude)
%
% INPUT PARAMETERS :
%   a_frequencyDoxyValues : FREQUENCY_DOXY measurements
%   a_presValues          : PRES measurements
%   a_tempValues          : TEMP measurements
%   a_psalValues          : PSAL measurements
%   a_latitude            : measurement interpolated latitudes
%   a_longitude           : measurement interpolated longitudes
%
% OUTPUT PARAMETERS :
%   o_doxyValues : computed DOXY values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/31/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_102_207_206( ...
   a_frequencyDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues, ...
   a_latitude, a_longitude)

   % output parameters initialization
o_doxyValues = nan(size(a_frequencyDoxyValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;

% retrieve global coefficient default values
global g_decGl_doxy_102_207_206_a0;
global g_decGl_doxy_102_207_206_a1;
global g_decGl_doxy_102_207_206_a2;
global g_decGl_doxy_102_207_206_a3;
global g_decGl_doxy_102_207_206_a4;
global g_decGl_doxy_102_207_206_a5;
global g_decGl_doxy_102_207_206_b0;
global g_decGl_doxy_102_207_206_b1;
global g_decGl_doxy_102_207_206_b2;
global g_decGl_doxy_102_207_206_b3;
global g_decGl_doxy_102_207_206_c0;


if (isempty(a_frequencyDoxyValues))
   return
end

% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
   return
end
calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
if (isfield(calibInfo, 'SbeTabDoxyCoef'))
   tabDoxyCoef = calibInfo.SbeTabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
   if (~isempty(find((size(tabDoxyCoef) == [1 6]) ~= 1, 1)))
      fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
      return
   end
else
   fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
   return
end


idDef = find( ...
   isnan(a_frequencyDoxyValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues) | ...
   isnan(a_latitude) | (abs(a_latitude) > 180) | ...
   isnan(a_longitude) | (abs(a_longitude) > 90));
idNoDef = setdiff(1:length(o_doxyValues), idDef);

if (~isempty(idNoDef))
   
   frequencyDoxyValues = a_frequencyDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   latitude = a_latitude(idNoDef);
   longitude = a_longitude(idNoDef);
   
   % compute MLPL_DOXY from FREQUENCY_DOXY reported by the SBE 43F sensor
   mlplDoxyValues = calcoxy_sbe43f( ...
      frequencyDoxyValues, presValues, tempValues, psalValues, tabDoxyCoef, ...
      g_decGl_doxy_102_207_206_a0, ...
      g_decGl_doxy_102_207_206_a1, ...
      g_decGl_doxy_102_207_206_a2, ...
      g_decGl_doxy_102_207_206_a3, ...
      g_decGl_doxy_102_207_206_a4, ...
      g_decGl_doxy_102_207_206_a5, ...
      g_decGl_doxy_102_207_206_b0, ...
      g_decGl_doxy_102_207_206_b1, ...
      g_decGl_doxy_102_207_206_b2, ...
      g_decGl_doxy_102_207_206_b3, ...
      g_decGl_doxy_102_207_206_c0);
   
   % convert MLPL_DOXY in micromol/L
   molarDoxyValues = 44.6596*mlplDoxyValues;
      
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, longitude, latitude);
   rho = rho/1000;

   oxyValues = molarDoxyValues ./ rho;
   idNoNan = find(~isnan(oxyValues));
   
   o_doxyValues(idNoDef(idNoNan)) = oxyValues(idNoNan);
end

return
