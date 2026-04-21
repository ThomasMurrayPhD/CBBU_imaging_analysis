function [prc_config, obs_config] = cbbu_RW_config

prc_config = tapas_rw_binary_config;

prc_config.logitalmu = tapas_logit(0.1197, 1); % from bopars
prc_config.logitalsa = 1;

prc_config = tapas_align_priors(prc_config);

obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;

end