% function to run parameter recovery on Pearce Hall model

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = double([run1.cue == run1.outcome; run2.cue == run2.outcome]);

% load models
[prc_config, obs_config] = cbbu_PH_config;

% load optim algorithm
optim_config = tapas_quasinewton_optim_config;
% optim_config.nRandInit = 4;

    
% simulate data with sampleModel
sim = tapas_simModel(u, 'tapas_ph_binary', [tapas_sgm(0, 1), tapas_sgm(-3.37866, 1), exp(-0.272429)], 'tapas_unitsq_sgm', 48, 12345);

% recover
est = tapas_fitModel(...
            sim.y,...
            sim.u,...
            prc_config,...
            obs_config,...
            optim_config);
