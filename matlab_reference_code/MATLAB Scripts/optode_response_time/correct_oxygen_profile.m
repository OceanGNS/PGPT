function [ DO_out ] = correct_oxygen_profile( t, DO, tau )
% correct_oxygen_profile: Correct a single oxygen profile using a given
% response time (tau). Used by calculate_tau.m but can also be used on its own
% when tau is known.
%
% The filter used here is the mean filter given in Bittig and Körtzinger (2016)
% equation A3. Mean times are taken as well, and then oxygen is interpolated
% back to the original input times such that dimensions match the input.
%
% Bittig and Körtzinger (2016): Bittig, H. C., & Körtzinger, A. (2016).
% Technical Note: Oxygen Optodes on Profiling Platforms: Update on Response
% Times, In-Air Measurements, and In-Situ Drift. Ocean Science Discussions.
% http://doi.org/10.5194/os-2016-75
%
% Author: Christopher Gordon, chris.gordon@dal.ca
% Last update: Christopher Gordon, January 28, 2020
%
% INPUT
% -----------------------------------------------------------------------------
% t: time vector, monotonically increasing, matlab datenum, dims(1, N)
% DO: dissolved oxygen vector, dims(1, N)
% tau: response time in seconds, scalar
%
% OUTPUT
% -----------------------------------------------------------------------------
% DO_out: corrected oxygen profile, dims(1, N)

% pre-allocate arrays
N = numel(DO);
mean_oxy  = nan(N-1,1);
mean_time = nan(N-1,1);

% convert time to seconds
t_sec = t*24*60*60;

% loop through oxygen data
for i=1:N-1
    dt = t_sec(i+1) - t_sec(i); % timestep in seconds

    % do the correction using the mean filter, get the mean time
    mean_oxy(i)  = (1/(2*oxy_b(dt,tau)))*(DO(i+1) - oxy_a(dt,tau)*DO(i));
    mean_time(i) = t_sec(i) + dt/2;
end % for

% interpolate back to original times for output
% if length(mean_oxy)>2
    DO_out = interp1(mean_time,mean_oxy,t_sec,'linear');
% else
%     DO_out = t_sec*0+nanmedian(mean_oxy);
% end

end % function

function b = oxy_b(dt,tau)
    inv_b = 1 + 2*(tau/dt);
    b = 1/inv_b;
end

function a = oxy_a(dt,tau)
    a = 1 - 2*oxy_b(dt,tau);
end
