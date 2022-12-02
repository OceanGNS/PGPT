function pO2=O2stoO2p(O2sat,T,S,P,p_atm)
%function pO2=O2stoO2p(O2sat,T,S,P,p_atm)
%
% convert oxygen saturation to oxygen partial pressure
%
% inputs:
%   O2sat  - oxygen saturation in %
%   T      - temperature in °C
%   S      - salinity (PSS-78)
%   P      - hydrostatic pressure in dbar (default: 0 dbar)
%   p_atm  - atmospheric (air) pressure in mbar (default: 1013.25 mbar)
%
% output:
%   pO2    - oxygen partial pressure in mbar
%
% according to recommendations by SCOR WG 142 "Quality Control Procedures
% for Oxygen and Other Biogeochemical Sensors on Floats and Gliders"
%
% Henry Bittig
% Laboratoire d'Océanographie de Villefranche-sur-Mer, France
% bittig@obs-vlfr.fr
% 28.10.2015

% set a few input defaults
if nargin<5, p_atm = 1013.25; end
if nargin<4, P     = 0;       end

xO2     = 0.20946; % mole fraction of O2 in dry air (Glueckauf 1951)
pH2Osat = 1013.25.*(exp(24.4543-(67.4509*(100./(T+273.15)))-(4.8489*log(((273.15+T)./100)))-0.000544.*S)); % saturated water vapor in mbar
Vm      = 0.317; % molar volume of O2 in m3 mol-1 Pa dbar-1 (Enns et al. 1965)
R       = 8.314; % universal gas constant in J mol-1 K-1

pO2=O2sat./100.*(xO2.*(p_atm-pH2Osat));