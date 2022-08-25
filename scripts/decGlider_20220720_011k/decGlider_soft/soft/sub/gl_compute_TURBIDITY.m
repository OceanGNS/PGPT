% ------------------------------------------------------------------------------
% Compute TURBIDITY from SIDE_SCATTERING_TURBIDITY.
%
% SYNTAX :
%  [o_turbidityValues] = gl_compute_TURBIDITY(a_sideScatteringTurbidityValues)
%
% INPUT PARAMETERS :
%   a_sideScatteringTurbidityValues : input SIDE_SCATTERING_TURBIDITY data
%
% OUTPUT PARAMETERS :
%   o_turbidityValues : output TURBIDITY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_turbidityValues] = gl_compute_TURBIDITY(a_sideScatteringTurbidityValues)

% output parameters initialization
o_turbidityValues = nan(size(a_sideScatteringTurbidityValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;


% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: TURBIDITY calibration information is missing => TURBIDITY set to FillValue\n');
   return
else
   calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
   if ((isfield(calibInfo, 'ScaleFactTURBIDITY')) && ...
         (isfield(calibInfo, 'DarkCountTURBIDITY')))
      scaleFactTURBIDITY = double(calibInfo.ScaleFactTURBIDITY);
      darkCountTURBIDITY = double(calibInfo.DarkCountTURBIDITY);
   else
      fprintf('WARNING: inconsistent TURBIDITY calibration information => TURBIDITY set to FillValue\n');
      return
   end
end

% compute output data
idNoDef = find(~isnan(a_sideScatteringTurbidityValues));
o_turbidityValues(idNoDef) = (a_sideScatteringTurbidityValues(idNoDef) - darkCountTURBIDITY)*scaleFactTURBIDITY;

return
