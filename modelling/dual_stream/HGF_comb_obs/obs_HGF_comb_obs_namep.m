function [pstruct] = obs_HGF_comb_obs_namep(pvec)

pstruct = struct;
pstruct.zeta  = pvec(1);
pstruct.beta0 = pvec(2);
pstruct.beta1 = pvec(3);
pstruct.beta2 = pvec(4);
pstruct.beta3 = pvec(5);
pstruct.beta4 = pvec(6);
pstruct.beta5 = pvec(7);
pstruct.sa    = pvec(8);

return;
