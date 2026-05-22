function [prc_config, obs_config] = cbbu_VKF_config
addpath('VKF');

% Perceptual model
prc_config = prc_vkf_binary_config;

prc_config.logitlambdamu = tapas_logit(0.5, 1);
prc_config.logitlambdasa = 4;

prc_config.logv0mu = log(.2);
prc_config.logv0sa = 0;

prc_config.logomegamu = log(0.15);
prc_config.logomegasa = 16;

prc_config.logw0mu = log(0.2);
prc_config.logw0sa = 0;

prc_config = align_priors(prc_config);

% Response model
obs_config = unitsq_sgm_config;
obs_config.logzemu = log(48);
obs_config.logzesa = 1;
obs_config.predorpost = 1;
obs_config = align_priors(obs_config);

end