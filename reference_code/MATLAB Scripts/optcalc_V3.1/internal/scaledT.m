function out=scaledT(in)
% function out=scaledT(in)
% calculate scaled temperature
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

out=log((298.15-in)./(273.15+in));