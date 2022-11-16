% ------------------------------------------------------------------------------
% Generate NetCDF Argo profile files from an EGO netCDF file.
% 
% SYNTAX :
%  [o_generatedFiles] = gl_generate_prof(a_ncEgoFileName, a_outputDirName, ...
%    a_applyRtqc, a_testDoneList, a_testFailedList)
% 
% INPUT PARAMETERS :
%   a_ncEgoFileName  : EGO netCDF file path name
%   a_outputDirName  : directory of the generated NetCDF files
%   a_applyRtqc      : RTQC tests have been applied on input EGO file data
%   a_testDoneList   : test performed report variable
%   a_testFailedList : test failed report variable
% 
% OUTPUT PARAMETERS :
%   o_generatedFiles : list of generated profile file path names
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/11/2013 - RNU - creation
%   04/17/2015 - RNU - for Slocum gliders: as the measurements are attached to
%                      the CTD levels, the original data set is reduced.
%                      Start and stop indexes of each profile should take this
%                      reduction into account.
% ------------------------------------------------------------------------------
function [o_generatedFiles] = gl_generate_prof(a_ncEgoFileName, a_outputDirName, ...
   a_applyRtqc, a_testDoneList, a_testFailedList)

o_generatedFiles = [];

% type of the glider to process
global g_decGl_gliderType;

% QC flag values
global g_decGl_qcDef;
global g_decGl_qcNoQc;
global g_decGl_qcGood;
global g_decGl_qcProbablyGood;
global g_decGl_qcCorrectable;
global g_decGl_qcBad;
global g_decGl_qcChanged;
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;

% global configuration values
global g_decGl_rtqcTest4;
global g_decGl_rtqcTest20;
global g_decGl_rtqcGebcoFile;

% phase codes
CODE_DESCENT = int8(1);
CODE_ASCENT = int8(4);


