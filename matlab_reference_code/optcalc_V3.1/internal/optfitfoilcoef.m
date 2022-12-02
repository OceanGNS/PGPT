function out=optfitfoilcoef(temp,phase,oxygen,modeltype,sal,P_atm,oxygenstd,weightedflag,P_dbar,pcfactor,generatorflag,note)
% function out=optfitfoilcoef(temp,phase,oxygen,modeltype,sal,P_atm,oxygenstd,weightedflag,P_dbar,pcfactor,generatorflag,note)
%
% polynomial fit of oxygen measurements to optode phase and temperature
% according to specified model
% model: 
% 'aanderaa' - 20 coefficient matrix 3rd order in t and 4th order
%             in O2conc                          **(oxygen = O2conc; O2conc fitted; phase = DPhase!)**
% '3x4b'    - 14 coefficient matrix by Craig Neill (oxygen = O2conc; pO2 fitted)
% '5x5b'    - AADI 21 coefficients; 21 coefficient matrix by Craig Neill
%                                                  (oxygen = O2conc; pO2 fitted)
% 'uchidasimple'- 6 coefficients following Stern-Volmer equation derived
%             approach (after Uchida et al. 2008, simplified after GO SHIP 
%             Hydrography Manual (Version 1, 2010) (oxygen = O2conc; pO2 fitted))
% 'uchida' (default) - 7 coefficients following Stern-Volmer equation derived
%             approach (exact Uchida et al. 2008)    (oxygen = O2conc; pO2 fitted)
% 'uchidaAADI' - 7 coefficients following Stern-Volmer equation derived
%             approach (exact Uchida et al. 2008; AADI variant (directly on O2 conc)
%                                                    (oxygen = O2conc; O2conc fitted)
% 'uchidasq'  - 7 coefficients following Stern-Volmer equation derived
%             approach (after Uchida et al. 2008; plus squared term)
%                                                    (oxygen = O2conc; pO2 fitted)
% 'uchidasqmolar'  - 7 coefficients following Stern-Volmer equation derived
%             approach (after Uchida et al. 2008; plus squared term)
%                                                    (oxygen = O2conc; O2conc fitted)
% 'uchidaSBE' - 8 coefficients following Stern-Volmer equation derived
%             approach (after Uchida et al. 2008; Sea-Bird variant)
%                                                    (oxygen = O2conc; pO2 fitted)
% 'uchidaSBEmolar' - 8 coefficients following Stern-Volmer equation derived
%             approach (after Uchida et al. 2008; Sea-Bird variant; gives O2conc instead of pO2)
%                                                    (oxygen = O2conc; O2conc fitted)

% 'any number' - upper polynomial matrix in bphase & t for pO2 (oxygen = O2conc; pO2 fitted)
%
% salinity (default = 0) and atm./GTD pressure (default = 1013.25 mbar) optional
%
% when weightedflag is set to 1, oxygenstd is used for a weighted fit
% (default: weightedflag = 0)
%
% if reference oxygen samples are taken at significant hydrostatic
% pressure, optode readings must be adjusted. Optional argument P_dbar
% gives respective pressure levels / dbar (Default: 0 dbar)
%
% set generatorflag to 1 if sensor data is from O2 generator calibration
% (takes care of salinity effect of 0.02M NaOH medium) (Default: 0)
%
% note - add comment / name of calibration run to output structure
%
% output is structure with fields
%   foilcoef     - foil coefficients from fit in first column and confidence
%                  interval in second column or in 5x4 shape (aanderaa), respectively
%   fint         - foil coefficients confidence intervals for aanderaa type
%                  model in 5x4 shape
%   r / rpO2     - residual of fit in umol/l / mbar
%   mse / msepO2 - mean squared error for concentration / partial pressure
%   weighted     - 1 or 0
%
% part of optcalc-toolbox
% Henry Bittig, IFM-GEOMAR
% 01.11.2010
% revised 29.02.2012
% cleaned-up 13.01.2015

brightness=[.5 .5 .5];

simpleplot=1; % 1: only 2:1 panel subplot (0: 2:2:1 panel subplot)
ext=1;

if nargin<3
    disp('too few input variables')
    return
else
    if any(size(temp)~=size(oxygen) | size(temp)~=size(phase))
        disp('variable sizes don''t match')
        return
    end
end

if nargin<4
    modeltype='uchida';
else
    modeltype=lower(modeltype);
end

%make column vectors
temp=temp(:);
phase=phase(:);
oxygen=oxygen(:);

shape=length(temp);

if nargin<5
    sal=zeros(shape,1);
else
    sal=sal(:);
    if length(sal)~=shape
        if length(sal)==1
            sal=ones(shape,1).*sal;
            %disp('expand salinity to match variable size')
        else
            disp('salinity size doesn''t match')
            return
        end
    end
end

if nargin<6
    P_atm=ones(shape,1).*1013.25;
else
    P_atm=P_atm(:);
    if length(P_atm)~=shape
        if length(P_atm)==1
            P_atm=ones(shape,1).*P_atm;
            %disp('expand atmospheric pressure to match variable size')
        else
            disp('atmospheric pressure size doesn''t match')
            return
        end
    end
end

if nargin<7
    oxygenstd=zeros(shape,1);
end

if nargin<8
    weightedflag=0;
end

if nargin<9
    P_dbar=zeros(shape,1);
else
    P_dbar=P_dbar(:);
    if length(P_dbar)~=shape
        if length(P_dbar)==1
            P_dbar=ones(shape,1).*P_dbar;
            %disp('expand hydrostatic pressure to match variable size')
        else
            disp('hydrostatic pressure size doesn''t match')
            return
        end
    end
end

if nargin<10
    pcfactor=3.2; % 3.2% per 1000 dbar as default for 3830 / 4330 standard foil
else
    if length(pcfactor)~=1
        disp('singular value for pcfactor expected!')
        return
    end
end
    
if nargin<11
    generatorflag=false(size(temp));
else
    if length(generatorflag)==1
        %disp('singular value for generatorflag expected!')
        %return
        generatorflag=logical(ones(size(temp)).*generatorflag);
    end
end

if ~isempty(inputname(1))
    SNstring=inputname(1);
    SNstring=SNstring(2:end);
else
    SNstring='';
end

if nargin<12
    note={['Optode 4330 SN' SNstring],'laboratory calibration'};
end

% convert deep winkler oxygen to "surface" samples by inverse optode
% pressure correction (instead of correcting optode readings/calculations
% in each iteration step below)
oxygen=optreverseprescorr(oxygen,P_dbar,pcfactor);

% convert NaOH oxygen concentration / umol/l to freshwater oxygen
% concentration / umol/l for correct winkler pO2 / mbar conversion if
% generatorflag is given
% pO2(NaOH) * O2sol(NaOH) = pO2(fresh) * O2sol(fresh)
if find(generatorflag)
   oxygen(generatorflag)=oxygen(generatorflag) ./ 0.99158; %from Clegg and Brimblecombe (1990)
end

% convert ("surface") winkler oxygen concentration / umol/l to winkler pO2 / mbar
wpO2=O2conctopO2(oxygen,temp,sal,P_atm);

% cheat nlinfit input (matrix of size nxp)
if weightedflag
    % weighted
    X=[temp phase wpO2 1+oxygenstd];
else
    % uniform weights
    X=[temp phase wpO2 ones(shape,1)];
end

if strcmp(modeltype,'aanderaa')
    option=1;
    %cheat nlinfit input (matrix of size nxp)
    % replace pO2 by O2 conc with "freshwater" concentration
    X(:,3)=O2saltofresh(oxygen,temp,sal);
    foilcoef0=zeros(20,1);
    % do optimisation (of freshwater concentration)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefun3830,foilcoef0);
    % interpret result
    out.foilcoef=reshape(foilcoef(:,1),4,5)';
    % then statistics for (real world surface salt water) oxygen concentration / umol/l
    oxygenfit=optcalcO2(temp,phase,foilcoef(:,1),'aanderaa',sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=sum(out.r.^2)./length(out.r);
elseif  strcmp(modeltype,'3x4b')
    option=2;
    % nlinfit additional input
    foilcoef0=zeros(14,1);
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefun3x4b,foilcoef0);
    % then statistics for actual pO2 fit
    pO2fit=optodefun3x4b(foilcoef,[temp phase]);
