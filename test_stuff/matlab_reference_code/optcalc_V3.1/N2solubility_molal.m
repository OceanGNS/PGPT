function out=N2solubility_molal(T,S,P_atm)
% function out=N2solubility_molal(T,S,P_atm)
% calculate nitrogen solubilty / umol/kg at zero p_dbar after Hamme and
% Emerson 2004
% with (wet) atmospheric pressure scaling
%
% H. Bittig, GEOMAR
% 03.04.2011

if nargin<3
    P_atm=1; % 1 atm
else
    P_atm=P_atm/1013.25; %mbar -> atm
end
sca_T = scaledT(T);
out=(exp(6.42931+2.92704.*sca_T+4.32531.*sca_T.^2+4.69149.*sca_T.^3+...
   S.*(-0.00744129-0.00802566.*sca_T-0.0146775.*sca_T.^2)));
% do scaling to (wet) atmospheric pressure
% (only pN2 scaled, not pH2O)
% pH2O / atm
pH2O = 1.*watervapor(T,S);
out=out.*P_atm.*((1-pH2O./P_atm)./(1-pH2O));