% check if the file exists
if (~exist(a_ncEgoFileName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_ncEgoFileName);
   return
end

% open NetCDF file
fCdf = netcdf.open(a_ncEgoFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncEgoFileName);
   return
end

% retrieve PHASE data
if (gl_var_is_present(fCdf, 'PHASE'))
   phaseData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE'));
else
   fprintf('ERROR: Variable %s not present in file : %s\n', ...
      'PHASE', a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end

% retrieve PHASE_NUMBER data
if (gl_var_is_present(fCdf, 'PHASE_NUMBER'))
   phaseNumData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PHASE_NUMBER'));
else
   fprintf('ERROR: Variable %s not present in file : %s\n', ...
      'PHASE_NUMBER', a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end

% compute JULD from TIME
paramJuldName = 'JULD';
paramJuldDef = [];
paramJuldData = [];
paramDef = gl_get_netcdf_param_attributes(paramJuldName);
if (~isempty(paramDef))
   if (gl_var_is_present(fCdf, 'TIME'))
      paramTimeDef = gl_get_netcdf_param_attributes('TIME');
      paramTimeData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
      
      paramJuldDef = paramDef;
      paramJuldData = ones(size(paramTimeData))*paramDef.fillValue;
      epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      idNodef = find(paramTimeData ~= paramTimeDef.fillValue);
      paramJuldData(idNodef) = paramTimeData(idNodef)/86400 + epoch_offset;
   else
      fprintf('WARNING: Variable %s not present in file : %s\n', ...
         'TIME', a_ncEgoFileName);
   end
end

% retrieve the parameter measurements
if (gl_var_is_present(fCdf, 'PARAMETER'))
   param = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER'))';
else
   % in previous version of EGO file PARAMETER list is stored in SENSOR variable
   % also needed to process SOCIB EGO files
   if (gl_var_is_present(fCdf, 'SENSOR'))
      param = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR'))';
   else
      fprintf('ERROR: Variable %s not present in file : %s\n', ...
         'PARAMETER', a_ncEgoFileName);
      netcdf.close(fCdf);
      return
   end
end

tabParamName = [];
tabParamDef = [];
tabParamData = [];
tabParamQcData = [];
tabParamDataAdj = [];
tabParamQcDataAdj = [];
for idParam = 1:size(param, 1)
   paramName = strtrim(param(idParam, :));
   paramDef = gl_get_netcdf_param_attributes(paramName);
   if (~isempty(paramDef))
      if (gl_var_is_present(fCdf, paramName))
         tabParamName{end+1} = paramName;
         tabParamDef = [tabParamDef paramDef];
         
         paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramName));
         fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramName), '_FillValue');
         paramData(find(paramData == fillVal)) = paramDef.fillValue;
         tabParamData = [tabParamData paramData];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            paramName, a_ncEgoFileName);
         continue
      end
      paramQcName = [paramName '_QC'];
      if (gl_var_is_present(fCdf, paramQcName))
         paramByteQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramQcName));
         paramQcData = repmat(' ', size(paramByteQcData, 1), 1);
         fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramQcName), '_FillValue');
         paramQcData(find(paramByteQcData ~= fillVal)) = num2str(paramByteQcData(find(paramByteQcData ~= fillVal)));
         tabParamQcData = [tabParamQcData paramQcData];
      else
         fprintf('ERROR: Variable %s not present in file : %s\n', ...
            paramQcName, a_ncEgoFileName);
         continue
      end
      paramNameAdj = [paramName '_ADJUSTED'];
      if (gl_var_is_present(fCdf, paramNameAdj))
         paramDataAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramNameAdj));
         fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramNameAdj), '_FillValue');
         paramDataAdj(find(paramDataAdj == fillVal)) = paramDef.fillValue;
      else
         paramDataAdj = ones(size(paramData))*paramDef.fillValue;
      end
      tabParamDataAdj = [tabParamDataAdj paramDataAdj];
      paramQcNameAdj = [paramName '_ADJUSTED_QC'];
      if (gl_var_is_present(fCdf, paramQcNameAdj))
         paramByteQcDataAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramQcNameAdj));
         paramQcDataAdj = repmat(' ', size(paramByteQcDataAdj, 1), 1);
         fillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramQcNameAdj), '_FillValue');
         paramQcDataAdj(find(paramByteQcDataAdj ~= fillVal)) = num2str(paramByteQcDataAdj(find(paramByteQcDataAdj ~= fillVal)));
      else
         paramQcDataAdj = repmat(' ', size(paramQcData, 1), 1);
      end
      tabParamQcDataAdj = [tabParamQcDataAdj paramQcDataAdj];
   end
end

% assign a location to each parameter measurement
tabRefPosDate = [];
tabRefPosDateQc = [];
tabRefPosLon = [];
tabRefPosLat = [];
tabRefPosQc = [];
tabMeasPosDate = [];
tabMeasPosDateQc = [];
if (gl_var_is_present(fCdf, 'TIME_GPS'))
   tabRefPosDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'));
   tabRefPosDateQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS_QC'));
   tabRefPosLon = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'));
   tabRefPosLat = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'));
   tabRefPosQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_GPS_QC'));
