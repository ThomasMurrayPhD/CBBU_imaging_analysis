% function to run parameter recovery on uHGF_2level

toolboxroot = 'C:\Users\Tom\Documents\MATLAB\Toolboxes\hgf-toolbox-main\hgf-toolbox-main';
run(fullfile(toolboxroot, 'setup.m'));

addpath('HGF_comb_obs\')

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = [run1.cue == run1.outcome; run2.cue == run2.outcome];

% load models
[prc_config, obs_config] = cbbu_uHGF_2level_comb_obs_config;

% load optim algorithm
optim_config = quasinewton_optim_config;
optim_config.nRandInit = 4;

% one run
% sim = sampleModel(u, prc_config, obs_config);
% est = fitModel(...
%                 sim.y,...
%                 sim.u,...
%                 prc_config,...
%                 obs_config,...
%                 optim_config);


% run recovery
N=100;

% Parameters to recover
prc_param_names = {'om2'};
prc_param_idx   = 13;
prc_param_space = {'native'};
obs_param_names = {'zeta', 'beta0', 'beta1', 'beta2', 'beta3', 'beta5', 'sa'};
obs_param_idx   = [1, 2, 3, 4, 5, 7, 8];
obs_param_space = {'log', 'native', 'native', 'native', 'native', 'native', 'log'};

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


save('cbbu_uHGF_2level_comb_obs_PEslowing_recov.mat', 'recov');
recovery_figures(recov);


