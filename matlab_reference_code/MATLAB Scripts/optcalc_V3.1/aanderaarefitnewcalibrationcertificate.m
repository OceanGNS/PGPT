function out=aanderaarefitnewcalibrationcertificate(batchno,calibrationdate,temp,phase,O2conc,p_atm,modeltype,phasecoef,goodi)
% function out=aanderaarefitnewcalibrationcertificate(batchno,calibrationdate,temp,phase,O2conc,p_atm,modeltype,phasecoef,goodi)
%
% refit Aanderaa MkII calibration certificates to match, e.g., the
% uchida model and be integrated in GEOMARs standard processing
% 
% if phasecoef is given: translate multipoint batch-refit to individual
% sensor using its two-point calibration result
%
% inputs:
% batchno         - number of foil batch
% calibrationdate - date of calibration certificate's calibration
% temp            - temperatures
% phase           - phase readings
% O2conc          - O2 concentration / umol/L
% p_atm           - unique value of atmospheric pressure (e.g. obtained
%                   from eklima.met.no; 1000 hPa as 'Bergen default')
% modeltype       - functional model for refit; as default 'uchida'
% phasecoef       - provide phase coefficients if individual sensor refit;
%                   empty variable treated as no individual refit
% goodi           - logical index to (t,p,o2) tuples used for refit
%
%
% outputs:
% batchno         - number of foil batch
% calibrationdate - date of calibration certificate's calibration
% refitdate       - date of calibration certificate's refit (now)
% modeltype       - functional model for refit; as default 'uchida'
% 
%
% Henry Bittig, GEOMAR
% 27.01.2014

% usage:
% test=aanderaarefitoldcalibrationcertificate(aadib1707.batchno,aadib1707.calibrationdate,aadib1707.temp,aadib1707.phase,aadib1707.p_cal,aadib1707.p_atm,aadib1707.sat,'uchidasq');


% sort inputs
if nargin<9
    goodi=true(size(temp));
end
if nargin<8
    batchflag=1; % fit batch as such
else
    if isempty(phasecoef)
        batchflag=1;
    else
        batchflag=0; % use phase coefficients and refit surface to individual sensor
    end
end
if nargin<7
    modeltype='uchida';
end
if nargin<6
    p_atm=1000;
end

% store metadata
out.batchno=batchno;
out.calibrationdate=calibrationdate;
out.refitdate=datestr(now);
out.modeltype=modeltype;
out.p_atm=p_atm;

% deal with batch vs. individual sensor calibration
if batchflag % use phase from calibration certificate as such
    usedphase=phase(:);
else % individual sensor: scale phase from calibration certificate to sensor
    % (invert dp=phasecoef(1) + phasecoef(2)*bp + phasecoef(3)*bp.^2 + phasecoef(4)*bp.^3)
    usedphase=(phase-phasecoef(1))/phasecoef(2); % only first two coefficients are used..
    out.phasecoef=phasecoef;
end
% start to reorganize input data
out.temp=temp(:);
out.phase=usedphase;
out.O2conc=O2conc(:);
out.goodi=goodi;
out.batchflag=batchflag;


fcoef=optfitfoilcoef(temp(goodi),usedphase(goodi),O2conc(goodi),modeltype,0,p_atm,0.5*ones(size(O2conc(goodi))),0,0,4,false(size(O2conc(goodi))),{'Aanderaa new certificate refit',['batch no. ' num2str(batchno,'%.4u')]});
fnames=fieldnames(fcoef);
for i=1:length(fnames)
    eval(['out.' fnames{i} '=fcoef.' fnames{i} ';'])
end
