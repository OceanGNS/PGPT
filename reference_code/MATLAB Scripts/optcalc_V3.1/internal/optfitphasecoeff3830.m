function out=optfitphasecoeff3830(temp,Bphase,foilcoef,phasecoef0,oxygen,sal,oxygenstd,weightedflag,P_dbar,pcfactor)
% function out=optfitphasecoeff3830(temp,Bphase,foilcoef,phasecoef0,oxygen,sal,oxygenstd,weightedflag,P_dbar,pcfactor)
% fit phase coefficients of internal aanderaa calculation according to
% measurements (temp, bphase, sal, hydrostatic pressure) and winkler oxygen
% values (oxygen, oxygenstd)
% phasecoef0 is first guess of phase coefficients
% degree can be adjusted by length of phasecoef0
%
% optional: weighted fit if weightedflag is set to 1 (default: 0) winkler
% oxygen value standard deviations are taken as weight for the coefficient
% fit
% if reference oxygen samples are taken at significant hydrostatic
% pressure, optode readings must be adjusted. Optional argument P_dbar
% gives respective pressure levels / dbar (Default: 0 dbar)
%
% output is structure with fields
%   phasecoef    - phase coefficients from fit in first column and confidence
%                  interval in second column, respectively
%   r            - residual of fit in umol/l
%   mse          - mean squared error for concentration
%   weighted     - 1 or 0
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

brightness=[.5 .5 .5];
degree=length(phasecoef0)-1;
phase=Bphase(:);
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

%make column vectors
temp=temp(:);
oxygen=oxygen(:);

shape=length(temp);
[n,m]=size(phasecoef0);
if m>n
    phasecoef0=phasecoef0';
end

if nargin<6
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

if nargin<7
    oxygenstd=zeros(shape);
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

% convert deep winkler oxygen to "surface" samples by inverse optode
% pressure correction (instead of correcting optode readings/calculations
% in each iteration step below)
oxygen=optreverseprescorr(oxygen,P_dbar,pcfactor);

% cheat nlinfit input (matrix of size nxp)
% replace O2 conc with "freshwater" concentration for T/BPhase-space phasecoef fitting
if weightedflag
    % weighted
    X=[temp phase zeros(shape,1) O2saltofresh(oxygen,temp,sal) 1+oxygenstd];
else
    % uniform weights
    X=[temp phase zeros(shape,1) O2saltofresh(oxygen,temp,sal) ones(shape)];
end

% add foilcoefficients as separate variable
% (expand X if necessary)
i=size(X,1);
X(1:20,3)=foilcoef(:); % insert foil coefficients artificially
%X(21,3)=i; % insert number of "real" entries artificially
if i<20
    X(i+1:20,1:2)=NaN;
    X(i+1:20,4:5)=NaN;
elseif i>20
    X(21:i,3)=NaN;
end

% do actual optimisation (of "surface" concentrations)
%[beta,r,J,COVB,mse]=nlinfit(X,winkler,@applyphasecoeff3830,[beta0]);
[phasecoef,r,J,COVB,mse]=nlinfit(X,zeros(length(X),1),@applyphasecoeff3830,phasecoef0);
% interpret result
% first confidence interval
ci=nlparci(phasecoef,r,'covar',COVB);
phasecoef(:,2)=(ci(:,2)-ci(:,1))/2;
out.phasecoef=phasecoef;
%% shrink winkler again
%%winkler=winkler(1:i);

% then statistics for oxygen concentration / umol/l (real world salt water
% concentration at surface)
oxygenfit=optapplyphasecoeff3830(temp,phase,foilcoef,phasecoef(:,1),sal,0,pcfactor);
out.r=oxygen-oxygenfit;
out.mse=sum(out.r.^2)./length(out.r);

out.w=weightedflag;

% prepare plot of results
tlim=[min(temp)-2 max(temp)+2];     % only T/BPhase - space (-> freshwater)
plim=[min(phase)-2 max(phase)+2];
% fitted surface
[plotT,plotP]=meshgrid([tlim(1):(tlim(2)-tlim(1))/15:tlim(2)],[plim(1):(plim(2)-plim(1))/15:plim(2)]);
plotD=polyval(flipud(phasecoef(:,1)),plotP(:));
plotO=optcalcO2(plotT(:),plotD,foilcoef,'aanderaa');
plotO=reshape(plotO,size(plotT));
plotO(plotO>max(oxygen+60))=NaN;
plotO(plotO<min(oxygen-60))=NaN;

% convert Winkler oxygen to respective freshwater concentration to fit in
% T/BPhase-Space plot
oxygen=O2saltofresh(oxygen,temp,sal);
% same for fitted oxygen
oxygenfit=O2saltofresh(oxygenfit,temp,sal);

% plot surface
fha=figure;
set(fha,'color',[1 1 1])
set(fha,'Position',[000 350 2.7*560 1*420])
subplot(1,5,5)     % info plot
subplot(1,5,[3 4]) % difference plot
subplot(1,5,[1 2]) % surface plot
mhandle=mesh(plotP,plotT,plotO,'EdgeColor','black'); % fitted surface
set(gca,'XDir','reverse','YDir','reverse')
xlim(plim)
ylim(tlim)
hold on
shandle=scatter3(phase,temp,oxygen,18,[0 0 1],'filled'); % Winkler samples (freshwater, surface analoguous)
for i = 1:length(oxygen)                                 % and sample-fit surface distance line for each
    plot3([phase(i) phase(i)],[temp(i) temp(i)],[oxygen(i) oxygenfit(i)],'-b','Linewidth',1)
