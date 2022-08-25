% ------------------------------------------------------------------------------
% Finalize the XML report.
%
% SYNTAX :
%  [o_status] = gl_finalize_xml_report(a_ticStartTime, a_logFileName, a_error)
%
% INPUT PARAMETERS :
%   a_ticStartTime : identifier for the "tic" command
%   a_logFileName  : log file path name of the run
%   a_error        : Matlab error
%
% OUTPUT PARAMETERS :
%   o_status : final status of the run
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = gl_finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_decGl_xmlReportDOMNode;

% report information structure
global g_decGl_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_decGl_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% newChild = docNode.createElement('decoder_version');
% newChild.appendChild(docNode.createTextNode(g_decGl_decoderVersion));
% docRootNode.appendChild(newChild);

% list of processings done
for idDeploy = 1:length(g_decGl_reportData)
   
   reportStruct = g_decGl_reportData(idDeploy);
   
   newChild = docNode.createElement(sprintf('deployment_%d', idDeploy));
   
   newChildBis = docNode.createElement('json_deployment_file');
   newChildBis.appendChild(docNode.createTextNode(num2str(reportStruct.jsonDeploymentFileName)));
   newChild.appendChild(newChildBis);
      
   newChildBis = docNode.createElement('input_files');
   
   textNode = [sprintf('\n')];
   for idFile = 1:length(reportStruct.inputFiles)
      textNode = [textNode ...
         sprintf('%s\n', reportStruct.inputFiles{idFile})];
   end
   
   newChildBis.appendChild(docNode.createTextNode(textNode));
   newChild.appendChild(newChildBis);
   
   newChildBis = docNode.createElement('output_files');
   
   textNode = [sprintf('\n')];
   for idFile = 1:length(reportStruct.outputFiles)
      textNode = [textNode ...
         sprintf('%s\n', reportStruct.outputFiles{idFile})];
   end
   
   newChildBis.appendChild(docNode.createTextNode(textNode));
   newChild.appendChild(newChildBis);
   
   docRootNode.appendChild(newChild);
end

% retrieve information from the log file
[decInfoMsg, decWarningMsg, decErrorMsg, ...
   rtQcInfoMsg, rtQcWarningMsg, rtQcErrorMsg, ...
   rtAdjInfoMsg, rtAdjWarningMsg, rtAdjErrorMsg] = parse_log_file(a_logFileName);

if (~isempty(decInfoMsg))
   newChild = docNode.createElement('decoding_info');
   
   textNode = [sprintf('\n')];
   for idMsg = 1:length(decInfoMsg)
      textNode = [textNode ...
         sprintf('%s\n', decInfoMsg{idMsg})];
   end
   
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
end

if (~isempty(decWarningMsg))
   newChild = docNode.createElement('decoding_warning');
   
   textNode = [sprintf('\n')];
   for idMsg = 1:length(decWarningMsg)
      textNode = [textNode ...
         sprintf('%s\n', decWarningMsg{idMsg})];
   end
   
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
end

if (~isempty(decErrorMsg))
   newChild = docNode.createElement('decoding_error');
   
   textNode = [sprintf('\n')];
   for idMsg = 1:length(decErrorMsg)
      textNode = [textNode ...
         sprintf('%s\n', decErrorMsg{idMsg})];
   end
   
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
   
   o_status = 'nok';
end

if (~isempty(rtQcInfoMsg))
   newChild = docNode.createElement('rt_qc_info');
   
   textNode = [sprintf('\n')];
   for idMsg = 1:length(rtQcInfoMsg)
      textNode = [textNode ...
         sprintf('%s\n', rtQcInfoMsg{idMsg})];
   end
   
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
end

if (~isempty(rtQcWarningMsg))
   newChild = docNode.createElement('rt_qc_warning');
   
   textNode = [sprintf('\n')];
   for idMsg = 1:length(rtQcWarningMsg)
      textNode = [textNode ...
         sprintf('%s\n', rtQcWarningMsg{idMsg})];
   end
   
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
end

if (~isempty(rtQcErrorMsg))
   newChild = docNode.createElement('rt_qc_error');
   
   textNode = [sprintf('\n')];
   for idMsg = 1:length(rtQcErrorMsg)
      textNode = [textNode ...
         sprintf('%s\n', rtQcErrorMsg{idMsg})];
   end
   
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
   
   o_status = 'nok';
end

% add matlab error
if (~isempty(a_error))
   o_status = 'nok';
   
   textNode = sprintf('\n%s\n', a_error.message);
   textNode = [textNode sprintf('Stack:\n')];
   for idS = 1:size(a_error.stack, 1)
      textNode = [textNode ...
         sprintf('Line: %3d File: %s (func: %s)\n', ...
         a_error.stack(idS). line, ...
         a_error.stack(idS). file, ...
         a_error.stack(idS). name)];
   end
   
   newChild = docNode.createElement('matlab_error');
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
   
end

newChild = docNode.createElement('duration');
newChild.appendChild(docNode.createTextNode(gl_format_time(toc(a_ticStartTime)/3600)));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode(o_status));
docRootNode.appendChild(newChild);

return

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
%    o_rtQcInfoMsg, o_rtQcWarningMsg, o_rtQcErrorMsg, ...
%    o_rtAdjInfoMsg, o_rtAdjWarningMsg, o_rtAdjErrorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_decInfoMsg      : DECODER INFO messages
%   o_decWarningMsg   : DECODER WARNING messages
%   o_decErrorMsg     : DECODER ERROR messages
%   o_rtQcInfoMsg     : RTQC INFO messages
%   o_rtQcWarningMsg  : RTQC WARNING messages
%   o_rtQcErrorMsg    : RTQC ERROR messages
%   o_rtAdjInfoMsg    : RTADJ INFO messages
%   o_rtAdjWarningMsg : RTADJ WARNING messages
%   o_rtAdjErrorMsg   : RTADJ ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
   o_rtQcInfoMsg, o_rtQcWarningMsg, o_rtQcErrorMsg, ...
   o_rtAdjInfoMsg, o_rtAdjWarningMsg, o_rtAdjErrorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_decInfoMsg = [];
o_decWarningMsg = [];
o_decErrorMsg = [];
o_rtQcInfoMsg = [];
o_rtQcWarningMsg = [];
o_rtQcErrorMsg = [];
o_rtAdjInfoMsg = [];
o_rtAdjWarningMsg = [];
o_rtAdjErrorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(upper(line), 'INFO:', length('INFO:')))
            o_decInfoMsg = [o_decInfoMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'WARNING:', length('WARNING:')))
            o_decWarningMsg = [o_decWarningMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'ERROR:', length('ERROR:')))
            o_decErrorMsg = [o_decErrorMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'RTQC_INFO:', length('RTQC_INFO:')))
            o_rtQcInfoMsg = [o_rtQcInfoMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'RTQC_WARNING:', length('RTQC_WARNING:')))
            o_rtQcWarningMsg = [o_rtQcWarningMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'RTQC_ERROR:', length('RTQC_ERROR:')))
            o_rtQcErrorMsg = [o_rtQcErrorMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'RTADJ_INFO:', length('RTADJ_INFO:')))
            o_rtAdjInfoMsg = [o_rtAdjInfoMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'RTADJ_WARNING:', length('RTADJ_WARNING:')))
            o_rtAdjWarningMsg = [o_rtAdjWarningMsg {strtrim(line)}];
         elseif (strncmp(upper(line), 'RTADJ_ERROR:', length('RTADJ_ERROR:')))
            o_rtAdjErrorMsg = [o_rtAdjErrorMsg {strtrim(line)}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break
         end
      end
   end
end

return
