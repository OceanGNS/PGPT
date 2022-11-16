% ------------------------------------------------------------------------------
% Read the CTD data (from a ppc*a/b.eng file) and store it in a structure.
%
% SYNTAX :
%  [o_sgStructure] = gl_seaglider_ctd_eng_ascii2matlab( ...
%    a_sgStructure, a_ctdFilePathName, a_ctdDir, a_bOnlyFlag)
%
% INPUT PARAMETERS :
%   a_sgStructure     : seaglider input structure
%   a_ctdFilePathName : ppc*a/b.eng file path name
%   a_ctdDir          : direction of the CTD
%   a_bOnlyFlag       : only upcast CTD flag
%
% OUTPUT PARAMETERS :
%   o_sgStructure : seaglider output structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sgStructure] = gl_seaglider_ctd_eng_ascii2matlab( ...
   a_sgStructure, a_ctdFilePathName, a_ctdDir, a_bOnlyFlag)

% output data initialization
o_sgStructure = a_sgStructure;

% check inputs
if ~(exist(a_ctdFilePathName, 'file') == 2)
   fprintf('INFO: Input file not found: %s\n', a_ctdFilePathName);
   return
end

% open the file
fIdIn = fopen(a_ctdFilePathName, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_ctdFilePathName);
   return
end

% read the meta-data
castLabel = [];
if (a_ctdDir == 'a')
   castLabel = '%cast   1 ';
elseif (a_ctdDir == 'b')
   if (~a_bOnlyFlag)
      castLabel = '%cast   2 ';
   else
      castLabel = '%cast   1 ';
   end
end
castInfo = [];
columnsInfo = [];
line = fgetl(fIdIn);
while (~strncmp(line, '%data:', length('%data:')))
   line = fgetl(fIdIn);
   if (line == -1)
      break
   end
   if (strncmp(line, castLabel, length(castLabel)))
      castInfo = line(length(castLabel)+1:end);
   elseif (strncmp(line, '%columns: ', length('%columns: ')))
      columnsInfo = line(length('%columns: ')+1:end);
   end
end

% parse information
idFSamp = strfind(castInfo, 'samples');
dateStr = castInfo(1:idFSamp-2);
dateNum = datenum(dateStr, 'dd mmm yyyy HH:MM:SS');
janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
% JULD time
o_sgStructure.(['ppc' a_ctdDir]).time_start_juld = dateNum - janFirst1950InMatlab;
% EPOCH 1970 time
o_sgStructure.(['ppc' a_ctdDir]).time_start = (dateNum - epoch_offset)*86400;

idFSep = strfind(castInfo, ',');
index = castInfo(idFSamp+length('samples')+1:idFSep(1)-1);
o_sgStructure.(['ppc' a_ctdDir]).id_start = [];
o_sgStructure.(['ppc' a_ctdDir]).id_end = [];
[id, count, errmsg, nextIndex] = sscanf(index, '%d to %d');
if (isempty(errmsg) && (count == 2))
   o_sgStructure.(['ppc' a_ctdDir]).id_start = id(1);
   o_sgStructure.(['ppc' a_ctdDir]).id_end = id(2);
end

period = castInfo(idFSep(1)+2:idFSep(2)-1);
o_sgStructure.(['ppc' a_ctdDir]).int = [];
[id, count, errmsg, nextIndex] = sscanf(period, 'int = %d');
if (isempty(errmsg) && (count == 1))
   o_sgStructure.(['ppc' a_ctdDir]).int = id(1);
end

idFSep = [0 strfind(columnsInfo, ',') length(columnsInfo)+1];
colName = [];
o_sgStructure.(['ppc' a_ctdDir]).data = [];
for id = 1:length(idFSep)-1
   columnName = columnsInfo(idFSep(id)+1:idFSep(id+1)-1);
   columnName(strfind(columnName, '.')) = '_';
   colName{end+1} = columnName;
   o_sgStructure.(['ppc' a_ctdDir]).data.(columnName) = [];
end

% read the data
nbCol = length(colName);
while (1)
   line = fgetl(fIdIn);
   if (line == -1)
      break
   end
   data = sscanf(line, '%g');
   if (length(data) == nbCol)
      for id = 1:nbCol
         o_sgStructure.(['ppc' a_ctdDir]).data.(colName{id})(end+1) = data(id);
      end
   end
end

% compute measurement dates
nbMeas = length(o_sgStructure.(['ppc' a_ctdDir]).data.(colName{1}));
intInSeconds = o_sgStructure.(['ppc' a_ctdDir]).int;
firstTime = o_sgStructure.(['ppc' a_ctdDir]).time_start;
lastTime = firstTime + (nbMeas-1)*intInSeconds;
times = firstTime:intInSeconds:lastTime;
o_sgStructure.(['ppc' a_ctdDir]).data.time = times;
janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
o_sgStructure.(['ppc' a_ctdDir]).data.juld = times/86400 + epoch_offset - janFirst1950InMatlab;

fclose(fIdIn);

return
