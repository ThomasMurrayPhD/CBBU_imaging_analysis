function [prc_config, obs_config] = cbbu_PH_config

% http://www.scholarpedia.org/article/Pearce-Hall_error_learning_theory
% Wise, T., Michely, J., Dayan, P., & Dolan, R. J. (2019). A computational
% account of threat-related attentional bias. PLoS computational biology,
% 15(10), e1007341. 
% Barnby, J. M., Mehta, M. A., & Moutoussis, M. (2022).
% The computational relationship between reinforcement learning, social
% inference, and paranoia. PLoS computational biology, 18(7), e1010326.

% Perceptual model
prc_config = tapas_ph_binary_config;

prc_config.logitv_0mu   = tapas_logit(0.5, 1);
prc_config.logitv_0sa   = 0;
prc_config.logital_0mu  = tapas_logit(0.5457, 1); % from bopars
prc_config.logital_0sa  = 1;
prc_config.logSmu       = log(0.2075); % from bopars
prc_config.logSsa       = 8;

prc_config = tapas_align_priors(prc_config);


% Response model
obs_config = tapas_unitsq_sgm_config;
obs_config.predorpost = 1;


end