end
hold off
view(-75,30)
xlabel('BPhase / °')
ylabel('T / °C')
zlabel('O_2 / \mumol/l')
lhandle=legend({'fitted surface';'Winkler samples'},'Location','NorthEast');
set(gca,'XColor',brightness)
set(gca,'YColor',brightness)
set(gca,'ZColor',brightness)
hidden off
%c_axes = copyobj(gca,gcf);
%set(c_axes, 'color', 'none', 'xcolor', 'k', 'xgrid', 'off', 'ycolor','k', 'ygrid','off', 'zcolor','k', 'zgrid','off','Visible','Off');

%difference plot
subplot(1,5,[3 4])
hold on
%shandle0=scatter3(bphase,temp,optcalcO2(temp,polyval(flipud(phasecoef0(:,1)),bphase),foilcoef,'Aanderaa')-oxygen,18,[0 0 1],'filled');
mhandle2=mesh(plotP,plotT,zeros(size(plotT)),'EdgeColor',sqrt(brightness)); % fitted surface
set(gca,'XDir','reverse','YDir','reverse')
xlim(plim)
ylim(tlim)
shandle1=scatter3(phase,temp,out.r,18,[0 0 0],'filled'); % residuals
if nargin<8
    for i = 1:length(out.r)                              % and residual-zero plane difference line
        plot3([phase(i) phase(i)],[temp(i) temp(i)],[out.r(i) 0],'-','Color',brightness,'Linewidth',1)
    end
else
    for i = 1:length(out.r)                              % difference line and error bar/weight for each
        %plot3([phase(i) phase(i)],[temp(i) temp(i)],[oxygen(i)-optcalcO2(temp(i),polyval(flipud(phasecoef0(:,1)),phase(i)),foilcoef,'5x5b',sal(i),P_atm(i)) 0],'-b')
        plot3([phase(i) phase(i)],[temp(i) temp(i)],[out.r(i) 0],'-','Color',brightness,'Linewidth',1)
        plot3([phase(i) phase(i)],[temp(i) temp(i)],out.r(i)+(1+oxygenstd(i))*[-1 1],'-r','Linewidth',1.5)
    end
end
%zlim([-8 8])
hold off
view(-75,30)
grid on
xlabel('BPhase / °')
ylabel('T / °C')
zlabel('Diff. O_2 Winkler - O_2 calc. / \mumol/l')
lhandle2=legend({'fitted surface';'Winkler samples'},'Location','NorthEast');
set(gca,'XColor',brightness)
set(gca,'YColor',brightness)
set(gca,'ZColor',brightness)
hidden off

% info plot
if weightedflag
    weightstring=' ; weighted fit';
else
    weightstring='';
end
functionstring={'Phase coefficient fit; Aanderaa model','', 'DPhase = \Pi_i^n c_i\cdotBPhase^n',['degree n = ' num2str(degree) weightstring]};
phasecoef0string{1}='old set: ';
phasecoefstring{1}='new set: ';
for i=1:degree+1
    eval(['phasecoef0string{i+1}= ''c' num2str(i-1) ' = ' num2str(phasecoef0(i),'%6.4f') ''';']);
    eval(['phasecoefstring{i+1}= ''c'  num2str(i-1) ' = ' num2str(phasecoef(i,1),'%6.4f') ' \pm ' num2str(phasecoef(i,2),'%6.4f') ''';']);
end
subplot(1,5,5)
set(gca,'Visible','Off')
thandle=text(0,.5,[{'Optode 3830 #   ','3830 cal'} functionstring ,{['RMSE = ' num2str(sqrt(out.mse),'%6.2f') ' \mumol/l  (N = ' num2str(length(oxygen)) ')'],''}, phasecoef0string phasecoefstring]);

% finally set renderer of figure to painters (not zbuffer)
set(fha,'Renderer','painters')

function F=applyphasecoeff3830(phasecoef,X)
% function ox=applyphasecoeff4330(phasecoef,[temp TCphase foilcoef oxygen weights])

% function ox=applyphasecoeff3830(beta,[temp bphase sal P_atm foilcoef])
%dphase=polyval(flipud(beta),X(:,2));
%ox=optcalcO2(X(:,1),dphase,X(1:20,5),'Aanderaa',X(:,3),X(:,4));

[n,m]=size(X);

t=X(:,1);
dphase=polyval(flipud(phasecoef),X(:,2));
foilcoef=X(1:20,3);

if m>3
    OW=X(:,4); % Winkler reference
    w=1./(X(:,5).^2); % weights
else
    OW=zeros(n,1);
    w=ones(n,1);
end
% pO=optodefun5x5b(foilcoef,[t Calphase zeros(n,1) X(:,5)]));
pO=w.*(optodefun3830(foilcoef,[t dphase zeros(n,1) ones(n,1)]));
F=pO-w.*OW;
