% ------------------------------------------------------------------------------
% Compute CDOM from FLUORESCENCE_CDOM.
%
% SYNTAX :
%  [o_cdomValues] = gl_compute_CDOM(a_fluorescenceCdomValues)
%
% INPUT PARAMETERS :
%   a_fluorescenceCdomValues : input FLUORESCENCE_CDOM data
%
% OUTPUT PARAMETERS :
%   o_cdomValues : output CDOM data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cdomValues] = gl_compute_CDOM(a_fluorescenceCdomValues)

% output parameters initialization
o_cdomValues = nan(size(a_fluorescenceCdomValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;


% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: CDOM calibration information is missing => CDOM set to FillValue\n');
   return
else
   calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
   if ((isfield(calibInfo, 'ScaleFactCDOM')) && ...
         (isfield(calibInfo, 'DarkCountCDOM')))
      scaleFactCDOM = double(calibInfo.ScaleFactCDOM);
      darkCountCDOM = double(calibInfo.DarkCountCDOM);
   else
      fprintf('WARNING: inconsistent CDOM calibration information => CDOM set to FillValue\n');
      return
   end
end

% compute output data
idNoDef = find(~isnan(a_fluorescenceCdomValues));
o_cdomValues(idNoDef) = (a_fluorescenceCdomValues(idNoDef) - darkCountCDOM)*scaleFactCDOM;

return
