function F=optodefunUchidaSBE(beta,x)
% function F=optodefunUchidaSBE(beta,x)
% Stern-Volmer inspired BPhase->pO2 calculation
% beta - 7 coefficients following Stern-Volmer equation-derived
%        approach after Uchida et al. 2008 and adapted with squared term
% x    - xdata with temperature as first and phase as second column
%        temperature and phase must have same size
%
% part of optcalc-toolbox
% H. Bittig, IFM-GEOMAR
% 31.03.2011

% O = (P_0/P_c - 1) / K_SV
% P_0 = a_0 + a_1*T ##+ a_2*P^2## (Uchida org.: P_0 = c_3 + c_4*T)
% P_c = b_0 + b_1*T               (Uchida org.: P_c = c_5 + c_6*P)
% K_SV = c_0 + c_1*T + c_2*T^2    (Uchida org.: identical)
% beta(1): a_0
% beta(2): a_1
% beta(3): a_2
% beta(4): b_0
% beta(5): b_1
% beta(6): c_0
% beta(7): c_1
% beta(8): c_2

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
%O=w.*(((beta(4)+beta(5).*t)./(beta(6)+beta(7).*p) -1)./(beta(1)+beta(2).*t+beta(3).*t.^2));
O=w.*(((beta(1)+beta(2).*t+beta(3).*p.^2)./(beta(4)+beta(5).*p) -1)./(beta(6)+beta(7).*t+beta(8).*t.^2));
F=O-w.*OW;