elseif strcmp(modeltype,'5x5b')
    option=3;
    % nlinfit additional input
    foilcoef0=zeros(21,1);
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefun5x5b,foilcoef0);
    % then statistics for actual pO2 fit
    pO2fit=optodefun5x5b(foilcoef,[temp phase]);
elseif strcmp(modeltype,'uchidasimple')
    option=6;
    % nlinfit additional input
    options=statset('MaxIter',600);
    foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70]'; % 6 parameter Uchida model (org)
    %foilcoef0=[1e-3 1e-4 0 0 1/70 1e-4]';
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchidasimple,foilcoef0,options);
    % then statistics for actual pO2 fit
    pO2fit=optodefunUchidasimple(foilcoef,[temp phase]);
elseif strcmp(modeltype,'uchidasimplemolar')
    option=6;
    % replace pO2 by O2 conc with "freshwater" concentration
    X(:,3)=O2saltofresh(oxygen,temp,sal);
    %% nlinfit additional input
    options=statset('MaxIter',600);
    foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70]'; % 6 parameter Uchida model (org)
    % do optimisation (of O2conc)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchidasimple,foilcoef0,options);
    % then statistics for (real world surface salt water) oxygen concentration / umol/l
    oxygenfit=optcalcO2(temp,phase,foilcoef(:,1),'uchidasimplemolar',sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=sum(out.r.^2)./length(out.r);
elseif strcmp(modeltype,'uchida')
    option=6;
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[8e-3 -1e-4 -1e-6 70 0 0 1]';
    %foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70 0]'; % 7 parameter Uchida model
    foilcoef0=[5e-3 8e-5 1e-7 1e-1 -4e-5 -1e-2 1e-3]'; % 7 parameter Uchida model
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchida,foilcoef0,options);
    % then statistics for actual pO2 fit
    pO2fit=optodefunUchida(foilcoef,[temp phase]);
