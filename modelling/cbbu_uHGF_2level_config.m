function [prc_config, obs_config] = cbbu_uHGF_2level_config

% Perceptual model
prc_config = uhgf_binary_config;

prc_config.logkamu(2) = log(0);
prc_config.logkasa(2) = 0;

prc_config.ommu(2) = -3;
prc_config.omsa(2) = 8;

prc_config.ommu(3) = 0;
prc_config.omsa(3) = 0;

prc_config = align_priors(prc_config);

% obs model
obs_config = unitsq_sgm_config;
obs_config.logzemu = log(48);
obs_config.logzesa = 1; 

obs_config = align_priors(obs_config);

obs_config.predorpost = 1;


end