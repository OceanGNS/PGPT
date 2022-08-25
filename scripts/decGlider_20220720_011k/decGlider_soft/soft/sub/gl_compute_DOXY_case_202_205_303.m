% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (C1PHASE_DOXY, C2PHASE_DOXY and TEMP_DOXY) according to Case 202_205_303
% specifications.
%
% SYNTAX :
%  [o_doxyValues] = gl_compute_DOXY_case_202_205_303(a_timeValues, ...
%    a_ctdValues, a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, ...
%    a_timeGps, a_latitudeGps, a_longitudeGps)
%
% INPUT PARAMETERS :
%   a_timeValues        : time measurements
%   a_ctdValues         : CTD measurements
%   a_c1PhaseDoxyValues : C1PHASE_DOXY measurements
%   a_c2PhaseDoxyValues : C2PHASE_DOXY measurements
%   a_tempDoxyValues    : TEMP_DOXY measurements
%   a_timeGps           : TIME_GPS data
%   a_latitudeGps       : LATITUDE_GPS data
%   a_longitudeGps      : LONGITUDE_GPS data
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
function [o_doxyValues] = gl_compute_DOXY_case_202_205_303(a_timeValues, ...
   a_ctdValues, a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, ...
   a_timeGps, a_latitudeGps, a_longitudeGps)

% output parameters initialization
o_doxyValues = nan(size(a_c1PhaseDoxyValues));


inputDoxyNoDef = find(~isnan(a_c1PhaseDoxyValues) & ...
   ~isnan(a_c2PhaseDoxyValues) & ~isnan(a_tempDoxyValues));
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
         o_doxyValues(inputDoxyNoDef) = compute_DOXY_202_205_303( ...
            a_c1PhaseDoxyValues(inputDoxyNoDef), ...
            a_c2PhaseDoxyValues(inputDoxyNoDef), ...
            a_tempDoxyValues(inputDoxyNoDef), ...
            ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), ...
            latIntGps, lonIntGps);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (C1PHASE_DOXY, C2PHASE_DOXY and TEMP_DOXY) according to Case 202_205_303
% specifications.
%
% SYNTAX :
%  [o_doxyValues] = compute_DOXY_202_205_303( ...
%    a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, ...
%    a_presValues, a_tempValues, a_psalValues, ...
%    a_latitude, a_longitude)
%
% INPUT PARAMETERS :
%   a_c1PhaseDoxyValues : C1PHASE_DOXY measurements
%   a_c2PhaseDoxyValues : C2PHASE_DOXY measurements
%   a_tempDoxyValues    : TEMP_DOXY measurements
%   a_presValues        : PRES measurements
%   a_tempValues        : TEMP measurements
%   a_psalValues        : PSAL measurements
%   a_latitude          : measurement interpolated latitudes
%   a_longitude         : measurement interpolated longitudes
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
function [o_doxyValues] = compute_DOXY_202_205_303( ...
   a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues, ...
   a_latitude, a_longitude)

% output parameters initialization
o_doxyValues = nan(size(a_c1PhaseDoxyValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;

% retrieve global coefficient default values
global g_decGl_doxy_202_205_303_a0;
global g_decGl_doxy_202_205_303_a1;
global g_decGl_doxy_202_205_303_a2;
global g_decGl_doxy_202_205_303_a3;
global g_decGl_doxy_202_205_303_a4;
global g_decGl_doxy_202_205_303_a5;
global g_decGl_doxy_202_205_303_d0;
global g_decGl_doxy_202_205_303_d1;
global g_decGl_doxy_202_205_303_d2;
global g_decGl_doxy_202_205_303_d3;
global g_decGl_doxy_202_205_303_sPreset;
global g_decGl_doxy_202_205_303_b0;
global g_decGl_doxy_202_205_303_b1;
global g_decGl_doxy_202_205_303_b2;
global g_decGl_doxy_202_205_303_b3;
global g_decGl_doxy_202_205_303_c0;
global g_decGl_doxy_202_205_303_pCoef1;
global g_decGl_doxy_202_205_303_pCoef2;
global g_decGl_doxy_202_205_303_pCoef3;


if (isempty(a_c1PhaseDoxyValues) || isempty(a_c2PhaseDoxyValues) || isempty(a_tempDoxyValues))
   return
end

% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
   return
end
calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
if (isfield(calibInfo, 'TabDoxyCoef'))
   tabDoxyCoef = calibInfo.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
   % Aanderaa standard calibration + an additional two-point adjustment
   if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
      fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
      return
   end
else
   fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
   return
end


idDef = find( ...
   isnan(a_c1PhaseDoxyValues) | ...
   isnan(a_c2PhaseDoxyValues) | ...
   isnan(a_tempDoxyValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues) | ...
   isnan(a_latitude) | (abs(a_latitude) > 180) | ...
   isnan(a_longitude) | (abs(a_longitude) > 90));
idNoDef = setdiff(1:length(o_doxyValues), idDef);

if (~isempty(idNoDef))
   
   tPhaseDoxyValues = a_c1PhaseDoxyValues(idNoDef) - a_c2PhaseDoxyValues(idNoDef);
   tempDoxyValues = a_tempDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   latitude = a_latitude(idNoDef);
   longitude = a_longitude(idNoDef);
   
   % compute MOLAR_DOXY from TPHASE_DOXY using the Aanderaa standard calibration
   % + an additional two-point adjustment
   molarDoxyValues = calcoxy_aanderaa4330_aanderaa( ...
      tPhaseDoxyValues, presValues, tempDoxyValues, tabDoxyCoef, ...
      g_decGl_doxy_202_205_303_pCoef1, ...
      g_decGl_doxy_202_205_303_a0, ...
      g_decGl_doxy_202_205_303_a1, ...
      g_decGl_doxy_202_205_303_a2, ...
      g_decGl_doxy_202_205_303_a3, ...
      g_decGl_doxy_202_205_303_a4, ...
      g_decGl_doxy_202_205_303_a5 ...
      );

   % salinity effect correction
   sRef = 0; % not considered since a PHASE_DOXY is transmitted
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, sRef, ...
      g_decGl_doxy_202_205_303_d0, ...
      g_decGl_doxy_202_205_303_d1, ...
      g_decGl_doxy_202_205_303_d2, ...
      g_decGl_doxy_202_205_303_d3, ...
      g_decGl_doxy_202_205_303_sPreset, ...
      g_decGl_doxy_202_205_303_b0, ...
      g_decGl_doxy_202_205_303_b1, ...
      g_decGl_doxy_202_205_303_b2, ...
      g_decGl_doxy_202_205_303_b3, ...
      g_decGl_doxy_202_205_303_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decGl_doxy_202_205_303_pCoef2, ...
      g_decGl_doxy_202_205_303_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, longitude, latitude);
   rho = rho/1000;
   
   oxyValues = oxygenPresComp ./ rho;
   idNoNan = find(~isnan(oxyValues));
   
   o_doxyValues(idNoDef(idNoNan)) = oxyValues(idNoNan);
end

return
