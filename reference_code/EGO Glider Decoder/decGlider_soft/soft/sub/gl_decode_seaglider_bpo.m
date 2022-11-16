% ------------------------------------------------------------------------------
% This decodes seaglider data from a single yo bpo text format and places
% it in a matlab structure for subsequent conversion to EGO netcdf format
% by EGO routines.
%
% SYNTAX :
% gl_decode_seaglider_bpo(a_bpoFileNameIn, a_matFileNameOut)
%
% INPUT PARAMETERS :
%   a_bpoFileNameIn  : name of the input .bpo file from a yo
%   a_matFileNameOut : name of the output .mat file containing the structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
% gl_decode_seaglider_bpo( ...
%   '/users/argo/juck/gliders/p5080010.bpo','/login/juck/tmp/test.mat')
%
% SEE ALSO :
% AUTHORS  : Justin Buck (BODC)(juck@bodc.ac.uk)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/07/2013 - BUCK - creation
%   06/04/2013 - RNU - updated
% ------------------------------------------------------------------------------
function gl_decode_seaglider_bpo(a_bpoFileNameIn, a_matFileNameOut)


% read data from the .bpo file
rawDataFull = gl_seaglider_bpo_ascii2matlab(a_bpoFileNameIn);

% master list of all fields, initialize it with the first dive
allBpoFields = fieldnames(rawDataFull.bpo);

% now create master time channels
rawDataFull.vars_dives.time = rawDataFull.bpo.start;
rawDataFull.vars_time.juld = rawDataFull.bpo.time_bpo_juld;

% copy data from bpo structure to vars structures
for idF = 1:length(allBpoFields)
   if (strcmp(allBpoFields{idF}, 'time_bpo_juld'))
      continue
   elseif (strncmp(allBpoFields{idF}, 'comment', length('comment')) || ...
         strncmp(allBpoFields{idF}, 'basestation_version', length('basestation_version')))
      rawDataFull.vars_dives.(allBpoFields{idF}) = ...
         rawDataFull.bpo.(allBpoFields{idF});
   elseif (length(rawDataFull.bpo.(allBpoFields{idF})) == ...
         length(rawDataFull.vars_dives.time))
      % length of data is one, i.e. a single entry per dive
      rawDataFull.vars_dives.(allBpoFields{idF}) = ...
         rawDataFull.bpo.(allBpoFields{idF});
   else
      % i.e. length of data is time
      rawDataFull.vars_time.(allBpoFields{idF}) = NaN(size(rawDataFull.vars_time.juld));
      for idD = 1:length(rawDataFull.vars_time.juld)
         if (~isempty(rawDataFull.bpo.(allBpoFields{idF})))
            rawDataFull.vars_time.(allBpoFields{idF})(idD) = ...
               rawDataFull.bpo.(allBpoFields{idF})( ...
               rawDataFull.bpo.time_bpo_juld == rawDataFull.vars_time.juld(idD));
         end
      end
   end
end

% save the data as a .mat file so it can be passed to the netcdf file generator
rawData.source = rawDataFull.source;
rawData.vars_time = rawDataFull.vars_time;
rawData.vars_dives = rawDataFull.vars_dives;

% parse included GPS data
rawData.vars_time_gps = gl_parse_gps_data(rawData.vars_dives);

% compute and add derived parameters
rawData = gl_add_derived_parameters(rawData);

save(a_matFileNameOut,'rawData');

return
