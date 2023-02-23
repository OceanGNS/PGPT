function var=scale_var(var,sfac)
% function scales the variable far rounding (down) to the nearest fraction
% given by sfac. Its usefull for binning data into categories etc.
% 
% Example: 
% 
% scale_var([0.3 0.555 0.66 0.777],0.01)
% 
% ans =
% 
%     0.3000
%     0.5500
%     0.6600
%     0.7700
% 
% $Nicolai Bronikowski, nbronikowski@mun.ca
% September 2020, MUN glidertoolbox
    [M,N] = size(var);
    for i = 1:N
        idnan = find(~isnan(var(:,i)));
        var(idnan,i) = floor(var(idnan,i)) + floor((var(idnan,i)-floor(var(idnan,i)))/sfac) * sfac;
    end
end