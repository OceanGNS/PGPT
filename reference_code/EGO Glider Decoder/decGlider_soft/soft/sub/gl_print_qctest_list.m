% ------------------------------------------------------------------------------
% Print test list from HEX code.
%
% SYNTAX :
%  gl_print_qctest_list(a_qcTestHex)
%
% INPUT PARAMETERS :
%   a_qcTestHex : HEX code
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/01/2021 - RNU - creation
% ------------------------------------------------------------------------------
function gl_print_qctest_list(a_qcTestHex)

bitStr = repmat('0', 1, 64);
for id = 1:2:length(a_qcTestHex)
   bitStr(1+(id-1)*4:8+(id-1)*4) = dec2bin(hex2dec(a_qcTestHex(id:id+1)), 8);
end
fprintf('QC test (hexa): ''%s''\n', a_qcTestHex);
testList = [];
for id = length(bitStr)-1:-1:1
   if (bitStr(id) == '1')
      testList = [testList length(bitStr)-id];
   end
end
testListStr = sprintf('%d ', testList);
fprintf('QC test (num): %s\n', testListStr);

return