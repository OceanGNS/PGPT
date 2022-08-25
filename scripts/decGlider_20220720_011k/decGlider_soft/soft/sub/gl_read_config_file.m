% ------------------------------------------------------------------------------
% Retrieve parameter values from configuration file (should be in the MATLAB
% path).
%
% SYNTAX :
%  [o_configVal, o_inputError] = gl_read_config_file(a_configVar)
%
% INPUT PARAMETERS :
%   a_configVar : wanted configuration parameter names
%
% OUTPUT PARAMETERS :
%   o_configVal  : wanted configuration parameter values
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configVal, o_inputError] = gl_read_config_file(a_configVar)

% output parameters initialization
o_configVal = [];
o_inputError = 0;


% read configuration file and store the configVarName/configVarvalue parameters
varList1 = [];
valList1 = [];

% configuration file name
CONFIG_FILE_NAME = '_glider_decoder_conf.txt';
if ~(exist(CONFIG_FILE_NAME, 'file') == 2)
   fprintf('ERROR: Configuration file not found: %s\n', CONFIG_FILE_NAME);
   o_inputError = 1;
   return
else
   
   fprintf('INFO: Using configuration file: %s\n', which(CONFIG_FILE_NAME));
   
   % read configuration file
   fId = fopen(CONFIG_FILE_NAME, 'r');
   if (fId == -1)
      fprintf('ERROR: Unable to open file: %s\n', CONFIG_FILE_NAME);
      o_inputError = 1;
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n', 'commentstyle', 'matlab');
   fileContents = fileContents{:};
   fclose(fId);
   
   % get rid of comments lines
   idLine = 1;
   while (1)
      if (length(fileContents{idLine}) == 0)
         fileContents(idLine) = [];
      elseif (fileContents{idLine}(1) == '%')
         fileContents(idLine) = [];
      else
         idLine = idLine + 1;
      end
      if (idLine > length(fileContents))
         break
      end
   end
   
   % find and store parameter values
   for idLine = 1:size(fileContents, 1)
      line = fileContents{idLine};
      eqPos = strfind(line, '=');
      if (isempty(eqPos) || (length(line) == eqPos))
         fprintf('ERROR: Error in configuration file, in line: %s\n', line);
         o_inputError = 1;
         return
      end;
      
      % variable
      var = line(1:eqPos-1);
      var = strtrim(var);
      varList1 = [varList1; {var}];
      
      % value
      val = line(eqPos+1:end);
      val = strtrim(val);
      valList1 = [valList1; {val}];
   end
end
   
% store the data
for idVar = 1:length(a_configVar)
   row = strmatch(a_configVar{idVar}, varList1, 'exact');
   if (isempty(row))
%       fprintf('Configuration file %s, parameter %s not found\n', ...
%          CONFIG_FILE_NAME, a_configVar{idVar});
      o_configVal{end+1} = [];
   else
      if (isempty(valList1{row}))
%          fprintf('Configuration file %s, parameter %s not filled\n', ...
%             CONFIG_FILE_NAME, a_configVar{idVar});
      end
      o_configVal{end+1} = valList1{row};
   end
end

return
