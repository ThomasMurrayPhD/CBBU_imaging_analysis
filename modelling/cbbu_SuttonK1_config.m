function [prc_config, obs_config] = cbbu_SuttonK1_config

% Perceptual model
prc_config = tapas_sutton_k1_binary_config;
prc_config.logmumu = log(4.4422); % from bopars
prc_config.logmusa = 8;

prc_config.logitvhat_1mu=tapas_logit(0.7115, 1); % from bopars
prc_config.logitvhat_1sa=4; 

prc_config.logh_1mu = log(0.0033); % from bopars
prc_config.logh_1sa = 16;

prc_config.logRhatmu = log(1);
prc_config.logRhatsa = 0;

prc_config = tapas_align_priors(prc_config);

% Response model
obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;


end