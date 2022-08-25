% ------------------------------------------------------------------------------
% Read the eng data (from a p*.eng file) and store it in a structure.
%
% SYNTAX :
%  [o_sgStructure] = gl_seaglider_eng_ascii2matlab(a_engFilePathname)
%
% INPUT PARAMETERS :
%   a_engFilePathname : eng file path name
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
%   06/09/2015 - RNU - adapted from gl_seaglider_bpo_ascii2matlab
% ------------------------------------------------------------------------------
function [o_sgStructure] = gl_seaglider_eng_ascii2matlab(a_engFilePathname)

% output data initialization
o_sgStructure = [];

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_egoVarName;


% check inputs
if ~(exist(a_engFilePathname, 'file') == 2)
   fprintf('INFO: Log file not found: %s\n', a_engFilePathname);
   return
end

% open the eng file and intialize structures
fIdIn = fopen(a_engFilePathname, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_engFilePathname);
   return
end
o_sgStructure.eng.comment = {};
o_sgStructure.eng.basestation_version = {};

% read the processed science data file
gg = fgetl(fIdIn);
while (~strncmp('%data:', gg, 5))
   ggg = textscan(gg, '%s');
   gggg = ggg{1};
   
   if (strncmp('%start:', gggg{1}, 7)) % need to convert date to matlab day number
      o_sgStructure.eng.start = datenum([ ...
         1900 + str2double(gggg{4}), str2double(gggg{2}), str2double(gggg{3}), ...
         str2double(gggg{5}), str2double(gggg{6}), str2double(gggg{7})]);
   elseif (strncmp('%columns:', gggg{1}, 9))
      comma_idx = strfind(gggg{2}, ',');
      columns = {};
      for ii_comma = 1:length(comma_idx)+1
         if (ii_comma == 1)
            columns{ii_comma} = gggg{2}(1:comma_idx(ii_comma)-1);
         elseif (ii_comma == length(comma_idx)+1)
            columns{ii_comma} = gggg{2}(comma_idx(ii_comma-1)+1:end);
         else
            columns{ii_comma} = gggg{2}(comma_idx(ii_comma-1)+1:comma_idx(ii_comma)-1);
         end
      end
   elseif (strncmp('%comment:', gggg{1}, 9))
      o_sgStructure.eng.comment{end+1} = gg;
   elseif (strncmp('%basestation_version:', gggg{1}, 21))
      colon_idx = strfind(gggg{1}, ':');
      o_sgStructure.eng.basestation_version{end+1} = gg(colon_idx+2:end);
   else
      space_idx = strfind(gg, ' ');
      tvar = gg(2:space_idx-2);
      if (length(space_idx) == 1)
         o_sgStructure.eng.(tvar) = str2double(gg(space_idx+1:end));
      else
         o_sgStructure.eng.(tvar) = {gg(space_idx+1:end)}; % the entires with multiple values include strings too, not parsing fully in this version of code
      end
   end
   gg = fgetl(fIdIn);
end

% predeclare eng data fields
o_sgStructure.eng.data = [];
for ii_columnidx=1:length(columns)
   fieldName = columns{ii_columnidx};
   fieldName(strfind(fieldName, '.')) = '_';
   o_sgStructure.eng.data.(fieldName)= [];
end

% read the data
fields = fieldnames(o_sgStructure.eng.data);
while (~feof(fIdIn))
   gg=fgetl(fIdIn);
   data = sscanf(gg, '%g');
   if (length(data) == length(fields))
      for id = 1:length(fields)
         o_sgStructure.eng.data.(fields{id})(end+1) = data(id);
      end
   end
end
fclose(fIdIn);

% retrieve glider variable name for TIME
timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};

% compute times in Matlab time
o_sgStructure.eng.data.(timeGliderVarName) = ...
   repmat(o_sgStructure.eng.start, size(o_sgStructure.eng.data.(timeGliderVarName))) + ...
   datenum([ ...
   zeros(size(o_sgStructure.eng.data.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.eng.data.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.eng.data.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.eng.data.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.eng.data.(timeGliderVarName)))', ...
   o_sgStructure.eng.data.(timeGliderVarName)'])';

% convert times in EPOCH 1970 time
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
o_sgStructure.eng.data.(timeGliderVarName) = (o_sgStructure.eng.data.(timeGliderVarName) - epoch_offset)*86400;

% create JULD time
janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
o_sgStructure.eng.data.time_eng_juld = o_sgStructure.eng.data.(timeGliderVarName) - janFirst1950InMatlab;

% assign source file names
o_sgStructure.source = a_engFilePathname;

return
