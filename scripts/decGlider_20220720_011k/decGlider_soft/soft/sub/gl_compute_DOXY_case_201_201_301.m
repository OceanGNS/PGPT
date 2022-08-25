% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (MOLAR_DOXY) according to Case 201_201_301 specifications.
%
% SYNTAX :
%  [o_doxyValues] = gl_compute_DOXY_case_201_201_301(a_timeValues, ...
%    a_ctdValues, a_molarDoxyValues, ...
%    a_timeGps, a_latitudeGps, a_longitudeGps)
%
% INPUT PARAMETERS :
%   a_timeValues      : time measurements
%   a_ctdValues       : CTD measurements
%   a_molarDoxyValues : MOLAR_DOXY measurements
%   a_timeGps          : TIME_GPS data
%   a_latitudeGps      : LATITUDE_GPS data
%   a_longitudeGps     : LONGITUDE_GPS data
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
%   08/25/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = gl_compute_DOXY_case_201_201_301(a_timeValues, ...
   a_ctdValues, a_molarDoxyValues, ...
   a_timeGps, a_latitudeGps, a_longitudeGps)

% output parameters initialization
o_doxyValues = nan(size(a_molarDoxyValues));


molarDoxyNoDef = find(~isnan(a_molarDoxyValues));
if (~isempty(molarDoxyNoDef))
   
   molarDoxyTime = a_timeValues(molarDoxyNoDef);
   
   % interpolate the CTD data at the time of the OPTODE measurements
   ctdIntData = gl_compute_interpolated_CTD_measurements(a_timeValues, ...
      a_ctdValues, molarDoxyTime);
   
   if (~isempty(ctdIntData))
      
      % interpolate the GPS locations at the time of the OPTODE measurements
      [latIntGps, lonIntGps] =  gl_compute_interpolated_GPS_locations( ...
         a_timeGps, a_latitudeGps, a_longitudeGps, ...
         molarDoxyTime);
      
      if (~isempty(latIntGps))
         
         % compute DOXY
         o_doxyValues(molarDoxyNoDef) = compute_DOXY_201_201_301(a_molarDoxyValues(molarDoxyNoDef), ...
            ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), ...
            latIntGps, lonIntGps);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (MOLAR_DOXY) according to Case 201_201_301 specifications.
%
% SYNTAX :
%  [o_doxyValues] = compute_DOXY_201_201_301(a_molarDoxyValues, ...
%    a_presValues, a_tempValues, a_psalValues, ...
%    a_latitude, a_longitude)
%
% INPUT PARAMETERS :
%   a_molarDoxyValues : MOLAR_DOXY measurements
%   a_presValues      : PRES measurements
%   a_tempValues      : TEMP measurements
%   a_psalValues      : PSAL measurements
%   a_latitude         : measurement interpolated latitudes
%   a_longitude        : measurement interpolated longitudes
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
%   08/25/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_201_201_301(a_molarDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues, ...
   a_latitude, a_longitude)

% output parameters initialization
o_doxyValues = nan(size(a_molarDoxyValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;

% retrieve global coefficient default values
global g_decGl_doxy_201and202_201_301_d0;
global g_decGl_doxy_201and202_201_301_d1;
global g_decGl_doxy_201and202_201_301_d2;
global g_decGl_doxy_201and202_201_301_d3;
global g_decGl_doxy_201and202_201_301_sPreset;
global g_decGl_doxy_201and202_201_301_b0;
global g_decGl_doxy_201and202_201_301_b1;
global g_decGl_doxy_201and202_201_301_b2;
global g_decGl_doxy_201and202_201_301_b3;
global g_decGl_doxy_201and202_201_301_c0;
global g_decGl_doxy_201and202_201_301_pCoef2;
global g_decGl_doxy_201and202_201_301_pCoef3;


if (isempty(a_molarDoxyValues))
   return
end

% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: DOXY calibration reference salinity is missing => set to 0\n');
   doxyCalibRefSalinity = 0;
else
   calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
   if (isfield(calibInfo, 'DoxyCalibRefSalinity'))
      doxyCalibRefSalinity = calibInfo.DoxyCalibRefSalinity;
   else
      fprintf('WARNING: DOXY calibration reference salinity is missing => set to 0\n');
      doxyCalibRefSalinity = 0;
   end
end

idDef = find( ...
   isnan(a_molarDoxyValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues) | ...
   isnan(a_latitude) | (abs(a_latitude) > 180) | ...
   isnan(a_longitude) | (abs(a_longitude) > 90));
idNoDef = setdiff(1:length(o_doxyValues), idDef);

if (~isempty(idNoDef))
   
   molarDoxyValues = a_molarDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   latitude = a_latitude(idNoDef);
   longitude = a_longitude(idNoDef);
   
   % salinity effect correction
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, doxyCalibRefSalinity, ...
      g_decGl_doxy_201and202_201_301_d0, ...
      g_decGl_doxy_201and202_201_301_d1, ...
      g_decGl_doxy_201and202_201_301_d2, ...
      g_decGl_doxy_201and202_201_301_d3, ...
      g_decGl_doxy_201and202_201_301_sPreset, ...
      g_decGl_doxy_201and202_201_301_b0, ...
      g_decGl_doxy_201and202_201_301_b1, ...
      g_decGl_doxy_201and202_201_301_b2, ...
      g_decGl_doxy_201and202_201_301_b3, ...
      g_decGl_doxy_201and202_201_301_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decGl_doxy_201and202_201_301_pCoef2, ...
      g_decGl_doxy_201and202_201_301_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, longitude, latitude);
   rho = rho/1000;
   
   oxyValues = oxygenPresComp ./ rho;
   idNoNan = find(~isnan(oxyValues));

   o_doxyValues(idNoDef(idNoNan)) = oxyValues(idNoNan);   
end

return
