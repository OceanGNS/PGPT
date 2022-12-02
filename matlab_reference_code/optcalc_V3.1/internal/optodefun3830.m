function F=optodefun3830(beta,x)
% function F=modelfunaanderaa(beta,x)
% Aanderaa Optode DPhase->O2conc. calculation
% beta - 20 foil coefficients C0_0, C0_1, ... C4_3
% x    - xdata with temperature as first and phase as second column
%        temperature and phase must have same size
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

[n,m]=size(x);

t=x(:,1);
p=x(:,2);
if m>2
    OW=x(:,3); % Winkler reference
    w=1./(x(:,4).^2); % weights
else
    OW=zeros(n,1);
    w=ones(n,1);
end

O=w.*(beta(1) + beta(2).*t+ beta(3).*t.^2 + beta(4).*t.^3 +...
    beta(5).*p + beta(6).*p.*t+ beta(7).*p.*t.^2 + beta(8).*p.*t.^3 +...
    beta(9).*p.^2 + beta(10).*p.^2.*t+ beta(11).*p.^2.*t.^2 + beta(12).*p.^2.*t.^3 +...
    beta(13).*p.^3 + beta(14).*p.^3.*t+ beta(15).*p.^3.*t.^2 + beta(16).*p.^3.*t.^3 +...
    beta(17).*p.^4 + beta(18).*p.^4.*t+ beta(19).*p.^4.*t.^2 + beta(20).*p.^4.*t.^3);
F=O-w.*OW;