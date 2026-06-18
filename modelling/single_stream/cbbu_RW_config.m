function [prc_config, obs_config] = cbbu_RW_config

prc_config = rw_binary_config;
prc_config.logitalmu = tapas_logit(0.1197, 1); % from bopars
prc_config.logitalsa = 1;
prc_config = align_priors(prc_config);


obs_config = unitsq_sgm_config;
obs_config.logzemu = log(48);
obs_config.logzesa = 1;
obs_config.predorpost = 1;
obs_config = align_priors(obs_config);

end