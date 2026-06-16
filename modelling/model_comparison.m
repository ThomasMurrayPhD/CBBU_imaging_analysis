% Model comparison using VBA toolbox

% Name models as folder names
% model_names = {'uHGF_3level', 'RW', 'SuttonK1', 'VKF'};
model_names = {'uHGF_2level_comb_obs2', 'uHGF_3level_comb_obs2'};
N_models = numel(model_names);


%% Load model fits
for iM = 1:N_models
    models(iM).model_fits = importdata(['cbbu_', model_names{iM}, '_model_fits.mat']);
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
% valid = ~(isnan(LMEs) + isinf(LMEs));
% LMEs = LMEs(~any(~valid, 2), :);

% LMEs(any(LMEs < -9000, 2), :) = [];

%% Model comparison
options.modelNames = model_names;
[posterior,out] = VBA_groupBMC(LMEs', options);


