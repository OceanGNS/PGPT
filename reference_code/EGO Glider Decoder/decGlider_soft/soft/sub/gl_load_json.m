% ------------------------------------------------------------------------------
% Read JSON file content.
%
% SYNTAX :
%  [o_data] = gl_load_json(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : JSON file path name
%
% OUTPUT PARAMETERS :
%   o_data : JSON data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/19/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = gl_load_json(a_filePathName)

% output data initialization
o_data = [];

% Matlab version (before or after R2017A)
global g_decGl_matlabVersionBeforeR2017A;


% check if the input file exists
if (~exist(a_filePathName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_filePathName);
   return
end

% read JSON file

% The LOADJSON function should be used before R2017A (we don't have other
% alternative).
% Note that arrays such as ["ECO_FLBBCD", "ECO_FLBBCD", "ECO_FLBBCD"] are
% converted in char arrays of 3x10 char (i.e. strings of same length) whereas
% arrays such as ["FLUOROMETER_CDOM", "FLUOROMETER_CHLA",
% "BACKSCATTERINGMETER_BBP700"] are converted in cellstr arrays (i.e. strings of
% different length).
% In the decoder, we convert string arrays to cellstr arrays.

% From R2017A, the string arrays where introduced and LOADJSON should not be
% used anymore (["ECO_FLBBCD", "ECO_FLBBCD", "ECO_FLBBCD"] is always converted
% in string array and ["", "", ""] to empty).
% Fortunately the JSONDECODE function was introduced.
% As JSONDECODE outputs sligthly differ from LOADJSON ones, the code have been
% updated so that both function could be used whatever the Matlab version is.

if (g_decGl_matlabVersionBeforeR2017A) % R2017A
   o_data = loadjson(a_filePathName);
else
   dataStr = fileread(a_filePathName);
   o_data = jsondecode(dataStr);
   
   % loadjson vs jsondecode issue
   fieldNames = fields(o_data);
   for idF = 1:length(fieldNames)
      data = o_data.(fieldNames{idF});
      if ((iscell(data) || isstruct(data)) && (size(data, 1) > size(data, 2)))
         o_data.(fieldNames{idF}) = o_data.(fieldNames{idF})';
      end
   end
   
%    if ( ...
%          isfield(o_data, 'SENSOR') || ...
%          isfield(o_data, 'SENSOR_MAKER') || ...
%          isfield(o_data, 'SENSOR_MODEL') || ...
%          isfield(o_data, 'SENSOR_SERIAL_NO') || ...
%          isfield(o_data, 'SENSOR_MOUNT') || ...
%          isfield(o_data, 'SENSOR_ORIENTATION'))
%       
%       dimSensorList = {
%          'SENSOR', ...
%          'SENSOR_MAKER', ...
%          'SENSOR_MODEL', ...
%          'SENSOR_SERIAL_NO', ...
%          'SENSOR_MOUNT', ...
%          'SENSOR_ORIENTATION', ...
%          };
%       
%       for idF = 1:length(dimSensorList)
%          fieldName = dimSensorList{idF};
%          if (isstring(o_data.(fieldName)))
%             o_data.(fieldName) = cellstr(o_data.(fieldName));
%          end
%       end
%       
%       %       if (isempty(o_data.SENSOR_MOUNT))
%       %          o_data.SENSOR_MOUNT = char.empty(0, size(o_data.SENSOR, 1));
%       %       end
%       %       if (isempty(o_data.SENSOR_ORIENTATION))
%       %          o_data.SENSOR_ORIENTATION = char.empty(0, size(o_data.SENSOR, 1));
%       %       end
%    end
%    
%    if ( ...
%          isfield(o_data, 'PARAMETER') || ...
%          isfield(o_data, 'PARAMETER_SENSOR') || ...
%          isfield(o_data, 'PARAMETER_DATA_MODE') || ...
%          isfield(o_data, 'PARAMETER_UNITS') || ...
%          isfield(o_data, 'PARAMETER_ACCURACY') || ...
%          isfield(o_data, 'PARAMETER_RESOLUTION'))
%       
%       dimParamList = {
%          'PARAMETER', ...
%          'PARAMETER_SENSOR', ...
%          'PARAMETER_DATA_MODE', ...
%          'PARAMETER_UNITS', ...
%          'PARAMETER_ACCURACY', ...
%          'PARAMETER_RESOLUTION', ...
%          };
%       
%       for idF = 1:length(dimParamList)
%          fieldName = dimParamList{idF};
%          if (isstring(o_data.(fieldName)))
%             o_data.(fieldName) = cellstr(o_data.(fieldName));
%          end
%       end
%    end
end

return
