% script to fit multtriial GLM for MVPA
% 
% 
% Example:
% S.d = rand(40, 10); % N scans x N voxels
% S.events.names = {'faces', 'houses'};
% S.events.ons = {[10, 30, 50, 70, 90], [20, 40, 60, 80, 100]};
% S.events.dur = {[2, 2, 2, 2, 2], [2, 2, 2, 2, 2]};
% S.method = 'LSS';
% S.lambda = 0;
% S.XC = rand(40,5); % confound regressors
% S.TR = 3;
% S.units = 'secs';
% S.T = 16;
% S.T0 = 8;
% S.HC = 128;
% S.zflag = 0;
% [Beta,res,Z] = fMRI_multitrial_GLMs(S);



BIDS_root = 'F:\cbbu_BIDS\';

subs = [1:18, 20:44];


for iSub = subs
    fprintf('\nSub %i', iSub);
    for iRun = 1:2
        fprintf('\n\tRun %i', iRun);
        
        %Get data
        % Get all events, including missed. Remove these later in analysis
        fprintf('\n\t\tLoading data...');
        [scans, events, multiple_regressors, mask, missed_idx, face_valid_idx, house_valid_idx] = get_subject_data(iSub, iRun, BIDS_root);

        %Reshape scans (nVoxels x nScans)
        fprintf('\n\t\tReshaping scans...');
        scans_reshaped = reshape(scans, [(192*186*78), size(scans, 4)]);
        scans_reshaped = scans_reshaped'; % nScans * nVox
        mask_reshaped = logical(mask(:))';
        scans_masked = scans_reshaped(:, mask_reshaped);
        scans_masked = single(scans_masked); % single point precision
        
        
        %%%% Special case (stimuli presented after scanner cutoff). Only
        %%%% estimate those where full HRF can be modelled (~30 seconds).
        %%%% This is particularly important for LSS method (see Abdulrahman
        %%%% & Henson, 2016, Neuroimage)
        if iSub == 1 && iRun == 1
            for i = 1:2%3
                valid = events.ons{i} < 570;
                events.ons{i} = events.ons{i}(valid);
                events.dur{i} = events.dur{i}(valid);
            end
        end
        
        
        % make structure
        S.d         = scans_masked;         % data
        S.events    = events;               % conditions
        S.method    = 'LSS';                % Least-squares-separate
        S.lambda    = 0;                    % regularisation parameter
        S.XC        = multiple_regressors;  % confound regressors
        S.TR        = 3;                    % TR
        S.units     = 'secs';               % units (seconds)
        S.T         = 16;                   % microtime resolution
        S.T0        = 8;                    % reference timebin
        S.HC        = 128;                  % highpass cutoff for filtering
        S.zflag     = 0;                    % Z-score regressors flag
        S.voxel_batch_size = 10000;
        
        
        % Fit LSS GLM
        fprintf('\n\t\tFitting GLM...');
        [betas, ~, ~] = fMRI_multitrial_GLMs_optimised(S);
        
        % Run voxel-by-voxel to avoid OOM errors
