% ------------------------------------------------------------------------------
% Add the real time QCs to NetCDF profile files generated from EGO file.
%
% SYNTAX :
%  gl_add_rtqc_to_profile_file(a_ncMonoProfPathFileName)
%
% INPUT PARAMETERS :
%   a_ncMonoProfPathFileName : input profile file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - V 1.0: creation
%   08/24/2020 - RNU - V 1.1: Test 13: extended the list of parameters
%                             concerned by the test (added BBP700, BBP532,
%                             PH_IN_SITU_TOTAL, NITRATE, DOWN_IRRADIANCE380,
%                             DOWN_IRRADIANCE412, DOWN_IRRADIANCE443,
%                             DOWN_IRRADIANCE490 and DOWNWELLING_PAR
%                             parameters).
%                             Update of density function EOS80 => TEOS 10.
%   08/17/2021 - RNU - V 1.6: Updated to cope with version 3.5 of Argo Quality
%                             Control Manual For CTD and Trajectory Data
%                              - a measurement with QC = '3' is tested by other
%                             quality control tests.
%   02/22/2022 - RNU - V 1.7: Manage (PRES2, TEMP2, PSAL2) introduced for
%                             deployments with dual CTD sensors.
%   03/18/2022 - RNU - V 1.9: DOWN_IRRADIANCE532 and DOWN_IRRADIANCE555 added to
%                             RTQC tests (since the global range test has been
%                             specified).
% ------------------------------------------------------------------------------
function gl_add_rtqc_to_profile_file(a_ncMonoProfPathFileName)

% default values
global g_decGl_dateDef;
global g_decGl_argosLonDef;
global g_decGl_argosLatDef;

% QC flag values (char)
global g_decGl_qcStrDef;
global g_decGl_qcStrNoQc;
global g_decGl_qcStrGood;
global g_decGl_qcStrProbablyGood;
global g_decGl_qcStrCorrectable;
global g_decGl_qcStrBad;
global g_decGl_qcStrChanged;
global g_decGl_qcStrInterpolated;
global g_decGl_qcStrMissing;

% global configuration values
global g_decGl_rtqcTest8;
global g_decGl_rtqcTest12;
global g_decGl_rtqcTest13;
global g_decGl_rtqcTest14;


% RTQC test to perform
testToPerformList = [ ...
   {'TEST008_PRESSURE_INCREASING'} {g_decGl_rtqcTest8} ...
   {'TEST012_DIGIT_ROLLOVER'} {g_decGl_rtqcTest12} ...
   {'TEST013_STUCK_VALUE'} {g_decGl_rtqcTest13} ...
   {'TEST014_DENSITY_INVERSION'} {g_decGl_rtqcTest14} ...
   ];

% check if the input file exists
if (~exist(a_ncMonoProfPathFileName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_ncMonoProfPathFileName);
   return
end

% retrieve the test to perform
lastTestNum = 63;
testFlagList = zeros(lastTestNum, 1);
for idT = 1:2:length(testToPerformList)
   if (testToPerformList{idT+1} == 1)
      testName = testToPerformList{idT};
      testFlagList(str2num(testName(5:7))) = 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ MONO PROFILE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve the data from the core mono profile file
wantedVars = [ ...
   {'CYCLE_NUMBER'} ...
   {'DIRECTION'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'POSITIONING_SYSTEM'} ...
   {'STATION_PARAMETERS'} ...
   ];

[ncMonoProfData] = gl_get_data_from_nc_file(a_ncMonoProfPathFileName, wantedVars);

cycleNumber = gl_get_data_from_name('CYCLE_NUMBER', ncMonoProfData)';
direction = gl_get_data_from_name('DIRECTION', ncMonoProfData)';
dataMode = gl_get_data_from_name('DATA_MODE', ncMonoProfData)';
juld = gl_get_data_from_name('JULD', ncMonoProfData)';
juldQc = gl_get_data_from_name('JULD_QC', ncMonoProfData)';
juldLocation = gl_get_data_from_name('JULD_LOCATION', ncMonoProfData)';
latitude = gl_get_data_from_name('LATITUDE', ncMonoProfData)';
longitude = gl_get_data_from_name('LONGITUDE', ncMonoProfData)';
positionQc = gl_get_data_from_name('POSITION_QC', ncMonoProfData)';
positioningSystem = gl_get_data_from_name('POSITIONING_SYSTEM', ncMonoProfData)';

% create the list of parameters
stationParametersNcMono = gl_get_data_from_name('STATION_PARAMETERS', ncMonoProfData);
[~, nParam, nProf] = size(stationParametersNcMono);
ncParamNameList = [];
ncParamAdjNameList = [];
for idProf = 1:nProf
   if (dataMode(idProf) ~= 'D')
      for idParam = 1:nParam
         paramName = deblank(stationParametersNcMono(:, idParam, idProf)');
         if (~isempty(paramName))
            ncParamNameList{end+1} = paramName;
            paramInfo = gl_get_netcdf_param_attributes(paramName);
            if (paramInfo.adjAllowed == 1)
               ncParamAdjNameList = [ncParamAdjNameList ...
                  {[paramName '_ADJUSTED']} ...
                  ];
            end
         end
      end
   end
end
ncParamNameList = unique(ncParamNameList);
ncParamAdjNameList = unique(ncParamAdjNameList);

% retrieve the data
ncParamNameQcList = [];
wantedVars = [];
for idParam = 1:length(ncParamNameList)
   paramName = ncParamNameList{idParam};
   paramNameQc = [paramName '_QC'];
   ncParamNameQcList{end+1} = paramNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramName} ...
      {paramNameQc} ...
      ];
