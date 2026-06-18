function [pvec, pstruct] = obs_RW_comb_obs_transp(r, ptrans)

% empty array
pstruct = struct();

% vector with parameter values transformed back into native space
pvec = ptrans;

pvec(1)     = exp(ptrans(1));    % zeta (decision temperature (binary obs model))
pstruct.zeta  = pvec(1);

pvec(2)     = ptrans(2);         % be0
pstruct.beta0 = pvec(2);

pvec(3)     = ptrans(3);         % be1
pstruct.beta1 = pvec(3);

pvec(4)     = exp(ptrans(4));    % sa (logRT model noise parameter)
pstruct.sa  = pvec(4);



end
