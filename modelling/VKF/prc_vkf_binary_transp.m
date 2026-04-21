function [pvec, pstruct] = prc_vkf_binary_transp(r, ptrans)
% Parameters:
% lambda    - volatility learning rate (0 < lambda < 1)
% v0        - initial volatility (v0 > 0)
% omega     - noise parameter (omega > 0)
% w0        - initial variance (w0 > 0)

pvec    = NaN(1,length(ptrans));
pstruct = struct;

pvec(1)         = tapas_sgm(ptrans(1), 1); % lambda
pstruct.lambda  = pvec(1);

pvec(2)         = exp(ptrans(2)); % v0
pstruct.v0      = pvec(2);

pvec(3)         = exp(ptrans(3)); % omega
pstruct.omega   = pvec(3);

pvec(4)         = exp(ptrans(4)); % w0
pstruct.w0      = pvec(4);


end