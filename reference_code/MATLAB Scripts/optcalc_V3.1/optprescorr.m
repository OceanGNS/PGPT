function oxygenprescorr=optprescorr(oxygen,pres,pcfactor)
%function oxygenprescorr=optprescorr(oxygen,pres,pcfactor)
% corrects optode readings for water pressure / db effect 
% linear correction with 3.2 percent as default (pcfactor optional)
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 11.12.2010

if nargin<3
    pcfactor=3.2;
end

corrf=1+0.01.*pcfactor.*pres./1000;
oxygenprescorr=oxygen.*corrf;