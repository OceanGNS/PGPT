% ------------------------------------------------------------------------------
% Generate the rules file to check the EGO 1.2 format with the Coriolis Java
% checker.
%
% SYNTAX :
%  gl_generate_ego_1_2_checker_rules_file
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function gl_generate_ego_1_2_checker_rules_file

%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION START
%%%%%%%%%%%%%%%%%%%%%

% list of EGO parameters
% to generate .txt file from .xlsx file:
% - visualize only columns A, B, D, E, G, H, I, J, K, M, R, S
% - set '-' in empty cells
% - replace tabulation with ' '
% - remove '.f' and final '.' in columns H, I, R
% - copy/paste data from .xlsx to .txt
% PARAMETER_FILE_PATH_NAME = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\soft\util\ref_lists\argo-parameters-list-core-and-b_CS_20171020.txt';
PARAMETER_FILE_PATH_NAME = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\soft\util\ref_lists\argo-parameters-list-core-and-b_CS_20180129.txt';

% output rules file directory
RULES_FILE_OUTPUT_DIR = 'C:\Users\jprannou\NEW_20190125\_RNU\Checker_Java_Co\checker_20181129\netcdf-checker-1.15\resources\RULES\';

% templates of the rules file to use
TEMPLATE_RULES_FILE_PATH_NAME = 'C:\Users\jprannou\NEW_20190125\_RNU\Glider\soft\util\ref_lists\EGO_V1.2_TEMPLATE_20180207.xml';

%%%%%%%%%%%%%%%%%%%
% CONFIGURATION END
%%%%%%%%%%%%%%%%%%%


% list of mandatory attributes
MAND_ATT_LIST = [ ...
   {'standard_name'} ...
   {'units'} ...
   {'FillValue'} ...
   ];

% list of not mandatory attributes
NOT_MAND_ATT_LIST = [ ...
   {'long_name'} ...
   {'valid_min'} ...
   {'valid_max'} ...
   {'comment'} ...
   {'sensor_mount'} ...
   {'sensor_orientation'} ...
   {'sensor_name'} ...
   {'sensor_serial_number'} ...
   {'ancillary_variables'} ...
   {'cell_methods'} ...
   {'reference_scale'} ...
   {'coordinates'} ...
   {'sdn_parameter_urn'} ...
   {'sdn_uom_urn'} ...
   {'sdn_uom_name'} ...
   {'glider_original_parameter_name'} ...
   ];

