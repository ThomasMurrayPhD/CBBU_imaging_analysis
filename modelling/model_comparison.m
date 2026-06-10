% Model comparison using VBA toolbox

% Name models as folder names
model_names = {'uHGF_2level', 'uHGF_3level', 'RW', 'SuttonK1', 'VKF'};

N_models = numel(model_names);

%% Load model fits
for iM = 1:N_models
    models(iM).model_fits = importdata(['cbbu_', model_names{iM}, '_model_fits.mat']);
end


%% Get LME
LMEs = nan(44, N_models);
for iP = 1:44
    for iM = 1:N_models
        if ~isempty(models(iM).model_fits{iP})
            LMEs(iP, iM) = models(iM).model_fits{iP}.optim.LME;
        end
    end
end
valid = ~(isnan(LMEs) + isinf(LMEs));
LMEs_valid = LMEs(~any(~valid, 2), :);

% LMEs_valid(19,:) = []; % this person has the highest across all models...
% LMEs_valid = LMEs_valid(~any(LMEs_valid < -10000, 2), :); % some for 3L Iglesias 

%% Model comparison
options.modelNames = model_names;
[posterior,out] = VBA_groupBMC(LMEs_valid', options);


