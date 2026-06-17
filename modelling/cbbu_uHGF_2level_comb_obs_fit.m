% function to fit 2level HGF

% toolboxroot = 'C:\Users\Tom\Documents\MATLAB\Toolboxes\hgf-toolbox-main\hgf-toolbox-main';
toolboxroot = 'C:\Users\LabDesktop\Documents\MATLAB\hgf-toolbox-main\hgf-toolbox-main';
run(fullfile(toolboxroot, 'setup.m'));

addpath('HGF_comb_obs\')

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = double([run1.cue == run1.outcome; run2.cue == run2.outcome]);

% load models
[prc_config, obs_config] = cbbu_uHGF_2level_comb_obs_config;

% load optim algorithm
optim_config = quasinewton_optim_config;
optim_config.nRandInit = 4;


% initialise parallel
n_workers = 8;
pool = gcp('nocreate');
if isempty(pool)
    parpool('local', n_workers);
elseif pool.NumWorkers ~= n_workers
    delete(pool);
    parpool('local', n_workers);
end

% Loop through files and fit
model_fits = cell(44,1);
parfor i = 1:44

    % sub directory
    sub_dir = ['task_data\sub-', num2str(i, '%02i'), '\'];

    % preallocate est
    est = [];

    % load data
    run1_fname = dir(fullfile(sub_dir, ['sub-', num2str(i, '%02i'), '_facehouse-MRI_run1*.mat'])).name;
    run2_fname = dir(fullfile(sub_dir, ['sub-', num2str(i, '%02i'), '_facehouse-MRI_run2*.mat'])).name;
    run1 = importdata([sub_dir, run1_fname]);
    run2 = importdata([sub_dir, run2_fname]);
    
    % get responses in contingency space
    y = double([run1.cue == strcmp(run1.prediction, 'face'); run2.cue == strcmp(run2.prediction, 'face')]);
    y(:,2) = log([run1.prediction_RT; run2.prediction_RT] * 1000);
    y([run1.prediction_timedout; run2.prediction_timedout], :) = NaN; %remove missed
    
    % fit model
    success = false;
    attempt = 1;
    max_attempts = 5;
    while ~success && attempt < max_attempts
        
        try
            est = fitModel(...
                    y,...
                    u,...
                    prc_config,...
                    obs_config,...
                    optim_config);
            if isequaln(est.p_prc.ptrans, est.c_prc.priormus) && isequaln(est.p_obs.ptrans, est.c_obs.priormus)
                success = false;
            else
                success = true;
            end
        catch
            fprintf('\nFit failed on attempt %i', attempt)
            attempt = attempt + 1;
            if attempt == max_attempts
                est = NaN;
            end
        end
        
        model_fits{i} = est;

    end
    
end

save('cbbu_uHGF_2level_comb_obs_model_fits.mat', 'model_fits');