elseif strcmp(modeltype,'uchidaaadi')
    option=6;
    %cheat nlinfit input (matrix of size nxp)
    % replace pO2 by O2 conc with "freshwater" concentration
    X(:,3)=O2saltofresh(oxygen,temp,sal);
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %options=statset('MaxIter',1200,'robust','on');
    %foilcoef0=[8e-3 -1e-4 -1e-6 70 0 0 1]';
    %foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70 0]'; % 7 parameter Uchida model
    foilcoef0=[5e-3 8e-5 1e-7 1e-1 -4e-5 -1e-2 1e-3]'; % 7 parameter Uchida model
    % then statistics for actual pO2 fit
    % do optimisation (of freshwater concentration)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchida,foilcoef0,options);
    % then statistics for (real world surface salt water) oxygen concentration / umol/l
    oxygenfit=optcalcO2(temp,phase,foilcoef(:,1),'uchidaAADI',sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=sum(out.r.^2)./length(out.r);
elseif strcmp(modeltype,'uchidasq')
    option=6;
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[8e-3 -1e-4 -1e-6 70 0 0 1]';
    %foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70 0]'; % 7 parameter Uchida model
    foilcoef0=[5e-3 8e-5 1e-7 1e-1 -4e-5 -1e-2 1e-3]'; % 7 parameter Uchida model
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchidasq,foilcoef0,options);
    % then statistics for actual pO2 fit
    pO2fit=optodefunUchidasq(foilcoef,[temp phase]);
