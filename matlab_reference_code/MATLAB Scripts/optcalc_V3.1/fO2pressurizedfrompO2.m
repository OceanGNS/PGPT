function fO2=fO2pressurizedfrompO2(pO2,TEMP,PRES,VmO2)
%function fO2=fO2pressurizedfrompO2(pO2,TEMP,PRES)
%
% use Taylor 1978 relationship to calculate increasing O2 partial pressure
% with hydrostatic pressure
%
% uses more recent value of 8.314 J K-1 mol-1 for universal gas constant
%
% Henry Bittig, GEOMAR
% 10.02.2015

if nargin<4,
    % partial molar volume of O2 in sea water (Enns 1965)
    VmO2=31.7  ./1e6; % molar volume of O2; mL mol-1 -> m3 mol-1
else
    VmO2=VmO2  ./1e6; % molar volume of O2; mL mol-1 -> m3 mol-1
end
R   =8.314 ./1e4; % J mol-1 K-1 = m3 Pa mol-1 K-1 -> m3 dbar mol-1 K-1

fO2=pO2.*exp(VmO2.*PRES./R./(TEMP+273.15));