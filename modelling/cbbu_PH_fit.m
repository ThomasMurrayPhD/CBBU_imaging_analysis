function [prc_config, obs_config] = cbbu_PH_config

% Perceptual model
prc_config = tapas_sutton_k1_binary_config; ##
prc_config.logmumu = log(0.1);
prc_config.logmusa = 8;

prc_config.logitvhat_1mu=0;
prc_config.logitvhat_1sa=4; 

prc_config.logh_1mu = log(.005);
prc_config.logh_1sa = 16;

prc_config.logRhatmu = 0;
prc_config.logRhatsa = 0;

prc_config = tapas_align_priors(prc_config);

% Response model
obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;


end