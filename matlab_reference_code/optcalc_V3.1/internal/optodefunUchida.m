function F=optodefunUchida(beta,x)
% function F=optodefunUchida(beta,x)
% Stern-Volmer inspired BPhase->pO2 calculation
% beta - 7 coefficients following Stern-Volmer equation-derived
%        approach after Uchida et al. 2008
% x    - xdata with temperature as first and phase as second column
%        temperature and phase must have same size
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

% O = (P_0/P_c - 1) / K_SV
% P_0 = 1 + d_0*T                 (Uchida org.: P_0 = c_3 + c_4*T)
% P_c = d_1 + d_2*P ##+ d_3*P^2## (Uchida org.: P_c = c_5 + c_6*P)
% K_SV = c_0 + c_1*T + c_2*T^2    (Uchida org.: identical)
% beta(1): c_0
% beta(2): c_1
% beta(3): c_2
% beta(4): d_0
% beta(5): d_1
% beta(6): d_2
% beta(7): d_3

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

%%O=w.*(((1+beta(4).*t)./(beta(5)+beta(6).*p) -1)./(beta(1)+beta(2).*t+beta(3).*t.^2));
O=w.*(((beta(4)+beta(5).*t)./(beta(6)+beta(7).*p) -1)./(beta(1)+beta(2).*t+beta(3).*t.^2));
%O=w.*(((1+beta(4).*t)./(beta(5)+beta(6).*p+beta(7).*p.^2) -1)./(beta(1)+beta(2).*t+beta(3).*t.^2));
F=O-w.*OW;