% ------------------------------------------------------------------------------
% Read Slocum data (and associated description columns) in a dedicated
% structure.
%
% SYNTAX :
%  [o_dataStruct] = gl_slocum_read_data(a_mFileNameIn)
%
% INPUT PARAMETERS :
%   a_mFileNameIn    : name of the .m file from a yo
%
% OUTPUT PARAMETERS :
%   o_dataStruct : output structure with Slocum data and associated description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = gl_slocum_read_data(a_mFileNameIn)

% output parameter initialization
o_dataStruct.data = [];


% open the input file and read the data description
fId = fopen(a_mFileNameIn, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_mFileNameIn);
   return
end

globalVarList = [];
dataFileName = [];
while (1)
   line = fgetl(fId);
   
   if (line == -1)
      break
   end
   
   if (any(strfind(line, 'global')))
      globalVarList{end+1} = strtrim(regexprep(line, 'global', ''));
   elseif (any(strfind(line, '=')))
      idFEq = strfind(line, '=');
      varName = strtrim(line(1:idFEq(1)-1));
      if (any(strcmp(varName, globalVarList)))
         idFEnd = strfind(line, ';');
         varNum = strtrim(line(idFEq(1)+1:idFEnd(1)-1));
         if (~any(~ismember(varNum, 48:57)))
            o_dataStruct.(varName) = str2double(varNum);
         end
      end
   elseif (any(strfind(line, 'load(''')))
      idFStart = strfind(line, 'load(''');
      idFEnd = strfind(line, ''')');
      dataFileName = line(idFStart+length('load('''):idFEnd-1);
   end
end

fclose(fId);

% load the associated data file
if (~isempty(dataFileName))
   [pathstr, ~, ~] = fileparts(a_mFileNameIn);
   dataFilePathName = [pathstr '/' dataFileName];
   if (exist(dataFilePathName, 'file') == 2)
      o_dataStruct.data = load(dataFilePathName);
   end
end

return
