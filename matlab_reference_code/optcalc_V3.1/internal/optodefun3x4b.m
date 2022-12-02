function F=optodefun3x4b(beta,x)
% function F=optodefun3x4b(beta,x)
% Craig Neill BPhase->pO2 calculation
% beta - 14 foil coefficients a0, a1, ... a13
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

O=w.*(beta(1) + beta(2).*t + beta(3).*p + beta(4).*t.^2 + beta(5).*t.*p + ...
    beta(6).*p.^2 + beta(7).*t.^3 + beta(8).*t.^2.*p + beta(9).*t.*p.^2 ...
    + beta(10).*p.^3 + beta(11).*t.^3.*p + beta(12).*t.^2.*p.^2 + ...
    beta(13).*t.*p.^3 + beta(14).*p.^4);
F=O-w.*OW;