function F=optodefunrinko(beta,X)
% function out=rinkofun(beta,X)
%
% apply calibration coefficients to RINKO oxygen voltage
%
% beta   - [A;B;C;D;E;F;G;H] 8 calibration parameters
% X(:,1) - temperature / °C
% X(:,2) - RINKO oxygen voltage / phase
%
% out    - O2 saturation (freshwater)

[n,m]=size(X);

Vo=X(:,2);
t=X(:,1);

if m>2
    OW=X(:,3); % Winkler reference
    w=1./(X(:,4).^2); % weights
else
    OW=zeros(n,1);
    w=ones(n,1);
end

A=beta(1);
B=beta(2);
C=beta(3);
D=beta(4);
%E=beta(5); % pressure correction factor (linear on phase)
F=beta(5);
G=beta(6);
H=beta(7);

O = w.*( G+ H.*(A./(1+D.*(t-25)) + B./((Vo-F).*(1+D.*(t-25))+C+F)) );

F=O-w.*OW;