function oxygen=optcalcO2(temp,phase,foilcoef,modeltype,sal,P_atm,P_dbar,pcfactor)
% function oxygen=optcalcO2(temp,phase,foilcoef,modeltype,sal,P_atm,P_dbar,pcfactor,rhumid)
%
% apply polynomial fit/foil coefficients to optode phase and temperature 
% measurements according to specified model and calculate O2 in umol/l (or
% as desired)
% model: 
% 'aanderaa'   - 20 coefficient matrix 3rd order in t and 4th order
%                (via O2conc calculation only) (phase = DPhase/CalPhase!)
%                No atmospheric pressure required
% '3x4b'       - 14 coefficient matrix by Craig Neill (via pO2 calculation)
%                (phase = BPhase/TCPhase)
% '5x5b'       - AADI 4330 21 coefficients; 21 coefficient matrix by Craig Neill 
%                (via pO2 calculation) (phase = BPhase/TCPhase)
% 'uchida'     - 7 coefficients following Stern-Volmer equation derived
%                approach (Uchida et al. 2008 equation but via pO2 calculation)
% 'uchidaAADI' - 7 coefficients following Stern-Volmer equation derived
%                approach (exact Uchida et al. 2008; AADI variant directly
%                on O2conc)
% 'uchidasq'   - 7 coefficients following Stern-Volmer equation derived
%                approach (after Uchida et al. 2008 and adapted squared
%                term) (via pO2 calculation)
% 'uchidasqmolar' - 7 coefficients following Stern-Volmer equation derived
%                approach (after Uchida et al. 2008 and adapted squared
%                term) to give O2 conc directly instead of more reasonable pO2
% 'uchidaSBE'  - 8 coefficients following Stern-Volmer equation derived 
%                approach (after Uchida et al. 2008 and adapted terms), 
%                (via pO2 calculation)
% 'uchidaSBEmolar' - 8 coefficients following Stern-Volmer equation derived 
%                approach (after Uchida et al. 2008 and adapted terms) to
%                give O2 conc directly instead of more reasonable pO2
% 'uchidasimple'- 6 coefficients following Stern-Volmer equation derived
%                approach (after Uchida et al. 2008, simplified after GO
%                SHIP Hydrography Manual (Version 1, 2010); via pO2 calculation)
% 'uchidasimplemolar' - 6 coefficients following Stern-Volmer equation 
%                derived approach (after Uchida et al. 2008, simplified 
%                after GO SHIP Hydrography Manual (Version 1, 2010)) to
%                give O2 conc directly instead of more reasonable pO2
% 'any number' - upper polynomial matrix in bphase & t up to degree n
%                (1x1b, 2x2b, 3x3b, 4x4b) (via pO2 calculation)
% (if no modeltype is given size/shape of foilcoef is used as indicator)
%
% salinity can be of same length as temp/phase or singular value (default:
% sal = 0)
% atmospheric/gas pressure can be of same length as temp/phase or singular 
% value (default: P_atm = 1013.25 mbar) (=atmospheric pressure if available)
% hydrostatic pressure can be of same length as temp/phase or singular
% value (default: P_dbar = 0 dbar)
% pcmodeltype (optional) determines pressure correction:
%     any numeric value: linear % increase per 1000 dbar (classical correction: 3.2)
%     'Aanderaa' or 'AADI' : use revised optode calculation scheme of 
%                            Bittig et al. 2015 for Aanderaa optodes (default)
%     'Seabird' or 'SBE'   : use revised optode calculation scheme of 
%                            Bittig et al. 2015 for Sea-Bird optodes
%     'RINKO'
% rhumid (optional) gives relative humidity (between 0 and 1) (default: 1)
% for measurements in air
%
% relevant subfunctions at end of m-file
%
% part of optcalc-toolbox
% Henry Bittig, EOMAR
% 01.11.2010
% revised 30.09.2011
% cleaned-up 13.01.2015
% v2: inclusion of Bittig et al. 2015 pressure correction 03.06.2015
% v3: change to SCOR WG 142 recommendations on O2 conversion 28.01.2016
%     functions can be found at http://dx.doi.org/10.13155/45915
% v3.1: temp can be a 2x1 cell instead of an array: first element: TEMP
% from CTD, second element: TEMP_DOXY (to split unit conversion and O2
% calculation)

% check and clean up input variables
if nargin<3
    disp('too few input variables')
    return
else
    if iscell(temp)
        temp_doxy=temp{2};
        temp=temp{1};
    else
        temp_doxy=temp; % simple copy
    end
    if size(temp)~=size(phase)
        disp('variable sizes don''t match')
        return
    end
end

% remember shape of input
shape=size(temp);

if nargin<4
    %modeltype='aanderaa';
    [modeltype,foilcoef]=getmodeltype(foilcoef);
else
    modeltype=lower(modeltype);
    [n,m]=size(foilcoef);
    if m>n
        disp('foilcoef flipped')
        foilcoef=foilcoef';
    end
end

if nargin<5
    sal=zeros(shape);
