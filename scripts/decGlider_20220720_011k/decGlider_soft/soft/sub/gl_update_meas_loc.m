% ------------------------------------------------------------------------------
% Update location of the measurements in an EGO netCDF file.
% The EGO file is created from concatenation of transmitted Yo files. To be sure
% that all measurement locations are set, we must interpolate locations of the
% final EGO file.
%
% SYNTAX :
%  gl_update_meas_loc(a_ncFileName, a_applyRtqc)
%
% INPUT PARAMETERS :
%   a_ncFileName : EGO netCDF file path name
%   a_applyRtqc  : RTQC tests have been applied on input EGO file data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2016 - RNU - creation
% ------------------------------------------------------------------------------
function gl_update_meas_loc(a_ncFileName, a_applyRtqc)

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

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_egoVarName;

% type of the glider to process
global g_decGl_gliderType;


% check if the file exists
if (~exist(a_ncFileName, 'file'))
   fprintf('ERROR: File not found : %s\n', a_ncFileName);
   return
end

% check that TIME, LATITUDE and LONGITUDE are present in the EGO file
wantedVars = [ ...
   {'TIME'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'HISTORY_ACTION'} ...
   {'HISTORY_QCTEST'} ...
   ];
[ncEgoData] = gl_get_data_from_nc_file(a_ncFileName, wantedVars);
time = gl_get_data_from_name('TIME', ncEgoData);
latitude = gl_get_data_from_name('LATITUDE', ncEgoData);
longitude = gl_get_data_from_name('LONGITUDE', ncEgoData);
if (isempty(time) || isempty(latitude) || isempty(longitude))
   return
end

% open NetCDF file
fCdf = netcdf.open(a_ncFileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncFileName);
   return
end

% retrieve location data
time = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME'));
timeQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_QC'));
longitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'));
latitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'));
positionQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'));

% retrieve fill values
timeFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME'), '_FillValue');
lonFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), '_FillValue');
latFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), '_FillValue');
posMethodFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'POSITIONING_METHOD'), '_FillValue');

% interpolate the GPS fixes (and, for slocum, the glider fixes, if any) along the TIME dimension

% retrieve GPS reference location data
timeRef = [];
longitudeRef = [];
latitudeRef = [];
if (gl_var_is_present(fCdf, 'TIME_GPS'))
   timeRef = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'));
   timeRefQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS_QC'));
   longitudeRef = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'));
   latitudeRef = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'));
   positionRefQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_GPS_QC'));

   % retrieve associated fill values
   timeRefFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TIME_GPS'), '_FillValue');
   lonRefFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE_GPS'), '_FillValue');
   latRefFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE_GPS'), '_FillValue');

   if (a_applyRtqc == 1)
      idOk = find((timeRef ~= timeRefFillVal) & (longitudeRef ~= lonRefFillVal) & (latitudeRef ~= latRefFillVal) & ...
         (timeRefQc == g_decGl_qcGood) & (positionRefQc == g_decGl_qcGood));
   else
      idOk = find((timeRef ~= timeRefFillVal) & (longitudeRef ~= lonRefFillVal) & (latitudeRef ~= latRefFillVal));
   end

   timeRef = timeRef(idOk);
   longitudeRef = longitudeRef(idOk);
   latitudeRef = latitudeRef(idOk);
end

% add glider reference location data
if (a_applyRtqc == 1)
   idOk = find((time ~= timeFillVal) & (longitude ~= lonFillVal) & (latitude ~= latFillVal) & ...
      (timeQc == g_decGl_qcGood) & (positionQc == g_decGl_qcGood));
else
   idOk = find((time ~= timeFillVal) & (longitude ~= lonFillVal) & (latitude ~= latFillVal));
end
timeRef = [timeRef; time(idOk)];
longitudeRef = [longitudeRef; longitude(idOk)];
latitudeRef = [latitudeRef; latitude(idOk)];

% interpolate measurement locations
positioningMethod = int8(ones(size(time)))*posMethodFillVal;
if (~isempty(longitudeRef))

   [timeRef, idSort] = sort(timeRef);
   longitudeRef = longitudeRef(idSort);
   latitudeRef = latitudeRef(idSort);

   if (length(longitudeRef) > 1)

      idGliderPos = find((longitude ~= lonFillVal) & (latitude ~= latFillVal));

      if (a_applyRtqc == 1)
         idOk = find((time ~= timeFillVal) & (timeQc == g_decGl_qcGood) & ...
            (longitude == lonFillVal) & (latitude == latFillVal));
      else
         idOk = find((time ~= timeFillVal) & ...
            (longitude == lonFillVal) & (latitude == latFillVal));
      end

      longitude(idOk) = interp1q(timeRef, longitudeRef, time(idOk));
      latitude(idOk) = interp1q(timeRef, latitudeRef, time(idOk));

      longitude(find(isnan(longitude))) = lonFillVal;
      latitude(find(isnan(latitude))) = latFillVal;

      if (a_applyRtqc == 1)
         idPosOk = find((time ~= timeFillVal) & (timeQc == g_decGl_qcGood) & ...
            (latitude ~= latFillVal) & (longitude ~= lonFillVal));
      else
         idPosOk = find((time ~= timeFillVal) & ...
            (latitude ~= latFillVal) & (longitude ~= lonFillVal));
      end
      positioningMethod(idPosOk) = 2;

      idRef = find(ismember(time(idPosOk), timeRef));
      if (~isempty(idRef))
         positioningMethod(idPosOk(idRef)) = 0;
      end

      positioningMethod(idGliderPos) = 3;
   end
end

% compute POSITION_QC
positionQc = int8(ones(size(time)))*g_decGl_qcMissing;
positionQc(find((positioningMethod == 0) | (positioningMethod == 3))) = g_decGl_qcNoQc;
positionQc(find(positioningMethod == 2)) = g_decGl_qcInterpolated;

