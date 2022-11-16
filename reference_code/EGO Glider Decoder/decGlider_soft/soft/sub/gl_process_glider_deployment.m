% ------------------------------------------------------------------------------
% Process a glider deployment stored in a directory.
% This directory must contain:
%    - the json deployment file
%    - the data:
%       .bpo files stored in a 'bpo' sub-directory for a seaglider
%       .eng and .log files stored in a 'eng' sub-directory for a seaglider
%       .m and .dat files stored in a 'dat' sub-directory for a slocum
%       .gz files stored in a 'gz' sub-directory for a seaexplorer
%
% SYNTAX :
%  gl_process_glider_deployment(a_deploymentDirName, ...
%    a_computeCurrents, a_generateProfiles, a_applyRtqc)
%
% INPUT PARAMETERS :
%   a_deploymentDirName : path name of the deployment directory
%   a_computeCurrents   : compute subsurface currents from slocum glider data
%   a_generateProfiles  : generate profile files from output EGO file data
%   a_applyRtqc         : apply RTQC tests on output EGO file data (and profile
%                         files if generated)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES : 
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function gl_process_glider_deployment(a_deploymentDirName, ...
   a_computeCurrents, a_generateProfiles, a_applyRtqc)

% reference json file of the EGO format
global g_decGl_egoFormatJsonFile;

% type of the glider to process
global g_decGl_gliderType;

% real time processing
global g_decGl_realtimeFlag;

% report information structure
global g_decGl_reportData;
global g_decGl_reportStruct;

% sea Explorer GPS locations
global g_decGl_seaExplorerGpsData;
g_decGl_seaExplorerGpsData = [];

% variable names defined in the json deployment file
global g_decGl_gliderVarName;
global g_decGl_gliderAdjVarName;
global g_decGl_gliderVarPathName;
global g_decGl_egoVarName;

% calibration information defined in the json deployment file
global g_decGl_calibInfo;

% DOXY processing Id defined in the json deployment file
global g_decGl_processingId;

% variable names added to the .mat structure
global g_decGl_directEgoVarName;
g_decGl_directEgoVarName = [];

% meta-data for derived parameters
global g_decGl_derivedParamMetaData;
g_decGl_derivedParamMetaData = [];

% flag for specific input (NetCDF file of sea glider)
global g_decGl_seaGliderInputNc;
g_decGl_seaGliderInputNc = 0;

% flag for HR data
global g_decGl_hrDataFlag;
g_decGl_hrDataFlag = 0;


% to compute the subsurface current from slocum glider data
COMPUTE_SLOCUM_SUBSURFACE_CURRENT = a_computeCurrents;

% to store the subsurface current estimates in a CSV file
PRINT_CURRENT_ESTIMATES_IN_CSV = 0;

% to append the subsurface current estimates to the final NetCDF file
APPEND_CURRENT_ESTIMATES_TO_NC = a_computeCurrents;


