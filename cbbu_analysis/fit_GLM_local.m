% script to fit GLM using lab desktop


BIDS_root = 'F:\cbbu_BIDS\';

subs = [2:18, 20:44];

% For subject 1 - the first run was 10 scans too short. The batch job has
% been written, but I have manually deleted any stimulus onsets (and
% associated parametric modulators) more than 590 seconds and re-run.

for iSub = subs
    
    % scans
    run1_scans = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_task-facehouse_acq-1_dir-PA_bold_centred_unwarped_realigned_smoothed.nii'];
    run2_scans = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_task-facehouse_acq-2_dir-PA_bold_centred_unwarped_realigned_smoothed.nii'];
    
    % trials
    d1 = dir([BIDS_root, 'sub-', num2str(iSub, '%02i'), '\beh\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run1*']);
    run1_trials_fname = fullfile(d1(1).folder, d1(1).name);
    d2 = dir([BIDS_root, 'sub-', num2str(iSub, '%02i'), '\beh\sub-', num2str(iSub, '%02i'), '_facehouse-MRI_run2*']);
    run2_trials_fname = fullfile(d2(1).folder, d2(1).name);
    
    % multiple regressors
    physio_dir = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_facehouse_physio_output\'];
    if exist(physio_dir, 'dir')
        run1_multiple_regressors_fname = [physio_dir, 'run-1_physio_regressors.txt'];
        run2_multiple_regressors_fname = [physio_dir, 'run-2_physio_regressors.txt'];
    else
        run1_multiple_regressors_fname = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_task-facehouse_acq-1_dir-PA_bold_centred_unwarped_realigned.par'];
        run2_multiple_regressors_fname = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\func\sub-', num2str(iSub, '%02i'), '_task-facehouse_acq-2_dir-PA_bold_centred_unwarped_realigned.par'];
    end
    
    % parametric modulators
    run1_modulators = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\uHGF_3level_parametric_modulators\run_1_parametric_modulators.mat'];
    run2_modulators = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\uHGF_3level_parametric_modulators\run_2_parametric_modulators.mat'];
    output_batch_fname = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\uHGF_3level_parametric_modulators\first_level_batch.mat'];
    spm_output_dir = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\uHGF_3level_parametric_modulators\'];
    runjob = true;
    
    % run function
    specify_first_level_2runs( ...
        run1_scans, ...
        run2_scans, ...
        run1_trials_fname, ...
        run2_trials_fname, ...
        run1_multiple_regressors_fname, ...
        run2_multiple_regressors_fname, ...
        run1_modulators, ...
        run2_modulators, ...
        output_batch_fname, ...
        spm_output_dir, ...
        runjob)
    
end