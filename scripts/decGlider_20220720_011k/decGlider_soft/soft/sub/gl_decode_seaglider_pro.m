% ------------------------------------------------------------------------------
% This decodes seaglider data from a single yo pro text format and places
% it in a matlab structure for subsequent conversion to EGO netcdf format
% by EGO routines.
%
% SYNTAX :
% gl_decode_seaglider_pro(a_proFileNameIn, a_matFileNameOut)
%
% INPUT PARAMETERS :
%   a_proFileNameIn  : name of the input .pro file from a yo
%   a_matFileNameOut : name of the output .mat file containing the structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2013 - RNU - creation (from gl_decode_seaglider_bpo)
% ------------------------------------------------------------------------------
function gl_decode_seaglider_pro(a_proFileNameIn, a_matFileNameOut)


% read data from the .pro file
rawDataFull = gl_seaglider_pro_ascii2matlab(a_proFileNameIn);

% master list of all fields, initialize it with the first dive
allProFields = fieldnames(rawDataFull.pro);

% now create master time channels
rawDataFull.vars_dives.time = rawDataFull.pro.start;
rawDataFull.vars_time.juld = rawDataFull.pro.time_pro_juld;

% copy data from pro structure to vars structures
for idF = 1:length(allProFields)
   if (strcmp(allProFields{idF}, 'time_pro_juld'))
      continue
   elseif (strncmp(allProFields{idF}, 'comment', length('comment')) || ...
         strncmp(allProFields{idF}, 'basestation_version', length('basestation_version')))
      rawDataFull.vars_dives.(allProFields{idF}) = ...
         rawDataFull.pro.(allProFields{idF});
   elseif (length(rawDataFull.pro.(allProFields{idF})) == ...
         length(rawDataFull.vars_dives.time))
      % length of data is one, i.e. a single entry per dive
      rawDataFull.vars_dives.(allProFields{idF}) = ...
         rawDataFull.pro.(allProFields{idF});
   else
      % i.e. length of data is time
      rawDataFull.vars_time.(allProFields{idF}) = NaN(size(rawDataFull.vars_time.juld));
      for idD = 1:length(rawDataFull.vars_time.juld)
         if (~isempty(rawDataFull.pro.(allProFields{idF})))
            rawDataFull.vars_time.(allProFields{idF})(idD) = ...
               rawDataFull.pro.(allProFields{idF})( ...
               rawDataFull.pro.time_pro_juld == rawDataFull.vars_time.juld(idD));
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
