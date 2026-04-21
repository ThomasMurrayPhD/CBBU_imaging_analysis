function [prc_config, obs_config] = cbbu_HGF_2level_config

% Perceptual model
prc_config = tapas_hgf_binary_config;
prc_config.logkamu(2) = log(0);
prc_config.logkasa(2) = 0;
prc_config.omsa(3) = 0; 
prc_config.omsa(2) = 8;
prc_config = tapas_align_priors(prc_config);

% obs model
obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;


end