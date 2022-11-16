function O2fresh=O2saltofresh(O2sal,T,S)
% function O2fresh=O2saltofresh(O2sal,T,S)
% reverse salinity correction and get initial "freshwater" oxygen optode reading / umol/l
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

sca_T = scaledT(T);
%O2fresh=O2sal./exp(S.*(-0.00624097-0.00693498*sca_T-0.00690358*sca_T.^2-0.00429155*sca_T.^3)-3.11680e-7*S.^2); % Garcia and Gordon 1992, combined refit (superseded)
Scorr   = exp(S.*(-6.24523e-3-7.37614e-3.*sca_T-1.03410e-3.*sca_T.^2-8.17083e-3.*sca_T.^3)-4.88682e-7.*S.^2); % salinity correction part from Garcia and Gordon (1992), Benson and Krause (1984) refit ml(STP) L-1
pH2Osat = 1013.25.*(exp(24.4543-(67.4509*(100./(T+273.15)))-(4.8489*log(((273.15+T)./100)))-0.000544.*S)); % saturated water vapor in mbar
pH2Osatfresh = 1013.25.*(exp(24.4543-(67.4509*(100./(T+273.15)))-(4.8489*log(((273.15+T)./100)))-0.000544.*0)); % saturated water vapor in mbar in freshwater
O2fresh=O2sal./(Scorr.*(1013.25-pH2Osatfresh)./(1013.25-pH2Osat)); % Garcia and Gordon 1992, Benson and Krause 1984 refit