function [prc_config, obs_config] = cbbu_RW_comb_obs_config

% Perceptual model
prc_config = rw_binary_config;
prc_config.logitv_0mu = 0;
prc_config.logitv_0sa = 0;
prc_config.logitalmu = 0;
prc_config.logitalsa = 1;

prc_config = align_priors(prc_config);

% Response model
obs_config = obs_RW_comb_obs_config;

obs_config.logzetamu        = log(5); % inverse decision noise
obs_config.logzetasa        = 2;

obs_config.beta0mu          = 5.8; % RT intercept
obs_config.beta0sa          = 4;
obs_config.beta1mu          = 0; % Post error slowing
obs_config.beta1sa          = 4;
obs_config.logsamu          = log(.1); % RT noise
obs_config.logsasa          = 2;
obs_config                  = align_priors(obs_config);



end