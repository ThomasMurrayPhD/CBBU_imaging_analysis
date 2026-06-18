function [prc_config, obs_config] = cbbu_SuttonK1_comb_obs_config

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
obs_config = obs_SuttonK1_comb_obs_config;

obs_config.logzetamu        = log(5); % inverse decision noise
obs_config.logzetasa        = 2;

obs_config.beta0mu          = 5.8; % RT intercept
obs_config.beta0sa          = 4;
obs_config.beta1mu          = 0; % learning rate
obs_config.beta1sa          = 4;
obs_config.beta2mu          = 0; % Post error slowing
obs_config.beta2sa          = 4;
obs_config.logsamu          = log(.1); % RT noise
obs_config.logsasa          = 2;
obs_config                  = align_priors(obs_config);



end