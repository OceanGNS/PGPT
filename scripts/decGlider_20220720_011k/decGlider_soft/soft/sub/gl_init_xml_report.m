% ------------------------------------------------------------------------------
% Initialize XML report.
%
% SYNTAX :
%  gl_init_xml_report(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function gl_init_xml_report(a_time)

% DOM node of XML report
global g_decGl_xmlReportDOMNode;

% decoder version
global g_decGl_decoderVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('CO-04-17'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode(sprintf('EGO Coriolis Matlab decoder (version %s)', g_decGl_decoderVersion)));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSS.FFF'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_decGl_xmlReportDOMNode = docNode;

return
