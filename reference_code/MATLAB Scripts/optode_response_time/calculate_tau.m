function [ tau ] = calculate_tau( MTIME, PRES, DOXY, varargin )
% calculate_tau: calculate the response time for each pair of profiles
%
% Author: Christopher Gordon, chris.gordon@dal.ca
% Last update: Christopher Gordon, March 16, 2020
%
% INPUT
% -----------------------------------------------------------------------------
% REQUIRED ARGUMENTS
%
% MTIME: time matrix where each row is a profile, monotonically increasing
% dims(M, N)
%
% PRES: pressure matrix, should alternate between upcasts and downcasts
% dims(M, N)
%
% DOXY: dissolved oxygen matrix with valuues corresponding to each time/pressure
% dims(M, N)
%
% OPTIONAL PARAMETERS
%
% zlim: lower and upper depth bounds to perform optimization over,
% default is [25,175]
% dims(1, 2)
%
% zres: resolution for profiles to be interpolated to, default is 1
% dims(scalar)
%
% tlim: lower and upper time constant bounds to perform optimization over,
% default is [0,100]
% dims(1, 2)
%
% tres: resolition to linearly step through tlim, default is 1
% dims(scalar)
%
% OUTPUT
% -----------------------------------------------------------------------------
% tau: response time values for each pair of profiles dims(1, M-1)

% ------------------------- PARSE OPTIONAL PARAMETERS -------------------------
% zlim
index = find(strcmpi(varargin,'zlim'));
if isempty(index)
    zlim = [25,175];
%     fprintf('No ''zlim'' specified, optimizing between depths 25-175\n')
elseif length(varargin) >= index+1 && isvector(varargin{index+1})
    zlim = varargin{index+1};
end

% zres
index = find(strcmpi(varargin,'zres'));
if isempty(index)
    zres = 1;
%     fprintf('No ''zres'' specified, interpolating to resolution of 1\n')
elseif length(varargin) >= index+1 && isscalar(varargin{index+1})
    zres = varargin{index+1};
end

% tlim
index = find(strcmpi(varargin,'tlim'));
if isempty(index)
    tlim = [0,100];
%     fprintf('No ''tlim'' specified, optimizing over range of 0-100 seconds\n')
elseif length(varargin) >= index+1 && isvector(varargin{index+1})
    tlim = varargin{index+1};
end

% tres
index = find(strcmpi(varargin,'tres'));
if isempty(index)
    tres = 1;
%     fprintf('No ''tres'' specified, looking for optimal time constant using 1 second resolution\n')
elseif length(varargin) >= index+1 && isscalar(varargin{index+1})
    tres = varargin{index+1};
end

% ------------------------ CALCULATE RMSD FOR EACH TAU ------------------------

% dimensions of TEMP, PRES, and DOXY
[M, N] = size(DOXY);
% depth to interpolate to
ztarg = zlim(1):zres:zlim(2);
% time constants to loop through
time_constants = tlim(1):tres:tlim(2);
ntau = numel(time_constants);
% allocate array for optimized time constants
tau = nan(1, M-1);

for m=1:M-1
    % oxygen profiles
    profile1 = DOXY(m,:);
    profile2 = DOXY(m+1,:);
    % depth vectors
    depth1 = PRES(m,:);
    depth2 = PRES(m+1,:);
    % time vectors
    time1 = MTIME(m,:);
    time2 = MTIME(m+1,:);

    % filter nan values
    index1 = ~(isnan(profile1) | isnan(depth1) | isnan(time1));
    index2 = ~(isnan(profile2) | isnan(depth2) | isnan(time2));

    % allocate rmsd vector
    rmsd = nan(1, ntau);

    % loop through range of tau values
    for k=1:ntau
        % to be used in correction
        loop_tau = time_constants(k);
        % rmsd of each tau value
        rmsd(k) = profile_rmsd([profile1(index1);depth1(index1);time1(index1)],...
                               [profile2(index2);depth2(index2);time2(index2)],...
                               loop_tau,ztarg);
    end % for k=1:ntau
    % optimal time constant is the one with the lowest rmsd
    if ~any(rmsd) 
        disp('you got nans in your minimization')

        tau(m) = 0;
    else
        tau(m)= nanmin(time_constants(rmsd == nanmin(rmsd)));
    end
%     
end % for m=1:M-1

end  % function

% calculate rmsd between profiles for a give time constant
function rmsd = profile_rmsd(P1, P2, tau, z)
    % correct each profile
    corr1 = correct_oxygen_profile(P1(3,:), P1(1,:), tau);
    corr2 = correct_oxygen_profile(P2(3,:), P2(1,:), tau);
    % clean up unique points for interpolation
    [d1, c1] = clean(P1(2,:), corr1);
    [d2, c2] = clean(P2(2,:), corr2);
    % interpolated profiles
    ic1 = interp1(d1, c1, z);
    ic2 = interp1(d2, c2, z);
    % rmsd between interp profiles
    rmsd = calc_rmsd(ic1, ic2);
end % profile_rmsd

% clean up vectors, if there are any repeated depths interpolation will
% throw an error
function [ux, y_out] = clean(x, y)
    ux = unique(x);
    y_out = nan(size(ux));
    for ii=1:length(ux)
        rept = x==ux(ii);
        y_out(ii) = nanmean(y(rept));
    end % for ii=1:length(ux)
end % clean

% more compact rmsd calculation
function rmsd = calc_rmsd(x, y)
    rmsd = sqrt(nanmean((x - y).^2));
end % calc_rmsd