elseif strcmp(modeltype,'uchidasqmolar')
    option=6;
    % replace pO2 by O2 conc with "freshwater" concentration
    X(:,3)=O2saltofresh(oxygen,temp,sal);
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[8e-3 -1e-4 -1e-6 70 0 0 1]';
    %foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70 0]'; % 7 parameter Uchida model
    foilcoef0=[5e-3 8e-5 1e-7 1e-1 -4e-5 -1e-2 1e-3]'; % 7 parameter Uchida model
    % do optimisation (of freshwater concentration)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchidasq,foilcoef0,options);
    % then statistics for (real world surface salt water) oxygen concentration / umol/l
    oxygenfit=optcalcO2(temp,phase,foilcoef(:,1),'uchidasqmolar',sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=sum(out.r.^2)./length(out.r);
elseif strcmp(modeltype,'uchidasbe')
    option=6;
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[8e-3 -1e-4 -1e-6 70 0 0 1]';
    %foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70 0]'; % 7 parameter Uchida model
    foilcoef0=[1e-1 -4e-5 0 -1e-2 1e-3 5e-3 8e-5 1e-7]'; % 8 parameter Uchida SBE model
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchidaSBE,foilcoef0,options);
    % then statistics for actual pO2 fit
    pO2fit=optodefunUchidaSBE(foilcoef,[temp phase]);
elseif strcmp(modeltype,'uchidasbemolar')
    option=6;
    % replace pO2 by O2 conc with "freshwater" concentration
    X(:,3)=O2saltofresh(oxygen,temp,sal);
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[8e-3 -1e-4 -1e-6 70 0 0 1]';
    %foilcoef0=[8e-3 -1e-4 -1e-6 0 0 1/70 0]'; % 7 parameter Uchida model
    foilcoef0=[1e-1 -4e-5 0 -1e-2 1e-3 5e-3 8e-5 1e-7]'; % 8 parameter Uchida SBE model
    % do optimisation (of O2conc)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunUchidaSBE,foilcoef0,options);
    % then statistics for (real world surface salt water) oxygen concentration / umol/l
    oxygenfit=optcalcO2(temp,phase,foilcoef(:,1),'uchidaSBEmolar',sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=sum(out.r.^2)./length(out.r);
elseif strcmp(modeltype,'mcneil')
    option=13;
    options=optimset('MaxFunEvals',3000,'TolFun',1e-14,'TolX',1e-10,'PrecondBandWidth',0);
    % two quenchable luminophore sites
    foilcoef0=[2e-5;3;5e-2;9;20;0.8];lb=[0;-inf;0;-inf;0;0];ub=[1;inf;1;inf;inf;1]; % 6 coefficients  
    %foilcoef0=[60e-6;3;5e-2;9;20;0.8];lb=[0;-inf;0;-inf;0;0];ub=[1;inf;1;inf;inf;1]; % 6 coefficients  
    %foilcoef0=[2e-5;3;5e-2;9;1e-3;7;0.8];lb=[0;-inf;0;-inf;0;-inf;0];ub=[1;inf;1;inf;1;inf;1]; % 6 coefficients  
    % do optimisation (of pO2)
	foilcoef=lsqcurvefitci(@optodefunMcNeil,foilcoef0,X,zeros(size(temp,1),size(temp,2)),lb,ub,options); %
    % then statistics for actual pO2 fit
    pO2fit=optodefunMcNeil(foilcoef,[temp phase]);
elseif strcmp(modeltype,'rinko')
    option=6;
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[-38.8 120 -.4 .01 0 0 1]'; % 8 parameter Rinko model;
    %parameter E dropped (gives pressure dependence)
    foilcoef0=[10;1000;-1;-.01;0;0;1];
    % do optimisation (of pO2)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunrinko,foilcoef0,options);
    % then statistics for actual pO2 fit
    pO2fit=optodefunrinko(foilcoef,[temp phase]);
