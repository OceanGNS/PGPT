% ------------------------------------------------------------------------------
% Find and sort seaglider input data files according to their names.
%
% SYNTAX :
%  [o_fileNameList, o_fileNumList] = ...
%    gl_get_input_data_file_list_seaglider(a_dataDirPathName, a_dataFileExt)
%
% INPUT PARAMETERS :
%   a_dataDirPathName : data directory
%   a_dataFileExt     : data file extension
%
% OUTPUT PARAMETERS :
%   o_fileList    : file information list
%   o_fileNumList : file number list
%
% EXAMPLES : 
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileNameList, o_fileNumList] = ...
   gl_get_input_data_file_list_seaglider(a_dataDirPathName, a_dataFileExt)

o_fileNameList = [];
o_fileNumList = [];

fileInfo = dir([a_dataDirPathName ['*.' a_dataFileExt]]);
fileNumTot = zeros(length(fileInfo), 1);
for idFile = 1:length(fileInfo)
   dataInputFile = fileInfo(idFile).name;
   [id, count, errmsg, nextIndex] = sscanf(dataInputFile, ['p%d.' a_dataFileExt]);
   if (isempty(errmsg))
      fileNumTot(idFile) = id(1);
   end
end
   
% sort the files
[~, idSorted] = sort(fileNumTot);
o_fileNameList = fileInfo(idSorted);
o_fileNumList = fileNumTot(idSorted);

return