else
    if find(~(size(sal)==shape)) %size(sal)~=shape
        if length(sal)==1
            sal=ones(shape).*sal;
            %disp('expand salinity to match variable size')
        else
            disp('salinity size doesn''t match')
            return
        end
    end
end

if nargin<6
    P_atm=ones(shape).*1013.25; % mbar
else
    if size(P_atm)~=shape
        if length(P_atm)==1
            P_atm=ones(shape).*P_atm;
            %disp('expand atmospheric pressure to match variable size')
        else
            disp('atmospheric pressure size doesn''t match')
            return
        end
    end
end

if nargin<7
    P_dbar=zeros(shape); % dbar
else
    if size(P_dbar)~=shape
        if length(P_dbar)==1
            P_dbar=ones(shape).*P_dbar;
            %disp('expand hydrostatic pressure to match variable size')
        else
            disp('hydrostatic pressure size doesn''t match')
            return
        end
    end
end

if nargin<8
    pcfactor='A'; % Bittig et al. 2015 as default for 3830 / 4330 standard foil
end
%{
if nargin<9
    rhumid=1;
else
    if size(rhumid)~=shape
        if length(rhumid)==1
            rhumid=ones(shape).*rhumid;
        else
            disp('relative humidity size doesn''t match')
            return
        end
    end
end
%}

%make column vectors
temp=temp(:);
temp_doxy=temp_doxy(:);
phase=phase(:);
%foilcoef=foilcoef(:);
sal=sal(:);
P_atm=P_atm(:);
P_dbar=P_dbar(:);
%rhumid=rhumid(:);

% check for O2-independent pressure correction
if ~isnumeric(pcfactor)
    if strncmpi(pcfactor,'a',1) % Aanderaa
	    phase = phase + 0.1 .* P_dbar/1000; % do O2-independent phase adjustment
        pcfactor=4.19+0.022.*temp; % and calculate temperature-dependent O2 pressure factor
	elseif strncmpi(pcfactor,'s',1) % Sea-Bird
		phase = phase + 0.115 .* P_dbar/1000; % do O2-independent phase adjustment
        pcfactor=4.19+0.022.*temp; % and calculate temperature-dependent O2 pressure factor
    end
end

%do actual calculation according to specified modeltype
if strcmp(modeltype,'unknown')
    disp('unknown model: foilcoef doesn''t fit any expected size!')
    return
