% ------------------------------------------------------------------------------
% Set one (character) QC value to a set of existing ones.
%
% SYNTAX :
%  [o_qcValues] = gl_set_qc_str(a_qcValues, a_newQcValue)
%
% INPUT PARAMETERS :
%   a_qcValues   : existing set on QC values
%   a_newQcValue : QC value
%
% OUTPUT PARAMETERS :
%   o_qcValues : resulting set on QC values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_qcValues] = gl_set_qc_str(a_qcValues, a_newQcValue)

o_qcValues = a_qcValues;

% QC flag values (char)
global g_decGl_qcStrDef;
global g_decGl_qcStrNoQc;
global g_decGl_qcStrGood;
global g_decGl_qcStrProbablyGood;
global g_decGl_qcStrCorrectable;
global g_decGl_qcStrBad;


if (~isempty(a_qcValues))
   id1 = find(ismember(a_qcValues, [g_decGl_qcStrDef g_decGl_qcStrNoQc g_decGl_qcStrGood g_decGl_qcStrProbablyGood g_decGl_qcStrCorrectable g_decGl_qcStrBad]));
   o_qcValues(id1) = char(max(a_qcValues(id1), repmat(a_newQcValue, size(id1))));
   id2 = setdiff(1:length(a_qcValues), id1);
   o_qcValues(id2) = repmat(a_newQcValue, size(id2));
end

return
