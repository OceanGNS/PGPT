% ------------------------------------------------------------------------------
% Reads the seaglider bpo file
%
% SYNTAX :
%  [o_sgStructure] = gl_seaglider_bpo_ascii2matlab(a_bpoFilePathname)
%
% INPUT PARAMETERS :
%   a_bpoFilePathname : bpo file path name
%
% OUTPUT PARAMETERS :
%   o_sgStructure : seaglider output structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Justin Buck (BODC)(juck@bodc.ac.uk)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/07/2013 - BUCK - creation
%   06/04/2013 - RNU - updated
% ------------------------------------------------------------------------------
function [o_sgStructure] = gl_seaglider_bpo_ascii2matlab(a_bpoFilePathname)

% output data initialization
o_sgStructure = [];

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_egoVarName;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;

% QC flag values
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;


% check inputs
if ~(exist(a_bpoFilePathname, 'file') == 2)
   fprintf('INFO: File not found: %s\n', a_bpoFilePathname);
   return
end

% open the bpo file and intialize structures
fIdIn = fopen(a_bpoFilePathname, 'r');
if (fIdIn == -1)
   fprintf('ERROR: While openning file : %s\n', a_bpoFilePathname);
   return
end
o_sgStructure.bpo.comment = {};
o_sgStructure.bpo.basestation_version = {};

% read the processed science data file
gg = fgetl(fIdIn);
while (~strncmp('%data:', gg, 5))
   ggg = textscan(gg, '%s');
   gggg = ggg{1};
   
   if (strncmp('%start:', gggg{1}, 7)) % need to convert date to matlab day number
      o_sgStructure.bpo.start = datenum([ ...
         1900 + str2double(gggg{4}), str2double(gggg{2}), str2double(gggg{3}), ...
         str2double(gggg{5}), str2double(gggg{6}), str2double(gggg{7})]);
   elseif (strncmp('%columns:', gggg{1}, 9))
      comma_idx = strfind(gggg{1}, ',');
      colon_idx = strfind(gggg{1}, ':');
      columns = {};
      for ii_comma = 1:length(comma_idx)+1
         if (ii_comma == 1)
            columns{ii_comma} = gggg{1}(colon_idx+1:comma_idx(ii_comma)-1);
         elseif (ii_comma == length(comma_idx)+1)
            columns{ii_comma} = gggg{1}(comma_idx(ii_comma-1)+1:end);
         else
            columns{ii_comma} = gggg{1}(comma_idx(ii_comma-1)+1:comma_idx(ii_comma)-1);
         end
      end
   elseif (strncmp('%comment:', gggg{1}, 9))
      o_sgStructure.bpo.comment{end+1} = gg;
   elseif (strncmp('%basestation_version:', gggg{1}, 21))
      colon_idx = strfind(gggg{1}, ':');
      o_sgStructure.bpo.basestation_version{end+1} = gg(colon_idx+2:end);
   else
      space_idx = strfind(gg, ' ');
      tvar = gg(2:space_idx-2);
      if (length(space_idx) == 1)
         o_sgStructure.bpo.(tvar) = str2double(gg(space_idx+1:end));
      else
         o_sgStructure.bpo.(tvar) = {gg(space_idx+1:end)}; % the entires with multiple values include strings too, not parsing fully in this version of code
      end
   end
   gg = fgetl(fIdIn);
end

% predeclare bpo data fields
for ii_columnidx = 1:length(columns)
   o_sgStructure.bpo.(columns{ii_columnidx}) = [];
end

% read the data
while (~feof(fIdIn))
   gg = fgetl(fIdIn);
   comma_idx = strfind(gg, ',');
   for ii_columnidx = 1:length(columns)
      if (ii_columnidx == 1)
         if (strncmp('NaN', gg(1:comma_idx(ii_columnidx)-1), 3))
            o_sgStructure.bpo.(columns{ii_columnidx})(end+1) = NaN;
         else
            o_sgStructure.bpo.(columns{ii_columnidx})(end+1) = ...
               str2double(gg(1:comma_idx(ii_columnidx)-1));
         end
      elseif (ii_columnidx == length(comma_idx)+1)
         if (strncmp('NaN', gg(comma_idx(ii_columnidx-1)+1:end), 3))
            o_sgStructure.bpo.(columns{ii_columnidx})(end+1) = NaN;
         else
            o_sgStructure.bpo.(columns{ii_columnidx})(end+1) = ...
               str2double(gg(comma_idx(ii_columnidx-1)+1:end));
         end
      else
         if (strncmp('NaN', gg(comma_idx(ii_columnidx-1)+1:comma_idx(ii_columnidx)-1), 3))
            o_sgStructure.bpo.(columns{ii_columnidx})(end+1) = NaN;
         else
            o_sgStructure.bpo.(columns{ii_columnidx})(end+1) = ...
               str2double(gg(comma_idx(ii_columnidx-1)+1:comma_idx(ii_columnidx)-1));
         end
      end
   end
