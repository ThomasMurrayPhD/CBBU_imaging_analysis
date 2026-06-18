function [pstruct] = obs_RW_comb_obs_namep(pvec)

pstruct = struct;
pstruct.zeta  = pvec(1);
pstruct.beta0 = pvec(2);
pstruct.beta1 = pvec(3);
pstruct.sa    = pvec(4);

return;
