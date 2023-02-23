function out=optfitfoilcoeffromstruct(wout,modeltype)
%
%
%
% Henry Bittig, GEOMAR
% 20.02.2013

%% started with
% dir2mat('readlabviewarbitrary','.txt')
%
%

if nargin<2
    modeltype='uchida';
end

if isfield(wout,'sal')
    sal=wout.sal(wout.goodi);
else
    sal=0;
end
if isfield(wout,'p_atm')
    patm=wout.p_atm(wout.goodi);
else
    patm=1013.25;
end

note={['Optode ' num2str(wout.model) ' SN ' num2str(wout.sn)],wout.note};

out=optfitfoilcoef(wout.t(wout.goodi),wout.bp(wout.goodi),wout.OW(wout.goodi),modeltype,sal,patm,wout.OWstd(wout.goodi),0,0,4,wout.generatorflag(wout.goodi),note);