% list of parameters that are not considered
IGNORE_PARAM_LIST = [ ...
   {'BETA_BACKSCATTERING'} ...
   {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION'} ...
   {'BBP'} ...
   {'CP'} ...
   {'RAW_DOWNWELLING_IRRADIANCE'} ...
   {'DOWN_IRRADIANCE'} ...
   {'RAW_UPWELLING_RADIANCE'} ...
   {'UP_RADIANCE'} ...
   {'TILT'} ...
   {'MTIME'} ...
   ];

% check configuration information
if ~(exist(PARAMETER_FILE_PATH_NAME, 'file') == 2)
   fprintf('ERROR: ''PARAMETER_FILE_PATH_NAME'' file not found: %s\n', PARAMETER_FILE_PATH_NAME);
   return
end

if ~(exist(RULES_FILE_OUTPUT_DIR, 'dir') == 7)
   fprintf('ERROR: ''RULES_FILE_OUTPUT_DIR'' directory not found: %s\n', RULES_FILE_OUTPUT_DIR);
   return
end

if ~(exist(TEMPLATE_RULES_FILE_PATH_NAME, 'file') == 2)
   fprintf('ERROR: ''TEMPLATE_RULES_FILE_PATH_NAME'' file not found: %s\n', TEMPLATE_RULES_FILE_PATH_NAME);
   return
end

% read Argo/EGO parameter file
fId = fopen(PARAMETER_FILE_PATH_NAME, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', PARAMETER_FILE_PATH_NAME);
   return
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fclose(fId);

% process EGO parameter information
paramData = fileContents{:};
paramData = reshape(paramData, 12, size(paramData, 1)/12)';

paramDataStruct = [];
for idL = 2:size(paramData, 1)
   newStruct = [];
   for idC = 1:size(paramData, 2)
      
      fieldName = paramData{1, idC};
      fieldName = strtrim(fieldName);
      fieldName = regexprep(fieldName, ' ', '_');
      fieldName = regexprep(fieldName, '/', '_');
      
      fieldValue = paramData{idL, idC};
      fieldValue = strtrim(fieldValue);
      if (fieldValue == '-')
         fieldValue = '';
      end
      
      newStruct.(fieldName) = fieldValue;
   end
   paramDataStruct = [paramDataStruct newStruct];
end

tabVar = [];
for idP = 1:length(paramDataStruct)
   
   paramStruct = paramDataStruct(idP);
   
   if (ismember(paramStruct.parameter_name, IGNORE_PARAM_LIST))
      continue
   end
   
   var = [];
   var.mandAttList = MAND_ATT_LIST;
   var.notMandAttList = NOT_MAND_ATT_LIST;
   
   var.name = paramStruct.parameter_name;
   var.type = paramStruct.Data_Type;
   var.standard_name = paramStruct.cf_standard_name;
   var.units = paramStruct.unit;
   var.FillValue = paramStruct.Fillvalue;
   var.long_name = paramStruct.long_name;
   var.valid_min = paramStruct.valid_min;
   var.valid_max = paramStruct.valid_max;
   var.sdn_parameter_urn = paramStruct.sdn_parameter_urn;
   var.sdn_uom_urn = paramStruct.sdn_uom_urn;
   
   tabVar{end+1} = var;
   
   %    if (paramStruct.core_bio_intermediate ~= 'i')
   %
   %       varAdj = var;
   %       varAdj.name = [var.name '_ADJUSTED'];
   %       varAdj.long_name = [var.long_name ' adjusted'];
   %       tabVar{end+1} = varAdj;
   %
   %       varAdjErr = var;
   %       varAdjErr.name = [varAdj.name '_ADJUSTED_ERROR'];
   %       varAdjErr.standard_name = '';
   %       varAdjErr.long_name = [varAdj.long_name ' adjusted error'];
   %       tabVar{end+1} = varAdjErr;
   %    end
end

% generate parameter template string
[paramXmlString] = generate_param_xml_string(tabVar);

% create output file name
[~, outputFileName, ~] = fileparts(TEMPLATE_RULES_FILE_PATH_NAME);
outputFileName = regexprep(outputFileName, '_TEMPLATE', '');
outputFilePathName = [RULES_FILE_OUTPUT_DIR '/' outputFileName '_' datestr(now, 'yyyymmddTHHMMSS') '.xml'];

% generate output file
ok = generate_checker_rules_file(TEMPLATE_RULES_FILE_PATH_NAME, outputFilePathName, ...
   paramXmlString);

if (ok)
   fprintf('Generated file: %s\n', outputFilePathName);
end

return

% ------------------------------------------------------------------------------
% Generate XML string (from variable information) for the rules file.
%
% SYNTAX :
%  [o_paramString] = generate_param_xml_string(a_tabVar)
%
% INPUT PARAMETERS :
%   a_tabVar : input variables information
%
% OUTPUT PARAMETERS :
%   o_paramString    : output XML string
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramString] = generate_param_xml_string(a_tabVar)

o_paramString = sprintf('\n');


% templates for rule file lines
headerPattern = '\t\t<VARIABLE>\n\t\t\t<IDENTIFY>\n\t\t\t\t<NAME VALUE="%s"/>\n\t\t\t</IDENTIFY>\n\t\t\t<MUST_VERIFY>\n\t\t\t\t<TYPE VALUE="%s"/>\n\t\t\t\t<DIMENSION_COUNT VALUE="1"/>\n';
dimPattern = '\t\t\t\t<DIMENSION NAME="TIME" RANK="1"/>\n';
attWhithValueMandPattern = '\t\t\t\t<ATTRIBUTE NAME="%s" VALUE="%s"/>\n';
attWhithValueListMandPattern = '\t\t\t\t<ATTRIBUTE NAME="%s" VALUE_LIST="%s"/>\n';
attWithoutValueMandPattern = '\t\t\t\t<ATTRIBUTE NAME="%s"/>\n';
attWhithValueNotMandPattern = '\t\t\t\t<OPTIONAL_ATTRIBUTE NAME="%s" VALUE="%s"/>\n';
attCoordinates = '\t\t\t\t<OPTIONAL_ATTRIBUTE NAME="coordinates" PATTERN="TIME LATITUDE LONGITUDE PRES|TIME LATITUDE LONGITUDE DEPTH"/>\n';
footPattern = '\t\t\t</MUST_VERIFY>\n\t\t</VARIABLE>\n';

for idV = 1:length(a_tabVar)
   
   % <PARAM>
   var = a_tabVar{idV};
   
   varStr = sprintf(headerPattern, var.name, var.type);
   varStr = [varStr sprintf(dimPattern)];
   
   % mandatory attributes: print all attributes
   mandAttList = var.mandAttList;
   for idF = 1:length(mandAttList)
      attName = mandAttList{idF};
      attNameStr = attName;
      if (strcmp(attName, 'FillValue'))
         attNameStr = ['_' attNameStr];
      end
      if (isfield(var, attName))
         if (~isempty(var.(attName)))
            varStr = [varStr sprintf(attWhithValueMandPattern, attNameStr, var.(attName))];
         else
            varStr = [varStr sprintf(attWithoutValueMandPattern, attNameStr)];
         end
      else
         varStr = [varStr sprintf(attWithoutValueMandPattern, attNameStr)];
      end
   end
      
   % mandatory attributes: print only attributes with provided value
   notMandAttList = var.notMandAttList;
   for idF = 1:length(notMandAttList)
      attName = notMandAttList{idF};
      attNameStr = attName;
      if (isfield(var, attName))
         if (~isempty(var.(attName)))
            varStr = [varStr sprintf(attWhithValueNotMandPattern, attNameStr, var.(attName))];
         end
      end
   end
      
   if (strcmp(var.name, 'PRES'))
      varStr = [varStr sprintf(attWhithValueNotMandPattern, 'axis', 'Z')];
      varStr = [varStr sprintf(attWhithValueNotMandPattern, 'positive', 'down')];
   end
   
   varStr = [varStr sprintf(attCoordinates)];
   varStr = [varStr sprintf(footPattern)];
   
   o_paramString = [o_paramString varStr];
   
   % <PARAM>_QC
   var = a_tabVar{idV};
   
   varStr = sprintf(headerPattern, [var.name '_QC'], 'byte');
   varStr = [varStr sprintf(dimPattern)];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'long_name', 'Quality flag')];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'conventions', 'EGO reference table 2')];
   varStr = [varStr sprintf(attWhithValueMandPattern, '_FillValue', '-128')];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'valid_min', '0')];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'valid_max', '9')];
   varStr = [varStr sprintf(attWhithValueListMandPattern, 'flag_values', '0||1||2||3||4||5||8||9')];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'flag_meanings', 'no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed interpolated_value missing_value')];
   varStr = [varStr sprintf(footPattern)];

   o_paramString = [o_paramString varStr];

   % <PARAM>_UNCERTAINTY
   var = a_tabVar{idV};
   
   varStr = sprintf(headerPattern, [var.name '_UNCERTAINTY'], var.type);
   varStr = [varStr sprintf(dimPattern)];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'long_name', 'Uncertainty')];
   varStr = [varStr sprintf(attWhithValueMandPattern, '_FillValue', var.FillValue)];
   varStr = [varStr sprintf(attWhithValueMandPattern, 'units', var.units)];
   varStr = [varStr sprintf(footPattern)];

   o_paramString = [o_paramString varStr];

