function out=CO2solubility_molal(T,S,P_atm)
% function out=CO2solubility_molal(T,S,P_atm)
% calculate CO2 solubilty / mol/kg at zero p_dbar after Wiss 1974
% with (wet) atmospheric pressure scaling
%
% H. Bittig, GEOMAR
% 03.04.2012

if nargin<3
    P_atm=1; % 1 atm
else
    P_atm=P_atm/1013.25; %mbar -> atm
end
%% Calculates CO2 solubility in mol L-1 atm-1 from the equations of Weiss
%% 1974.
[co2_eq] = co2sol_b(T,S); % mol L-1 atm-1
% convert to molal
out=molar2molal(co2_eq,T,S); % mol kg-1 atm-1
% do scaling to (wet) atmospheric pressure
% (only pCO2 scaled, not pH2O)
% pH2O / atm
pH2O = 1.*watervapor(T,S);
out=out.*P_atm.*((1-pH2O./P_atm)./(1-pH2O));