function out=aanderaarefitoldcalibrationcertificate(batchno,calibrationdate,temp,phase,p_cal,p_atm,sat,modeltype,phasecoef)
% function out=aanderaarefitoldcalibrationcertificate(batchno,calibrationdate,temp,phase,p_cal,p_atm,sat,modeltype,phasecoef)
%
% refit original Aanderaa calibration certificates to match, e.g., the
% uchida model and be integrated in GEOMARs standard processing
%
% inputs:
% batchno         - number of foil batch
% calibrationdate - date of calibration certificate's calibration
% temp            - 1x5 matrix of temperatures
% phase           - 7x5 matrix of phase readings
% p_cal           - 1x5 matrix or unique value of gas pressure (N2 & O2)
%                   used during calibration
% p_atm           - unique value of atmospheric pressure (e.g. obtained
%                   from eklima.met.no; 1000 hPa as 'Bergen default')
% sat             - 7x1 matrix of mixing ratio values O2/N2, if empty:
%                   as default 0, 1, 2, 5, 10, 20.9, 30 %
% modeltype       - functional model for refit; as default 'uchida'
% phasecoef       - provide phase coefficients if individual sensor refit;
%                   empty variable treated as no individual refit
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
% test=aanderaarefitoldcalibrationcertificate(aadib1707.batchno,aadib1707.calibrationdate,aadib1707.temp,aadib1707.phase,aadib1707.p_cal,aadib1707.p_atm,aadib1707.sat,'uchidasq',[]);

% sort inputs
if nargin<7 || isempty(sat)
    sat=[0;1;2;5;10;20.9;30];
end
if nargin<8
    modeltype='uchida';
end
if nargin<6
    p_atm=1000;
end
if nargin<9
    batchflag=1; % fit batch as such
else
    if isempty(phasecoef)
        batchflag=1;
    else
        batchflag=0; % use phase coefficients and refit surface to individual sensor
    end
end

% store metadata
out.batchno=batchno;
out.calibrationdate=calibrationdate;
out.refitdate=datestr(now);
out.modeltype=modeltype;

% deal with batch vs. individual sensor calibration
if batchflag % use phase from calibration certificate as such
    usedphase=phase(:);
else % individual sensor: scale phase from calibration certificate to sensor
    % (invert dp=phasecoef(1) + phasecoef(2)*bp + phasecoef(3)*bp.^2 + phasecoef(4)*bp.^3)
    usedphase=(phase-phasecoef(1))/phasecoef(2); % only first two coefficients are used..
    out.phasecoef=phasecoef;
end

% start to reorganize input data
[n,m]=size(phase);
if size(temp,2)==m & size(temp,1)==1
    temp=ones(n,1)*temp;
elseif size(temp,2)==1 & size(temp,1)==m % temperature flipped...
    temp=ones(n,1)*temp';
elseif ~isempty(setdiff(size(temp),[n m]))
    disp('Check size of temperature input! Processing might fail..')
end
p_cal=nanmean(p_cal);
out.p_calibrationgases=p_cal;
out.p_atm=p_atm;
if size(sat,2)==1 & size(sat,1)==n
    sat=sat*ones(1,m);
elseif size(sat,2)==n & size(sat,1)==1 % saturation flipped...
    sat=sat'*ones(1,m);
elseif ~isempty(setdiff(size(sat),[n m]))
    disp('Check size of saturation input! Processing might fail..')
end

% translate mixing ratio O2/N2 to equilibration partial pressure
% assume that calibration pressure gives sum of dry gases, i.e., only N2 
% and O2
pO2=p_cal.*sat/100; 
% assume that pressure gives equilibrium pressure of atmosphere, i.e., wet
% gases including N2 and O2 and water vapor
%pO2=(p_cal-watervapor(temp,0)*1013.25).*sat/100;

% convert equilibration partial pressure to oxygen concentration
% (=intermediate input to fitting routine; gets converted back to partial
% pressure again for uchida model inside optfitfoilcoef.m)
O2conc=pO2toO2conc(pO2,temp,0,p_atm,1); % p_atm = sum of wet gases

out.temp=temp(:);
out.phase=usedphase(:);
out.O2conc=O2conc(:);
out.batchflag=batchflag;

fcoef=optfitfoilcoef(temp(:),usedphase(:),O2conc(:),modeltype,0,p_atm,0.5*ones(size(O2conc(:))),0,0,4,false(size(O2conc(:))),{'Aanderaa old certificate refit',['batch no. ' num2str(batchno,'%.4u')]});
fnames=fieldnames(fcoef);
for i=1:length(fnames)
    eval(['out.' fnames{i} '=fcoef.' fnames{i} ';'])
end
