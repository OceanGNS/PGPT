function O2sal=O2freshtosal(O2fresh,T,S)
% function O2sal=O2freshtosal(O2fresh,T,S)
% apply salinity correction to "freshwater" oxygen concentration / umol/l
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

sca_T = scaledT(T);
O2sal=O2fresh.*exp(S.*(-0.00624097-0.00693498*sca_T-0.00690358*sca_T.^2-0.00429155*sca_T.^3)-3.11680e-7*S.^2);