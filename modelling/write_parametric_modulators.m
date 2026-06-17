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




%% 3 level HGF
clear; clc;

% load subject model fits
fits = importdata('cbbu_uHGF_3level_model_fits.mat');

% Either use data_dir or BIDS_root, depending on the computer. Fantastic coding
% data_dir = 'C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\DATA';
BIDS_root = 'F:\cbbu_BIDS';

for iSub = 1:numel(fits)
    
    for iRun = 1:2
        % load subject data
        if exist('data_dir', 'var')
            d = dir([data_dir, '\sub-', num2str(iSub, '%02i'), '\task_fmri\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run', num2str(iRun), '*']);
        elseif exist('BIDS_root', 'var')
            d = dir([BIDS_root, '\sub-', num2str(iSub, '%02i'), '\beh\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run', num2str(iRun), '*']);
        end
        trials = importdata(fullfile(d(1).folder, d(1).name));

        % get different events
        face_outcome        = strcmp(trials.stim_type, 'face');
        house_outcome       = strcmp(trials.stim_type, 'house');
        face_response       = strcmp(trials.prediction, 'face');
        house_response      = strcmp(trials.prediction, 'house');
        star_cue            = strcmp(trials.cue_name, 'star');
        triangle_cue        = strcmp(trials.cue_name, 'triangle');
        missed              = cellfun(@isempty, trials.prediction_key);

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

        % remove missed
        e2(missed)      = NaN;
        e3(missed)      = NaN;
        psi2(missed)    = NaN;
        psi3(missed)    = NaN;
        mu3(missed)     = NaN;
        ech(missed)     = NaN;

        % set pm structure
        pm(1).name = 'e2';
        pm(1).faces_data = e2(face_outcome);
        pm(1).houses_data = e2(house_outcome);
        pm(2).name = 'e3';
        pm(2).faces_data = e3(face_outcome);
        pm(2).houses_data = e3(house_outcome);
        pm(3).name = 'psi2';
        pm(3).faces_data = psi2(face_outcome);
        pm(3).houses_data = psi2(house_outcome);
        pm(4).name = 'psi3';
        pm(4).faces_data = psi3(face_outcome);
        pm(4).houses_data = psi3(house_outcome);
        pm(5).name = 'mu3';
        pm(5).faces_data = mu3(face_outcome);
        pm(5).houses_data = mu3(house_outcome);
        pm(6).name = 'ech';
        pm(6).faces_data = ech(face_outcome);
        pm(6).houses_data = ech(house_outcome);
        
        % save
        mkdir([BIDS_root, '\sub-', num2str(iSub, '%02i'), '\GLM\uHGF_3level_parametric_modulators']);
        save([BIDS_root, '\sub-', num2str(iSub, '%02i'), '\GLM\uHGF_3level_parametric_modulators\run_', num2str(iRun), '_parametric_modulators.mat'], 'pm');        
    end
end



%% 2 level HGF
clear; clc;

% load subject model fits
fits = importdata('cbbu_uHGF_2level_model_fits.mat');

% Either use data_dir or BIDS_root, depending on the computer. Fantastic coding
% data_dir = 'C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\DATA';
BIDS_root = 'F:\cbbu_BIDS';

for iSub = 1:numel(fits)
    
    for iRun = 1:2
        % load subject data
        if exist('data_dir', 'var')
            d = dir([data_dir, '\sub-', num2str(iSub, '%02i'), '\task_fmri\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run', num2str(iRun), '*']);
        elseif exist('BIDS_root', 'var')
            d = dir([BIDS_root, '\sub-', num2str(iSub, '%02i'), '\beh\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run', num2str(iRun), '*']);
        end
        trials = importdata(fullfile(d(1).folder, d(1).name));

        % get different events
        face_outcome        = strcmp(trials.stim_type, 'face');
        house_outcome       = strcmp(trials.stim_type, 'house');
        face_response       = strcmp(trials.prediction, 'face');
        house_response      = strcmp(trials.prediction, 'house');
        star_cue            = strcmp(trials.cue_name, 'star');
        triangle_cue        = strcmp(trials.cue_name, 'triangle');
        missed              = cellfun(@isempty, trials.prediction_key);

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

        % remove missed
        e2(missed)      = NaN;
        e3(missed)      = NaN;
        psi2(missed)    = NaN;
        psi3(missed)    = NaN;
        ech(missed)     = NaN;

        % set pm structure
        pm(1).name = 'e2';
        pm(1).faces_data = e2(face_outcome);
        pm(1).houses_data = e2(house_outcome);
        pm(2).name = 'e3';
        pm(2).faces_data = e3(face_outcome);
        pm(2).houses_data = e3(house_outcome);
        pm(3).name = 'psi2';
        pm(3).faces_data = psi2(face_outcome);
        pm(3).houses_data = psi2(house_outcome);
        pm(4).name = 'psi3';
        pm(4).faces_data = psi3(face_outcome);
        pm(4).houses_data = psi3(house_outcome);
        pm(5).name = 'ech';
        pm(5).faces_data = ech(face_outcome);
        pm(5).houses_data = ech(house_outcome);
        
        % save
        mkdir([BIDS_root, '\sub-', num2str(iSub, '%02i'), '\GLM\uHGF_2level_parametric_modulators']);
        save([BIDS_root, '\sub-', num2str(iSub, '%02i'), '\GLM\uHGF_2level_parametric_modulators\run_', num2str(iRun), '_parametric_modulators.mat'], 'pm');        
    end
end

