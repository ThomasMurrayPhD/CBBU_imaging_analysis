function [prc_config, obs_config] = cbbu_SuttonK1_config

% Perceptual model
prc_config = sutton_k1_binary_config;
prc_config.logmumu = log(1); % from bopars
prc_config.logmusa = 4;

prc_config.logRhatmu = log(1);
prc_config.logRhatsa = 0; 

prc_config.logitvhat_1mu=tapas_logit(0.5, 1); % Initial belief
prc_config.logitvhat_1sa=0; 

prc_config.logh_1mu = log(0.001); % from bopars
prc_config.logh_1sa = 0;

prc_config = align_priors(prc_config);

% Response model
obs_config = unitsq_sgm_config;
obs_config.logzemu = log(48);
obs_config.logzesa = 1; 
obs_config = align_priors(obs_config);
obs_config.predorpost = 1;


end