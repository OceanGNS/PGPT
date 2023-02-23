function out=O2solubility_molal(T,S,P_atm)
% function out=O2solubility_molal(T,S,P_atm)
% calculate oxygen solubilty / umol/kg at zero p_dbar after Garcia and
% Gordon 1992
% with (wet) atmospheric pressure scaling
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

if nargin<3
    P_atm=1; % 1 atm
else
    P_atm=P_atm/1013.25; %mbar -> atm
end
sca_T = scaledT(T);
out=(exp(5.80818+3.20684.*sca_T+4.11890.*sca_T.^2+4.93845.*sca_T.^3+1.01567.*sca_T.^4+...
    1.41575.*sca_T.^5+S.*(-0.00701211-0.00725958.*sca_T-0.00793334.*sca_T.^2-0.00554491.*sca_T.^3)...
    -0.000000132412.*S.^2));
% account for non-ideal behaviour of O2 (Benson and Krause 1984)
th0=1-(0.999025+0.00001426.*T-0.00000006436.*T.^2); % theta0
% do scaling to (wet) atmospheric pressure
% (only pO2 scaled, not pH2O)
% pH2O / atm
pH2O = 1.*watervapor(T,S);
out=out.*P_atm.*(((1-pH2O./P_atm).*(1-th0.*P_atm))./((1-pH2O).*(1-th0)));