end

return

% ------------------------------------------------------------------------------
% Generate final rules file.
%
% SYNTAX :
%  [o_ok] = generate_checker_rules_file(a_templateFileName, a_outputFilename, ...
%    a_paramXmlString)
%
% INPUT PARAMETERS :
%   a_templateFileName : rules file template
%   a_outputFilename   : output file path names
%   a_paramXmlString   : XML string for variables
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the creation succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = generate_checker_rules_file(a_templateFileName, a_outputFilename, ...
   a_paramXmlString)

% output parameters initialization
o_ok = 0;


% create the output file
fidOut = fopen(a_outputFilename, 'wt');
if (fidOut == -1)
   fprintf('ERROR: unable to create output file: %s\n', a_outputFilename);
   return
end

fidIn = fopen(a_templateFileName, 'r');
if (fidIn == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_templateFileName);
   fclose(fidOut);
   return
end

% duplicate the template file contents and replace template values
while (1)
   line = fgetl(fidIn);
   if (line == -1)
      break
   end
   
   if (strfind(line, '<TEMPLATE_PARAMETERS>'))
      line = regexprep(line, '<TEMPLATE_PARAMETERS>', a_paramXmlString);
   end
   
   line = unicode2native(line, 'UTF-8'); % the output should be encoded in UTF-8 (to manage special characters)
   fprintf(fidOut, '%s\n', line);
end

fclose(fidIn);
fclose(fidOut);

o_ok = 1;

return
