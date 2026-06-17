function c = obs_HGF_comb_obs_config

obs_config.predorpost       = 1; % 1=Predictions, 2=Posteriors
obs_config.model            = 'obs_HGF_comb_obs';
obs_config.obs_fun          = @obs_HGF_comb_obs;
obs_config.transp_obs_fun   = @obs_HGF_comb_obs_transp;

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
obs_config.beta5mu          = 0; % Post error slowing
obs_config.beta5sa          = 4;
obs_config.logsamu          = log(.1); % RT noise
obs_config.logsasa          = 2;
obs_config                  = align_priors(obs_config);

c = obs_config;


end