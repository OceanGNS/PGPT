% ------------------------------------------------------------------------------
% Compute CHLA from FLUORESCENCE_CHLA.
%
% SYNTAX :
%  [o_chlaValues] = gl_compute_CHLA(a_fluorescenceChlaValues)
%
% INPUT PARAMETERS :
%   a_fluorescenceChlaValues : input FLUORESCENCE_CHLA data
%
% OUTPUT PARAMETERS :
%   o_chlaValues : output CHLA data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_chlaValues] = gl_compute_CHLA(a_fluorescenceChlaValues)

% output parameters initialization
o_chlaValues = nan(size(a_fluorescenceChlaValues));

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;


% get calibration information
if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
   fprintf('WARNING: CHLA calibration information is missing => CHLA set to FillValue\n');
   return
else
   calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
   if ((isfield(calibInfo, 'ScaleFactCHLA')) && ...
         (isfield(calibInfo, 'DarkCountCHLA')))
      scaleFactCHLA = double(calibInfo.ScaleFactCHLA);
      darkCountCHLA = double(calibInfo.DarkCountCHLA);
   else
      fprintf('WARNING: inconsistent CHLA calibration information => CHLA set to FillValue\n');
      return
   end
end

% compute output data
idNoDef = find(~isnan(a_fluorescenceChlaValues));
o_chlaValues(idNoDef) = (a_fluorescenceChlaValues(idNoDef) - darkCountCHLA)*scaleFactCHLA;

return