end
fclose(fIdIn);

% retrieve glider variable name for TIME
timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};

% delete timely duplicated measurements
if (~isempty(find(diff(o_sgStructure.bpo.(timeGliderVarName)) == 0, 1)))
   idDup = find(diff(o_sgStructure.bpo.(timeGliderVarName)) == 0);
   o_sgStructure.bpo.(timeGliderVarName)(idDup) = [];
   for idC = 1:length(columns)
      o_sgStructure.bpo.(columns{idC})(idDup) = [];
   end
   fprintf('WARNING: Duplicated times in %s => deleted data: ', a_bpoFilePathname);
   fprintf('#%d ', idDup);
   fprintf('\n');
end

% compute times in Matlab time
o_sgStructure.bpo.(timeGliderVarName) = ...
   repmat(o_sgStructure.bpo.start, size(o_sgStructure.bpo.(timeGliderVarName))) + ...
   datenum([ ...
   zeros(size(o_sgStructure.bpo.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.bpo.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.bpo.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.bpo.(timeGliderVarName)))', ...
   zeros(size(o_sgStructure.bpo.(timeGliderVarName)))', ...
   o_sgStructure.bpo.(timeGliderVarName)'])';

% convert times in EPOCH 1970 time
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
o_sgStructure.bpo.(timeGliderVarName) = (o_sgStructure.bpo.(timeGliderVarName) - epoch_offset)*86400;

% clean measurements (delete timestamps when all measurements = Nan)
excludedEgoVarList = [{'TIME_GPS'} {'LATITUDE_GPS'} {'LONGITUDE_GPS'}];
dataAll = [];
for idV = 1:length(g_decGl_egoVarName)
   if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
         ~strcmp(g_decGl_egoVarName{idV}, 'TIME') && ...
         ~isempty(g_decGl_gliderVarName{idV}))
      if (isfield(o_sgStructure.bpo, g_decGl_gliderVarName{idV}))
         dataAll = [dataAll; o_sgStructure.bpo.(g_decGl_gliderVarName{idV})];
      end
   end
end
idDel = find(sum(isnan(dataAll), 1) == size(dataAll, 1));
if (~isempty(idDel))
   for idV = 1:length(g_decGl_egoVarName)
      if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
            ~isempty(g_decGl_gliderVarName{idV}))
         if (isfield(o_sgStructure.bpo, g_decGl_gliderVarName{idV}))
            o_sgStructure.bpo.(g_decGl_gliderVarName{idV})(idDel) = [];
         end
      end
   end
end

% interpolate PRES measurements for all timestamps => needed for PHASE processing

% find the glider variable names for TIME, PRES and PRES
timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};
presGliderVarName = [];
idF = find(strcmp(g_decGl_egoVarName, 'PRES'));
if (~isempty(idF))
   presGliderVarName = g_decGl_gliderVarName{idF};
end
presQcGliderVarName = [];
idF = find(strcmp(g_decGl_egoVarName, 'PRES_QC'));
if (~isempty(idF))
   presQcGliderVarName = g_decGl_gliderVarName{idF};
end

% convert and interpolate PRES measurements
if (~isempty(timeGliderVarName) && ~isempty(presGliderVarName))
   
   time = [];
   pres = [];
   if (isfield(o_sgStructure.bpo, timeGliderVarName))
      time = o_sgStructure.bpo.(timeGliderVarName);
   end
   if (isfield(o_sgStructure.bpo, presGliderVarName))
      pres = o_sgStructure.bpo.(presGliderVarName);
   end
   
   if (~isempty(time) && ~isempty(pres))
      
      pres_qc = zeros(1, length(pres));
      
      idNan = find(isnan(pres));
      if (~isempty(idNan))
         idNotNan = setdiff(1:length(pres), idNan);
         if (length(idNotNan) > 1)
            pres(idNan) = interp1q(time(idNotNan)', pres(idNotNan)', time(idNan)')';
            pres_qc(idNan) = g_decGl_qcInterpolated;
            pres_qc(find(isnan(pres))) = g_decGl_qcMissing;
         end
      end
      
      o_sgStructure.bpo.(presGliderVarName) = pres;
      if (~isempty(presQcGliderVarName))
         o_sgStructure.bpo.(presQcGliderVarName) = pres_QC;
      else
         o_sgStructure.bpo.PRES_QC = pres_qc;
         g_decGl_directEgoVarName{end+1} = 'vars_time.PRES_QC';
      end
   end
end

% create JULD time
janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
o_sgStructure.bpo.time_bpo_juld = o_sgStructure.bpo.(timeGliderVarName) - janFirst1950InMatlab;

% assign source file names
o_sgStructure.source = a_bpoFilePathname;

return