end
ncParamAdjNameQcList = [];
for idParam = 1:length(ncParamAdjNameList)
   paramAdjName = ncParamAdjNameList{idParam};
   paramAdjNameQc = [paramAdjName '_QC'];
   ncParamAdjNameQcList{end+1} = paramAdjNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramAdjName} ...
      {paramAdjNameQc} ...
      ];
end

[ncMonoProfData] = gl_get_data_from_nc_file(a_ncMonoProfPathFileName, wantedVars);

ncParamDataList = [];
ncParamDataQcList = [];
ncParamFillValueList = [];
for idParam = 1:length(ncParamNameList)
   paramName = ncParamNameList{idParam};
   paramNameData = lower(paramName);
   ncParamDataList{end+1} = paramNameData;
   paramNameQc = ncParamNameQcList{idParam};
   paramNameQcData = lower(paramNameQc);
   ncParamDataQcList{end+1} = paramNameQcData;
   paramInfo = gl_get_netcdf_param_attributes(paramName);
   ncParamFillValueList{end+1} = paramInfo.fillValue;
   
   data = gl_get_data_from_name(paramName, ncMonoProfData)';
   dataQc = gl_get_data_from_name(paramNameQc, ncMonoProfData)';
   
   eval([paramNameData ' = data;']);
   eval([paramNameQcData ' = dataQc;']);
