function [prc_config, obs_config] = cbbu_PH_config

% Perceptual model
prc_config = tapas_ph_binary_config;

prc_config.logitv_0mu   = tapas_logit(0.5, 1);
prc_config.logitv_0sa   = 0;
prc_config.logital_0mu  = tapas_logit(0.5457, 1); % from bopars
prc_config.logital_0sa  = 1;
prc_config.logSmu       = log(0.2075); % from bopars
prc_config.logSsa       = 8;

prc_config = tapas_align_priors(prc_config);


% Response model
obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;


end