% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (BPHASE_DOXY) according to Case 201_202_202 specifications.
%
% SYNTAX :
%  [o_doxyValues] = gl_compute_DOXY_case_201_202_202(a_timeValues, ...
%    a_ctdValues, a_bPhaseDoxyValues, ...
%    a_timeGps, a_latitudeGps, a_longitudeGps)
%
% INPUT PARAMETERS :
%   a_timeValues       : time measurements
%   a_ctdValues        : CTD measurements
%   a_bPhaseDoxyValues : BPHASE_DOXY measurements
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
function [o_doxyValues] = gl_compute_DOXY_case_201_202_202(a_timeValues, ...
   a_ctdValues, a_bPhaseDoxyValues, ...
   a_timeGps, a_latitudeGps, a_longitudeGps)

% output parameters initialization
o_doxyValues = nan(size(a_bPhaseDoxyValues));


bPhaseDoxyNoDef = find(~isnan(a_bPhaseDoxyValues));
if (~isempty(bPhaseDoxyNoDef))
   
   bPhaseDoxyTime = a_timeValues(bPhaseDoxyNoDef);
   
   % interpolate the CTD data at the time of the OPTODE measurements
   ctdIntData = gl_compute_interpolated_CTD_measurements(a_timeValues, ...
      a_ctdValues, bPhaseDoxyTime);
   
   if (~isempty(ctdIntData))
      
      % interpolate the GPS locations at the time of the OPTODE measurements
      [latIntGps, lonIntGps] =  gl_compute_interpolated_GPS_locations( ...
         a_timeGps, a_latitudeGps, a_longitudeGps, ...
         bPhaseDoxyTime);
      
      if (~isempty(latIntGps))
         
         % compute DOXY
         o_doxyValues(bPhaseDoxyNoDef) = compute_DOXY_201_202_202(a_bPhaseDoxyValues(bPhaseDoxyNoDef), ...
            ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), ...
            latIntGps, lonIntGps);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (BPHASE_DOXY) according to Case 201_202_202 specifications.
%
% SYNTAX :
%  [o_doxyValues] = compute_DOXY_201_202_202(a_bPhaseDoxyValues, ...
%    a_presValues, a_tempValues, a_psalValues, ...
%    a_latitude, a_longitude)
%
% INPUT PARAMETERS :
%   a_bPhaseDoxyValues : BPHASE_DOXY measurements
%   a_presValues       : PRES measurements
%   a_tempValues       : TEMP measurements
%   a_psalValues       : PSAL measurements
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
function [o_doxyValues] = compute_DOXY_201_202_202(a_bPhaseDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues, ...
   a_latitude, a_longitude)

% output parameters initialization
o_doxyValues = nan(size(a_bPhaseDoxyValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;

% retrieve global coefficient default values
global g_decGl_doxy_201_202_202_d0;
global g_decGl_doxy_201_202_202_d1;
global g_decGl_doxy_201_202_202_d2;
global g_decGl_doxy_201_202_202_d3;
global g_decGl_doxy_201_202_202_sPreset;
global g_decGl_doxy_201_202_202_b0;
global g_decGl_doxy_201_202_202_b1;
global g_decGl_doxy_201_202_202_b2;
global g_decGl_doxy_201_202_202_b3;
global g_decGl_doxy_201_202_202_c0;
global g_decGl_doxy_201_202_202_pCoef1;
global g_decGl_doxy_201_202_202_pCoef2;
global g_decGl_doxy_201_202_202_pCoef3;


if (isempty(a_bPhaseDoxyValues))
   return
end

% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
   return
end
calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
if (isfield(calibInfo, 'TabPhaseCoef') && isfield(calibInfo, 'TabDoxyCoef'))
   tabPhaseCoef = calibInfo.TabPhaseCoef;
   % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
   % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
   if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
      fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
      return
   end
   tabDoxyCoef = calibInfo.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
   % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
   if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
      fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
      return
   end
else
   fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
   return
end

idDef = find( ...
   isnan(a_bPhaseDoxyValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues) | ...
   isnan(a_latitude) | (abs(a_latitude) > 180) | ...
   isnan(a_longitude) | (abs(a_longitude) > 90));
idNoDef = setdiff(1:length(o_doxyValues), idDef);

if (~isempty(idNoDef))
   
   bPhaseDoxyValues = a_bPhaseDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   latitude = a_latitude(idNoDef);
   longitude = a_longitude(idNoDef);
   
   % compute DPHASE_DOXY
   
   phaseCoef0 = tabPhaseCoef(1);
   phaseCoef1 = tabPhaseCoef(2);
   phaseCoef2 = tabPhaseCoef(3);
   phaseCoef3 = tabPhaseCoef(4);

   rPhaseDoxy = 0; % not available from the DO sensor
   uncalPhase = bPhaseDoxyValues - rPhaseDoxy;
   phasePcorr = uncalPhase + g_decGl_doxy_201_202_202_pCoef1 .* presValues/1000;
   dPhaseDoxyValues = phaseCoef0 + phaseCoef1.*phasePcorr + ...
      phaseCoef2.*phasePcorr.^2 + phaseCoef3.*phasePcorr.^3;   
   
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830_aanderaa( ...
      dPhaseDoxyValues, presValues, tempValues, tabDoxyCoef, ...
      0 ... % the phase has already been corrected
      );
   
   % salinity effect correction
   sRef = 0; % not considered since a PHASE_DOXY is transmitted
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, sRef, ...
      g_decGl_doxy_201_202_202_d0, ...
      g_decGl_doxy_201_202_202_d1, ...
      g_decGl_doxy_201_202_202_d2, ...
      g_decGl_doxy_201_202_202_d3, ...
      g_decGl_doxy_201_202_202_sPreset, ...
      g_decGl_doxy_201_202_202_b0, ...
      g_decGl_doxy_201_202_202_b1, ...
      g_decGl_doxy_201_202_202_b2, ...
      g_decGl_doxy_201_202_202_b3, ...
      g_decGl_doxy_201_202_202_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decGl_doxy_201_202_202_pCoef2, ...
      g_decGl_doxy_201_202_202_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, longitude, latitude);
   rho = rho/1000;
   
   oxyValues = oxygenPresComp ./ rho;
   idNoNan = find(~isnan(oxyValues));

   o_doxyValues(idNoDef(idNoNan)) = oxyValues(idNoNan);   
end

return
