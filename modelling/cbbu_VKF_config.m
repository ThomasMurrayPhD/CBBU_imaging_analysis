function [prc_config, obs_config] = cbbu_VKF_config

% Perceptual model
prc_config = prc_vkf_binary_config;

prc_config.logitlambdamu = tapas_logit(0.5, 1);
prc_config.logitlambdasa = 0;

prc_config.logv0mu = log(.2);
prc_config.logv0sa = 0;

prc_config.logomegamu = log(0.1405); % from bopars
prc_config.logomegasa = 2;

prc_config.logw0mu = log(0.2802); % from bopars
prc_config.logw0sa = 2;

prc_config = tapas_align_priors(prc_config);


% Response model
obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;

end