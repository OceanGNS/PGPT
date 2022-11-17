function [CORR_DOXY] = apply_tau_wTemp( MTIME, PRES, DOXY, TEMP,thickness,varargin )
% calculate_tau: calculate the response time for each pair of profiles
%
% Author: Christopher Gordon, chris.gordon@dal.ca
% Last update: Christopher Gordon, March 16, 2020
% Modified by Henry Bittig (IOW) to include temperature effect on tau, April 23, 2020
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
% DOXY: dissolved oxygen matrix with values corresponding to each time/pressure
% dims(M, N)
%
% TEMP: Temperature matrix with values corresponding to each time/pressure
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
% tlim: lower and upper empirical boundary layer thickness bounds to perform optimization over,
% default is [0,100]
% dims(1, 2)
%
% thickness can easily be converted to tau if temperature is specified
% (e.g., 5 degC or 20 degC) (see l. 131-134)
%
% tres: resolition to linearly step through tlim, default is 1
% dims(scalar)
%
% tvec: input vector of tau values, not compatible with tlim and tres inputs
% dims(1, K) where K is any number of tau values
%
% Tref: reference temperature at which to report tau value, default is 20 deg C
% dims(scalar)
%
% OUTPUT
% -----------------------------------------------------------------------------
% tau: response time values for each pair of profiles dims(1, M-1)

% ------------------------- PARSE OPTIONAL PARAMETERS -------------------------
% verbose
index = find(strcmpi(varargin,'verbose'));
if isempty(index)
    verbose = 0;
elseif length(varargin) >= index+1
    verbose = varargin{index+1};
end

% zlim
index = find(strcmpi(varargin,'zlim'));
if isempty(index)
    zlim = [25,175];
    if verbose
        fprintf('No ''zlim'' specified, optimizing between depths 25-175\n')
    end
elseif length(varargin) >= index+1 && isvector(varargin{index+1})
    zlim = varargin{index+1};
end

% zres
index = find(strcmpi(varargin,'zres'));
if isempty(index)
    zres = 1;
    if verbose
        fprintf('No ''zres'' specified, interpolating to resolution of 1\n')
    end
elseif length(varargin) >= index+1 && isscalar(varargin{index+1})
    zres = varargin{index+1};
end

% tlim
index = find(strcmpi(varargin,'tlim'));
if isempty(index)
    tlim = [25,150];
    if verbose
        fprintf('No ''tlim'' specified, optimizing over range of 25-150 micro-m\n')
    end
elseif length(varargin) >= index+1 && isvector(varargin{index+1})
    tlim = varargin{index+1};
end

% tres
index = find(strcmpi(varargin,'tres'));
if isempty(index)
    tres = 1;
    if verbose
        fprintf('No ''tres'' specified, looking for optimal thickness using 1 micro-m resolution\n')
    end
elseif length(varargin) >= index+1 && isscalar(varargin{index+1})
    tres = varargin{index+1};
end

% Tref
index = find(strcmpi(varargin,'tres'));
if isempty(index)
    Tref = 20;
    if verbose
        fprintf('No ''Tref'' specified, report response time at 20 deg C\n')
    end
elseif length(varargin) >= index+1 && isscalar(varargin{index+1})
    Tref = varargin{index+1};
end

% boundary layer thicknesses to loop through
time_constants = tlim(1):tres:tlim(2);

% tvec 
index = find(strcmpi(varargin,'tvec'));
% if length(varargin) >= index+1 && isvector(varargin{index+1})
%     time_constants = varargin{index+1};
% end

% ------------------------ CALCULATE RMSD FOR EACH TAU ------------------------

% dimensions of MTIME, PRES, DOXY, and TEMP
[M, N] = size(DOXY);
CORR_DOXY = DOXY*NaN;
% depth to interpolate to
ztarg = zlim(1):zres:zlim(2);
ntau = numel(time_constants);
% allocate array for optimized boundary layer thicknesses
% thickness = nan(1, M-1);
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
    % temperature vectors
    temp1 = TEMP(m,:);
    temp2 = TEMP(m+1,:);

    % filter nan values
    index1 = ~(isnan(profile1) | isnan(depth1) | isnan(time1) | isnan(temp1));
    index2 = ~(isnan(profile2) | isnan(depth2) | isnan(time2) | isnan(temp2));

    % allocate rmsd vector
%     rmsd = nan(1, ntau);

    % loop through range of thickness values
%     for k=1:ntau
%         % to be used in correction
%         loop_thickness = time_constants(k);
%         % rmsd of each thickness value
%         rmsd(k) = profile_rmsd([profile1(index1);depth1(index1);time1(index1);temp1(index1)],...
%                                [profile2(index2);depth2(index2);time2(index2);temp2(index2)],...
%                                loop_thickness,ztarg);
%     end % for k=1:ntau
%     % optimal boundary layer thickness is the one with the lowest rmsd
      [d1,c1,d2,c2]=corr_DOXY( [profile1(index1);depth1(index1);time1(index1);temp1(index1)],...
                               [profile2(index2);depth2(index2);time2(index2);temp2(index2)],...
                               thickness(m),ztarg)  ;

    CORR_DOXY(m,index1)=mean_interp(d1,c1,depth1(index1));
    CORR_DOXY(m+1,index2)=mean_interp(d2,c2,depth2(index2));

%     thickness(m) = time_constants(rmsd == nanmin(rmsd));
end % for m=1:M-1

% convert thickness to more graspable tau at a specified temperature
% in=dlmread('T_lL_tau_3830_4330.dat'); lL=in(1,2:end);T=in(2:end,1);tau100=in(2:end,2:end); clear in
% [lL,TEMP_LUT]=meshgrid(lL,TEMP_LUT);
% tau_Tref=interp2(lL,TEMP_LUT,tau100,thickness,Tref,'linear');

end  % function

% calculate rmsd between profiles for a given boundary layer thickness
function rmsd = profile_rmsd(P1, P2, thickness, z)
    % correct each profile
    corr1 = correct_oxygen_profile_wTemp(P1(3,:), P1(1,:), P1(4,:), thickness);
    corr2 = correct_oxygen_profile_wTemp(P2(3,:), P2(1,:), P2(4,:), thickness);
    % clean up unique points for interpolation
    [d1, c1] = clean(P1(2,:), corr1);
    [d2, c2] = clean(P2(2,:), corr2);
    % interpolated profiles
    ic1 = interp1(d1, c1, z);
    ic2 = interp1(d2, c2, z);
    % rmsd between interp profiles
    rmsd = calc_rmsd(ic1, ic2);
end % profile_rmsd

function [d1,c1,d2,c2] = corr_DOXY(P1, P2,thickness, z)
    % correct each profile
    corr1 = correct_oxygen_profile_wTemp(P1(3,:), P1(1,:), P1(4,:), thickness);
    corr2 = correct_oxygen_profile_wTemp(P2(3,:), P2(1,:), P2(4,:), thickness);
%     clean up unique points for interpolation
    [d1, c1] = clean(P1(2,:), corr1);
    [d2, c2] = clean(P2(2,:), corr2);
%     % interpolated profiles
%     ic1 = interp1(d1, c1, z);
%     ic2 = interp1(d2, c2, z);
    
%     % rmsd between interp profiles
%     rmsd = calc_rmsd(ic1, ic2);
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