end
ncParamAdjDataList = [];
ncParamAdjDataQcList = [];
ncParamAdjFillValueList = [];
for idParam = 1:length(ncParamAdjNameList)
   paramAdjName = ncParamAdjNameList{idParam};
   paramAdjNameData = lower(paramAdjName);
   ncParamAdjDataList{end+1} = paramAdjNameData;
   paramAdjNameQc = ncParamAdjNameQcList{idParam};
   paramAdjNameQcData = lower(paramAdjNameQc);
   ncParamAdjDataQcList{end+1} = paramAdjNameQcData;
   adjPos = strfind(paramAdjName, '_ADJUSTED');
   paramName = paramAdjName(1:adjPos-1);
   paramInfo = gl_get_netcdf_param_attributes(paramName);
   ncParamAdjFillValueList{end+1} = paramInfo.fillValue;
   
   data = gl_get_data_from_name(paramAdjName, ncMonoProfData)';
   dataQc = gl_get_data_from_name(paramAdjNameQc, ncMonoProfData)';
   
   eval([paramAdjNameData ' = data;']);
   eval([paramAdjNameQcData ' = dataQc;']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY RTQC TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

testDoneList = zeros(lastTestNum, length(juld));
testFailedList = zeros(lastTestNum, length(juld));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 8: pressure increasing test
%
if (testFlagList(8) == 1)
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2

      switch idLoop
         case 1
            paramNamePres = 'PRES';
         case 2
            paramNamePres = 'PRES2';
         otherwise
            fprintf('RTQC_ERROR: TEST008: Too many loops\n');
            continue
      end

      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing

            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;

            % retrieve PRES data from the workspace
            idPres = find(strcmp(paramNamePres, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing

            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;

            % retrieve PRES adjusted data from the workspace
            idPres = find(strcmp([paramNamePres '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end

         if (~isempty(idPres))
            presData = eval(ncParamXDataList{idPres});
            presDataQc = eval(ncParamXDataQcList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};

            if (~isempty(presData))
               for idProf = 1:length(juld)
                  profPres = presData(idProf, :);
                  idNoDefPres = find(profPres ~= presDataFillValue);
                  profPres = profPres(idNoDefPres);
                  if (~isempty(profPres))

                     % initialize Qc flags
                     presDataQc(idProf, idNoDefPres) = gl_set_qc_str(presDataQc(idProf, idNoDefPres), g_decGl_qcStrGood);
                     eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                     testDoneList(8, idProf) = 1;

                     % apply the test
                     if (length(profPres) > 1)
                        % start algorithm from middle of the profile
                        idToFlag = [];
                        idStart = fix(length(profPres)/2);
                        pMin = profPres(idStart);
                        for id = idStart-1:-1:1
                           if (profPres(id) >= pMin)
                              idToFlag = [idToFlag id];
                           else
                              pMin = profPres(id);
                           end
                        end
                        pMax = profPres(idStart);
                        for id = idStart+1:length(profPres)
                           if (profPres(id) <= pMax)
                              idToFlag = [idToFlag id];
                           else
                              pMax = profPres(id);
                           end
                        end
                        if (~isempty(idToFlag))
                           presDataQc(idProf, idNoDefPres(idToFlag)) = gl_set_qc_str(presDataQc(idProf, idNoDefPres(idToFlag)), g_decGl_qcStrBad);
                           eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                           testFailedList(8, idProf) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 12: digit rollover test
%
if (testFlagList(12) == 1)
   
   % list of parameters concerned by the current test
   paramTestList = [ ...
      {'TEMP'} ...
      {'TEMP2'} ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      {'PSAL'} ...
      {'PSAL2'} ...
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      paramTestDiff = [ ...
         10; ... % TEMP
         10; ... % TEMP2
         10; ... % TEMP_DOXY
         10; ... % TEMP_DOXY2
         5; ... % PSAL
         5; ... % PSAL2
         ];
      
      for idP = 1:length(paramTestList)
         paramName = paramTestList{idP};
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         
         idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncParamXDataList{idParam});
            dataQc = eval(ncParamXDataQcList{idParam});
            paramFillValue = ncParamXFillValueList{idParam};
            
            if (~isempty(data))
               for idProf = 1:length(juld)
                  profData = data(idProf, :);
                  profDataQc = dataQc(idProf, :);
                  idDefOrBad = find((profData == paramFillValue) | ...
                     (profDataQc == g_decGl_qcStrBad));
                  idDefOrBad = [0 idDefOrBad length(profData)+1];
                  for idSlice = 1:length(idDefOrBad)-1
                     
                     % part of continuous measurements
                     idLevel = idDefOrBad(idSlice)+1:idDefOrBad(idSlice+1)-1;
                     
                     if (~isempty(idLevel))
                        
                        % initialize Qc flags
                        dataQc(idProf, idLevel) = gl_set_qc_str(dataQc(idProf, idLevel), g_decGl_qcStrGood);
                        eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                        testDoneList(12, idProf) = 1;
                        
                        % apply the test (we choose to set g_decGl_qcStrBad on
                        % the levels where jumps are detected and
                        % g_decGl_qcStrCorrectable on the remaining levels of
                        % the profile)
                        idToFlag = find(abs(diff(profData(idLevel))) > paramTestDiff(idP));
                        if (~isempty(idToFlag))
                           idToFlag = unique([idToFlag idToFlag+1]);
                           dataQc(idProf, idLevel) = gl_set_qc_str(dataQc(idProf, idLevel), g_decGl_qcStrCorrectable);
                           dataQc(idProf, idLevel(idToFlag)) = gl_set_qc_str(dataQc(idProf, idLevel(idToFlag)), g_decGl_qcStrBad);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testFailedList(12, idProf) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 13: stuck value test
%
if (testFlagList(13) == 1)
   
   % list of parameters managed by RTQC
   rtqcParameterList = [ ...
      {'PRES'} ...
      {'PRES2'} ...
      {'TEMP'} ...
      {'TEMP2'} ...
      {'PSAL'} ...
      {'PSAL2'} ...
      {'CNDC'} ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'CHLA'} ...
      {'CHLA2'} ...
      {'BBP700'} ...
      {'BBP532'} ...
      {'PH_IN_SITU_TOTAL'} ...
      {'NITRATE'} ...
      {'DOWN_IRRADIANCE380'} ...
      {'DOWN_IRRADIANCE412'} ...
      {'DOWN_IRRADIANCE443'} ...
      {'DOWN_IRRADIANCE490'} ...
      {'DOWN_IRRADIANCE532'} ...
      {'DOWN_IRRADIANCE555'} ...
      {'DOWNWELLING_PAR'} ...
      ];   
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      for idP = 1:length(rtqcParameterList)
         paramName = rtqcParameterList{idP};
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         
         idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncParamXDataList{idParam});
            dataQc = eval(ncParamXDataQcList{idParam});
            paramFillValue = ncParamXFillValueList{idParam};
            
            if (~isempty(data))
               for idProf = 1:length(juld)
                  profData = data(idProf, :);
                  idNoDef = find(profData ~= paramFillValue);
                  profData = profData(idNoDef);
                  
                  % initialize Qc flags
                  dataQc(idProf, idNoDef) = gl_set_qc_str(dataQc(idProf, idNoDef), g_decGl_qcStrGood);
                  eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                  testDoneList(13, idProf) = 1;
                  
                  % apply the test
                  uProfData = unique(profData);
                  if ((length(idNoDef) > 1) && (length(uProfData) == 1))
                     dataQc(idProf, idNoDef) = gl_set_qc_str(dataQc(idProf, idNoDef), g_decGl_qcStrBad);
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                     testFailedList(13, idProf) = 1;
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 14: density inversion test
%
if (testFlagList(14) == 1)
   
   VERBOSE = 0;

   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2
      
      switch idLoop
         case 1
            paramNamePres = 'PRES';
            paramNameTemp = 'TEMP';
            paramNamePsal = 'PSAL';
         case 2
            paramNamePres = 'PRES2';
            paramNameTemp = 'TEMP2';
            paramNamePsal = 'PSAL2';
         otherwise
            fprintf('RTQC_ERROR: TEST014: Too many loops\n');
            continue
      end

      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing

            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;

            % retrieve PRES, TEMP and PSAL data from the workspace
            idPres = find(strcmp(paramNamePres, ncParamXNameList) == 1, 1);
            idTemp = find(strcmp(paramNameTemp, ncParamXNameList) == 1, 1);
            idPsal = find(strcmp(paramNamePsal, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing

            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;

            % retrieve PRES, TEMP and PSAL adjusted data from the workspace
            idPres = find(strcmp([paramNamePres '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idTemp = find(strcmp([paramNameTemp '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idPsal = find(strcmp([paramNamePsal '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end

         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))

            presData = eval(ncParamXDataList{idPres});
            presDataQc = eval(ncParamXDataQcList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};

            tempData = eval(ncParamXDataList{idTemp});
            tempDataQc = eval(ncParamXDataQcList{idTemp});
            tempDataFillValue = ncParamXFillValueList{idTemp};

            psalData = eval(ncParamXDataList{idPsal});
            psalDataQc = eval(ncParamXDataQcList{idPsal});
            psalDataFillValue = ncParamXFillValueList{idPsal};

            if (~isempty(presData) && ~isempty(tempData) && ~isempty(psalData))

               for idProf = 1:length(juld)

                  profPres = presData(idProf, :);
                  profPresQc = presDataQc(idProf, :);
                  profTemp = tempData(idProf, :);
                  profTempQc = tempDataQc(idProf, :);
                  profPsal = psalData(idProf, :);
                  profPsalQc = psalDataQc(idProf, :);

                  % initialize Qc flags
                  idNoDefTemp = find(profTemp ~= tempDataFillValue);
                  tempDataQc(idProf, idNoDefTemp) = gl_set_qc_str(tempDataQc(idProf, idNoDefTemp), g_decGl_qcStrGood);
                  eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);

                  idNoDefPsal = find(profPsal ~= psalDataFillValue);
                  psalDataQc(idProf, idNoDefPsal) = gl_set_qc_str(psalDataQc(idProf, idNoDefPsal), g_decGl_qcStrGood);
                  eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);

                  testDoneList(14, idProf) = 1;

                  idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                     (profPresQc ~= g_decGl_qcStrBad) & ...
                     (profTemp ~= tempDataFillValue) & ...
                     (profTempQc ~= g_decGl_qcStrBad) & ...
                     (profPsal ~= psalDataFillValue) & ...
                     (profPsalQc ~= g_decGl_qcStrBad));
                  profPres = profPres(idNoDefAndGood);
                  profTemp = profTemp(idNoDefAndGood);
                  profPsal = profPsal(idNoDefAndGood);

                  % apply the test

                  % top to bottom check (the shallow level should be flagged)
                  profPresRef = (profPres(1:end-1)+profPres(2:end))/2;

                  sigmaShallow = potential_density_gsw(profPres(1:end-1), profTemp(1:end-1), profPsal(1:end-1), profPresRef, longitude(idProf), latitude(idProf))';
                  sigmaDeep = potential_density_gsw(profPres(2:end), profTemp(2:end), profPsal(2:end), profPresRef, longitude(idProf), latitude(idProf))';

                  idToFlag = find((sigmaShallow - sigmaDeep) >= 0.03);

                  % bottom to top check (the deep level should be flagged => add one
                  % to the dected ids)
                  idToFlag = sort(unique([idToFlag; find((sigmaDeep - sigmaShallow) <= -0.03) + 1]));

                  if (VERBOSE == 1)
                     for id = 1:length(idToFlag)
                        if (idD == 1)
                           fprintf('Density inversion detected: PRES %.1f TEMP %.3f PSAL %.3f\n', ...
                              profPres(idToFlag(id)), ...
                              profTemp(idToFlag(id)), ...
                              profPsal(idToFlag(id)));
                        else
                           fprintf('Density inversion detected: PRES_ADJUSTED %.1f TEMP_ADJUSTED %.3f PSAL_ADJUSTED %.3f\n', ...
                              profPres(idToFlag(id)), ...
                              profTemp(idToFlag(id)), ...
                              profPsal(idToFlag(id)));
                        end
                     end
                  end

                  if (~isempty(idToFlag))

                     tempDataQc(idProf, idNoDefAndGood(idToFlag)) = gl_set_qc_str(tempDataQc(idProf, idNoDefAndGood(idToFlag)), g_decGl_qcStrBad);
                     eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);

                     psalDataQc(idProf, idNoDefAndGood(idToFlag)) = gl_set_qc_str(psalDataQc(idProf, idNoDefAndGood(idToFlag)), g_decGl_qcStrBad);
                     eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);

                     testFailedList(14, idProf) = 1;
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE THE REPORT HEX VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the report hex values
testDoneHex = repmat({''}, length(juld), 1);
testFailedHex = repmat({''}, length(juld), 1);
for idProf = 1:length(juld)
   testDoneHex{idProf} = gl_compute_qctest_hex(find(testDoneList(:, idProf) == 1));
   testFailedHex{idProf} = gl_compute_qctest_hex(find(testFailedList(:, idProf) == 1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE THE NETCDF FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory to store temporary files
[monoProfInputPath, ~, ~] = fileparts(a_ncMonoProfPathFileName);
DIR_TMP_FILE = [monoProfInputPath '/tmp/'];

% delete the temp directory
gl_remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the input mono profile file to be updated
[~, fileName, fileExtension] = fileparts(a_ncMonoProfPathFileName);
tmpNcMonoProfOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
copyfile(a_ncMonoProfPathFileName, tmpNcMonoProfOutputPathFileName);

% create the list of data Qc to store in the NetCDF mono profile files
dataQcList = [ ...
   {'JULD_QC'} {juldQc} ...
   {'POSITION_QC'} {positionQc} ...
   ];
for idParam = 1:length(ncParamNameList)
   dataQcList = [dataQcList ...
      {upper(ncParamDataQcList{idParam})} {eval(ncParamDataQcList{idParam})} ...
      ];
end
for idParam = 1:length(ncParamAdjNameList)
   dataQcList = [dataQcList ...
      {upper(ncParamAdjDataQcList{idParam})} {eval(ncParamAdjDataQcList{idParam})} ...
      ];
end

% create the list of data to store in the NetCDF mono profile files
dataList = [];
for idParam = 1:length(ncParamAdjNameList)
   dataList = [dataList ...
      {upper(ncParamAdjDataList{idParam})} {eval(ncParamAdjDataList{idParam})} ...
      ];
end

% update the input file
[ok] = nc_update_file(tmpNcMonoProfOutputPathFileName, ...
   dataQcList, testDoneHex, testFailedHex);

if (ok == 1)
   
   % if the update succeeded move the file in the output directory
   [monoProfOutputPath, ~, ~] = fileparts(a_ncMonoProfPathFileName);
   [~, fileName, fileExtension] = fileparts(tmpNcMonoProfOutputPathFileName);
   movefile(tmpNcMonoProfOutputPathFileName, [monoProfOutputPath '/' fileName fileExtension]);
end

% delete the temp directory
gl_remove_directory(DIR_TMP_FILE);

clear variables;

return

% ------------------------------------------------------------------------------
% Update NetCDF profile file after RTQC has been performed.
%
% SYNTAX :
%  [o_ok] = nc_update_file(a_monoFileName, a_dataQc, a_testDoneHex, a_testFailedHex)
%
% INPUT PARAMETERS :
%   a_monoFileName  : profile file path name to update
%   a_dataQc        : QC data to store in the profile file
%   a_testDoneHex   : HEX code of test performed on profile file data
%   a_testFailedHex : HEX code of test failed on profile file data
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
%   04/11/2016 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function [o_ok] = nc_update_file(a_monoFileName, a_dataQc, a_testDoneHex, a_testFailedHex)

% output parameters initialization
o_ok = 0;

% program version
global g_decGl_rtqcVersion;

% QC flag values
global g_decGl_qcStrDef;           % ' '
global g_decGl_qcStrNoQc;          % '0'
global g_decGl_qcStrGood;          % '1'
global g_decGl_qcStrProbablyGood;  % '2'
global g_decGl_qcStrCorrectable;   % '3'
global g_decGl_qcStrBad;           % '4'
global g_decGl_qcStrChanged;       % '5'
global g_decGl_qcStrInterpolated;  % '8'
global g_decGl_qcStrMissing;       % '9'


% date of the file update
dateUpdate = datestr(gl_now_utc, 'yyyymmddHHMMSS');

% update the mono profile file

% retrieve data from profile file
wantedVars = [ ...
   {'DATE_CREATION'} ...
   {'PRES'} ...
   {'DATA_STATE_INDICATOR'} ...
   {'HISTORY_ACTION'} ...
   {'HISTORY_QCTEST'} ...
   ];
[ncProfData] = gl_get_data_from_nc_file(a_monoFileName, wantedVars);

% retrieve the N_LEVELS dimension
pres = gl_get_data_from_name('PRES', ncProfData);
nLevels = size(pres, 1);

% open the file to update
fCdf = netcdf.open(a_monoFileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', a_monoFileName);
   return
end

% update <PARAM>_QC and PROFILE_<PARAM>_QC values
for idParamQc = 1:2:length(a_dataQc)
   paramQcName = a_dataQc{idParamQc};
   if (gl_var_is_present(fCdf, paramQcName))
      
      % <PARAM>_QC values
      dataQc = a_dataQc{idParamQc+1};
      if (strcmp(paramQcName, 'JULD_QC') || strcmp(paramQcName, 'POSITION_QC'))
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), dataQc');
      else
         if (size(dataQc, 2) > nLevels)
            dataQc = dataQc(:, 1:nLevels);
         end
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), dataQc');
         
         % PROFILE_<PARAM>_QC values
         % the <PARAM>_ADJUSTED_QC values are after the <PARAM>_QC values in
         % the a_dataQc list. So, if <PARAM>_ADJUSTED_QC values differ from
         % FillValue, they will be used to compute PROFILE_<PARAM>_QC values.
         profParamQcName = ['PROFILE_' paramQcName];
         if (gl_var_is_present(fCdf, profParamQcName))
            % compute PROFILE_<PARAM>_QC from <PARAM>_QC values
            newProfParamQc = repmat(g_decGl_qcStrDef, 1, size(dataQc, 1));
            for idProf = 1:size(dataQc, 1)
               newProfParamQc(idProf) = gl_compute_profile_quality_flag(dataQc(idProf, :));
            end
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), newProfParamQc);
         else
            if (~isempty(strfind(paramQcName, '_ADJUSTED_QC')))
               if ~((length(unique(dataQc)) == 1) && (unique(dataQc) == g_decGl_qcStrDef))
                  profParamQcName = ['PROFILE_' regexprep(paramQcName, '_ADJUSTED', '')];
                  if (gl_var_is_present(fCdf, profParamQcName))
                     % compute PROFILE_<PARAM>_QC from <PARAM>_ADJUSTED_QC values
                     newProfParamQc = repmat(g_decGl_qcStrDef, 1, size(dataQc, 1));
                     for idProf = 1:size(dataQc, 1)
                        newProfParamQc(idProf) = gl_compute_profile_quality_flag(dataQc(idProf, :));
                     end
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), newProfParamQc);
                  end
               end
            end
         end
      end
   end
end

% update miscellaneous information

% retrieve the creation date of the file
dateCreation = gl_get_data_from_name('DATE_CREATION', ncProfData)';
if (isempty(deblank(dateCreation)))
   dateCreation = dateUpdate;
end

% set the 'history' global attribute
netcdf.reDef(fCdf);
globalVarId = netcdf.getConstant('NC_GLOBAL');
globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
globalHistoryText = [globalHistoryText ...
   datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COQC software)'];
netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
netcdf.endDef(fCdf);

% upate date
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);

% data state indicator
dataStateIndicator = gl_get_data_from_name('DATA_STATE_INDICATOR', ncProfData)';
nProf = size(dataStateIndicator, 1);
profIdList = [];
newDataStateIndicator = '2B';
for idProf = 1:nProf
   if (~isempty(deblank(dataStateIndicator(idProf, :))))
      dataStateIndicator(idProf, 1:length(newDataStateIndicator)) = newDataStateIndicator;
      profIdList = [profIdList idProf];
   end
end
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_STATE_INDICATOR'), dataStateIndicator');