elseif strcmp(modeltype,'rinkomolar')
    option=6;
    % replace pO2 by O2 conc with "freshwater" concentration
    X(:,3)=O2saltofresh(oxygen,temp,sal);
    %% nlinfit additional input
    options=statset('MaxIter',1200);
    %foilcoef0=[-38.8 120 -.4 .01 0 0 1]'; % 8 parameter Rinko model;
    %parameter E dropped (gives pressure dependence)
    foilcoef0=[100;1000;-1;-.01;0;0;1];
    % do optimisation (of freshwater concentration)
    [foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefunrinko,foilcoef0,options);
    % then statistics for (real world surface salt water) oxygen concentration / umol/l
    oxygenfit=optcalcO2(temp,phase,foilcoef(:,1),'rinkomolar',sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=sum(out.r.^2)./length(out.r);
elseif  ~isnan(str2double(modeltype)) %strcmp(modeltype,'3n')
    n=str2double(modeltype);
    if n==5
        %explicit polynomial function; with confidence interval of fit
        option=4;
        % nlinfit additional input
        foilcoef0=zeros((n+1)*(n+2)/2,1);
        % do optimisation (of pO2)
        eval(['[foilcoef,r,J,COVB,mse]=nlinfit(X,zeros(size(temp)),@optodefun' num2str(n) 'x' num2str(n) 'b,foilcoef0);']);
    else
        %general polynomial function; no confidence interval of fit
        option=5;
        foilcoef=polyfitweighted2(X(:,1),X(:,2),diag(X(:,3)),n,diag(1./((X(:,4)).^2)))';
    end
    % then statistics for actual pO2 fit
    pO2fit=diag(polyval2(foilcoef(:,1)',temp,phase));
end

% add confidence interval for foilcoefs
if (isnan(str2double(modeltype)) | n~=5) & ~strcmp(modeltype,'mcneil')
    if strcmp(modeltype,'aanderaa')
        ci=nlparci(foilcoef(:),r,'covar',COVB);
        out.fint=reshape((ci(:,2)-ci(:,1))/2,4,5)';
    else
        ci=nlparci(foilcoef,r,'covar',COVB);
        foilcoef(:,2)=(ci(:,2)-ci(:,1))/2;
    end
end

%if option>1
if option>1 & ~strcmp(modeltype,'uchidaaadi') & isempty(strfind(modeltype,'molar'))
    out.foilcoef=foilcoef;
    % then statistics for actual pO2 fit
    out.rpO2=wpO2-pO2fit;
    out.msepO2=nansum(out.rpO2.^2)./length(out.rpO2);
    % then statistics for (surface) oxygen concentration / umol/l
    oxygenfit=pO2toO2conc(pO2fit,temp,sal,P_atm);
    out.r=oxygen-oxygenfit;
    out.mse=nansum(out.r.^2)./length(out.r);    
elseif ~strcmp(modeltype,'aanderaa')
    out.foilcoef=foilcoef;
end
out.w=weightedflag;
out.note=char(note);
out.modeltype=modeltype;
out.fittime=datestr(now);


%% done with calculations 


% prepare plot of results
tlim=[min(temp)-2 max(temp)+2]; %freshwater; only T and Phase
if option==12
    plim=[min(phase)-2e-6 max(phase)+2e-6];
else
    plim=[min(phase)-2 max(phase)+2];
end
% fitted surface
[plotT,plotP]=meshgrid([tlim(1):(tlim(2)-tlim(1))/15:tlim(2)],[plim(1):(plim(2)-plim(1))/15:plim(2)]);
%if option==1
%    if length(foilcoef(:,1))==7
%        plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'uchidaAADI');
%    else
%        plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'Aanderaa');
%    end
%elseif option==2
%    plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'3x4b');
%elseif option==3
%    plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'5x5b');
%elseif option==4
if option==4
    plotO=pO2toO2conc(diag(polyval2(foilcoef(:,1)',plotT(:),plotP(:))),plotT(:),0,1013.25);
elseif option==5
    plotO=pO2toO2conc(diag(polyval2(foilcoef',plotT(:),plotP(:))),plotT(:),0,1013.25);
%elseif option==6
%    if length(foilcoef(:,1))==7
%        if strcmp(modeltype,'uchida')
%            plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'uchida');
%        else
%            plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'uchidasq');
%        end
%    elseif length(foilcoef(:,1))==6
%        plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'uchidasimple'); % simple
%    elseif length(foilcoef(:,1))==8
%        plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'uchidaSBE'); % simple
else
        plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),modeltype);
