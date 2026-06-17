function [prc_config, obs_config] = cbbu_uHGF_2level_comb_obs_config

% Perceptual model
prc_config = uhgf_binary_config;
prc_config.logkamu(2) = log(0);
prc_config.logkasa(2) = 0;
prc_config.ommu(2) = -3;
prc_config.omsa(2) = 4;
prc_config.ommu(3) = 0;
prc_config.omsa(3) = 0;
prc_config = align_priors(prc_config);

% obs model
obs_config = obs_HGF_comb_obs_config;
obs_config.logzetamu        = log(5); % inverse decision noise
obs_config.logzetasa        = 2;
obs_config.beta0mu          = 5.8; % RT intercept
obs_config.beta0sa          = 4;
obs_config.beta1mu          = 0; % Surprise
obs_config.beta1sa          = 4;
obs_config.beta2mu          = 0; % Bernoulli variance
obs_config.beta2sa          = 4;
obs_config.beta3mu          = 0; % Inferential variance
obs_config.beta3sa          = 4;
obs_config.beta4mu          = 0; % Phasic volatility
obs_config.beta4sa          = 0;
obs_config.beta5mu          = 0; % Post error
obs_config.beta5sa          = 4;
obs_config.logsamu          = log(.1); % RT noise
obs_config.logsasa          = 2;
obs_config = align_priors(obs_config);


end