function [ DO_out ] = correct_oxygen_profile_wTemp( MTIME, DO, TEMP, thickness )
% correct_oxygen_profile: Correct a single oxygen profile using a given
% empirical boundary layer thickness (thickness). Used by calculate_tau.m
% but can also be used on its own when thickness is known.
%
% The filter used here is the mean filter given in Bittig and Körtzinger (2017)
% equation A3. Mean times are taken as well, and then oxygen is interpolated
% back to the original input times such that dimensions match the input.
%
% Bittig and Körtzinger (2017): Bittig, H. C., & Körtzinger, A. (2017).
% Technical Note: Oxygen Optodes on Profiling Platforms: Update on Response
% Times, In-Air Measurements, and In-Situ Drift. Ocean Science. 13, 1-11
% https://doi.org/10.5194/os-13-1-2017
%
% Author: Christopher Gordon, chris.gordon@dal.ca
% Last update: Christopher Gordon, January 28, 2020
% Modified by Henry Bittig (IOW) to include temperature effect on tau, April 23, 2020
%
% INPUT
% -----------------------------------------------------------------------------
% MTIME: time vector, monotonically increasing, matlab datenum, dims(1, N)
% DO: dissolved oxygen vector, dims(1, N)
% TEMP: temperature vector, dims(1, N)
% tau: response time in seconds, scalar
%
% OUTPUT
% -----------------------------------------------------------------------------
% DO_out: corrected oxygen profile, dims(1, N)

% pre-allocate arrays
N = numel(DO);
mean_oxy  = nan(N-1,1);

% convert time to seconds
t_sec = MTIME*24*60*60;
% calculate mean temperature, timestep in seconds, and mean time
mean_temp=0.5*TEMP(1:end-1)+0.5*TEMP(2:end);
dt=t_sec(2:end)-t_sec(1:end-1);
mean_time=t_sec(1:end-1)+dt/2;

% add temperature-dependence to tau
% Use results of boundary layer model of Bittig et al. 2014:
% Temperature-dependence of tau is dominated by T-influence on solubilities
% and diffusivities, while boundary layer thickness, lL, is T-independent
% -> use lL to add temperature-dependence on tau

% load Bittig et al. 2014 data, supplement to Bittig and K�rtzinger 2017
in=dlmread('T_lL_tau_3830_4330.dat'); lL=in(1,2:end);T=in(2:end,1);tau100=in(2:end,2:end); clear in
[lL,T]=meshgrid(lL,T);
% expand value of boundary layer thickness to proper dimension
thickness=thickness*ones(1,N-1);
% translate boundary layer thickness back to temperature-dependent tau
tau_T=reshape(interp2(lL,T,tau100,thickness,mean_temp,'linear'),size(dt));

% loop through oxygen data
for i=1:N-1
    % do the correction using the mean filter
    mean_oxy(i)  = (1/(2*oxy_b(dt(i),tau_T(i))))*(DO(i+1) - oxy_a(dt(i),tau_T(i))*DO(i));
end % for

% interpolate back to original times for output
DO_out = interp1(mean_time,mean_oxy,t_sec,'linear');

end  % function

function b = oxy_b(dt,tau)
    inv_b = 1 + 2*(tau/dt);
    b = 1/inv_b;
end

function a = oxy_a(dt,tau)
    a = 1 - 2*oxy_b(dt,tau);
end
