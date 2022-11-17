function oxygen=optreverseprescorr(oxygenprescorr,pres,pcfactor)
%function oxygen=optreverseprescorr(oxygenprescorr,pres,pcfactor)
% reverses optode readings correction for water pressure / db effect 
% linear correction with 3.2 percent as default (pcfactor optional)
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 11.12.2010

if nargin<3
    pcfactor=3.2;
end

corrf=1+0.01.*pcfactor.*pres./1000;
oxygen=oxygenprescorr./corrf;