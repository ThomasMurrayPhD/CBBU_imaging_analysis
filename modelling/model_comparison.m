% Model comparison using VBA toolbox

addpath(genpath('C:\Users\LabDesktop\Documents\MATLAB\VBA-toolbox-master\'));

% Name models as folder names
stream = 'dual';
% model_names = {'uHGF_2level', 'uHGF_3level', 'RW', 'SuttonK1'};
% model_names = {'uHGF_2level_comb_obs2', 'uHGF_3level_comb_obs2', 'SuttonK1_comb_obs', 'RW_comb_obs'};
model_names = {...
    'uHGF_2level_comb_obs1', 'uHGF_2level_comb_obs2', 'uHGF_2level_comb_obs3', ...
    'uHGF_3level_comb_obs1', 'uHGF_3level_comb_obs2', 'uHGF_3level_comb_obs3',...
    'SuttonK1_comb_obs', 'RW_comb_obs'};
% model_names = {'uHGF_3level_comb_obs1', 'uHGF_3level_comb_obs2', 'uHGF_3level_comb_obs3'} ;
fig_names = {'2a', '2b', '2c', '3a', '3b', '3c', 'SK1', 'RW'};

% model_names = {'uHGF_2level_comb_obs1', 'uHGF_3level_comb_obs1', ...
%     'uHGF_2level_comb_obs2', 'uHGF_3level_comb_obs2', ...
%     'uHGF_2level_comb_obs3', 'uHGF_3level_comb_obs3', ...
%     'SuttonK1_comb_obs', 'RW_comb_obs'};
% 
% model_names = {'uHGF_3level_comb_obs1','uHGF_3level_comb_obs2','uHGF_3level_comb_obs3'};
% 
% model_names = {'uHGF_2level_comb_obs1','uHGF_2level_comb_obs2','uHGF_2level_comb_obs3'};


N_models = numel(model_names);


%% Load model fits
for iM = 1:N_models
    d = importdata([stream, '_stream\cbbu_', model_names{iM}, '_model_fits.mat']);
    models(iM).model_fits = d.model_fits;
end
N_subs = numel(models(1).model_fits);


%% Get LME
LMEs = nan(N_subs, N_models);
for iP = 1:N_subs
    for iM = 1:N_models
        if ~isempty(models(iM).model_fits{iP})
            LMEs(iP, iM) = models(iM).model_fits{iP}.optim.LME;
        end
    end
end


%% Remove people with too many missing trials

n_missing = arrayfun(@(x) sum(isnan(models(1).model_fits{x}.y(:, 1))), 1:N_subs);

threshold = 33; % 10%+ - excludes 1 (one person missed exactly 10%...)

LMEs(n_missing > threshold,:) = [];


%% Remove invalid
valid = ~(isnan(LMEs) + isinf(LMEs));
LMEs = LMEs(~any(~valid, 2), :);

% LMEs(any(LMEs < -10000, 2), :) = [];

%% Model comparison

% options.modelNames = strrep(model_names, '_', '-');
options.modelNames = fig_names;
[posterior,out] = VBA_groupBMC(LMEs', options);