%    end
%elseif option==13
%    plotO=optcalcO2(plotT(:),plotP(:),foilcoef(:,1),'mcneil');
end
plotO=reshape(plotO,size(plotT));
plotO(plotO>max(oxygen+60))=NaN;
plotO(plotO<min(oxygen-60))=NaN;
plotO(plotO~=real(plotO))=NaN; % flag out imaginary data
% convert Winkler oxygen to freshwater concentration to fit in
% T/Phase-Space
oxygen=O2saltofresh(oxygen,temp,sal);
% same for fitted oxygen
oxygenfit=O2saltofresh(oxygenfit,temp,sal);


% plot surface
fha=figure;
set(fha,'color',[1 1 1])
if simpleplot
    %set(fha,'Position',[086 350 1.45*560 1*420])
    %set(fha,'Position',[068 350 1.70*560 1*420])
    set(fha,'Position',[068 350 (1.7+0.6*ext)*560 1*420])
    subplot(1,3+ext,3)     % statistics/info plot
    %subplot(1,5,[3 4]) % difference plot
    subplot(1,3+ext,[1 2]) % surface plot
else    
    set(fha,'Position',[010 350 2.5*560 1*420])
    subplot(1,5,5)     % statistics/info plot
    subplot(1,5,[3 4]) % difference plot
    subplot(1,5,[1 2]) % surface plot
end
if simpleplot
    mhandle=mesh(plotP,plotT,plotO,'EdgeColor',brightness); % fitted surface
else
    mhandle=mesh(plotP,plotT,plotO,'EdgeColor','black'); % fitted surface
end
set(gca,'XDir','reverse','YDir','reverse')
xlim(plim)
ylim(tlim)
hold on
if simpleplot
    shandle=scatter3(phase,temp,oxygen,72,[0 0 1],'filled','MarkerEdgeColor',[0 0 0]); % Winkler samples
    %set(shandle,'CData',abs(out.r)); % jet
    set(shandle,'CData',out.r); % rednblue
else
    shandle=scatter3(phase,temp,oxygen,72,[0 0 1],'filled','MarkerEdgeColor',brightness); % Winkler samples
    set(shandle,'CData',out.r); % rednblue
end
for i = 1:length(oxygen)                                 % and sample-fit surface distance line for each
    plot3([phase(i) phase(i)],[temp(i) temp(i)],[oxygen(i) oxygenfit(i)],'-','Linewidth',1,'Color',brightness)
end
%if simpleplot % add errorbars
%    for i = 1:length(out.r)                              % difference line and error bar/weight for each
%        plot3([phase(i) phase(i)],[temp(i) temp(i)],oxygen(i)+(1+oxygenstd(i))*[-1 1],'-r','Linewidth',1.5)
%    end
%end
hold off
view(-75,30)
if option==1
    xlabel('DPhase / °')
else
    xlabel('TCPhase / °')
end
ylabel('T / °C')
%zlabel('O_2 / \mumol/l')
zlabel('O_2 / \mumol L^{-1}')
lhandle=legend({'fitted surface';'Winkler samples'},'Location','NorthEast');
if ~simpleplot
    set(gca,'XColor',brightness)
    set(gca,'YColor',brightness)
    set(gca,'ZColor',brightness)
end
hidden off