elseif (strcmp(modeltype,'aanderaa')|strcmp(modeltype,'3830'))
    %check number of foil coefficients
    if size(foilcoef,1)~=20
        if find(size(foilcoef)==[5 4])
            foilcoef=reshape(foilcoef',20,1);
        elseif find(size(foilcoef)==[4 5])
            foilcoef=reshape(foilcoef,20,1);
        else
            disp('number of foil coefficient doesn''t match model type!')
            return
        end
    end
    % oxygen concentration in umol/l from Aanderaa coefficients
    % freshwater (phase should be dphase!)
    oxy_conc0_fresh=optodefun3830(foilcoef,[temp_doxy,phase]);
    %pO2=O2conctopO2(oxy_conc0_fresh,temp,0,P_atm,rhumid);
    pO2=O2ctoO2p(oxy_conc0_fresh,temp,0,0); % P_dbar=0 because functional models ignore pressure exponential..
elseif  strcmp(modeltype,'3x4b')
    if size(foilcoef,1)~=14
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (3x4b model polynom)
    % (phase should be bphase)
    pO2 = optodefun3x4b(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'5x5b')
    if size(foilcoef,1)~=21
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (5x5b model polynom)
    % (phase should be bphase)
    pO2 = optodefun5x5b(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchida')
    if size(foilcoef,1)~=7
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunUchida(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchida2')
    if size(foilcoef,1)~=8
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunUchida(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchidaaadi')
    if size(foilcoef,1)~=7
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % oxygen concentration in umol/l from Aanderaa coefficients
    % in freshwater (phase should be bphase)
    oxy_conc0_fresh = optodefunUchida(foilcoef,[temp_doxy,phase]);
    %pO2=O2conctopO2(oxy_conc0_fresh,temp,0,P_atm,rhumid);
    pO2=O2ctoO2p(oxy_conc0_fresh,temp,0,0); % P_dbar=0 because functional models ignore pressure exponential..
elseif  strcmp(modeltype,'uchidasq')
    if size(foilcoef,1)~=7
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunUchidasq(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchidasq2')
    if size(foilcoef,1)~=8
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunUchidasq2(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchidasqmolar')
    if size(foilcoef,1)~=7
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % oxygen concentration in umol/l in freshwater (phase should be bphase)
    oxy_conc0_fresh = optodefunUchidasq(foilcoef,[temp_doxy,phase]);
    %pO2=O2conctopO2(oxy_conc0_fresh,temp,0,P_atm,rhumid);
    pO2=O2ctoO2p(oxy_conc0_fresh,temp,0,0); % P_dbar=0 because functional models ignore pressure exponential..
elseif  strcmp(modeltype,'uchidasbe')
    if size(foilcoef,1)~=8
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunUchidaSBE(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchidasbemolar')
    if size(foilcoef,1)~=8
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % oxygen concentration in umol/l in freshwater (phase should be bphase)
    oxy_conc0_fresh = optodefunUchidaSBE(foilcoef,[temp_doxy,phase]);
    %pO2=O2conctopO2(oxy_conc0_fresh,temp,0,P_atm,rhumid);
    pO2=O2ctoO2p(oxy_conc0_fresh,temp,0,0); % P_dbar=0 because functional models ignore pressure exponential..
elseif  strcmp(modeltype,'uchidasimple')
    if size(foilcoef,1)~=6
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunUchidasimple(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'uchidasimplemolar')
    if size(foilcoef,1)~=6
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % oxygen concentration in umol/l in freshwater (phase should be bphase)
    oxy_conc0_fresh = optodefunUchidasimple(foilcoef,[temp_doxy,phase]);
    %pO2=O2conctopO2(oxy_conc0_fresh,temp,0,P_atm,rhumid);
    pO2=O2ctoO2p(oxy_conc0_fresh,temp,0,0); % P_dbar=0 because functional models ignore pressure exponential..
elseif  strcmp(modeltype,'mcneil')
    if size(foilcoef,1)~=6
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunMcNeil(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'rinko')
    if size(foilcoef,1)~=7
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (phase should be bphase)
    pO2 = optodefunrinko(foilcoef,[temp_doxy,phase]);
elseif  strcmp(modeltype,'rinkomolar')
    if size(foilcoef,1)~=7
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % oxygen concentration in umol/l in freshwater (phase should be bphase)
    oxy_conc0_fresh = optodefunrinko(foilcoef,[temp_doxy,phase]);
    %pO2=O2conctopO2(oxy_conc0_fresh,temp,0,P_atm,rhumid);
    pO2=O2ctoO2p(oxy_conc0_fresh,temp,0,0); % P_dbar=0 because functional models ignore pressure exponential..
elseif ~isnan(str2double(modeltype))
    n=str2double(modeltype);
    if size(foilcoef,1)~=(n+1)*(n+2)/2
        disp('number of foil coefficient doesn''t match model type!')
        return
    end
    % pO2 in mbar from individual coefficients (mixed polynom)
    % (phase should be bphase)
    pO2 = diag(polyval2(foilcoef',temp_doxy,phase));
else
    disp('unknown model! Check input and size of foil coefficients.')
    return
end

% oxygen concentration (salinity corrected) in umol/l
%oxy_conc0=pO2toO2conc(pO2,temp,sal,P_atm,rhumid);
oxy_conc0=O2ptoO2c(pO2,temp,sal,0); % P_dbar=0 because functional models ignore pressure exponential..
% pressure correction to saltwater concentration
oxy_conc0=optprescorr(oxy_conc0,P_dbar,pcfactor);

% oxygen concentration in umol/kg (salinity corrected and pressure
% corrected (input))
%oxy_conc=molar2molal(oxy_conc0,temp,sal,P_dbar);

% set actual output: 
oxygen=reshape(oxy_conc0,shape);

%function out=scaledT(in)
%% calculate scaled temperature
%out=log((298.15-in)./(273.15+in));

%function pw=watervapor(T,S)
%% calculating pH2O / atm after Weiss and Price 1980
%% T in °C
%pw=(exp(24.4543-(67.4509*(100./(T+273.15)))-(4.8489*log(((273.15+T)./100)))-0.000544.*S));

%function out=O2solubility(T,S)
%% calculate oxygen solubilty / umol/l
%sca_T = scaledT(T);
%out=((exp(2.00856+3.224.*sca_T+3.99063.*sca_T.^2+4.80299.*sca_T.^3+0.978188.*sca_T.^4+...
%    1.71069.*sca_T.^5+S.*(-0.00624097-0.00693498.*sca_T-0.00690358.*sca_T.^2-0.00429155.*sca_T.^3)...
%    -0.00000031168.*S.^2))./0.022391903);

%function O2sal=O2freshtosal(O2fresh,T,S)
%% apply salinity correction to oxygen concentration / umol/l
%sca_T = scaledT(T);
%O2sal=O2fresh.*exp(S.*(-0.00624097-0.00693498*sca_T-0.00690358*sca_T.^2-0.00429155*sca_T.^3)-3.11680e-7*S.^2);

%function out_kg=molar2molal(in_l,T,S,P_dbar)
%% convert from molar unit x/l to molal unit x/kg using seawater densitiy at
%% pressure level P / db(pressure level of intake: 11 dbar or surface/uw 
%% box: 0 dbar)
%
%if nargin<4
%	P_dbar=0; %surface/box
%end
%
%dens_ss=sw_pden(S,T,P_dbar,0); % potential density at S, T, P with 0 dbar as reference
%out_kg=in_l./(dens_ss./1000); %umol/l -> umol/kg