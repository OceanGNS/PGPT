% ------------------------------------------------------------------------------
% Find and sort glider input data files according to their names.
%
% SYNTAX :
%  [o_fileNameList, o_fileNumList, o_fileBaseNameList] = ...
%    gl_get_input_data_file_list(a_dataDirPathName, a_fileExt)
%
% INPUT PARAMETERS :
%   a_dataDirPathName : data directory
%   a_dataFileExt     : data file extension
%
% OUTPUT PARAMETERS :
%   o_fileList    : file information list
%   o_fileNumList : file number list
%   o_fileBaseNameList : base file name list
%
% EXAMPLES : 
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileNameList, o_fileNumList, o_fileBaseNameList] = ...
   gl_get_input_data_file_list(a_dataDirPathName, a_dataFileExt)

o_fileNameList = [];
o_fileNumList = [];
o_fileBaseNameList = [];

% type of the glider to process
global g_decGl_gliderType;


fileBaseNameTot = [];
if (strcmpi(g_decGl_gliderType, 'seaglider'))
   
   fileInfo = dir([a_dataDirPathName ['*.' a_dataFileExt]]);
   fileNumTot = zeros(length(fileInfo), 1);
   for idFile = 1:length(fileInfo)
      dataInputFile = fileInfo(idFile).name;
      [id, count, errmsg, nextIndex] = sscanf(dataInputFile, ['p%d.' a_dataFileExt]);
      if (isempty(errmsg))
         fileNumTot(idFile) = id(1);
      end
   end
   
elseif (strcmpi(g_decGl_gliderType, 'slocum'))
   
   fileInfo = dir([a_dataDirPathName '*.m']);
   fileNum = zeros(length(fileInfo), 4);
   for idFile = 1:length(fileInfo)
      dataInputFile = fileInfo(idFile).name;
      idU = strfind(dataInputFile, '_');
      [id, count, errmsg, nextIndex] = sscanf(dataInputFile(idU(1)+1:end), '%d_%d_%d_%d_sbd.m');
      if (isempty(errmsg) && (count == 4))
         fileNum(idFile, :) = id';
      end
   end
   
   maxVal = max(fileNum, [], 1);
   fact4 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))))]);
   fact3 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))) + ...
      length(num2str(maxVal(3))))]);
   fact2 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))) + ...
      length(num2str(maxVal(3))) + ...
      length(num2str(maxVal(2))))]);
   fileNumTot = fileNum(:, 1)*fact2 + fileNum(:, 2)*fact3 + ...
      fileNum(:, 3)*fact4 + fileNum(:, 4);
   
elseif (strcmpi(g_decGl_gliderType, 'seaexplorer'))
   
   fileList1 = dir([a_dataDirPathName '*.gli.*.gz']);
   fileList2 = dir([a_dataDirPathName '*.pl*.*.gz']);
   if (~isempty(fileList1) || ~isempty(fileList2))
      
      fileInfo = fileList1;
      fileBaseNameTot = [];
      fileNumTot = [];
      for idFile = 1:length(fileList1)
         dataInputFile = fileList1(idFile).name;
         dataInputFile = regexprep(dataInputFile, '.gli.sub.', '.gli.');
         idPattern = strfind(dataInputFile, '.gli.');
         fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
         fileNumTot(end+1) = str2num(dataInputFile(idPattern+5:end-3));
      end
      
      fileInfo = [fileInfo; fileList2];
      for idFile = 1:length(fileList2)
         dataInputFile = fileList2(idFile).name;
         dataInputFile = regexprep(dataInputFile, '.pld1.sub.', '.pld1.');
         idPattern = strfind(dataInputFile, '.pl1.');
         if (~isempty(idPattern))
            fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
            fileNumTot(end+1) = str2num(dataInputFile(idPattern+5:end-3));
         else
            idPattern = strfind(dataInputFile, '.pld1.');
            fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
            fileNumTot(end+1) = str2num(dataInputFile(idPattern+6:end-3));
         end
      end
   else
      
      fileList1 = dir([a_dataDirPathName '*.gli.*']);
      fileList2 = dir([a_dataDirPathName '*.pl*.*']);
      
      fileInfo = fileList1;
      fileNumTot = [];
      for idFile = 1:length(fileList1)
         dataInputFile = fileList1(idFile).name;
         dataInputFile = regexprep(dataInputFile, '.gli.sub.', '.gli.');
         idPattern = strfind(dataInputFile, '.gli.');
         fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
         fileNumTot(end+1) = str2num(dataInputFile(idPattern+5:end));
      end
      
      fileInfo = [fileInfo; fileList2];
      for idFile = 1:length(fileList2)
         dataInputFile = fileList2(idFile).name;
         dataInputFile = regexprep(dataInputFile, '.pld1.sub.', '.pld1.');
         idPattern = strfind(dataInputFile, '.pl1.');
         if (~isempty(idPattern))
            fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
            fileNumTot(end+1) = str2num(dataInputFile(idPattern+5:end));
         else
            idPattern = strfind(dataInputFile, '.pld1.');
            fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
            fileNumTot(end+1) = str2num(dataInputFile(idPattern+6:end));
         end
      end
   end
end

% sort the files
[o_fileNumList, idSorted] = sort(fileNumTot);
o_fileNameList = fileInfo(idSorted);
if (~isempty(fileBaseNameTot))
   o_fileBaseNameList = fileBaseNameTot(idSorted);
end

return
