% ------------------------------------------------------------------------------
% Compute and add derived parameters to the data structure.
%
% SYNTAX :
%  [o_rawData] = gl_add_derived_parameters(a_rawData)
%
% INPUT PARAMETERS :
%   a_rawData : input data structure
%
% OUTPUT PARAMETERS :
%   o_rawData : output data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rawData] = gl_add_derived_parameters(a_rawData)

% output parameter initialization
o_rawData = a_rawData;

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_gliderVarPathName;
global g_decGl_egoVarName;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;

% calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;

% DOXY processing Id
global g_decGl_processingId;

% meta-data for derived parameters
global g_decGl_derivedParamMetaData;

% type of the glider to process
global g_decGl_gliderType;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute 'slope_offset' derived parameter

idSlopeOffset = find(strcmp('slope_offset', g_decGl_processingId));
for idP = 1:length(idSlopeOffset)
   egoVarName = g_decGl_egoVarName{idSlopeOffset(idP)};
   gliderVarName = g_decGl_gliderVarName{idSlopeOffset(idP)};
   gliderVarPathName = g_decGl_gliderVarPathName{idSlopeOffset(idP)};
   calibInfo = g_decGl_calibInfo{idSlopeOffset(idP)};

   if (~isempty(egoVarName) && ~isempty(gliderVarName))

      if (gl_is_field_recursive(o_rawData, gliderVarPathName))
         eval(['varValue = o_rawData.' gliderVarPathName ';']);
         varValue = varValue*calibInfo.SlopeValue + varValue*calibInfo.OffsetValue;
         eval(['o_rawData.' gl_get_path_to_data('') '.' egoVarName ' = varValue;']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' egoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, egoVarName))

            metaData = [];
            metaData.derivation_equation = sprintf('%s = %s*SLOPE + OFFSET', egoVarName, gliderVarName);
            metaData.derivation_coefficient = sprintf('SLOPE=%g, OFFSET=%g', calibInfo.SlopeValue, calibInfo.OffsetValue);
            metaData.derivation_comment = 'Slope and offset factors applied by Coriolis decoder.';
            g_decGl_derivedParamMetaData.(egoVarName) = metaData;
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve glider data for TIME, PRES, TEMP, CNDC and PSAL parameters

time = get_values(o_rawData, 'TIME');
pres = get_values(o_rawData, 'PRES');
temp = get_values(o_rawData, 'TEMP');
cndc = get_values(o_rawData, 'CNDC');
psal = get_values(o_rawData, 'PSAL');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute PSAL parameter if it is not provided by the glider
if (isempty(psal) && ...
      ~isempty(pres) && ...
      ~isempty(temp) && ...
      ~isempty(cndc))

   psal = ones(1, length(pres))*nan;

   idNoNan = find((~isnan(pres)) & (~isnan(temp)) & (~isnan(cndc)));
   for id = 1:length(idNoNan)
      psalValue = gl_compute_salinity(pres(idNoNan(id)), ...
         temp(idNoNan(id)), cndc(idNoNan(id))*10);
      % psalValue can be complex (due to bad noisy data), store only real values
      if (isreal(psalValue))
         psal(idNoNan(id)) = psalValue;
      end
   end

   % store the PSAL values if wanted
   psalEgoVarName = [];
   psalGliderVarName = [];
   idPsal = find(strcmp(g_decGl_egoVarName, 'PSAL'));
   if (~isempty(idPsal))
      psalEgoVarName = g_decGl_egoVarName{idPsal};
      psalGliderVarName = g_decGl_gliderVarName{idPsal};
   end
   if (~isempty(psalEgoVarName) && isempty(psalGliderVarName))
      eval(['o_rawData.' gl_get_path_to_data('') '.PSAL = psal;']);
      g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.PSAL'];

      if (~isfield(g_decGl_derivedParamMetaData, 'PSAL'))
         g_decGl_derivedParamMetaData.(psalEgoVarName) = gl_get_derived_param_meta_data('PSAL', '');
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute PSAL2 parameter if it is not provided by the glider

psal2EgoVarName = [];
psal2GliderVarName = [];
idPsal2 = find(strcmp(g_decGl_egoVarName, 'PSAL2'));
if (~isempty(idPsal2))
   psal2EgoVarName = g_decGl_egoVarName{idPsal2};
   psal2GliderVarName = g_decGl_gliderVarName{idPsal2};
end
if (~isempty(psal2EgoVarName) && isempty(psal2GliderVarName))

   pres2 = get_values(o_rawData, 'PRES2');
   temp2 = get_values(o_rawData, 'TEMP2');
   cndc2 = get_values(o_rawData, 'CNDC2');

   if (~isempty(pres2) && ...
         ~isempty(temp2) && ...
         ~isempty(cndc2))

      psal2 = ones(1, length(pres2))*nan;

      idNoNan = find((~isnan(pres2)) & (~isnan(temp2)) & (~isnan(cndc2)));
      for id = 1:length(idNoNan)
         psal2Value = gl_compute_salinity(pres2(idNoNan(id)), ...
            temp2(idNoNan(id)), cndc2(idNoNan(id))*10);
         % psal2Value can be complex (due to bad noisy data), store only real values
         if (isreal(psal2Value))
            psal2(idNoNan(id)) = psal2Value;
         end
      end

      % store the PSAL2 values
      eval(['o_rawData.' gl_get_path_to_data('') '.PSAL2 = psal2;']);
      g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.PSAL2'];

      if (~isfield(g_decGl_derivedParamMetaData, 'PSAL2'))
         g_decGl_derivedParamMetaData.(psal2EgoVarName) = gl_get_derived_param_meta_data('PSAL2', '');
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute DOXY derived parameter

idDoxy = find(strncmp(g_decGl_egoVarName, 'DOXY', length('DOXY')));
timeGps = [];
latitudeGps = [];
longitudeGps = [];
if (~isempty(idDoxy))

   % we need glider latitudes and longitudes to compute potential density
   if (strcmpi(g_decGl_gliderType, 'seaexplorer'))

      % for the Seaexplorer we use the time and location provided with the
      % measurements (because GPS fixes generally don't cover the entire
      % measurement set).

      % retrieve glider data for TIME, LATITUDE and LONGITUDE parameters
      timeGps = get_values(o_rawData, 'TIME');
      latitudeGps = get_values(o_rawData, 'LATITUDE');
      longitudeGps = get_values(o_rawData, 'LONGITUDE');
   else

      % for other glider types we use the GPS time and locations

      % retrieve glider data for TIME_GPS, LATITUDE_GPS and LONGITUDE_GPS parameters
      timeGps = get_values(o_rawData, 'TIME_GPS');
      latitudeGps = get_values(o_rawData, 'LATITUDE_GPS');
      longitudeGps = get_values(o_rawData, 'LONGITUDE_GPS');
   end
end

for idP = 1:length(idDoxy)
   doxyEgoVarName = g_decGl_egoVarName{idDoxy(idP)};
   doxyGliderVarName = g_decGl_gliderVarName{idDoxy(idP)};

   % compute DOXY according to a provided 'Case'
   if (~isempty(doxyEgoVarName) && isempty(doxyGliderVarName))

      % retrieve the provided case
      caseValue = g_decGl_processingId{idDoxy(idP)};
      g_decGl_calibInfoId = idDoxy(idP);
      switch (caseValue)

         case {'201_201_301', '202_201_301'}

            molarDoxy = get_values(o_rawData, 'MOLAR_DOXY');
            %             if (isempty(molarDoxy))
            %                fprintf('WARNING: MOLAR_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end

            if (~isempty(time) && ...
                  ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
                  ~isempty(molarDoxy) && ...
                  ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

               doxy = gl_compute_DOXY_case_201_201_301(time', ...
                  cat(2, pres', temp', psal'), molarDoxy', ...
                  timeGps', latitudeGps', longitudeGps');

               eval(['o_rawData.' gl_get_path_to_data('') '.' doxyEgoVarName ' = doxy'';']);
               g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' doxyEgoVarName];

               if (~isfield(g_decGl_derivedParamMetaData, doxyEgoVarName))
                  g_decGl_derivedParamMetaData.(doxyEgoVarName) = gl_get_derived_param_meta_data('DOXY', caseValue);
               end
            end

         case '201_202_202'

            bPhaseDoxy = get_values(o_rawData, 'BPHASE_DOXY');
            %             if (isempty(bPhaseDoxy))
            %                fprintf('WARNING: BPHASE_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end

            if (~isempty(time) && ...
                  ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
                  ~isempty(bPhaseDoxy) && ...
                  ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

               doxy = gl_compute_DOXY_case_201_202_202(time', ...
                  cat(2, pres', temp', psal'), bPhaseDoxy', ...
                  timeGps', latitudeGps', longitudeGps');

               eval(['o_rawData.' gl_get_path_to_data('') '.' doxyEgoVarName ' = doxy'';']);
               g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' doxyEgoVarName];

               if (~isfield(g_decGl_derivedParamMetaData, doxyEgoVarName))
                  g_decGl_derivedParamMetaData.(doxyEgoVarName) = gl_get_derived_param_meta_data('DOXY', caseValue);
               end
            end

         case {'202_205_302', '202_205_303'}

            c1PhaseDoxy = get_values(o_rawData, 'C1PHASE_DOXY');
            %             if (isempty(c1PhaseDoxy))
            %                fprintf('WARNING: C1PHASE_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end
            c2PhaseDoxy = get_values(o_rawData, 'C2PHASE_DOXY');
            %             if (isempty(c2PhaseDoxy))
            %                fprintf('WARNING: C2PHASE_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end
            tempDoxy = get_values(o_rawData, 'TEMP_DOXY');
            %             if (isempty(tempDoxy))
            %                fprintf('WARNING: TEMP_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end

            if (~isempty(time) && ...
                  ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
                  ~isempty(c1PhaseDoxy) && ~isempty(c2PhaseDoxy) && ~isempty(tempDoxy) && ...
                  ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

               if (strcmp(caseValue, '202_205_302'))
                  doxy = gl_compute_DOXY_case_202_205_302(time', ...
                     cat(2, pres', temp', psal'), c1PhaseDoxy', c2PhaseDoxy', tempDoxy', ...
                     timeGps', latitudeGps', longitudeGps');
               elseif (strcmp(caseValue, '202_205_303'))
                  doxy = gl_compute_DOXY_case_202_205_303(time', ...
                     cat(2, pres', temp', psal'), c1PhaseDoxy', c2PhaseDoxy', tempDoxy', ...
                     timeGps', latitudeGps', longitudeGps');
               end

               eval(['o_rawData.' gl_get_path_to_data('') '.' doxyEgoVarName ' = doxy'';']);
               g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' doxyEgoVarName];

               if (~isfield(g_decGl_derivedParamMetaData, doxyEgoVarName))
                  g_decGl_derivedParamMetaData.(doxyEgoVarName) = gl_get_derived_param_meta_data('DOXY', caseValue);
               end
            end

         case {'202_205_304'}

            c1PhaseDoxy = get_values(o_rawData, 'C1PHASE_DOXY');
            %             if (isempty(c1PhaseDoxy))
            %                fprintf('WARNING: C1PHASE_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end
            c2PhaseDoxy = get_values(o_rawData, 'C2PHASE_DOXY');
            %             if (isempty(c2PhaseDoxy))
            %                fprintf('WARNING: C2PHASE_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end
            tempDoxy = get_values(o_rawData, 'TEMP_DOXY');
            %             if (isempty(tempDoxy))
            %                fprintf('WARNING: TEMP_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end

            if (~isempty(time) && ...
                  ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
                  ~isempty(c1PhaseDoxy) && ~isempty(c2PhaseDoxy) && ~isempty(tempDoxy) && ...
                  ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

               doxy = gl_compute_DOXY_case_202_205_304(time', ...
                  cat(2, pres', temp', psal'), c1PhaseDoxy', c2PhaseDoxy', tempDoxy', ...
                  timeGps', latitudeGps', longitudeGps');

               eval(['o_rawData.' gl_get_path_to_data('') '.' doxyEgoVarName ' = doxy'';']);
               g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' doxyEgoVarName];

               if (~isfield(g_decGl_derivedParamMetaData, doxyEgoVarName))
                  g_decGl_derivedParamMetaData.(doxyEgoVarName) = gl_get_derived_param_meta_data('DOXY', caseValue);
               end
            end

         case {'202_204_304'}

            tPhaseDoxy = get_values(o_rawData, 'TPHASE_DOXY');
            %             if (isempty(tPhaseDoxy))
            %                fprintf('WARNING: TPHASE_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end
            tempDoxy = get_values(o_rawData, 'TEMP_DOXY');
            %             if (isempty(tempDoxy))
            %                fprintf('WARNING: TEMP_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end

            if (~isempty(time) && ...
                  ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
                  ~isempty(tPhaseDoxy) && ~isempty(tempDoxy) && ...
                  ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

               doxy = gl_compute_DOXY_case_202_204_304(time', ...
                  cat(2, pres', temp', psal'), tPhaseDoxy', tempDoxy', ...
                  timeGps', latitudeGps', longitudeGps');

               eval(['o_rawData.' gl_get_path_to_data('') '.' doxyEgoVarName ' = doxy'';']);
               g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' doxyEgoVarName];

               if (~isfield(g_decGl_derivedParamMetaData, doxyEgoVarName))
                  g_decGl_derivedParamMetaData.(doxyEgoVarName) = gl_get_derived_param_meta_data('DOXY', caseValue);
               end
            end

         case {'102_207_206'}

            frequencyDoxy = get_values(o_rawData, 'FREQUENCY_DOXY');
            %             if (isempty(frequencyDoxy))
            %                fprintf('WARNING: FREQUENCY_DOXY parameter is missing => %s set to FillValue\n', doxyEgoVarName);
            %             end

            if (~isempty(time) && ...
                  ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
                  ~isempty(frequencyDoxy) && ...
                  ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

               doxy = gl_compute_DOXY_case_102_207_206(time', ...
                  cat(2, pres', temp', psal'), frequencyDoxy', ...
                  timeGps', latitudeGps', longitudeGps');

               eval(['o_rawData.' gl_get_path_to_data('') '.' doxyEgoVarName ' = doxy'';']);
               g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' doxyEgoVarName];

               if (~isfield(g_decGl_derivedParamMetaData, doxyEgoVarName))
                  g_decGl_derivedParamMetaData.(doxyEgoVarName) = gl_get_derived_param_meta_data('DOXY', caseValue);
               end
            end

         otherwise
            fprintf('WARNING: case ''%s'' is not implemented for DOXY processing\n', ...
               caseValue);
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute BBP700 derived parameter

idBbp = find(strncmp(g_decGl_egoVarName, 'BBP700', length('BBP700')));
for idP = 1:length(idBbp)
   bbpEgoVarName = g_decGl_egoVarName{idBbp(idP)};
   bbpGliderVarName = g_decGl_gliderVarName{idBbp(idP)};

   if (~isempty(bbpEgoVarName) && isempty(bbpGliderVarName))

      g_decGl_calibInfoId = idBbp(idP);

      betaBackscattering = get_values(o_rawData, 'BETA_BACKSCATTERING700');
      %       if (isempty(betaBackscattering))
      %          fprintf('WARNING: BETA_BACKSCATTERING700 parameter is missing => %s set to FillValue\n', bbpEgoVarName);
      %       end

      if (~isempty(time) && ...
            ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
            ~isempty(betaBackscattering))

         bbp700 = gl_compute_BBP(time', ...
            cat(2, pres', temp', psal'), betaBackscattering', 700);

         eval(['o_rawData.' gl_get_path_to_data('') '.' bbpEgoVarName ' = bbp700'';']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' bbpEgoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, bbpEgoVarName))
            g_decGl_derivedParamMetaData.(bbpEgoVarName) = gl_get_derived_param_meta_data('BBP700');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute BBP470 derived parameter

idBbp = find(strncmp(g_decGl_egoVarName, 'BBP470', length('BB470')));
for idP = 1:length(idBbp)
   bbpEgoVarName = g_decGl_egoVarName{idBbp(idP)};
   bbpGliderVarName = g_decGl_gliderVarName{idBbp(idP)};

   if (~isempty(bbpEgoVarName) && isempty(bbpGliderVarName))

      g_decGl_calibInfoId = idBbp(idP);

      betaBackscattering = get_values(o_rawData, 'BETA_BACKSCATTERING470');
      %       if (isempty(betaBackscattering))
      %          fprintf('WARNING: BETA_BACKSCATTERING470 parameter is missing => %s set to FillValue\n', bbpEgoVarName);
      %       end

      if (~isempty(time) && ...
            ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
            ~isempty(betaBackscattering))

         bbp470 = gl_compute_BBP(time', ...
            cat(2, pres', temp', psal'), betaBackscattering', 470);

         eval(['o_rawData.' gl_get_path_to_data('') '.' bbpEgoVarName ' = bbp470'';']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' bbpEgoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, bbpEgoVarName))
            g_decGl_derivedParamMetaData.(bbpEgoVarName) = gl_get_derived_param_meta_data('BBP470');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute CDOM derived parameter

idCdom = find(strncmp(g_decGl_egoVarName, 'CDOM', length('CDOM')));
for idP = 1:length(idCdom)
   cdomEgoVarName = g_decGl_egoVarName{idCdom(idP)};
   cdomGliderVarName = g_decGl_gliderVarName{idCdom(idP)};

   if (~isempty(cdomEgoVarName) && isempty(cdomGliderVarName))

      g_decGl_calibInfoId = idCdom(idP);

      fluorescenceCdom = get_values(o_rawData, 'FLUORESCENCE_CDOM');
      %       if (isempty(fluorescenceCdom))
      %          fprintf('WARNING: FLUORESCENCE_CDOM parameter is missing => %s set to FillValue\n', cdomEgoVarName);
      %       end

      if (~isempty(fluorescenceCdom))

         cdom = gl_compute_CDOM(fluorescenceCdom');

         eval(['o_rawData.' gl_get_path_to_data('') '.' cdomEgoVarName ' = cdom'';']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' cdomEgoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, cdomEgoVarName))
            g_decGl_derivedParamMetaData.(cdomEgoVarName) = gl_get_derived_param_meta_data('CDOM');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute CHLA derived parameter

idChla = find(strncmp(g_decGl_egoVarName, 'CHLA', length('CHLA')));
for idP = 1:length(idChla)
   chlaEgoVarName = g_decGl_egoVarName{idChla(idP)};
   chlaGliderVarName = g_decGl_gliderVarName{idChla(idP)};

   if (~isempty(chlaEgoVarName) && isempty(chlaGliderVarName))

      g_decGl_calibInfoId = idChla(idP);

      fluorescenceChla = get_values(o_rawData, 'FLUORESCENCE_CHLA');
      %       if (isempty(fluorescenceChla))
      %          fprintf('WARNING: FLUORESCENCE_CHLA parameter is missing => %s set to FillValue\n', chlaEgoVarName);
      %       end

      if (~isempty(fluorescenceChla))

         chla = gl_compute_CHLA(fluorescenceChla');

         eval(['o_rawData.' gl_get_path_to_data('') '.' chlaEgoVarName ' = chla'';']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' chlaEgoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, chlaEgoVarName))
            g_decGl_derivedParamMetaData.(chlaEgoVarName) = gl_get_derived_param_meta_data('CHLA');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute NITRATE derived parameter

idNitrate = find(strncmp(g_decGl_egoVarName, 'NITRATE', length('NITRATE')));
if (~isempty(idNitrate))
   if (isempty(timeGps))

      % we need glider latitudes and longitudes to compute potential density
      if (strcmpi(g_decGl_gliderType, 'seaexplorer'))

         % for the Seaexplorer we use the time and location provided with the
         % measurements (because GPS fixes generally don't cover the entire
         % measurement set).

         % retrieve glider data for TIME, LATITUDE and LONGITUDE parameters
         timeGps = get_values(o_rawData, 'TIME');
         latitudeGps = get_values(o_rawData, 'LATITUDE');
         longitudeGps = get_values(o_rawData, 'LONGITUDE');
      else

         % for other glider types we use the GPS time and locations

         % retrieve glider data for TIME_GPS, LATITUDE_GPS and LONGITUDE_GPS parameters
         timeGps = get_values(o_rawData, 'TIME_GPS');
         latitudeGps = get_values(o_rawData, 'LATITUDE_GPS');
         longitudeGps = get_values(o_rawData, 'LONGITUDE_GPS');
      end
   end
end
for idP = 1:length(idNitrate)
   nitrateEgoVarName = g_decGl_egoVarName{idNitrate(idP)};
   nitrateGliderVarName = g_decGl_gliderVarName{idNitrate(idP)};

   if (~isempty(nitrateEgoVarName) && isempty(nitrateGliderVarName))

      g_decGl_calibInfoId = idNitrate(idP);

      molarNitrate = get_values(o_rawData, 'MOLAR_NITRATE');
      %       if (isempty(molarNitrate))
      %          fprintf('WARNING: MOLAR_NITRATE parameter is missing => %s set to FillValue\n', nitrateEgoVarName);
      %       end

      if (~isempty(time) && ...
            ~isempty(pres) && ~isempty(temp) && ~isempty(psal) && ...
            ~isempty(molarNitrate) && ...
            ~isempty(timeGps) && ~isempty(latitudeGps) && ~isempty(longitudeGps))

         nitrate = gl_compute_NITRATE(time', ...
            cat(2, pres', temp', psal'), molarNitrate', ...
            timeGps', latitudeGps', longitudeGps');

         eval(['o_rawData.' gl_get_path_to_data('') '.' nitrateEgoVarName ' = nitrate'';']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' nitrateEgoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, nitrateEgoVarName))
            g_decGl_derivedParamMetaData.(nitrateEgoVarName) = gl_get_derived_param_meta_data('NITRATE');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute TURBIDITY derived parameter

idTurbidity = find(strncmp(g_decGl_egoVarName, 'TURBIDITY', length('TURBIDITY')));
for idP = 1:length(idTurbidity)
   turbidityEgoVarName = g_decGl_egoVarName{idTurbidity(idP)};
   turbidityGliderVarName = g_decGl_gliderVarName{idTurbidity(idP)};

   if (~isempty(turbidityEgoVarName) && isempty(turbidityGliderVarName))

      g_decGl_calibInfoId = idTurbidity(idP);

      sideScatteringTurbidity = get_values(o_rawData, 'SIDE_SCATTERING_TURBIDITY');
      %       if (isempty(sideScatteringTurbidity))
      %          fprintf('WARNING: SIDE_SCATTERING_TURBIDITY parameter is missing => %s set to FillValue\n', turbidityEgoVarName);
      %       end

      if (~isempty(sideScatteringTurbidity))

         turbidity = gl_compute_TURBIDITY(sideScatteringTurbidity');

         eval(['o_rawData.' gl_get_path_to_data('') '.' turbidityEgoVarName ' = turbidity'';']);
         g_decGl_directEgoVarName{end+1} = [gl_get_path_to_data('') '.' turbidityEgoVarName];

         if (~isfield(g_decGl_derivedParamMetaData, turbidityEgoVarName))
            g_decGl_derivedParamMetaData.(turbidityEgoVarName) = gl_get_derived_param_meta_data('TURBIDITY');
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve variable data from decoded structure.
%
% SYNTAX :
%  [o_values] = get_values(a_rawData, a_varName)
%
% INPUT PARAMETERS :
%   a_rawData : input data structure
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_values : variable data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/23/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_values] = get_values(a_rawData, a_varName)

% output parameter initialization
o_values = [];

% variable names defined in the json deployment file
global g_decGl_gliderVarPathName;
global g_decGl_egoVarName;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;


idF1 = find(strcmp(g_decGl_egoVarName, a_varName));
if (~isempty(idF1))
   idF2 = find(strcmp(g_decGl_directEgoVarName, [gl_get_path_to_data('') '.' a_varName]), 1);
   if (~isempty(idF2) && gl_is_field_recursive(a_rawData, g_decGl_directEgoVarName{idF2}))
      % retrieve the data from g_decGl_directEgoVarName (case of a
      % 'slope_offset' derived parameter)
      eval(['o_values = a_rawData.' g_decGl_directEgoVarName{idF2} ';']);
   elseif (gl_is_field_recursive(a_rawData, g_decGl_gliderVarPathName{idF1}))
      % retrieve the data from nominal structure
      eval(['o_values = a_rawData.' g_decGl_gliderVarPathName{idF1} ';']);
   end
end

return
