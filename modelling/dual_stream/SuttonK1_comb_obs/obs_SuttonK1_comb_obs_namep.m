function [pstruct] = obs_SuttonK1_comb_obs_namep(pvec)

pstruct = struct;
pstruct.zeta  = pvec(1);
pstruct.beta0 = pvec(2);
pstruct.beta1 = pvec(3);
pstruct.beta2 = pvec(4);
pstruct.sa    = pvec(5);

return;
