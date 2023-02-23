function O2conc_sal=pO2toO2conc(pO2,T,S,P_atm,rhumid)
% function O2conc_sal=pO2toO2conc(pO2,T,S,P_atm,rhumid)
% calculate O2 concentration in umol/l from pO2 / mbar with salinity and
% atm. pressure / mbar correction (at relative humidity [0,1] for in-air
% measurement (optional))
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 22.02.2012

if nargin<5
    rhumid=1;
end
% pH2O / atm
pH2Osat=watervapor(T,S); % saturated water vapor / atm
pH2O = rhumid.*pH2Osat; % true water vapor / atm
% atm. pressure / atm
atm_press=P_atm/1013.25; 
% theta0
th0=1-(0.999025+0.00001426.*T-0.00000006436.*T.^2);
% O2 solubility / umol/l
oxy_sol=O2solubility(T,S);
% correct for non-ideal behaviour (Benson & Krause 1984)
oxy_sol_pc=oxy_sol.*(((1-pH2O./atm_press).*(1-th0.*atm_press))./((1-pH2O).*(1-th0)));
% pressure correct O2 solubility / umol atm / l and account for missing
% humidity (G&G 1992 at saturated water vapor)
oxy_sol_pc=oxy_sol_pc.*(atm_press-pH2O)./(1-pH2Osat);
% oxygen concentration in umol/l (salinity corrected)
O2conc_sal=(pO2.*oxy_sol_pc)./((atm_press-pH2O).*0.20946.*1013.25);