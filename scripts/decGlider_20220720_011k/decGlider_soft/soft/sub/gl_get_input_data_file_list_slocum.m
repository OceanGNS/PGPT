% ------------------------------------------------------------------------------
% Find and sort slocum input data files according to their names.
%
% SYNTAX :
%  [o_vectorFileNameList, o_sensorFileNameList] = ...
%    gl_get_input_data_file_list_slocum(a_dataDirPathName)
%
% INPUT PARAMETERS :
%   a_dataDirPathName : data directory
%
% OUTPUT PARAMETERS :
%   o_vectorFileNameList : vector file information list
%   o_sensorFileNameList : sensor file information list
%
% EXAMPLES : 
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/23/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_vectorFileNameList, o_sensorFileNameList] = ...
   gl_get_input_data_file_list_slocum(a_dataDirPathName)

o_vectorFileNameList = [];
o_sensorFileNameList = [];


fileList1 = dir([a_dataDirPathName '*sbd.m']);
fileList2 = dir([a_dataDirPathName '*tbd.m']);
if (~isempty(fileList1) && ~isempty(fileList2))

   fileNum1 = zeros(length(fileList1), 4);
   fileType1 = ones(length(fileList1), 1);
   for idFile = 1:length(fileList1)
      dataInputFile = fileList1(idFile).name;
      idU = strfind(dataInputFile, '_');
      [id, count, errmsg, nextIndex] = sscanf(dataInputFile(idU(1)+1:end), '%d_%d_%d_%d_sbd.m');
      if (isempty(errmsg) && (count == 4))
         fileNum1(idFile, :) = id';
      end
   end
   
   fileNum2 = zeros(length(fileList2), 4);
   fileType2 = ones(length(fileList2), 1)*2;
   for idFile = 1:length(fileList2)
      dataInputFile = fileList2(idFile).name;
      idU = strfind(dataInputFile, '_');
      [id, count, errmsg, nextIndex] = sscanf(dataInputFile(idU(1)+1:end), '%d_%d_%d_%d_tbd.m');
      if (isempty(errmsg) && (count == 4))
         fileNum2(idFile, :) = id';
      end
   end

   fileInfo = [fileList1; fileList2];
   fileNum = [fileNum1; fileNum2];
   fileType = [fileType1; fileType2];

   maxVal = max(fileNum, [], 1);
   fact4 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))))]);
   fact3 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))) + ...
      length(num2str(maxVal(3))))]);
   fact2 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))) + ...
      length(num2str(maxVal(3))) + ...
      length(num2str(maxVal(2))))]);
   fileNumTot = fileNum(:, 1)*fact2 + fileNum(:, 2)*fact3 + ...
      fileNum(:, 3)*fact4 + fileNum(:, 4);

   % sort the files
   [~, idSorted] = sort(fileNumTot);
   fileNumTot = fileNumTot(idSorted);
   fileInfo = fileInfo(idSorted);
   fileType = fileType(idSorted);
   uFileNum = unique(fileNumTot);
   o_vectorFileNameList = cell(length(uFileNum), 1);
   o_sensorFileNameList = cell(length(uFileNum), 1);
   for id = 1:length(uFileNum)
      o_vectorFileNameList{id} = fileInfo((fileNumTot == uFileNum(id)) & (fileType == 1));
      o_sensorFileNameList{id} = fileInfo((fileNumTot == uFileNum(id)) & (fileType == 2));
   end
   
else
   fileList1 = dir([a_dataDirPathName '*mbd.m']);
   fileList2 = dir([a_dataDirPathName '*nbd.m']);
   if (~isempty(fileList1) && ~isempty(fileList2))

      fileNum1 = zeros(length(fileList1), 4);
      fileType1 = ones(length(fileList1), 1);
      for idFile = 1:length(fileList1)
         dataInputFile = fileList1(idFile).name;
         idU = strfind(dataInputFile, '_');
         [id, count, errmsg, nextIndex] = sscanf(dataInputFile(idU(1)+1:end), '%d_%d_%d_%d_mbd.m');
         if (isempty(errmsg) && (count == 4))
            fileNum1(idFile, :) = id';
         end
      end

      fileNum2 = zeros(length(fileList2), 4);
      fileType2 = ones(length(fileList2), 1)*2;
      for idFile = 1:length(fileList2)
         dataInputFile = fileList2(idFile).name;
         idU = strfind(dataInputFile, '_');
         [id, count, errmsg, nextIndex] = sscanf(dataInputFile(idU(1)+1:end), '%d_%d_%d_%d_nbd.m');
         if (isempty(errmsg) && (count == 4))
            fileNum2(idFile, :) = id';
         end
      end

      fileInfo = [fileList1; fileList2];
      fileNum = [fileNum1; fileNum2];
      fileType = [fileType1; fileType2];

      maxVal = max(fileNum, [], 1);
      fact4 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))))]);
      fact3 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))) + ...
         length(num2str(maxVal(3))))]);
      fact2 = str2num(['1' repmat('0', 1, length(num2str(maxVal(4))) + ...
         length(num2str(maxVal(3))) + ...
         length(num2str(maxVal(2))))]);
      fileNumTot = fileNum(:, 1)*fact2 + fileNum(:, 2)*fact3 + ...
         fileNum(:, 3)*fact4 + fileNum(:, 4);

      % sort the files
      [~, idSorted] = sort(fileNumTot);
      fileNumTot = fileNumTot(idSorted);
      fileInfo = fileInfo(idSorted);
      fileType = fileType(idSorted);
      uFileNum = unique(fileNumTot);
      o_vectorFileNameList = cell(length(uFileNum), 1);
      o_sensorFileNameList = cell(length(uFileNum), 1);
      for id = 1:length(uFileNum)
         o_vectorFileNameList{id} = fileInfo((fileNumTot == uFileNum(id)) & (fileType == 1));
         o_sensorFileNameList{id} = fileInfo((fileNumTot == uFileNum(id)) & (fileType == 2));
      end

   else

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

      % sort the files
      [~, idSorted] = sort(fileNumTot);
      o_vectorFileNameList = fileInfo(idSorted);

   end
end

return
