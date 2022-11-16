% ------------------------------------------------------------------------------
% Retrieve the list of test numbers from HEX code.
%
% SYNTAX :
%  [o_testNumList] = gl_retrieve_qctest_list(a_qcTestHex)
%
% INPUT PARAMETERS :
%   a_qcTestHex : HEX code
%
% OUTPUT PARAMETERS :
%   o_testNumList : list of test numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/01/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_testNumList] = gl_retrieve_qctest_list(a_qcTestHex)

% output parameters initialization
o_testNumList = '';


if (length(a_qcTestHex) ~= 16)
   fprintf('RTQC_ERROR: Unable to retrieve test list from HEX code => HEX code not updated\n');
   return
end

bitStr = repmat('0', 1, 64);
for id = 1:2:length(a_qcTestHex)
   bitStr(1+(id-1)*4:8+(id-1)*4) = dec2bin(hex2dec(a_qcTestHex(id:id+1)), 8);
end
testList = [];
for id = length(bitStr)-1:-1:1
   if (bitStr(id) == '1')
      testList = [testList length(bitStr)-id];
   end
end
o_testNumList = zeros(63, 1);
o_testNumList(testList) = 1;

return