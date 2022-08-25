% ------------------------------------------------------------------------------
% Set one (numerical) QC value to a set of existing ones.
%
% SYNTAX :
%  [o_qcValues] = gl_set_qc(a_qcValues, a_newQcValue)
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
function [o_qcValues] = gl_set_qc(a_qcValues, a_newQcValue)

o_qcValues = a_qcValues;


if (~isempty(a_qcValues))
   o_qcValues = max(a_qcValues, repmat(a_newQcValue, size(a_qcValues)));
end

% % QC flag values (numerical)
% global g_decGl_qcDef;
% global g_decGl_qcNoQc;
% global g_decGl_qcGood;
% global g_decGl_qcProbablyGood;
% global g_decGl_qcCorrectable;
% global g_decGl_qcBad;
% 
% if (~isempty(a_qcValues))
%    id1 = find(ismember(a_qcValues, [g_decGl_qcDef g_decGl_qcNoQc g_decGl_qcGood g_decGl_qcProbablyGood g_decGl_qcCorrectable g_decGl_qcBad]));
%    o_qcValues(id1) = max(a_qcValues(id1), repmat(a_newQcValue, size(id1)));
%    id2 = setdiff(1:length(a_qcValues), id1);
%    o_qcValues(id2) = repmat(a_newQcValue, size(id2));
% end

return
