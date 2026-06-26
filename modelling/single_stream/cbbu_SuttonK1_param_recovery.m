% function to run parameter recovery on Sutton K1 model

toolboxroot = 'C:\Users\Tom\Documents\MATLAB\Toolboxes\hgf-toolbox-main\hgf-toolbox-main';
run(fullfile(toolboxroot, 'setup.m'));

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = double([run1.cue == run1.outcome; run2.cue == run2.outcome]);

% load models
[prc_config, obs_config] = cbbu_SuttonK1_config;

% load optim algorithm
optim_config = quasinewton_optim_config;
% optim_config.nRandInit = 4;

% Parameters to recover
prc_param_names = {'mu'};
prc_param_idx   = 1;
prc_param_space = {'log'};
obs_param_names = {'zeta'};
obs_param_idx   = 1;
obs_param_space = {'log'};

N = 200;

recov = parameter_recovery_master_parallel( ...
    u,...
    prc_config,...
    obs_config,...
    optim_config,...
    N,...
    8, ...
    prc_param_names,...
    prc_param_idx,...
    prc_param_space,...
    obs_param_names,...
    obs_param_idx,...
    obs_param_space);

save('cbbu_SuttonK1_recov.mat', 'recov');
recovery_figures(recov);

% 
% 
% 
% % run recovery
% N=200;
% 
% % preallocate space
% recov.mu.sim = nan(N, 1);
% recov.mu.est = nan(N, 1);
% recov.mu.space = 'log';
% % recov.vhat_1.sim = nan(N, 1);
% % recov.vhat_1.est = nan(N, 1);
% % recov.vhat_1.space = 'logit';
% % recov.h_1.sim = nan(N, 1);
% % recov.h_1.est = nan(N, 1);
% % recov.h_1.space = 'log';
% recov.ze.sim = nan(N, 1);
% recov.ze.est = nan(N, 1);
% recov.ze.space = 'log';
% 
% recov.LME = nan(N, 1); % store LME
% recov.AIC = nan(N, 1); % store AIC
% recov.BIC = nan(N, 1); % store BIC
% 
% recov.sim = cell(N, 1);
% recov.est = cell(N, 1);
% 
% % Loop
% for i = 1:N
% 
%     % simulate data with sampleModel
%     sim = sampleModel(u, prc_config, obs_config);
% 
%     % store simulated params
%     recov.mu.sim(i) = sim.p_prc.mu;
%     % recov.vhat_1.sim(i) = sim.p_prc.vhat_1;
%     % recov.h_1.sim(i) = sim.p_prc.h_1;
%     recov.ze.sim(i) = sim.p_obs.ze;
% 
%     success = false;
%     attempt = 1;
%     while ~success && attempt < 5
%         % recover
%         est = fitModel(...
%                     sim.y,...
%                     sim.u,...
%                     prc_config,...
%                     obs_config,...
%                     optim_config);
%         if isequaln(est.p_prc.ptrans, est.c_prc.priormus) && isequaln(est.p_obs.ptrans, est.c_obs.priormus)
%             % no success
%             success = false;
%             attempt = attempt + 1;
%         else
%             % success
%             success = true;
% 
%             % store recovered params
%             recov.mu.est(i) = est.p_prc.mu;
%             % recov.vhat_1.est(i) = est.p_prc.vhat_1;
%             % recov.h_1.est(i) = est.p_prc.h_1;
%             recov.ze.est(i) = est.p_obs.ze;
% 
%             % store fit metrics
%             recov.LME(i) = est.optim.LME;
%             recov.AIC(i) = est.optim.AIC;
%             recov.BIC(i) = est.optim.BIC;
% 
%             % store sim and est
%             recov.sim{i} = sim;
%             recov.est{i} = est;
%         end
%     end
% 
% end
% save('cbbu_SuttonK1_recov.mat', 'recov');
% recovery_figures(recov);


