% function to fit RW

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = double([run1.cue == run1.outcome; run2.cue == run2.outcome]);

% load models
[prc_config, obs_config] = cbbu_SuttonK1_config;

% load optim algorithm
optim_config = tapas_quasinewton_optim_config;
optim_config.nRandInit = 4;

% Loop through files and fit
model_fits = cell(44,1);
for i = 1:44

    % sub directory
    sub_dir = ['..\..\DATA\sub-', num2str(i, '%02i'), '\task_fmri\'];

    % load data
    run1_fname = dir(fullfile(sub_dir, ['sub-', num2str(i, '%02i'), '_facehouse-MRI_run1*.mat'])).name;
    run2_fname = dir(fullfile(sub_dir, ['sub-', num2str(i, '%02i'), '_facehouse-MRI_run2*.mat'])).name;
    run1 = importdata([sub_dir, run1_fname]);
    run2 = importdata([sub_dir, run2_fname]);
    
    % get responses in contingency space
    y = double([run1.cue == strcmp(run1.prediction, 'face'); run2.cue == strcmp(run2.prediction, 'face')]);
    y([run1.prediction_timedout; run2.prediction_timedout]) = NaN; %remove missed
    
    % fit model
    model_fits{i} = tapas_fitModel(...
            y,...
            u,...
            prc_config,...
            obs_config,...
            optim_config);

end

save('HGF_SuttonK1_model_fits.mat', 'model_fits');