if (a_applyRtqc == 1)

   testDoneList = zeros(20, 1);
   testFailedList = zeros(20, 1);

   if (g_decGl_rtqcTest4 == 1)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TEST 4: position on land test

      if ~(exist(g_decGl_rtqcGebcoFile, 'file') == 2)
         fprintf('RTQC_ERROR: TEST004: GEBCO file (%s) not found => test #4 not performed\n', ...
            g_decGl_rtqcGebcoFile);
      else

         idToCheck = find( ...
            (latitude ~= latFillVal) & ...
            (longitude ~= lonFillVal) & ...
            (positionQc ~= g_decGl_qcCorrectable) & ...
            (positionQc ~= g_decGl_qcBad));

         % initialize Qc flag
         positionQc(idToCheck) = gl_set_qc(positionQc(idToCheck), g_decGl_qcGood);
         testDoneList(4) = 1;

         % retrieve GEBCO elevations
         [elev] = gl_get_gebco_elev_point(longitude(idToCheck), latitude(idToCheck), g_decGl_rtqcGebcoFile);

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
            positionQc(idToCheck(idToFlag)) = gl_set_qc(positionQc(idToCheck(idToFlag)), g_decGl_qcBad);
            testFailedList(4) = 1;
         end
      end
   end

   if (g_decGl_rtqcTest20 == 1)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TEST 20: questionable Argos position test

      idToCheck = find( ...
         (latitude ~= latFillVal) & ...
         (longitude ~= lonFillVal) & ...
         (positionQc ~= g_decGl_qcCorrectable) & ...
         (positionQc ~= g_decGl_qcBad) & ...
         (time ~= timeFillVal) & ...
         (timeQc ~= g_decGl_qcCorrectable) & ...
         (timeQc ~= g_decGl_qcBad));

      % initialize Qc flag
      positionQc(idToCheck) = gl_set_qc(positionQc(idToCheck), g_decGl_qcGood);
      testDoneList(20) = 1;

      % no need to apply the test since:
      % - the base surface positions used for interpolation have already
      %   succeeded test #20
      % - we didn't extrapolate subsurface trajectory

      %    % compute juld measurements and juldGps
      %    juldMeas = time(idToCheck);
      %    epoch_offset = datenum(1970, 1, 1) - datenum(1950, 1, 1);
      %    juldMeas = juldMeas/86400 + epoch_offset;
      %    juldGps = timeGps;
      %    juldGps = juldGps/86400 + epoch_offset;
      %
      %    % apply the test
      %    [idToFlag] = gl_check_subsurface_speed( ...
      %       juldMeas, ...
      %       longitude(idToCheck), ...
      %       latitude(idToCheck), ...
      %       juldGps, ...
      %       longitudeGps, ...
      %       latitudeGps);
      %
      %    if (~isempty(idToFlag))
      %       positionQc(idToCheck(idToFlag)) = gl_set_qc(positionQc(idToCheck(idToFlag)), g_decGl_qcBad);
      %       testFailedList(20) = 1;
      %    end
   end
end

% update the EGO file data
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), latitude);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), longitude);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), positionQc);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITIONING_METHOD'), positioningMethod);

% update the HISTORY section (new RTQC test reports should be add to existing
% ones)
if (a_applyRtqc == 1)

   % extend test lists to 63
   testDoneListBis = zeros(63, 1);
   testDoneListBis(testDoneList == 1) = 1;
   testFailedListBis = zeros(63, 1);
   testFailedListBis(testFailedList == 1) = 1;

   % update history information
   historyAction = gl_get_data_from_name('HISTORY_ACTION', ncEgoData);
   historyQcTest = gl_get_data_from_name('HISTORY_QCTEST', ncEgoData);
   [~, nHistory] = size(historyAction);
   for idH = 1:nHistory
      if (strcmp(strtrim(historyAction(:, idH)'), 'QCP$'))
         currentTestDoneHex = historyQcTest(:, idH)';
         currentTestDoneList = gl_retrieve_qctest_list(currentTestDoneHex);

         % merge test lists
         newTestDoneList = zeros(63, 1);
         newTestDoneList((currentTestDoneList == 1) | (testDoneListBis == 1)) = 1;
         newTestDoneHex = gl_compute_qctest_hex(find(newTestDoneList == 1));

         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
            fliplr([idH-1 0]), ...
            fliplr([1 length(newTestDoneHex)]), newTestDoneHex);

         %          testDoneHex = gl_compute_qctest_hex(find(testDoneList == 1));
         %          gl_print_qctest_list(testDoneHex);
         %          gl_print_qctest_list(currentTestDoneHex);
         %          gl_print_qctest_list(newTestDoneHex);
      end
      if (strcmp(strtrim(historyAction(:, idH)'), 'QCF$'))
         currentTestFailedHex = historyQcTest(:, idH)';
         currentTestFailedList = gl_retrieve_qctest_list(currentTestFailedHex);

         % merge test lists
         newTestFailedList = zeros(63, 1);
         newTestFailedList((currentTestFailedList == 1) | (testFailedListBis == 1)) = 1;
         newTestFailedHex = gl_compute_qctest_hex(find(newTestFailedList == 1));

         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
            fliplr([idH-1 0]), ...
            fliplr([1 length(newTestFailedHex)]), newTestFailedHex);

         %          testFailedHex = gl_compute_qctest_hex(find(testFailedList == 1));
         %          gl_print_qctest_list(testFailedHex);
         %          gl_print_qctest_list(currentTestFailedHex);
         %          gl_print_qctest_list(newTestFailedHex);
      end
   end
end

netcdf.close(fCdf);

return
