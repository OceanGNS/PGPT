function foilcoefout=optfoilcoef_modelAtomodelB(foilcoefin,modeltypein,modeltypeout,temp,phase)
% function foilcoefout=optfoilcoef_modelAtomodelB(foilcoefin,modeltypein,modeltypeout,temp,phase)
%
% Convert optode foilcoefficients from one model to another
%
% inputs:
% foilcoefin   - input foilcoefs
% modeltypein  - modeltype of input foilcoefs
% modeltypeout - desired modeltype of output
% temp, phase  - locations of reference points to fit output model against
%                input model calculations (optional; standard 45 point
%                matrix used otherwise)
%
% outputs:
% foilcoefout  - output foilcoefs of modeltypeout
%
% part of optcalc-toolbox
% Henry Bittig, GEOMAR
% 13.01.2015

if nargin<3
    disp('At least 3 arguments needed!')
    return
end

if isstruct(foilcoefin)
    fcoef=foilcoefin.foilcoef;
else
    fcoef=foilcoefin;
end

if nargin<5 % use standard matrix plus 100 % saturation
    temp=[2:5:32]'*ones(1,6);
    current=[0 4 9 14 19 24; 0 4 9 14 19 24; 0 4 8 13 18 24; 0 4 8 12 17 22; 0 4 8 12 17 22; 0 4 7 11 15 20; 0 4 7 11 15 20;];
    O2conc=current./96485.*60*1e5/4;
    % add 100 % saturation values
    O2conc=[O2conc(:);O2sattoO2conc(100,[2;7;12],0,1013.25);];
    temp=[temp(:);2;7;12];
    bp0=interp1([0 300],[65 30],O2conc,'linear','extrap');bp0(bp0<26)=26;
    phase=bp0*NaN;
    for i=1:length(bp0)
        phase(i)=fzero(@(x)optcalcO2(temp(i),x,fcoef,modeltypein)-O2conc(i),bp0(i));
    end
end

O2conc=optcalcO2(temp,phase,fcoef,modeltypein);

% and fit new model at reference points
fout=optfitfoilcoef(temp,phase,O2conc,modeltypeout);
if isstruct(foilcoefin)
    foilcoefout=foilcoefin;
    foilcoefout.foilcoef=fout.foilcoef;
    foilcoefout.modeltype=modeltypeout;
    foilcoefout.note=char('*refit to different modeltype*',foilcoefout.note);
else
    foilcoefout=fout;
end