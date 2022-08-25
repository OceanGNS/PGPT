% ------------------------------------------------------------------------------
% Merge eng data (coming from p*.eng and ppc*a/b.eng files)
%
% SYNTAX :
%  [o_sgStructure] = gl_seaglider_merge_eng_data(a_sgStructure)
%
% INPUT PARAMETERS :
%   a_sgStructure      : seaglider input structure
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
function [o_sgStructure] = gl_seaglider_merge_eng_data(a_sgStructure)

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


% retrieve glider variable name for TIME
timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};

% create the final output arrays (we should work in EPOCH time)
mergedTimes = a_sgStructure.eng.data.(timeGliderVarName);
if (isfield(a_sgStructure.ppca, 'data') && isfield(a_sgStructure.ppca.data, 'time'))
   mergedTimes = [mergedTimes a_sgStructure.ppca.data.time];
end
if (isfield(a_sgStructure.ppcb, 'data') && isfield(a_sgStructure.ppcb.data, 'time'))
   mergedTimes = [mergedTimes a_sgStructure.ppcb.data.time];
end
mergedTimes = sort(unique(mergedTimes));
nbMeas = length(mergedTimes);
a_sgStructure.eng.(timeGliderVarName) = mergedTimes;
janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);
a_sgStructure.eng.time_eng_juld = mergedTimes/86400 + epoch_offset - janFirst1950InMatlab;

% insert p*.eng measurements
finalFieldNames = [];
engTimes = a_sgStructure.eng.data.(timeGliderVarName);
engId = ones(1, length(engTimes))*-1;
for id = 1:length(engTimes)
   idF = find(engTimes(id) == mergedTimes, 1);
   engId(id) = idF;
end

fNames = fieldnames(a_sgStructure.eng.data);
for idF = 1:length(fNames)
   if (strcmp(fNames{idF}, 'time_eng_juld') || strcmp(fNames{idF}, timeGliderVarName))
      finalFieldNames{end+1} = fNames{idF};
      continue
   end
   a_sgStructure.eng.(fNames{idF}) = nan(1, nbMeas);
   a_sgStructure.eng.(fNames{idF})(engId) = a_sgStructure.eng.data.(fNames{idF});
   
   finalFieldNames{end+1} = fNames{idF};
end

% insert ppc*a/b.eng measurements
ctdDir = 'ab';
for idDir = 1:2
   if (isfield(a_sgStructure.(['ppc' ctdDir(idDir)]), 'data') && ...
         isfield(a_sgStructure.(['ppc' ctdDir(idDir)]).data, 'time'))
      
      dataStruct = a_sgStructure.(['ppc' ctdDir(idDir)]).data;
      
      engTimes = dataStruct.time;
      engId = ones(1, length(engTimes))*-1;
      for id = 1:length(engTimes)
         idF = find(engTimes(id) == mergedTimes, 1);
         engId(id) = idF;
      end
      
      fNames = fieldnames(dataStruct);
      for idF = 1:length(fNames)
         if (strcmp(fNames{idF}, 'time') || strcmp(fNames{idF}, 'juld'))
            continue
         end
         if (~isfield(a_sgStructure.eng, fNames{idF}))
            a_sgStructure.eng.(fNames{idF}) = nan(1, nbMeas);
         end
         
         a_sgStructure.eng.(fNames{idF})(engId) = dataStruct.(fNames{idF});
         
         finalFieldNames{end+1} = fNames{idF};
      end
   end
end

% retrieve glider variable name for TIME
timeGliderVarName = g_decGl_gliderVarName{find(strcmp(g_decGl_egoVarName, 'TIME'))};

% delete timely duplicated measurements
if (~isempty(find(diff(a_sgStructure.eng.(timeGliderVarName)) == 0, 1)))
   idDup = find(diff(a_sgStructure.eng.(timeGliderVarName)) == 0);
   a_sgStructure.eng.(timeGliderVarName)(idDup) = [];
   for idC = 1:length(columns)
      a_sgStructure.eng.(columns{idC})(idDup) = [];
   end
   fprintf('WARNING: Duplicated times in p*.eng and ppc*.eng files => deleted data: ');
   fprintf('#%d ', idDup);
   fprintf('\n');