%difference plot
if ~simpleplot
subplot(1,5,[3 4])
hold on
%shandle0=scatter3(bphase,temp,optcalcO2(temp,polyval(flipud(beta0(:,1)),bphase),foilcoef,'Aanderaa')-winkler,18,[0 0 1],'filled');
mhandle2=mesh(plotP,plotT,zeros(size(plotT)),'EdgeColor',sqrt(brightness)); % fitted surface
set(gca,'XDir','reverse','YDir','reverse')
xlim(plim)
ylim(tlim)
shandle1=scatter3(phase,temp,out.r,72,[0 0 0],'filled','MarkerEdgeColor',sqrt(brightness)); % residual
%set(shandle1,'CData',abs(out.r)) %jet
set(shandle1,'CData',out.r) %rednblue
end
cbah=colorbar;
%set(get(cbah,'Title'),'String','\Delta / \mumol/l');
set(get(cbah,'Title'),'String','\Delta / \mumol L^{-1}');
%caxis(get(shandle,'Parent'),caxis(get(shandle1,'Parent'))) % adjust common color settings
if simpleplot
    %caxis(get(shandle,'Parent'),[0 5]) %jet
    caxis(get(shandle,'Parent'),[-5 5]) %rednblue
    %colormap(brighten(rednblue,-.4))
    colormap(cmocean('balance'))
    % add plain difference plot if ext
    if ext
        subplot(1,3+ext,3,'replace')
        %hold on
        scah2(1)=scatter(oxygen,out.r,72,out.r,'filled','MarkerEdgeColor',[0 0 0]);
        grid on
        %xlabel('O_2 / \mumol/l')
        xlabel('O_2 / \mumol L^{-1}')
        %ylabel('\Delta = Winkler - optode fit / \mumol/l')
        ylabel('\Delta = Winkler - optode fit / \mumol L^{-1}')
        caxis([-5 5])
        ylim([-5 5])
        %set(gca,'xtick',[0:50:400])
    end
else
    caxis(get(shandle,'Parent'),[-5 5]) %rednblue
    %caxis(get(shandle1,'Parent'),[0 5]) %jet
    caxis(get(shandle1,'Parent'),[-5 5]) %rednblue
    %colormap(brighten(rednblue,-.4))
    colormap(rednblueSven)
    if nargin<7
        for i = 1:length(out.r)                              % and residual-zero plane difference line
            plot3([phase(i) phase(i)],[temp(i) temp(i)],[out.r(i) 0],'-','Color',brightness,'Linewidth',1)
        end
    else
        for i = 1:length(out.r)                              % difference line and error bar/weight for each
            plot3([phase(i) phase(i)],[temp(i) temp(i)],[out.r(i) 0],'-','Color',brightness,'Linewidth',1)
            plot3([phase(i) phase(i)],[temp(i) temp(i)],out.r(i)+(1+oxygenstd(i))*[-1 1],'-r','Linewidth',1.5)
        end
    end
    %zlim([-8 8])
    hold off
    view(-75,30)
    grid on
    if option==1
        xlabel('DPhase / °')
    else
        xlabel('TCPhase / °')
    end
    ylabel('T / °C')
    %zlabel('Diff. O_2 Winkler - O_2 calc. / \mumol/l')
    zlabel('Diff. O_2 Winkler - O_2 calc. / \mumol L^{-1}')
    lhandle2=legend({'fitted surface';'Winkler samples'},'Location','NorthEast');
    set(gca,'XColor',brightness)
    set(gca,'YColor',brightness)
    set(gca,'ZColor',brightness)
    hidden off
end

% info plot
if weightedflag
    weightstring='weighted fit';
else
    weightstring='';
end

if option==1
    functionstring={'Aanderaa model',weightstring};
elseif option==2
    functionstring={'3x4b model',weightstring};
elseif option==3
    functionstring={'5x5b model',weightstring};
elseif option==4
    functionstring={'mixed polynomial in T & TCPhase',['degree: n = ' num2str(n) ' ; ' weightstring]};