%         step = 5;  % Print every 5%
%         nVox = size(scans_masked,2); % variable between people depending on brain size
%         betas = {zeros(size(events.ons{1}, 1), nVox), zeros(size(events.ons{2}, 1), nVox)}; % only 2 as we don't really care about modelling missed
%         for iVox = 1:nVox
%             S.d = scans_masked(:, iVox); % data
%             [i_beta, ~, ~] = fMRI_multitrial_GLMs(S);
%             betas{1}(:, iVox) = i_beta{1};
%             betas{2}(:, iVox) = i_beta{2};
%             if mod(iVox, round(nVox * step / 100)) == 0
%                 fprintf('\n\t\t\t%d%%...\n', round(100*iVox/nVox));
%             end
%         end
%         
%         % reshape betas
%         full_betas = cell(1,2);
%         for iBeta = 1:2
%             b = zeros(size(betas{iBeta}, 1), size(mask_reshaped, 2));
%             b(mask_reshaped)
%             betas{iBeta} = reshape(betas{iBeta}, [size(scans, 1), size(scans, 2), size(scans, 3), numel(S.events.ons{iBeta})]);
%         end




        % Reshape betas back into full 4D brain space
        fprintf('\n\t\tReshaping betas...');
        full_betas = cell(1, 2);
        for iBeta = 1:2

            % Number of events for this condition
            nEvents = size(betas{iBeta}, 1);

            % Preallocate full brain volume:
            % X x Y x Z x events
            full_betas{iBeta} = zeros( ...
                size(scans,1), ...
                size(scans,2), ...
                size(scans,3), ...
                nEvents, ...
                'single');

            % Flatten spatial dimensions of output
            beta_reshaped = reshape(full_betas{iBeta}, [], nEvents);

            % Insert masked voxel estimates
            beta_reshaped(mask_reshaped, :) = betas{iBeta}';

            % Put back into 4D X x Y x Z x events format
            full_betas{iBeta} = reshape(beta_reshaped, ...
                [size(scans,1), size(scans,2), size(scans,3), nEvents]);
        end

        % Replace masked beta matrices with full-brain 4D beta volumes
        betas = full_betas;

        % save as .mat in subject directory
        fprintf('\n\t\tSaving betas...');
        output_dir = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\multitrial'];
        if ~exist(output_dir, 'dir'); mkdir(output_dir); end
        save([output_dir, '\betas_run', num2str(iRun), '.mat'], 'betas', 'events', 'missed_idx', 'mask', 'face_valid_idx', 'house_valid_idx', '-v7.3');

    end
end



% function to get data
function [scans, events, multiple_regressors, mask, missed_idx, face_valid_idx, house_valid_idx] = get_subject_data(iSub, iRun, BIDS_root)
    % scans
    scans_fname = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_task-facehouse_acq-', num2str(iRun), '_dir-PA_bold_centred_unwarped_realigned_smoothed.nii'];
    scans = spm_read_vols(spm_vol(scans_fname));
    
    % mask
    mask = spm_read_vols(spm_vol([BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\No_parametric_modulators\mask.nii']));
    
    % trials table
    d = dir([BIDS_root, 'sub-', num2str(iSub, '%02i'), '\beh\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run', num2str(iRun), '*']);
    trials_fname = fullfile(d(1).folder, d(1).name);
    trials = load(trials_fname);
    trials = trials.trials;
    
    % Missed predictions indices
    missed_idx = isnan(trials.prediction_RT);
    
    % Logical indices (run 1)
    face_idx = trials.outcome == 1;
    house_idx = trials.outcome == 2;

    face_valid_idx = face_idx & ~missed_idx;
    house_valid_idx = house_idx & ~missed_idx;

    % Valid trials only
    face_onsets     = trials.timings_stim_onset(face_idx);
    house_onsets    = trials.timings_stim_onset(house_idx);

    face_durations = trials.timings_stim_duration(face_idx);
    house_durations = trials.timings_stim_duration(house_idx);

    % Missed trials
%     missed_onsets    = trials.timings_stim_onset(missed_idx);
%     missed_durations = trials.timings_stim_duration(missed_idx);
    
    
    % make events srtuctures
    events.names = {'faces', 'houses'};%, 'missed'};
    events.ons = {face_onsets, house_onsets};%, missed_onsets};
    events.dur = {face_durations, house_durations};%, missed_durations};
    
    % multiple regressors
    physio_dir = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_facehouse_physio_output\'];
    if exist(physio_dir, 'dir')
        multiple_regressors_fname = [physio_dir, 'run-', num2str(iRun), '_physio_regressors.txt'];
    else
        multiple_regressors_fname = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_task-facehouse_acq-', num2str(iRun), '_dir-PA_bold_centred_unwarped_realigned.txt'];
    end
    multiple_regressors = importdata(multiple_regressors_fname);
end
