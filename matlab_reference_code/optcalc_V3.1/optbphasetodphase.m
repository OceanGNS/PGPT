function dphase=optbphasetodphase(bphase,phasecoef)
% function dphase=optbphasetodphase(bphase,phasecoef)
% convert raw phase (BPhase for 3830, TCPhase for 4330) to *two-point*
% calibrated phase (DPhase for 3830, CalPhase for 4330) using the internal
% phase coefficients (up to 4)
%
% part of optcalc-toolbox
% Henry Bittig, IFM-GEOMAR
% 31.03.2011

phasecoef=phasecoef(:);
dphase=polyval(flipud(phasecoef),bphase(:));