end
if (gl_var_is_present(fCdf, 'TIME'))
   tabMeasPosDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
   tabMeasPosDateQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_QC'));

   tabRefPosDate = [tabRefPosDate; tabMeasPosDate];
   tabRefPosDateQc = [tabRefPosDateQc; tabMeasPosDateQc];
   tabRefPosLon = [tabRefPosLon; netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'))];
   tabRefPosLat = [tabRefPosLat; netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'))];
   tabRefPosQc = [tabRefPosQc; netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'))];
end
[tabRefPosDate, idUnique, ~] = unique(tabRefPosDate);
tabRefPosDateQc = tabRefPosDateQc(idUnique);
tabRefPosLon = tabRefPosLon(idUnique);
tabRefPosLat = tabRefPosLat(idUnique);
tabRefPosQc = tabRefPosQc(idUnique);

% interpolate the GPS fixes along the TIME dimension
dateFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'), '_FillValue');
lonFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'), '_FillValue');
latFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'), '_FillValue');

tabMeasPosLon = ones(size(tabMeasPosDate))*lonFillVal;
tabMeasPosLat = ones(size(tabMeasPosDate))*latFillVal;
if (~isempty(tabRefPosLon))
   
   if (a_applyRtqc == 1)
      idOk = find((tabRefPosDate ~= dateFillVal) & (tabRefPosDateQc == g_decGl_qcGood) & ...
         (tabRefPosLon ~= lonFillVal) & (tabRefPosLat ~= latFillVal) & (tabRefPosQc == g_decGl_qcGood));
   else
      idOk = find((tabRefPosDate ~= dateFillVal) & ...
         (tabRefPosLon ~= lonFillVal) & (tabRefPosLat ~= latFillVal));
   end
   
   tabRefPosDate = tabRefPosDate(idOk);
   tabRefPosLon = tabRefPosLon(idOk);
   tabRefPosLat = tabRefPosLat(idOk);
   
   [tabRefPosDate, idSort] = sort(tabRefPosDate);
   tabRefPosLon = tabRefPosLon(idSort);
   tabRefPosLat = tabRefPosLat(idSort);
      
   if (length(tabRefPosLon) > 1)
      if (a_applyRtqc == 1)
         idDateOk = find((tabMeasPosDate ~= dateFillVal) & (tabMeasPosDateQc == g_decGl_qcGood));
      else
         idDateOk = find(tabMeasPosDate ~= dateFillVal);
      end
      tabMeasPosLon(idDateOk) = interp1q(tabRefPosDate, tabRefPosLon, tabMeasPosDate(idDateOk));
      tabMeasPosLat(idDateOk) = interp1q(tabRefPosDate, tabRefPosLat, tabMeasPosDate(idDateOk));
      
      tabMeasPosLon(find(isnan(tabMeasPosLon))) = lonFillVal;
      tabMeasPosLat(find(isnan(tabMeasPosLat))) = latFillVal;
   end
end

% compute position QC for these interpolated locations
tabMeasPosQc = int8(ones(size(tabMeasPosDate)))*g_decGl_qcMissing;
idOk = find((tabMeasPosLon ~= lonFillVal) & (tabMeasPosLat ~= latFillVal));
tabMeasPosQc(idOk) = g_decGl_qcNoQc;

if (a_applyRtqc == 1)
   
   if (g_decGl_rtqcTest4 == 1)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TEST 4: position on land test
      
      if ~(exist(g_decGl_rtqcGebcoFile, 'file') == 2)
         fprintf('RTQC_ERROR: TEST004: GEBCO file (%s) not found => test #4 not performed\n', ...
            g_decGl_rtqcGebcoFile);
      else
         
         idToCheck = idOk;
         
         % initialize Qc flag
         tabMeasPosQc(idToCheck) = gl_set_qc(tabMeasPosQc(idToCheck), g_decGl_qcGood);
         
         % retrieve GEBCO elevations
         [elev] = gl_get_gebco_elev_point(tabMeasPosLon(idToCheck), tabMeasPosLat(idToCheck), g_decGl_rtqcGebcoFile);
         
         % apply the test
         idToFlag = [];
         for idP = 1:length(idToCheck)
            elevation = elev(idP, :);
            elevation(find(isnan(elevation))) = [];
            if (mean(elevation) >= 0)
               idToFlag = [idToFlag idP];
            end
         end
         
         if (~isempty(idToFlag))
            tabMeasPosQc(idToCheck(idToFlag)) = gl_set_qc(tabMeasPosQc(idToCheck(idToFlag)), g_decGl_qcBad);
         end
      end
   end

   if (g_decGl_rtqcTest20 == 1)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TEST 20: questionable Argos position test
      
      idToCheck = find( ...
         (tabMeasPosLat ~= latFillVal) & ...
         (tabMeasPosLon ~= lonFillVal) & ...
         (tabMeasPosQc == g_decGl_qcGood) & ...
         (tabMeasPosDate ~= dateFillVal) & ...
         (tabMeasPosDateQc == g_decGl_qcGood));
      
      % initialize Qc flag
      tabMeasPosQc(idToCheck) = gl_set_qc(tabMeasPosQc(idToCheck), g_decGl_qcGood);
      
      % no need to apply the test since:
      % - the base surface positions used for interpolation have already
      %   succeeded test #20
      % - we didn't extrapolate subsurface trajectory
      
      %    % compute juld measurements
      %    juldMeas = tabMeasPosDate(idToCheck);
      %    epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      %    juldMeas = juldMeas/86400 + epoch_offset;
      %
      %    % apply the test
      %    [idToFlag] = gl_check_subsurface_speed( ...
      %       juldMeas, ...
      %       tabMeasPosLon(idToCheck), ...
      %       tabMeasPosLat(idToCheck), ...
      %       tabRefPosDate, ...
      %       tabRefPosLon, ...
      %       tabRefPosLat);
      %
      %    if (~isempty(idToFlag))
      %       tabMeasPosQc(idToCheck(idToFlag)) = gl_set_qc(tabMeasPosQc(idToCheck(idToFlag)), g_decGl_qcBad);
      %    end
   end
end

% for the slocum and seaglider gliders, we attach all the parameter measurements
% to the bin levels of the CTD
ctdLevels = [];
testDoneList = a_testDoneList;
testFailedList = a_testFailedList;
if (strcmpi(g_decGl_gliderType, 'slocum') || strcmpi(g_decGl_gliderType, 'seaglider'))
   % retrieve the time of the sensors
   if (gl_var_is_present(fCdf, 'TIME'))
      time = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));

      % retrieve the CTD measurement levels
      if (gl_var_is_present(fCdf, 'PRES') && gl_var_is_present(fCdf, 'TEMP') && gl_var_is_present(fCdf, 'CNDC'))
         pres = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
         presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
         temp = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP'));
         tempFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TEMP'), '_FillValue');
         cndc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CNDC'));
         cndcFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'CNDC'), '_FillValue');
         ctdLevels = find((pres ~= presFillVal) & (temp ~= tempFillVal) & (cndc ~= cndcFillVal));
      elseif (gl_var_is_present(fCdf, 'PRES') && gl_var_is_present(fCdf, 'TEMP') && gl_var_is_present(fCdf, 'PSAL'))
         pres = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
         presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
         temp = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP'));
         tempFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TEMP'), '_FillValue');
         psal = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL'));
         psalFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PSAL'), '_FillValue');
         ctdLevels = find((pres ~= presFillVal) & (temp ~= tempFillVal) & (psal ~= psalFillVal));
      end
      
      if (~isempty(ctdLevels))

         % process each sensor measurements
         for idParam = 1:length(tabParamName)
            paramName = tabParamName{idParam};

            if (~strcmp(paramName, 'PRES'))
               data = tabParamData(:, idParam);
               dataQc = tabParamQcData(:, idParam);
               dataAdj = tabParamDataAdj(:, idParam);
               dataAdjQc = tabParamQcDataAdj(:, idParam);
               dataFillVal = tabParamDef(idParam).fillValue;
               if (any(data(ctdLevels) == dataFillVal))
                  timeData = time;
                  idDel = find(data == dataFillVal);
                  timeData(idDel) = [];
                  data(idDel) = [];
                  dataQc(idDel) = [];
                  dataAdj(idDel) = [];
                  dataAdjQc(idDel) = [];
                  
                  % times of all measurements with index of CTD levels in
                  % column 2 (or '0' otherwise)
                  time2 = cat(2, time, zeros(size(time)));
                  time2(ctdLevels, 2) = ctdLevels*-1;
                  
                  % times of data measurements with '1' in column 2
                  time3 = cat(2, timeData, ones(size(timeData)));
                  
                  % concat and timely sort
                  time4 = cat(1, time2, time3);
                  [~, idSort] = sort(time4(:, 1));
                  time4 = time4(idSort, :);
                  
                  %                   for id = 2500:2600
                  %                      fprintf('%d: %s %d\n', ...
                  %                         id, ...
                  %                         gl_julian_2_gregorian(gl_epoch_2_julian(time4(id, 1))), ...
                  %                         time4(id, 2));
                  %                   end
                  usedLevel = zeros(length(time), 1);
                  timeDiff = ones(length(time), 1)*-1;
                  dataNew = ones(length(time), 1)*dataFillVal;
                  dataQcNew = repmat(' ', length(time), 1);
                  dataAdjNew = ones(length(time), 1)*dataFillVal;
                  dataAdjQcNew = repmat(' ', length(time), 1);
                  
                  % process all data times
                  dataIdList = find(time4(:, 2) == 1);
                  for idData = 1:length(dataIdList)
                     dataId = dataIdList(idData);
                     
                     % find the timely closest CTD bin to assign the measurement
                     idF1 = '';
                     nb = 1;
                     while ((dataId-nb >= 1) && (time4(dataId-nb, 2) >= 0))
                        nb = nb + 1;
                     end
                     if ((dataId-nb >= 1) && (time4(dataId-nb, 2) < 0))
                        idF1 = dataId - nb;
                     end
                     idF2 = '';
                     nb = 1;
                     while ((dataId+nb <= size(time4, 1)) && (time4(dataId+nb, 2) >= 0))
                        nb = nb + 1;
                     end
                     if ((dataId+nb <= size(time4, 1)) && (time4(dataId+nb, 2) < 0))
                        idF2 = dataId + nb;
                     end
                     if (~isempty(idF1) && ~isempty(idF2))
                        if (idF1 == idF2)
                           idMin = idF1;
                        else
                           if (abs(time4(idF1, 1) - time4(dataId, 1)) < ...
                                 abs(time4(idF2, 1) - time4(dataId, 1)))
                              idMin = idF1;
                           else
                              idMin = idF2;
                           end
                        end
                     elseif (~isempty(idF1))
                        idMin = idF1;
                     elseif (~isempty(idF2))
                        idMin = idF2;
                     end
                     minVal = abs(time4(idMin, 1) - time4(dataId, 1));
                     if (usedLevel(time4(idMin, 2)*-1) == 0)
                        dataNew(time4(idMin, 2)*-1) = data(idData);
                        dataQcNew(time4(idMin, 2)*-1) = dataQc(idData);
                        dataAdjNew(time4(idMin, 2)*-1) = dataAdj(idData);
                        dataAdjQcNew(time4(idMin, 2)*-1) = dataAdjQc(idData);
                        usedLevel(time4(idMin, 2)*-1) = 1;
                        timeDiff(time4(idMin, 2)*-1) = minVal;
                     else
                        if (timeDiff(time4(idMin, 2)*-1) > minVal)
                           dataNew(time4(idMin, 2)*-1) = data(idData);
                           dataQcNew(time4(idMin, 2)*-1) = dataQc(idData);
                           dataAdjNew(time4(idMin, 2)*-1) = dataAdj(idData);
                           dataAdjQcNew(time4(idMin, 2)*-1) = dataAdjQc(idData);
                           timeDiff(time4(idMin, 2)*-1) = minVal;
                        end
                        %                         fprintf('WARNING: one %s measurement ignored during the CTD level assigment process of the Argo profile generation\n', ...
                        %                            paramName);
                     end
                  end
                  
                  % store the processed data
                  tabParamData(:, idParam) = dataNew;
                  tabParamQcData(:, idParam) = dataQcNew;
                  tabParamDataAdj(:, idParam) = dataAdjNew;
                  tabParamQcDataAdj(:, idParam) = dataAdjQcNew;
               end
            end
         end
         
         % delete the extrapolated pressure levels
         if (~isempty(tabParamData))
            tabParamData = tabParamData(ctdLevels, :);
            tabParamQcData = tabParamQcData(ctdLevels, :);
            tabParamDataAdj = tabParamDataAdj(ctdLevels, :);
            tabParamQcDataAdj = tabParamQcDataAdj(ctdLevels, :);
         end
         
         % for the TIME dimensionned other parameters also
         if (~isempty(phaseData))
            phaseData = phaseData(ctdLevels);
            phaseNumData = phaseNumData(ctdLevels);
         end
         if (~isempty(paramJuldData))
            paramJuldData = paramJuldData(ctdLevels);
            tabMeasPosDate = tabMeasPosDate(ctdLevels);
            tabMeasPosDateQc = tabMeasPosDateQc(ctdLevels);
            tabMeasPosLon = tabMeasPosLon(ctdLevels);
            tabMeasPosLat = tabMeasPosLat(ctdLevels);
            tabMeasPosQc = tabMeasPosQc(ctdLevels);
         end
         
         if ((a_applyRtqc == 1) && (~isempty(testDoneList)))
            testDoneList = testDoneList(:, ctdLevels);
            testFailedList = testFailedList(:, ctdLevels);
         end
      end
   end
