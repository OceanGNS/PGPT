% ------------------------------------------------------------------------------
% Retrieve the path to data stored in the 'rawData' structure.
%
% SYNTAX :
%  [o_pathToData] = gl_get_path_to_data
%
% INPUT PARAMETERS :
%   o_pathToData : path to glider data in the 'rawData' structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/03/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_pathToData] = gl_get_path_to_data(a_gliderVarName)

% output parameters initialization
o_pathToData = [];

% type of the glider to process
global g_decGl_gliderType;

switch (g_decGl_gliderType)
   case 'slocum'
      if (~isempty(a_gliderVarName))
         idFUs = strfind(a_gliderVarName, '_');
         o_pathToData = ['vars_' (a_gliderVarName(1:idFUs(1)-1)) '_time'];
      else
         % for derived parameters
         o_pathToData = 'vars_sci_time';
      end
   case 'seaglider'
      o_pathToData = 'vars_time';
   case 'seaexplorer'
      if (~isempty(a_gliderVarName))
         if (strcmp(a_gliderVarName, upper(a_gliderVarName)) || contains(a_gliderVarName, '_'))
            o_pathToData = 'vars_sci_time';
         else
            o_pathToData = 'vars_m_time';
         end
      else
         % for derived parameters
         o_pathToData = 'vars_sci_time';
      end
   otherwise
      fprintf('ERROR: path to data is unknown for glider type ''%s''\n', g_decGl_gliderType);
end

return
