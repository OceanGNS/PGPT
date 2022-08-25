% ------------------------------------------------------------------------------
% Find and sort seaexplorer input data files according to their names.
%
% SYNTAX :
%  [o_fileNameList, o_fileNumList, o_fileBaseNameList] = ...
%    gl_get_input_data_file_list_seaexplorer(a_dataDirPathName)
%
% INPUT PARAMETERS :
%   a_dataDirPathName : data directory
%
% OUTPUT PARAMETERS :
%   o_fileList         : file information list
%   o_fileNumList      : file number list
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
   gl_get_input_data_file_list_seaexplorer(a_dataDirPathName)

o_fileNameList = [];
o_fileNumList = [];
o_fileBaseNameList = [];

% flag for HR data
global g_decGl_hrDataFlag;


fileBaseNameTot = [];
fileNumTot = [];

fileList1 = dir([a_dataDirPathName '*.gli.*.gz']);
fileList2 = dir([a_dataDirPathName '*.pl*.*.gz']);
if (~isempty(fileList1) || ~isempty(fileList2))

   fileInfo = fileList1;
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

   fileList1 = dir([a_dataDirPathName '*.pld*.raw.*']);
   if (~isempty(fileList1))

      fileInfo = fileList1;
      for idFile = 1:length(fileList1)
         dataInputFile = fileList1(idFile).name;
         dataInputFile = regexprep(dataInputFile, '.pld1.raw.', '.pld1.');
         idPattern = strfind(dataInputFile, '.pld1.');
         fileBaseNameTot{end+1} = dataInputFile(1:idPattern-1);
         fileNumTot(end+1) = str2num(dataInputFile(idPattern+6:end));
      end
      g_decGl_hrDataFlag = 1;
      
   else

      fileList1 = dir([a_dataDirPathName '*.gli.*']);
      fileList2 = dir([a_dataDirPathName '*.pl*.*']);
      if (~isempty(fileList1) || ~isempty(fileList2))

         fileInfo = fileList1;
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
end

% sort the files
[~, idSorted] = sort(fileNumTot);
o_fileNameList = fileInfo(idSorted);
o_fileNumList = fileNumTot(idSorted);
o_fileBaseNameList = fileBaseNameTot(idSorted);

return