% clean the deployment dir path name
a_deploymentDirName = [a_deploymentDirName '/'];
a_deploymentDirName = regexprep(a_deploymentDirName, '\', '/');
a_deploymentDirName = regexprep(a_deploymentDirName, '//', '/');

% check input data type
fileExt = '';
if (strcmpi(g_decGl_gliderType, 'seaglider'))
   bpoFile = 0;
   proFile = 0;
   engFile = 0;
   ncFile = 0;
   if (exist([a_deploymentDirName 'bpo/'], 'dir') == 7)
      bpoFile = 1;
      fileExt = 'bpo';
      dataDirPathName = [a_deploymentDirName 'bpo/'];
   elseif (exist([a_deploymentDirName 'pro/'], 'dir') == 7)
      proFile = 1;
      fileExt = 'pro';
      dataDirPathName = [a_deploymentDirName 'pro/'];
   elseif (exist([a_deploymentDirName 'eng/'], 'dir') == 7)
      engFile = 1;
      fileExt = 'eng';
      dataDirPathName = [a_deploymentDirName 'eng/'];
   elseif (exist([a_deploymentDirName 'nc_sg/'], 'dir') == 7)
      ncFile = 1;
      fileExt = 'nc';
      g_decGl_seaGliderInputNc = 1;
      dataDirPathName = [a_deploymentDirName 'nc_sg/'];
   else
      if (bpoFile+proFile+engFile+ncFile == 0)
         fprintf('ERROR: expecting a ''bpo'' or ''pro'' or ''eng'' or ''nc_sg'' sub-directory of %s => deployment ignored\n', ...
            a_deploymentDirName);
      end
      return
   end
elseif (strcmpi(g_decGl_gliderType, 'slocum'))
   dataDirPathName = [a_deploymentDirName 'dat/'];
elseif (strcmpi(g_decGl_gliderType, 'seaexplorer'))
   gzFile = 0;
   csvFile = 0;
   if (exist([a_deploymentDirName 'gz/'], 'dir') == 7)
      gzFile = 1;
      dataDirPathName = [a_deploymentDirName 'gz/'];
   elseif (exist([a_deploymentDirName 'csv/'], 'dir') == 7)
      csvFile = 1;
      dataDirPathName = [a_deploymentDirName 'csv/'];
   else
      if (gzFile+csvFile == 0)
         fprintf('ERROR: expecting a ''gz'' or ''csv_raw_HR'' or ''csv'' sub-directory of %s => deployment ignored\n', ...
            a_deploymentDirName);
      end
      return
   end
end

% check if a 'json' directory exists in the deployment directory
expJsonDirName = [a_deploymentDirName '/json/'];
if (exist(expJsonDirName, 'dir') == 7)
   
   % a 'json' directory exists in the deployment directory
   % we will create the json deployment file from this directory contents
   fprintf('INFO: a ''json'' directory exist in the deployment directory, we use these stored json files to generate the json file of the deployment\n');

   % check that the json file of the EGO format exists
   if ~(exist(g_decGl_egoFormatJsonFile, 'file') == 2)
      fprintf('ERROR: expected json EGO file not found (%s) => deployment ignored\n', ...
         g_decGl_egoFormatJsonFile);
      return
   end
   
   % check that the deployment json file exists
   sep = strfind(a_deploymentDirName, '/');
   dirName = a_deploymentDirName(sep(end-1)+1:sep(end)-1);
   jsonInputPathFile = [a_deploymentDirName '/json/' dirName '.json'];
   if ~(exist(jsonInputPathFile, 'file') == 2)
      fprintf('ERROR: expected json deployment file not found (%s) => deployment ignored\n', ...
         jsonInputPathFile);
      return
   end
   
   % create the json file for the deployment (from 'json' directory contents)
   [deploymentFileName] = gl_create_json_deployment_file( ...
      a_deploymentDirName, g_decGl_egoFormatJsonFile, dataDirPathName);
   if (isempty(deploymentFileName))
      return
   end
   fprintf('INFO: json deployment file created: %s\n', ...
      deploymentFileName);
end

% name of the json deployment file
sep = strfind(a_deploymentDirName, '/');
dirName = a_deploymentDirName(sep(end-1)+1:sep(end)-1);
jsonInputPathFile = [a_deploymentDirName 'deployment_' dirName '.json'];
if ~(~exist(jsonInputPathFile, 'dir') && exist(jsonInputPathFile, 'file'))
   fprintf('ERROR: expected json deployment file not found (%s) => deployment ignored\n', ...
      jsonInputPathFile);
   return
end

% retrieve the glider var 2 EGO var mapping from the json deployment file
% and collect calibration data
[g_decGl_gliderVarName, g_decGl_gliderAdjVarName, g_decGl_gliderVarPathName, ...
   g_decGl_egoVarName, g_decGl_calibInfo, g_decGl_processingId] = ...
   gl_get_var_names_from_json(jsonInputPathFile);

if (g_decGl_realtimeFlag == 1)
   % initialize data structure to store report information
   g_decGl_reportStruct = gl_get_report_init_struct(jsonInputPathFile);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process the deployment data
if (exist(dataDirPathName, 'dir'))
   
   fprintf('INFO: processing directory %s\n', dataDirPathName);
   
   matDirPathName = [a_deploymentDirName 'mat/'];
   if (exist(matDirPathName, 'dir'))
      fprintf('INFO: removing directory %s\n', matDirPathName);
      rmdir(matDirPathName, 's')
   end
   mkdir(matDirPathName);
   ncDirPathName = [a_deploymentDirName 'nc/'];
   if (exist(ncDirPathName, 'dir'))
      fprintf('INFO: removing directory %s\n', ncDirPathName);
      rmdir(ncDirPathName, 's')
   end
   mkdir(ncDirPathName);
   tmpDirPathName = [a_deploymentDirName 'tmp/'];
   if (exist(tmpDirPathName, 'dir'))
      fprintf('INFO: removing directory %s\n', tmpDirPathName);
      rmdir(tmpDirPathName, 's')
   end
   mkdir(tmpDirPathName);
   profDirPathName = [a_deploymentDirName 'profiles/'];
   if (exist(profDirPathName, 'dir'))
      fprintf('INFO: removing directory %s\n', profDirPathName);
      rmdir(profDirPathName, 's')
   end
   mkdir(profDirPathName);
   
   ncFinalOutputPathFile = [a_deploymentDirName  dirName '_P.nc'];
   if (~exist(ncFinalOutputPathFile, 'dir') && exist(ncFinalOutputPathFile, 'file'))
      fprintf('INFO: deleting file %s\n', ncFinalOutputPathFile);
      delete(ncFinalOutputPathFile);
      if (~exist(ncFinalOutputPathFile, 'dir') && exist(ncFinalOutputPathFile, 'file'))
         fprintf('ERROR: cannot delete file %s\n', ncFinalOutputPathFile);
         return
      end
   end
   ncFinalOutputPathFile = [a_deploymentDirName  dirName '_R.nc'];
   if (~exist(ncFinalOutputPathFile, 'dir') && exist(ncFinalOutputPathFile, 'file'))
      fprintf('INFO: deleting file %s\n', ncFinalOutputPathFile);
      delete(ncFinalOutputPathFile);
      if (~exist(ncFinalOutputPathFile, 'dir') && exist(ncFinalOutputPathFile, 'file'))
         fprintf('ERROR: cannot delete file %s\n', ncFinalOutputPathFile);
         return
      end
   end
   
   fprintf('\n');
   
   % GLIDER PROCESSING
   
   if (strcmpi(g_decGl_gliderType, 'slocum'))

      [vectorFileNameList, sensorFileNameList] = gl_get_input_data_file_list_slocum(dataDirPathName);
      extLen = 2;
      
      % one .sbd.dat or (.sbd.dat, .tbd.dat) or (.mbd.dat, .nbd.dat) file => one .mat file
      for idF = 1:length(vectorFileNameList)
         vectorDataInputFile = '';
         if (isstruct(vectorFileNameList(idF)))
            if (~isempty(vectorFileNameList(idF)))
               vectorDataInputFile = vectorFileNameList(idF).name;
            end
         else
            if (~isempty(vectorFileNameList{idF}))
               vectorDataInputFile = vectorFileNameList{idF}.name;
            end
         end

         if (isempty(vectorDataInputFile))
            fprintf('WARNING: Sensor file %s cannot be processed (no associated vector file)\n', ...
               sensorFileNameList{idF}.name);
            continue
         end

         vectorDataInputPathFile = [dataDirPathName vectorDataInputFile];
         matOutputPathFile = [matDirPathName vectorDataInputFile(1:end-extLen) '.mat'];
         if (exist(vectorDataInputPathFile, 'file') == 2)

            sensorDataInputPathFile = [];
            if (isempty(sensorFileNameList))

               fprintf('%03d/%03d Processing file ''%s''\n', ...
                  idF, length(vectorFileNameList), ...
                  vectorDataInputFile);

               % check that associated .dat file exists
               [pathstr, fileName, ~] = fileparts(vectorDataInputPathFile);
               vectorDatInputPathFile = [pathstr '/' fileName '.dat'];
               if ~(exist(vectorDatInputPathFile, 'file') == 2)
                  fprintf('WARNING: Associated .dat file not found for file: %s\n', ...
                     vectorDataInputFile);
                  continue
               end

            else

               if (isempty(sensorFileNameList{idF}))

                  fprintf('%03d/%03d Processing file ''%s''\n', ...
                     idF, length(vectorFileNameList), ...
                     vectorDataInputFile);
               else

                  sensorDataInputFile = sensorFileNameList{idF}.name;
                  sensorDataInputPathFile = [dataDirPathName sensorDataInputFile];

                  fprintf('%03d/%03d Processing files ''%s'' and ''%s''\n', ...
                     idF, length(vectorFileNameList), ...
                     vectorDataInputFile, ...
                     sensorDataInputFile);

                  % check that associated .dat file exists
                  [pathstr, fileName, ~] = fileparts(vectorDataInputPathFile);
                  vectorDatInputPathFile = [pathstr '/' fileName '.dat'];
                  if ~(exist(vectorDatInputPathFile, 'file') == 2)
                     fprintf('WARNING: Associated .dat file not found for file: %s\n', ...
                        vectorDataInputFile);
                     continue
                  end
                  [pathstr, fileName, ~] = fileparts(sensorDataInputPathFile);
                  sensorDatInputPathFile = [pathstr '/' fileName '.dat'];
                  if ~(exist(sensorDatInputPathFile, 'file') == 2)
                     fprintf('WARNING: Associated .dat file not found for file: %s\n', ...
                        sensorDataInputFile);
                     continue
                  end
               end
               
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % read the data file(s) and store the Matlab resulting structure in
            % a .mat file
            [matFileCreated] = gl_decode_slocum_dat( ...
               vectorDataInputPathFile, sensorDataInputPathFile, matOutputPathFile, COMPUTE_SLOCUM_SUBSURFACE_CURRENT);

            if (matFileCreated == 0)
               continue
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % write the EGO NetCDF file from the .mat file
            matInputPathFile = matOutputPathFile;
            ncOutputPathFile = [ncDirPathName '/' vectorDataInputFile(1:end-extLen) '.nc'];
            gl_co_writer(jsonInputPathFile, matInputPathFile, ncOutputPathFile);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % set PHASE and PHASE_NUMBER parameters in the EGO NetCDF file
            ncInputPathFile = ncOutputPathFile;
            gl_set_phase(ncInputPathFile);
         end
      end

   elseif (strcmpi(g_decGl_gliderType, 'seaglider'))

      [fileNameList, fileNumList] = gl_get_input_data_file_list_seaglider(dataDirPathName, fileExt);
      if (ncFile == 1)
         extLen = 3;
      else
         extLen = 4;
      end

      % one .bpo or .pro or .eng or .nc or .dat file => one .mat file
      for idF = 1:length(fileNameList)
         dataInputFile = fileNameList(idF).name;
         dataInputPathFile = [dataDirPathName dataInputFile];
         matOutputPathFile = [matDirPathName dataInputFile(1:end-extLen) '.mat'];
         if (exist(dataInputPathFile, 'file') == 2)

            [pathstr, fileName, ext] = fileparts(dataInputPathFile);
            fprintf('%03d/%03d Processing file %s\n', ...
               idF, length(fileNameList), [fileName ext]);

            if (engFile == 1)
               % check that associated .log and ppca.eng and/or ppcb.eng file exists
               datInputPathFile = [pathstr '/' fileName '.log'];
               if ~(exist(datInputPathFile, 'file') == 2)
                  fprintf('WARNING: Associated .log file not found for file: %s\n', ...
                     dataInputPathFile);
                  continue
               end
               ppca = 0;
               ppcb = 0;
               datInputPathFile = [pathstr '/ppc' num2str(fileNumList(idF)) 'a.eng'];
               if (exist(datInputPathFile, 'file') == 2)
                  ppca = 1;
               end
               datInputPathFile = [pathstr '/ppc' num2str(fileNumList(idF)) 'b.eng'];
               if (exist(datInputPathFile, 'file') == 2)
                  ppcb = 1;
               end
               if (ppca+ppcb == 0)
                  fprintf('WARNING: At least one associated ppca.eng or ppcb.eng file should be present for file: %s\n', ...
                     dataInputPathFile);
                  continue
               end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % read the data file and store the Matlab resulting structure in
            % a .mat file
            if (bpoFile == 1)
               gl_decode_seaglider_bpo(dataInputPathFile, matOutputPathFile);
            elseif (proFile == 1)
               gl_decode_seaglider_pro(dataInputPathFile, matOutputPathFile);
            elseif (engFile == 1)
               gl_decode_seaglider_eng(dataInputPathFile, matOutputPathFile);
            elseif (ncFile == 1)
               gl_decode_seaglider_nc(dataInputPathFile, matOutputPathFile);
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % write the EGO NetCDF file from the .mat file
            matInputPathFile = matOutputPathFile;
            ncOutputPathFile = [ncDirPathName '/' dataInputFile(1:end-extLen) '.nc'];
            gl_co_writer(jsonInputPathFile, matInputPathFile, ncOutputPathFile);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % set PHASE and PHASE_NUMBER parameters in the EGO NetCDF file
            ncInputPathFile = ncOutputPathFile;
            gl_set_phase(ncInputPathFile);
         end
      end

   elseif (strcmpi(g_decGl_gliderType, 'seaexplorer'))

      if (gzFile == 1)
         fprintf('\nReading .gz files to generate .mat files\n');
      elseif (csvFile == 1)
         fprintf('\nReading CSV files to generate .mat files\n');
      end

      [fileNameList, fileNumList, fileBaseNameList] = gl_get_input_data_file_list_seaexplorer(dataDirPathName);
      if (gzFile == 1)
         extLen = 3;
      elseif (csvFile == 1)
         extLen = 0;
      end
      
      % two input files (gli and pl1) => one .mat file
      matFileList = [];
      uFileBaseNameList = unique(fileBaseNameList);
      for fileBase = 1:length(uFileBaseNameList)
         fileBaseName = uFileBaseNameList{fileBase};
         idFiles = find(strcmp(fileBaseNameList, fileBaseName));
         fileNameListForBase = fileNameList(idFiles);
         fileNumListForBase = fileNumList(idFiles);
         uFileNumList = unique(fileNumListForBase);
         for fileNum = 1:length(uFileNumList)
            files = fileNameListForBase(fileNumListForBase == uFileNumList(fileNum));
            matFileAdd = 0;
            for idF = 1:length(files)
               dataInputFile = files(idF).name;
               dataInputPathFile = [dataDirPathName dataInputFile];
               matOutputFile = [dataInputFile(1:end-extLen) '.mat'];
               matOutputFile = regexprep(matOutputFile, '.gli.sub', '');
               matOutputFile = regexprep(matOutputFile, '.gli', '');
               matOutputFile = regexprep(matOutputFile, '.pl1', '');
               matOutputFile = regexprep(matOutputFile, '.pld1.sub', '');
               matOutputFile = regexprep(matOutputFile, '.pld1.raw', '');
               matOutputPathFile = [matDirPathName matOutputFile];
               if (~exist(dataInputPathFile, 'dir') && exist(dataInputPathFile, 'file'))

                  [~, fileName, ext] = fileparts(dataInputPathFile);
                  fprintf('%03d/%03d Processing file %s\n', ...
                     fileNum, length(uFileNumList), [fileName ext]);

                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % read the data files and store the Matlab resulting structure in
                  % a .mat file
                  matFileCreated = gl_decode_seaexplorer( ...
                     dataInputPathFile, matOutputPathFile, gzFile, (idF == length(files)));
                  if (matFileCreated == 1)
                     if (matFileAdd == 0)
                        matFileList{end+1} = matOutputPathFile;
                        matFileAdd = 1;
                     end
                  end
               end
            end
         end
      end
      
      fprintf('\nProcessing .mat files to generate EGO .nc files merged in a final EGO .nc file\n');
      
      % process the .mat files
      for idFile = 1:length(matFileList)
         
         matFileName = matFileList{idFile};
         [~, matFile, ext] = fileparts(matFileName);
         
         fprintf('%03d/%03d Processing file %s\n', ...
            idFile, length(matFileList), [matFile ext]);
         
         if (~exist(matFileName, 'dir') && exist(matFileName, 'file'))
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % write the EGO NetCDF file from the .mat file
            matInputPathFile = matFileName;
            [~, matFileName, ~] = fileparts(matInputPathFile);
            ncOutputPathFile = [ncDirPathName matFileName '.nc'];
            gl_co_writer(jsonInputPathFile, matInputPathFile, ncOutputPathFile);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % set PHASE and PHASE_NUMBER parameters in the EGO NetCDF file
            ncInputPathFile = ncOutputPathFile;
            gl_set_phase(ncInputPathFile);
            
         end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % merge individual EGO NetCDF files in a final one
   
   fprintf('\nMerging individual EGO NetCDF files\n');

   if (g_decGl_hrDataFlag == 0)
      ncFinalOutputPathFile = [a_deploymentDirName  dirName '_R.nc'];
   else
      ncFinalOutputPathFile = [a_deploymentDirName  dirName '_P.nc'];
   end   
   ok = gl_merge_files(ncFinalOutputPathFile, ncDirPathName);
   if (~ok)
      return
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute subsurface current estimates from slocum data
   if ((strcmpi(g_decGl_gliderType, 'slocum')) && (COMPUTE_SLOCUM_SUBSURFACE_CURRENT == 1))
      
      fprintf('\nComputing estimates of subsurface current\n');

      % name of the .csv file to store subsurface current data
      csvFilePathName = [ncFinalOutputPathFile(1:end-4) 'current.csv'];
      
      % compute the subsurface currents
      subsurfaceCurrent = ...
         gl_compute_subsurface_current(matDirPathName, csvFilePathName, ...
         PRINT_CURRENT_ESTIMATES_IN_CSV);
      
      % append the current estimates in the NetCDF file
      if (APPEND_CURRENT_ESTIMATES_TO_NC == 1)
         
         if (~isempty(subsurfaceCurrent))
            
            fprintf('\nAppending current estimates to EGO final .nc file\n');
            
            gl_add_current_data(subsurfaceCurrent, ncFinalOutputPathFile);
         end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % apply RTQC tests on output EGO file data
   testDoneList = [];
   testFailedList = [];
   if (a_applyRtqc == 1)
      
      fprintf('\nApplying RTQC tests to EGO final file data\n');
      
      [testDoneList, testFailedList] = gl_add_rtqc_to_ego_file(ncFinalOutputPathFile);
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % interpolate measurement locations of the final EGO file
   gl_update_meas_loc(ncFinalOutputPathFile, a_applyRtqc);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % generate the Argo profiles from EGO NetCDF file contents according to
   % PHASE and PHASE_NUMBER parameters
   if (a_generateProfiles == 1)
      
      fprintf('\nGenerating NetCDF Argo profile files from EGO final NetCDF file\n');
      
      [generatedFileList] = gl_generate_prof(ncFinalOutputPathFile, profDirPathName, ...
         a_applyRtqc, testDoneList, testFailedList);
      
      % apply RTQC tests on output profile files data
      if (a_applyRtqc == 1)
         
         fprintf('\nApplying RTQC tests to profile files data\n');
         
         for idF = 1:length(generatedFileList)
            gl_add_rtqc_to_profile_file(generatedFileList{idF});
         end
      end
   end
   
   fprintf('... done\n');
   
else
   fprintf('WARNING: cannot find expected data directory (%s) => deployment not processed\n', ...
      dataDirPathName);
end

% store the information for the XML report
if (g_decGl_realtimeFlag == 1)
   g_decGl_reportData = [g_decGl_reportData g_decGl_reportStruct];
end

return
