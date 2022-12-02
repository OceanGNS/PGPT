function out_kg=molar2molal(in_l,T,S,P_dbar)
% function out_kg=molar2molal(in_l,T,S,P_dbar)
% convert from molar unit x/l to molal unit x/kg using seawater densitiy at
% pressure level P / db(pressure level of intake: 11 dbar or surface/uw 
% box: 0 dbar)
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

if nargin<4
	P_dbar=0; %surface/box
end

dens_ss=sw_pden(S,T,P_dbar,0); % potential density at S, T, P with 0 dbar as reference
out_kg=in_l./(dens_ss./1000); %umol/l -> umol/kg