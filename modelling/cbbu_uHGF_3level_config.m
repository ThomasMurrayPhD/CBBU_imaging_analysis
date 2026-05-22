function [prc_config, obs_config] = cbbu_uHGF_3level_config

% Perceptual model
prc_config = uhgf_binary_config;

prc_config.logkamu(2) = log(1);
prc_config.logkasa(2) = 0;

prc_config.ommu(2) = -3; 
prc_config.omsa(2) = 4;

prc_config.ommu(3) = -3; 
prc_config.omsa(3) = 4;

prc_config.update_type = 'uhgf';
prc_config = align_priors(prc_config);

prc_config = align_priors(prc_config);

% obs model
obs_config = unitsq_sgm_config;
obs_config.logzemu = log(48);
obs_config.logzesa = 1;
obs_config.predorpost = 1;
obs_config = align_priors(obs_config);


end