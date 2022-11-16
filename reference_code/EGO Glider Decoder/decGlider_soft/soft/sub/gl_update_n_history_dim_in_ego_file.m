% ------------------------------------------------------------------------------
% Update the N_HISTORY dimension of an EGO file.
%
% SYNTAX :
%  [o_ok] = gl_update_n_history_dim_in_ego_file(a_egoFileName, a_nbStepToAdd)
%
% INPUT PARAMETERS :
%   a_egoFileName : EGO file path name
%   a_nbStepToAdd : N_HISTORY dimension increasing number
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = gl_update_n_history_dim_in_ego_file(a_egoFileName, a_nbStepToAdd)

% output parameters initialization
o_ok = 0;


% directory to store temporary files
[filePath, fileName, fileExtension] = fileparts(a_egoFileName);
DIR_TMP_FILE = [filePath '/tmp/'];

% delete the temp directory
gl_remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the file in the temp directory
egoFileName = [DIR_TMP_FILE '/' fileName fileExtension];
tmpEgoFileName = [DIR_TMP_FILE '/' fileName '_tmp' fileExtension];
copyfile(a_egoFileName, tmpEgoFileName);

% retrieve the file schema
outputFileSchema = ncinfo(tmpEgoFileName);

% retrieve the N_HISTORY dimension length
idF = find(strcmp([{outputFileSchema.Dimensions.Name}], 'N_HISTORY') == 1, 1);
nHistory = outputFileSchema.Dimensions(idF).Length;

% update the file schema with the correct N_HISTORY dimension
[outputFileSchema] = gl_update_dim_in_nc_schema(outputFileSchema, ...
   'N_HISTORY', nHistory+a_nbStepToAdd);

% create updated file
ncwriteschema(egoFileName, outputFileSchema);

% copy data in updated file
for idVar = 1:length(outputFileSchema.Variables)
   varData = ncread(tmpEgoFileName, outputFileSchema.Variables(idVar).Name);
   if (~isempty(varData))
      ncwrite(egoFileName, outputFileSchema.Variables(idVar).Name, varData);
   end
end

% update input file
movefile(egoFileName, a_egoFileName);

% delete the temp directory
gl_remove_directory(DIR_TMP_FILE);

o_ok = 1;

return
