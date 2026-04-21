function pstruct = prc_vkf_binary_namep(pvec)

pstruct = struct;

pstruct.lambda  = pvec(1);
pstruct.v0      = pvec(2);
pstruct.omega   = pvec(3);
pstruct.w0      = pvec(4);

end