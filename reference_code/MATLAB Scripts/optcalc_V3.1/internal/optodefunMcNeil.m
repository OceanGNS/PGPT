function F=optodefunMcNeil(beta,x)
% function F=optodefunMcNeil(beta,x)
% Stern-Volmer BPhase->pO2 calculation
%
% two quenchable luminophore sites
%
%
% x       - xdata with temperature as first and phase as second column
%           temperature and phase must have same size
% beta(1) - tau0 / us at 25 °C [30..100]
% beta(2) - dtau0 / dT [-inf..0]
% beta(3) - ksv at 25 °C [0..inf]
% beta(4) - dksv / dT [0..inf]
% beta(5) - ksv2 / ksv1 ratio [0..1]
% beta(6) - fraction of second site [0..1]
%
% beta(7) - 
%
% Henry Bittig, GEOMAR
% 09.02.2013


[n,m]=size(x);
tref=25;
omega=2*pi*5000;
%omega=2*pi*3840;


t=x(:,1);
p=x(:,2);
if m>2
    OW=x(:,3); % Winkler reference
    w=1./(x(:,4).^2); % weights
else
    OW=zeros(n,1);
    w=ones(n,1);
end

tauobs=tand(p)./omega;

% tau0, 25 °C reference
%tau0=(beta(1)+beta(2).*(t-tref)).*1e-6;
%tau0=beta(1).*1e-6;
tau0=1./( 1./beta(1) .* exp(-beta(2)*1000./8.314./(t+273.25)) );
%tau0=1./( 1./beta(1) .*exp(-beta(2)*1000./8.314./(tref+273.25)).* exp(-beta(2)*1000./8.314./(t+273.25)) );
% ksv, 25 °C reference
%ksv1=beta(3)+beta(4).*(t-tref);
%ksv1=beta(2);
%ksv=beta(3)+beta(4).*(t-tref)+beta(7).*(t-tref).^2;
ksv1=beta(3) .* exp(-beta(4)*1000./8.314./(t+273.25));
% dampening factor of ksv constant
ksv2=ksv1./beta(5);
%ksv2=beta(5).*beta(3)+beta(6).*beta(4).*(t-tref);
%ksv2=beta(3).*beta(2);
%ksv2=beta(5) .* exp(-beta(6)*1000./8.314./(t+273.25));
% second quenchable component fraction
f1=beta(6);
%f1=beta(7);
%nqfrac=beta(4);


O=((tau0./tauobs).*(ksv1-f1*ksv1+f1*ksv2)-(ksv1+ksv2)...
    +sqrt( (tau0./tauobs).^2.*(-2*f1*ksv1.^2+f1.^2*ksv1.^2+f1.^2*ksv2.^2 ...
    +2*f1*ksv1.*ksv2-2*f1.^2*ksv1.*ksv2+ksv1.^2) + 2*(tau0./tauobs).*(f1*ksv1.^2 ...
    - f1*ksv2.^2-ksv1.^2+ksv1.*ksv2) + (ksv1.^2+ksv2.^2 ...
    - 2*ksv1.*ksv2)))./(2*ksv1.*ksv2);

F=w.*(O-OW);