end

% clean measurements (delete timestamps when all measurements = Nan)
excludedEgoVarList = [{'TIME_GPS'} {'LATITUDE_GPS'} {'LONGITUDE_GPS'}];
dataAll = [];
for idV = 1:length(g_decGl_egoVarName)
   if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
         ~strcmp(g_decGl_egoVarName{idV}, 'TIME') && ...
         ~isempty(g_decGl_gliderVarName{idV}))
      if (isfield(a_sgStructure.eng, g_decGl_gliderVarName{idV}))
         dataAll = [dataAll; a_sgStructure.eng.(g_decGl_gliderVarName{idV})];
      end
   end
end
idDel = find(sum(isnan(dataAll), 1) == size(dataAll, 1));
if (~isempty(idDel))
   for idV = 1:length(g_decGl_egoVarName)
      if (~ismember(g_decGl_egoVarName{idV}, excludedEgoVarList) && ...
            ~isempty(g_decGl_gliderVarName{idV}))
         if (isfield(a_sgStructure.eng, g_decGl_gliderVarName{idV}))
            a_sgStructure.eng.(g_decGl_gliderVarName{idV})(idDel) = [];
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
   if (isfield(a_sgStructure.eng, timeGliderVarName))
      time = a_sgStructure.eng.(timeGliderVarName);
   end
   if (isfield(a_sgStructure.eng, presGliderVarName))
      pres = a_sgStructure.eng.(presGliderVarName);
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
      
      a_sgStructure.eng.(presGliderVarName) = pres;
      if (~isempty(presQcGliderVarName))
         a_sgStructure.eng.(presQcGliderVarName) = pres_QC;
      else
         a_sgStructure.eng.PRES_QC = pres_qc;
         g_decGl_directEgoVarName{end+1} = 'vars_time.PRES_QC';
      end
   end
end

o_sgStructure = a_sgStructure;

% DEBUG OUTPUT
if (0)
   dataStructTab = [ ...
      {a_sgStructure.eng.data} ...
      {a_sgStructure.ppca.data} ...
      {a_sgStructure.ppcb.data} ...
      {a_sgStructure.eng} ...
      ];
   timeNameTab = [ ...
      {'time_eng_juld'} ...
      {'juld'} ...
      {'juld'} ...
      {'time_eng_juld'} ...
      ];
   fieldNameTab = [ ...
      {fieldnames(a_sgStructure.eng.data)} ...
      {fieldnames(a_sgStructure.ppca.data)} ...
      {fieldnames(a_sgStructure.ppcb.data)} ...
      {unique(finalFieldNames)} ...
      ];
   fileNameTab = [ ...
      {'eng'} ...
      {'eng_a'} ...
      {'eng_b'} ...
      {'eng_merged'} ...
      ];
   
   for id = 1:length(dataStructTab)
      dataStruct = dataStructTab{id};
      fNames = fieldNameTab{id};
      data = nan(length(dataStruct.(fNames{1})), length(fNames)+1);
      for idF = 1:length(fNames)
         if (strcmp(fNames{idF}, timeNameTab{id}))
            data(:, 1) = dataStruct.(fNames{idF});
         end
         data(:, idF+1) = dataStruct.(fNames{idF});
      end
      
      outputFileName = ['./' fileNameTab{id} '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
         return
      end
      
      fprintf(fidOut, 'JULD');
      fprintf(fidOut, ';%s', fNames{:});
      fprintf(fidOut, '\n');
      
      for idL = 1:size(data, 1)
         fprintf(fidOut, '%s', gl_julian_2_gregorian(data(idL, 1)));
         fprintf(fidOut, ';%g', data(idL, 2:end));
         fprintf(fidOut, '\n');
      end
      
      fclose(fidOut);
   end
end

return
