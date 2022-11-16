function out=O2solubility(T,S,P_atm)
% function out=O2solubility(T,S,P_atm)
% calculate oxygen solubilty / umol/l after Garcia and Gordon 1992
% with scaling to wet atmospheric pressure P_atm
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

% uses conversion factor of 44.6590 (= 22.391903 l/mol)
%
% alternative: molar volume at STP of 22.392 l/mol
% Ref: CRC Handbook of Chemistry and Physics 
% 

if nargin<3
    P_atm=1; % 1 atm
else
    P_atm=P_atm/1013.25; %mbar -> atm
end
sca_T = scaledT(T);
out=((exp(2.00856+3.224.*sca_T+3.99063.*sca_T.^2+4.80299.*sca_T.^3+0.978188.*sca_T.^4+...
    1.71069.*sca_T.^5+S.*(-0.00624097-0.00693498.*sca_T-0.00690358.*sca_T.^2-0.00429155.*sca_T.^3)...
    -0.00000031168.*S.^2))./0.022391903);
% account for non-ideal behaviour of O2 (Benson and Krause 1984)
th0=1-(0.999025+0.00001426.*T-0.00000006436.*T.^2); % theta0
% do scaling to (wet) atmospheric pressure
% (only pO2 scaled, not pH2O)
% pH2O / atm
pH2O = 1.*watervapor(T,S);
out=out.*P_atm.*(((1-pH2O./P_atm).*(1-th0.*P_atm))./((1-pH2O).*(1-th0)));