elseif option==5
    functionstring={'mixed polynomial in T & TCPhase',['degree: n = ' num2str(n) ' ; ' weightstring]};
elseif option==6
    if strcmp(modeltype,'uchida')
        functionstring={'Uchida et al. 2008 model (pO2)',weightstring};
    elseif strcmp(modeltype,'uchidaaadi')
        functionstring={'Uchida et al. 2008 model (O2 conc)',weightstring};
    elseif strcmp(modeltype,'uchidasbe')
        functionstring={'after Uchida et al. 2008 model (SBE, pO2)',weightstring};
	elseif strcmp(modeltype,'uchidasbemolar')
        functionstring={'after Uchida et al. 2008 model (SBE)',weightstring};
	elseif strcmp(modeltype,'uchidasqmolar')
        functionstring={'after Uchida et al. 2008 model (O2 conc)',weightstring};
    else
        functionstring={'after Uchida et al. 2008 model',weightstring};
    end
elseif option==13
    functionstring={'McNeil & d''Asaro 2014 model',weightstring};
end
%for i=1:length(foilcoef(:,1))
if option==4
    betastring{1}='new coefficients:';
    for i=1:(n+1)
        for j=1:i
            ind{i*(i-1)/2+j,1}=[num2str(i-j) num2str(j-1)];
        end
    end
    for i=1:(n+1)*(n+2)/2
        eval(['betastring{i+1}= ''a'  ind{i} ' = ' num2str(foilcoef(i,1),'%6.4f') ' \pm ' num2str(foilcoef(i,2),'%6.4f') ''';']);
    end
elseif option==5
    betastring{1}='new coefficients:';
    for i=1:(n+1)
        for j=1:i
            ind{i*(i-1)/2+j,1}=[num2str(i-j) num2str(j-1)];
        end
    end
    for i=1:(n+1)*(n+2)/2
        eval(['betastring{i+1}= ''a'  ind{i} ' = ' num2str(foilcoef(i),'%6.4f')  ''';']);
    end
elseif option==6
    betastring{1}='new coefficients:';
    if strcmp(modeltype,'uchidasbe')
        for i=1:3
            eval(['betastring{i+1}= ''a'  num2str(i-1) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
        end
        for i=4:5
            eval(['betastring{i+1}= ''b'  num2str(i-1) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
        end
        for i=6:8
            eval(['betastring{i+1}= ''c'  num2str(i-1) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
        end
    else
    for i=1:3
        eval(['betastring{i+1}= ''c'  num2str(i-1) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
    end
    if strcmp(modeltype,'uchida')
    for i=4:size(foilcoef,1)
        eval(['betastring{i+1}= ''c'  num2str(i-1) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
    end    
    else
    for i=4:size(foilcoef,1)
        eval(['betastring{i+1}= ''d'  num2str(i-4) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
    end
    end
    end
elseif option>=7
    betastring{1}='new coefficients:';
    for i=1:size(foilcoef,1)
        eval(['betastring{i+1}= ''b'  num2str(i) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
    end
else
    betastring{1}='new coefficients (first part only):';
    for i=1:min(length(foilcoef(:,1)),11)
        eval(['betastring{i+1}= ''a'  num2str(i-1) ' = ' num2str(foilcoef(i,1),'%6.4g') ' \pm ' num2str(foilcoef(i,2),'%6.4g') ''';']);
    end
    betastring{13}='...';
end
if simpleplot
    subplot(1,3+ext,3+ext)
else
    subplot(1,5,5)
end
set(gca,'Visible','Off')
thandle=text(0,.5,[note, functionstring ,{'',['RMSE = ' num2str(sqrt(out.mse),'%6.2f') ' \mumol L^{-1}  (N = ' num2str(length(find(~isnan(oxygenfit)))) ')'],''}, betastring ]);

% finally set renderer of figure to painters (not zbuffer)
set(fha,'Renderer','painters')