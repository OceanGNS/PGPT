% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = gl_update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = gl_update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}) == 1, 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;
   
   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      if (~isempty(var.Dimensions))
         idDims = find(strcmp(a_dimName, {var.Dimensions.Name}) == 1);
         if (~isempty(idDims))
            a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
            for idDim = 1:length(idDims)
               a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
            end
         end
      end
   end
end

o_outputSchema = a_inputSchema;

return
