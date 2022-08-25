% ------------------------------------------------------------------------------
% Compute BBP* from BETA_BACKSCATTERING*.
%
% SYNTAX :
%  [o_bbpValues] = gl_compute_BBP(a_timeValues, ...
%    a_ctdValues, a_betaBackscatteringValues, a_wavelength)
%
% INPUT PARAMETERS :
%   a_timeValues               : time measurements
%   a_ctdValues                : CTD measurements
%   a_betaBackscatteringValues : BETA_BACKSCATTERING* measurements
%   a_wavelength               : measurements wavelength (in nm)
%
% OUTPUT PARAMETERS :
%   o_bbpValues : output BBP* data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bbpValues] = gl_compute_BBP(a_timeValues, ...
   a_ctdValues, a_betaBackscatteringValues, a_wavelength)

% output parameters initialization
o_bbpValues = nan(size(a_betaBackscatteringValues));


betaBackscatteringNoDef = find(~isnan(a_betaBackscatteringValues));
if (~isempty(betaBackscatteringNoDef))
   
   betaBackscatteringTime = a_timeValues(betaBackscatteringNoDef);
   
   % interpolate the CTD data at the time of the BBP measurements
   ctdIntData = gl_compute_interpolated_CTD_measurements(a_timeValues, ...
      a_ctdValues, betaBackscatteringTime);
   if (~isempty(ctdIntData))
      
      % compute BBP
      switch (a_wavelength)
         case 470
            o_bbpValues(betaBackscatteringNoDef) = gl_compute_BBP470_values(a_betaBackscatteringValues(betaBackscatteringNoDef), ...
               ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), a_wavelength);
         case 700
            o_bbpValues(betaBackscatteringNoDef) = gl_compute_BBP700_values(a_betaBackscatteringValues(betaBackscatteringNoDef), ...
               ctdIntData(:, 1), ctdIntData(:, 2), ctdIntData(:, 3), a_wavelength);
         otherwise
            fprintf('WARNING: BBP%d processing not implemented yet => BBP%d set to FillValue\n', ...
               a_wavelength, a_wavelength);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute BBP* from BETA_BACKSCATTERING*.
%
% SYNTAX :
%  [o_bbpValues] = gl_compute_BBP700_values(a_betaBackscatteringValues, ...
%    a_presValues, a_tempValues, a_psalValues, a_wavelength)
%
% INPUT PARAMETERS :
%   a_betaBackscatteringValues : BETA_BACKSCATTERING* measurements
%   a_presValues               : PRES measurements
%   a_tempValues               : TEMP measurements
%   a_psalValues               : PSAL measurements
%   a_wavelength               : measurements wavelength (in nm)
%
% OUTPUT PARAMETERS :
%   o_bbpValues : output BBP* data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bbpValues] = gl_compute_BBP700_values(a_betaBackscatteringValues, ...
   a_presValues, a_tempValues, a_psalValues, a_wavelength)

% output parameters initialization
o_bbpValues = nan(size(a_betaBackscatteringValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;


if (isempty(a_betaBackscatteringValues))
   return
end

% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: BBP700 calibration information is missing => BBP700 set to FillValue\n');
   return
else
   calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
   if ((isfield(calibInfo, 'ScaleFactBBP700')) && ...
         (isfield(calibInfo, 'DarkCountBBP700')) && ...
         (isfield(calibInfo, 'KhiCoefBBP700')) && ...
         (isfield(calibInfo, 'MeasAngleBBP700')))
      scaleFactBBP700 = double(calibInfo.ScaleFactBBP700);
      darkCountBBP700 = double(calibInfo.DarkCountBBP700);
      khiCoefBBP700 = double(calibInfo.KhiCoefBBP700);
      measAngleBBP700 = double(calibInfo.MeasAngleBBP700);
   else
      fprintf('WARNING: inconsistent BBP700 calibration information => BBP700 set to FillValue\n');
      return
   end
end

idDef = find( ...
   isnan(a_betaBackscatteringValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues));
idNoDef = setdiff(1:length(o_bbpValues), idDef);

if (~isempty(idNoDef))
   
   [betasw, ~, ~] = betasw_ZHH2009(a_wavelength, a_tempValues, measAngleBBP700, a_psalValues);
   
   % compute output data
   o_bbpValues(idNoDef) = 2*pi*khiCoefBBP700* ...
      ((a_betaBackscatteringValues(idNoDef) - darkCountBBP700)*scaleFactBBP700 - betasw(idNoDef));
end

return

% ------------------------------------------------------------------------------
% Compute BBP* from BETA_BACKSCATTERING*.
%
% SYNTAX :
%  [o_bbpValues] = gl_compute_BBP470_values(a_betaBackscatteringValues, ...
%    a_presValues, a_tempValues, a_psalValues, a_wavelength)
%
% INPUT PARAMETERS :
%   a_betaBackscatteringValues : BETA_BACKSCATTERING* measurements
%   a_presValues               : PRES measurements
%   a_tempValues               : TEMP measurements
%   a_psalValues               : PSAL measurements
%   a_wavelength               : measurements wavelength (in nm)
%
% OUTPUT PARAMETERS :
%   o_bbpValues : output BBP* data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/30/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bbpValues] = gl_compute_BBP470_values(a_betaBackscatteringValues, ...
   a_presValues, a_tempValues, a_psalValues, a_wavelength)

% output parameters initialization
o_bbpValues = nan(size(a_betaBackscatteringValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;


if (isempty(a_betaBackscatteringValues))
   return
end

% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: BBP470 calibration information is missing => BBP470 set to FillValue\n');
   return
else
   calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
   if ((isfield(calibInfo, 'ScaleFactBBP470')) && ...
         (isfield(calibInfo, 'DarkCountBBP470')) && ...
         (isfield(calibInfo, 'KhiCoefBBP470')) && ...
         (isfield(calibInfo, 'MeasAngleBBP470')))
      scaleFactBBP470 = double(calibInfo.ScaleFactBBP470);
      darkCountBBP470 = double(calibInfo.DarkCountBBP470);
      khiCoefBBP470 = double(calibInfo.KhiCoefBBP470);
      measAngleBBP470 = double(calibInfo.MeasAngleBBP470);
   else
      fprintf('WARNING: inconsistent BBP470 calibration information => BBP470 set to FillValue\n');
      return
   end
end

idDef = find( ...
   isnan(a_betaBackscatteringValues) | ...
   isnan(a_presValues) | ...
   isnan(a_tempValues) | ...
   isnan(a_psalValues));
idNoDef = setdiff(1:length(o_bbpValues), idDef);

if (~isempty(idNoDef))
   
   [betasw, ~, ~] = betasw_ZHH2009(a_wavelength, a_tempValues, measAngleBBP470, a_psalValues);
   
   % compute output data
   o_bbpValues(idNoDef) = 2*pi*khiCoefBBP470* ...
      ((a_betaBackscatteringValues(idNoDef) - darkCountBBP470)*scaleFactBBP470 - betasw(idNoDef));
end

return
