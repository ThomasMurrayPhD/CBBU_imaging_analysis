% script to write pm.mat for use in SPM
% 
%   structure:
%       pm(1).name = 'variable 1'
%       pm(1).faces_data = [ ... ]
%       pm(1).houses_data = [ ... ]
%       pm(2).name = 'variable 2'
%       pm(2).faces_data = [ ... ]
%       pm(2).houses_data = [ ... ] etc.
% 
% Original Iglesias paper uses: 
% e2 - the precision-weighted PE about visual stimulus outcome (that serves
%       to update the estimate of visual stimulus probabilities in logit
%       space);
% e3 - the precision-weighted PE about cue-outcome contingency (that serves
%       to update the estimate of log-volatility); 
% psi2 - precision weight at the second level; this corresponds to the
%       learning rate by which estimates of cue-outcome contingency are updated;
% psi3 - precision weight at the third level; this is proportional to the
%       learning rate by which log-volatility estimates are updated; 
% mu3 - the predicted log-volatility 
% e_ch - the choice prediction error


% load subject model fits
fits = importdata('cbbu_uHGF_3level_model_fits.mat');

data_dir = 'C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\DATA';

for iSub = 1:numel(fits)
    
    % load subject data
    d = dir([data_dir, '\sub-01\task_fmri\sub-01_facehouse-MRI_run1*']);
    run1 = importdata(fullfile(d(1).folder, d(1).name));
    d = dir([data_dir, '\sub-01\task_fmri\sub-01_facehouse-MRI_run2*']);
    run2 = importdata(fullfile(d(1).folder, d(1).name));


    trials = [run1; run2];
    face_outcome = strcmp(trials.stim_type, 'face');
    house_outcome = strcmp(trials.stim_type, 'house');
    face_response = strcmp(trials.prediction, 'face');
    house_response = strcmp(trials.prediction, 'house');
    star_cue = strcmp(trials.cue_name, 'star');
    triangle_cue = strcmp(trials.cue_name, 'triangle');
    
    % ech (choice error - see Iglesias supplementary)
    muhat1 = fits{iSub}.traj.muhat(:,1);
    ech = nan(size(trials,1), 1);
    ech(face_outcome & face_response & star_cue)          = 1 - muhat1(face_outcome & face_response & star_cue);
    ech(face_outcome & face_response & triangle_cue)      = 1 - (1 - muhat1(face_outcome & face_response & triangle_cue));
    ech(face_outcome & house_response & star_cue)         = 0 - (1 - muhat1(face_outcome & house_response & star_cue));
    ech(face_outcome & house_response & triangle_cue)     = 0 - muhat1(face_outcome & house_response & triangle_cue);
    ech(house_outcome & house_response & star_cue)        = 1 - (1 - muhat1(house_outcome & house_response & star_cue));
    ech(house_outcome & house_response & triangle_cue)    = 1 - muhat1(house_outcome & house_response & triangle_cue);
    ech(house_outcome & face_response & star_cue)         = 0 - muhat1(house_outcome & face_response & star_cue);
    ech(house_outcome & face_response & triangle_cue)     = 0 - (1 - muhat1(house_outcome & face_response & triangle_cue));
    
    % get other trajectories
    e2      = fits{iSub}.traj.epsi(:,2); % e2
    e3      = fits{iSub}.traj.epsi(:,3); % e3
    psi2    = fits{iSub}.traj.psi(:,2);  % psi2
    psi3    = fits{iSub}.traj.psi(:,3);  % psi3
    mu3     = fits{iSub}.traj.mu(:,3);   % mu3
    
end