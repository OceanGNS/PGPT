function BPhase=volts2bphase(volts,phasecoef)
% function BPhase=volts2bphase(volts,phasecoef)
% convert analog output of AADI 3966 Digital-Analog Converter to BPhase
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

dphase=10+12.*volts;
BPhase=(dphase-phasecoef(1))./phasecoef(2);