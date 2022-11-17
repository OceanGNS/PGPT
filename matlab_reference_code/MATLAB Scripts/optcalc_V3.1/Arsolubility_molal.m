function out=Arsolubility_molal(T,S,P_atm)
% function out=Arsolubility_molal(T,S,P_atm)
% calculate argon solubilty / umol/kg at zero p_dbar after Hamme and
% Emerson 2004
% with (wet) atmospheric pressure scaling
%
% H. Bittig, GEOMAR
% 03.04.2012

if nargin<3
    P_atm=1; % 1 atm
else
    P_atm=P_atm/1013.25; %mbar -> atm
end
sca_T = scaledT(T);
out=(exp(2.79150+3.17609.*sca_T+4.13116.*sca_T.^2+4.90379.*sca_T.^3+...
   S.*(-0.00696233-0.00766670.*sca_T-0.0116888.*sca_T.^2)));
% do scaling to (wet) atmospheric pressure
% (only pAr scaled, not pH2O)
% pH2O / atm
pH2O = 1.*watervapor(T,S);
out=out.*P_atm.*((1-pH2O./P_atm)./(1-pH2O));