% update history information (inputs should be add to existing reports)
historyAction = gl_get_data_from_name('HISTORY_ACTION', ncProfData);
historyQcTest = gl_get_data_from_name('HISTORY_QCTEST', ncProfData);
[~, nProf, nHistory] = size(historyAction);
for idP = 1:nProf
   for idH = 1:nHistory
      if (strcmp(strtrim(historyAction(:, idP, idH)'), 'QCP$'))
         currentTestDone = historyQcTest(:, idP, idH)';
         oldTestDone = a_testDoneHex{profIdList(idP)};
         newTestDoneHex = '';
         for id = 1:2:length(currentTestDone)
            current = currentTestDone(id:id+1);
            old = oldTestDone(id:id+1);
            newTestDoneHex = [newTestDoneHex dec2hex(bitor(hex2dec(current), hex2dec(old)), 2)];
         end
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
            fliplr([idH-1 idP-1 0]), ...
            fliplr([1 1 length(newTestDoneHex)]), newTestDoneHex);
      end
      if (strcmp(strtrim(historyAction(:, idP, idH)'), 'QCF$'))
         currentTestFailed = historyQcTest(:, idP, idH)';
         oldTestFailed = a_testFailedHex{profIdList(idP)};
         newTestFailedHex = '';
         for id = 1:2:length(currentTestFailed)
            current = currentTestFailed(id:id+1);
            old = oldTestFailed(id:id+1);
            newTestFailedHex = [newTestFailedHex dec2hex(bitor(hex2dec(current), hex2dec(old)), 2)];
         end
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
            fliplr([idH-1 idP-1 0]), ...
            fliplr([1 1 length(newTestFailedHex)]), newTestFailedHex);
      end
   end
end

% % update history information
% historyInstitution = gl_get_data_from_name('HISTORY_INSTITUTION', ncProfData);
% [~, ~, nHistory] = size(historyInstitution);
% histoInstitution = 'IF';
% histoStep = 'ARGQ';
% histoSoftware = 'COQC';
% histoSoftwareRelease = g_decGl_rtqcVersion;
% 
% for idHisto = 1:2
%    if (idHisto == 1)
%       histoAction = 'QCP$';
%    else
%       nHistory = nHistory + 1;
%       histoAction = 'QCF$';
%    end
%    for idProf = 1:length(profIdList)
%       if (idHisto == 1)
%          histoQcTest = a_testDoneHex{profIdList(idProf)};
%       else
%          histoQcTest = a_testFailedHex{profIdList(idProf)};
%       end
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(histoInstitution)]), histoInstitution');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(histoStep)]), histoStep');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(histoSoftware)]), histoSoftware');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(histoSoftwareRelease)]), histoSoftwareRelease');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(dateUpdate)]), dateUpdate');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(dateUpdate)]), dateUpdate');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(histoAction)]), histoAction');
%       netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
%          fliplr([nHistory profIdList(idProf)-1 0]), ...
%          fliplr([1 1 length(histoQcTest)]), histoQcTest');
%    end
% end

netcdf.close(fCdf);

o_ok = 1;

return