end

% abort if no profile can be generated
if (isempty(phaseNumData))
   fprintf('INFO: No profile to generate from EGO nc file : %s\n', ...
      a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end

% compute the indices of the profile measurements
tabStart = [];
tabStop = [];
tabDir = [];
idSplit = find(diff(phaseNumData) ~= 0);
idStart = 1;
for id = 1:length(idSplit)+1
   if (id <= length(idSplit))
      idStop = idSplit(id);
   else
      idStop = length(phaseData);
   end
   phase = unique(phaseData(idStart:idStop));
   if ((phase == CODE_DESCENT) || (phase == CODE_ASCENT))
      tabStart = [tabStart; idStart];
      tabStop = [tabStop; idStop];
      if (phase == CODE_DESCENT)
         tabDir = [tabDir 'D'];
      else
         tabDir = [tabDir 'A'];
      end
   end
   idStart = idStop + 1;
end

% abort if no profile can be generated
if (isempty(tabStart))
   fprintf('INFO: No profile to generate from EGO nc file : %s\n', ...
      a_ncEgoFileName);
   netcdf.close(fCdf);
   return
end

% store the profile data in structures
tabProfiles = [];
for idProf = 1:length(tabStart)

   idStart = tabStart(idProf);
   idStop = tabStop(idProf);
   
   measPosDate = [];
   measPosDateOnly = [];
   measPosQc = [];
   if (~isempty(tabMeasPosDate))
      
      measPosDate = tabMeasPosDate(idStart:idStop);
      measPosDateQc = tabMeasPosDateQc(idStart:idStop);
      measPosLon = tabMeasPosLon(idStart:idStop);
      measPosLat = tabMeasPosLat(idStart:idStop);
      measPosQc = tabMeasPosQc(idStart:idStop);
      
      dateFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'), '_FillValue');
      lonFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'), '_FillValue');
      latFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'), '_FillValue');
      
      measPosDateOnly = measPosDate;
      if (a_applyRtqc == 1)
         idDel = find((measPosDateOnly == dateFillVal) | (measPosDateQc ~= g_decGl_qcGood));
      else
         idDel = find(measPosDateOnly == dateFillVal);
      end
      measPosDateOnly(idDel) = [];
      
      offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      measPosDateOnly = measPosDateOnly/86400 + offset;
      
      if (a_applyRtqc == 1)
         idDel = find((measPosDate == dateFillVal) | (measPosDateQc ~= g_decGl_qcGood) | ...
            (measPosLon == lonFillVal) | (measPosLat == latFillVal) | (measPosQc ~= g_decGl_qcGood));
      else
         idDel = find((measPosDate == dateFillVal) | ...
            (measPosLon == lonFillVal) | (measPosLat == latFillVal));
      end
      
      measPosDate(idDel) = [];
      measPosLon(idDel) = [];
      measPosLat(idDel) = [];
      measPosQc(idDel) = [];
      
      offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      measPosDate = measPosDate/86400 + offset;
   end
   
   % create the profile structure
   profStruct = gl_get_profile_init_struct;
   
   % fill the structure
   profStruct.cycleNumber = idProf;
   profStruct.decodedProfileNumber = 1;
   profStruct.profileNumber = 1;
   profStruct.primarySamplingProfileFlag = 1;
   profStruct.phaseNumber = -1;
   profStruct.direction = tabDir(idProf);
   
   if (~isempty(measPosDateOnly))
      
      % profile date
      profStruct.date = mean(measPosDateOnly);
      if (a_applyRtqc == 1)
         profStruct.dateQc = num2str(g_decGl_qcGood);
      else
         profStruct.dateQc = num2str(g_decGl_qcNoQc);
      end

      % profile location
      if (~isempty(measPosDate))
         [~, minId] = min(abs(measPosDate-profStruct.date));
         profStruct.locationDate = measPosDate(minId);
         profStruct.locationLon = measPosLon(minId);
         profStruct.locationLat = measPosLat(minId);
         profStruct.locationQc = num2str(measPosQc(minId));
         profStruct.posSystem = 'GPS';
      end
   end
   
   % parameter definitions
   profStruct.paramList = tabParamDef;
   profStruct.dateList = paramJuldDef;
                  
   % parameter measurements
   profStruct.data = tabParamData(idStart:idStop, :);
   profStruct.dataQc = tabParamQcData(idStart:idStop, :);
   profStruct.dataAdj = tabParamDataAdj(idStart:idStop, :);
   profStruct.dataAdjQc = tabParamQcDataAdj(idStart:idStop, :);
   profStruct.dates = paramJuldData(idStart:idStop);
   
   % parameter data mode
   for idP = 1:length(profStruct.paramList)
      param = profStruct.paramList(idP);
      if (any(profStruct.dataAdj(:, idP) ~= param.fillValue))
         profStruct.paramDataMode(idP) = 'A';
      else
         profStruct.paramDataMode(idP) = 'R';
      end
   end
   
   % measurement dates
   dates = profStruct.dates;
   dates(find(dates == paramJuldDef.fillValue)) = [];
   profStruct.minMeasDate = min(dates);
   profStruct.maxMeasDate = max(dates);
   
   % RTQC test reports
   if ((a_applyRtqc == 1) && (~isempty(testDoneList)))
      profStruct.testDoneList = testDoneList(:, idStart:idStop);
      profStruct.testFailedList = testFailedList(:, idStart:idStop);
   end
   
   % retrieve and store additional meta-data
   tabMetaData = [];
   if (gl_att_is_present(fCdf, [], 'wmo_platform_code'))
      wmoPlatformCode = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'wmo_platform_code'));
      if (~isempty(wmoPlatformCode))
         if (length(wmoPlatformCode) > 8)
            fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
               'PLATFORM_NUMBER', wmoPlatformCode(1:8), ...
               'wmo_platform_code', wmoPlatformCode, ...
               a_ncEgoFileName);
            wmoPlatformCode = wmoPlatformCode(1:8);
         end
         tabMetaData = [tabMetaData {'PLATFORM_NUMBER'} {wmoPlatformCode}];
      end
   end
   if (gl_var_is_present(fCdf, 'PROJECT_NAME'))
      projectName = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PROJECT_NAME'))');
      if (~isempty(projectName))
         if (length(projectName) > 64)
            fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
               'PROJECT_NAME', projectName(1:64), ...
               'PROJECT_NAME', projectName, ...
               a_ncEgoFileName);
            projectName = projectName(1:64);
         end
         tabMetaData = [tabMetaData {'PROJECT_NAME'} {projectName}];
      end
   end
   if (gl_var_is_present(fCdf, 'PI_NAME'))
      piName = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PI_NAME'))');
      if (~isempty(piName))
         if (length(piName) > 64)
            fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
               'PI_NAME', piName(1:64), ...
               'PI_NAME', piName, ...
               a_ncEgoFileName);
            piName = piName(1:64);
         end
         tabMetaData = [tabMetaData {'PI_NAME'} {piName}];
      end
   end
   if (gl_var_is_present(fCdf, 'DATA_CENTRE'))
      dataCentre = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_CENTRE'))');
      if (~isempty(dataCentre))
         if (length(dataCentre) > 2)
            fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
               'DATA_CENTRE', dataCentre(1:2), ...
               'DATA_CENTRE', dataCentre, ...
               a_ncEgoFileName);
            dataCentre = dataCentre(1:2);
         end
         tabMetaData = [tabMetaData {'DATA_CENTRE'} {dataCentre}];
      end
   end
   platformCode = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'platform_code'));
   if (length(platformCode) > 64)
      fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
         'INST_REFERENCE', platformCode(1:64), ...
         'platform_code', platformCode, ...
         a_ncEgoFileName);
      platformCode = platformCode(1:64);
   end
   tabMetaData = [tabMetaData {'INST_REFERENCE'} {platformCode}];
   if (gl_var_is_present(fCdf, 'FIRMWARE_VERSION_NAVIGATION'))
      firmwareVersion = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'FIRMWARE_VERSION_NAVIGATION'))');
      if (~isempty(firmwareVersion))
         if (length(firmwareVersion) > 10)
            fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
               'FIRMWARE_VERSION', firmwareVersion(1:10), ...
               'FIRMWARE_VERSION_NAVIGATION', firmwareVersion, ...
               a_ncEgoFileName);
            firmwareVersion = firmwareVersion(1:10);
         end
         tabMetaData = [tabMetaData {'FIRMWARE_VERSION'} {firmwareVersion}];
      end
   end
   if (gl_var_is_present(fCdf, 'WMO_INST_TYPE'))
      wmoInstType = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'WMO_INST_TYPE'))');
      if (~isempty(wmoInstType))
         if (length(wmoInstType) > 4)
            fprintf('WARNING: ''%s'' truncated to ''%s'' (original value ''%s'' = ''%s'') while generating NetCDF Argo profile from EGO file : %s\n', ...
               'WMO_INST_TYPE', wmoInstType(1:4), ...
               'WMO_INST_TYPE', wmoInstType, ...
               wmoInstType);
            wmoInstType = wmoInstType(1:4);
         end
         tabMetaData = [tabMetaData {'WMO_INST_TYPE'} {wmoInstType}];
      end
   end

   tabProfiles = [tabProfiles profStruct];
end

% create the base file name of the NetCDF profile files
gliderId = [];
if (gl_att_is_present(fCdf, [], 'wmo_platform_code'))
   gliderId = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'wmo_platform_code'));
end
if (isempty(gliderId))
   gliderId = strtrim(netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'platform_code'));
end
deploymentStartDate = [];
if (gl_var_is_present(fCdf, 'DEPLOYMENT_START_DATE'))
   deploymentStartDate = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPLOYMENT_START_DATE'))');
   if (~isempty(deploymentStartDate))
      deploymentStartDate = deploymentStartDate(1:8);
   end
end
if (isempty(deploymentStartDate))
   deploymentStartDate = '99999999';
end
baseFileName = [gliderId '_' deploymentStartDate];

netcdf.close(fCdf);

% generate the NetCDF Argo PROF files
o_generatedFiles = gl_create_nc_mono_prof_files_3_0(tabProfiles, tabMetaData, a_outputDirName, baseFileName);

return
