function F=optodefun5x5b(beta,x)
% function F=optodefun5x5b(beta,x)
% Craig Neill BPhase->pO2 calculation
% beta - 21 foil coefficients a0, a1, ... a20
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

O=w.*(beta(1).*t.*p.^4 + beta(2).*p.^5 + beta(3).*p.^4 + ...
    beta(4).*p.^3 + beta(5).*t.*p.^3 + beta(6).*t.^2.*p.^3 + ...
    beta(7).*p.^2 + beta(8).*t.*p.^2 + beta(9).*t.^2.*p.^2 + beta(10).*t.^3.*p.^2 + ...
    beta(11).*p + beta(12).*t.*p + beta(13).*t.^2.*p + beta(14).*t.^3.*p + beta(15).*t.^4.*p + ...
    beta(16) + beta(17).*t + beta(18).*t.^2 + beta(19).*t.^3 + beta(20).*t.^4 + beta(21).*t.^5);
F=O-w.*OW;