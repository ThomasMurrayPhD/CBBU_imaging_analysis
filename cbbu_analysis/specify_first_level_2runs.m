% function to specify the first level GLM to use in spm

function specify_first_level_2runs( ...
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


% input
% scans = '../sub-10/func/sub-10_task-facehouse_acq-both_dir-PA_bold_centred_unwarped_realigned_normalised.nii';
% run1_trials_fname = 'sub-10_facehouse_MRI_run1_22-02-24_15-55-54.mat';
% run2_trials_fname = 'sub-10_facehouse_MRI_run2_22-02-24_16-07-35.mat';
% run1_multiple_regressors_fname = multiple regressors for run 1 (e.g. output from PhysIO - must be .txt);
% run2_multiple_regressors_fname = multiple regressors for run 1 (e.g. output from PhysIO - must be .txt);
% run1_modulators = parametric modulators for run 1. .mat file containing
%   structure:
%       pm(1).name = 'variable 1'
%       pm(1).faces_data = [ ... ]
%       pm(1).houses_data = [ ... ]
%       pm(2).name = 'variable 2'
%       pm(2).faces_data = [ ... ]
%       pm(2).houses_data = [ ... ] etc.
%   Leave empty if no parametric modulators
% run2_modulators = parametric modulators for run 2 (same rules).
% output_batch_fname = 'sub-10_first-level_batch.mat';
% spm_output_dir = pwd; % where to save SPM.mat
% runjob = boolean flag to run batch job




%% E.g.
% run1_scans='C:\Users\Tom\Desktop\sub-20\func\sub-20_task-facehouse_acq-1_dir-PA_bold_centred_unwarped_realigned_normalised.nii';
% run2_scans='C:\Users\Tom\Desktop\sub-20\func\sub-20_task-facehouse_acq-2_dir-PA_bold_centred_unwarped_realigned_normalised.nii';
% run1_trials_fname='C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\7T_analysis\GLM\sub-20_facehouse-MRI_run1_28-05-24_14-21-12.mat';
% run2_trials_fname='C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\7T_analysis\GLM\sub-20_facehouse-MRI_run2_28-05-24_14-33-12.mat';
% run1_multiple_regressors_fname='C:\Users\Tom\Desktop\sub-20\func\sub-20_facehouse_physio_output\run-1_physio_regressors.txt';
% run2_multiple_regressors_fname='C:\Users\Tom\Desktop\sub-20\func\sub-20_facehouse_physio_output\run-2_physio_regressors.txt';
% run1_modulators='C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\7T_analysis\GLM\run2_pm.mat';
% run2_modulators='C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\7T_analysis\GLM\run2_pm.mat';
% output_batch_fname='C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\7T_analysis\GLM\glmspec.mat';
% spm_output_dir='C:\Users\Tom\Desktop\sub-20\SPM';
% runjob=false;

%%




% if compressed .nii input (run 1)
if strcmp(run1_scans(end-2:end), '.gz')
    gunzip(run1_scans);
    run1_scans = run1_scans(1:end-3);
end

% if compressed .nii input (run 2)
if strcmp(run2_scans(end-2:end), '.gz')
    gunzip(run2_scans);
    run2_scans = run2_scans(1:end-3);
end

% Change realignment parameters from .par to .txt (Run 1)
if strcmp(run1_multiple_regressors_fname(end-3:end), '.par')
    rp_data = importdata(run1_multiple_regressors_fname);
    writematrix(rp_data, [run1_multiple_regressors_fname(1:end-4), '.txt']);
    run1_multiple_regressors_fname = [run1_multiple_regressors_fname(1:end-4), '.txt'];
end

% Change realignment parameters from .par to .txt (Run 2)
if strcmp(run2_multiple_regressors_fname(end-3:end), '.par')
    rp_data = importdata(run2_multiple_regressors_fname);
    writematrix(rp_data, [run2_multiple_regressors_fname(1:end-4), '.txt']);
    run2_multiple_regressors_fname = [run2_multiple_regressors_fname(1:end-4), '.txt'];
end

% read trial info
run1_trials = load(run1_trials_fname);
run1_trials = run1_trials.trials;
run2_trials = load(run2_trials_fname);
run2_trials = run2_trials.trials;


% Missed predictions onsets
run1_missed = isnan(run1_trials.prediction_RT);
run2_missed = isnan(run2_trials.prediction_RT);



% Logical indices (run 1)
f_idx_run1 = run1_trials.outcome == 1;
h_idx_run1 = run1_trials.outcome == 2;

valid_f_run1 = f_idx_run1 & ~run1_missed;
valid_h_run1 = h_idx_run1 & ~run1_missed;

% Valid trials only
f_onsets_run1    = run1_trials.timings_stim_onset(valid_f_run1);
h_onsets_run1    = run1_trials.timings_stim_onset(valid_h_run1);

f_durations_run1 = run1_trials.timings_stim_duration(valid_f_run1);
h_durations_run1 = run1_trials.timings_stim_duration(valid_h_run1);

% Missed trials
run1_missed_onsets    = run1_trials.timings_stim_onset(run1_missed);
run1_missed_durations = run1_trials.timings_stim_duration(run1_missed);


% Logical indices (run 2)
f_idx_run2 = run2_trials.outcome == 1;
h_idx_run2 = run2_trials.outcome == 2;

valid_f_run2 = f_idx_run2 & ~run2_missed;
valid_h_run2 = h_idx_run2 & ~run2_missed;

% Valid trials only
f_onsets_run2    = run2_trials.timings_stim_onset(valid_f_run2);
h_onsets_run2    = run2_trials.timings_stim_onset(valid_h_run2);

f_durations_run2 = run2_trials.timings_stim_duration(valid_f_run2);
h_durations_run2 = run2_trials.timings_stim_duration(valid_h_run2);

% Missed trials
run2_missed_onsets    = run2_trials.timings_stim_onset(run2_missed);
run2_missed_durations = run2_trials.timings_stim_duration(run2_missed);


% remove missed from parametric modulators (if present)
if ~isempty(run1_modulators)
    pm_1 = load(run1_modulators); % load .mat
    pm_1 = pm_1.pm; 

    for iPM = 1:numel(pm_1)
        % pm_1(iPM).faces_data(missed_f_run1) = [];
        % pm_1(iPM).houses_data(missed_h_run1) = [];

        pm_1(iPM).faces_data = pm_1(iPM).faces_data(valid_f_run1(f_idx_run1));
        pm_1(iPM).houses_data = pm_1(iPM).houses_data(valid_h_run1(h_idx_run1));

        assert(length(f_onsets_run1) == length(pm_1(iPM).faces_data));
        assert(length(h_onsets_run1) == length(pm_1(iPM).houses_data));
    end
end
if ~isempty(run2_modulators)
    pm_2 = load(run2_modulators); % load .mat
    pm_2 = pm_2.pm; 

    for iPM = 1:numel(pm_2)
        % pm_2(iPM).faces_data(missed_f_run2) = [];
        % pm_2(iPM).houses_data(missed_h_run2) = [];

        pm_2(iPM).faces_data = pm_2(iPM).faces_data(valid_f_run2(f_idx_run2));
        pm_2(iPM).houses_data = pm_2(iPM).houses_data(valid_h_run2(h_idx_run2));

        assert(length(f_onsets_run2) == length(pm_2(iPM).faces_data));
        assert(length(h_onsets_run2) == length(pm_2(iPM).houses_data));
    end
end



% List of scans in run 1
run1_nVols = size(importdata(run1_multiple_regressors_fname), 1);
scan_list_run1 = cell(run1_nVols,1);
for i = 1:run1_nVols
    scan_list_run1{i} = sprintf('%s,%d', run1_scans, i);
end

% List of scans in run 2
run2_nVols = size(importdata(run2_multiple_regressors_fname), 1);
scan_list_run2 = cell(run2_nVols,1);
for i = 1:run2_nVols
    scan_list_run2{i} = sprintf('%s,%d', run2_scans, i);
end

%% SPM batch
% output directory / timing
matlabbatch{1}.spm.stats.fmri_spec.dir = {spm_output_dir};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 3;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16; % microtime resolution
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8; % microtime onset (round( ref_time / (TR / t) ))

% run 1 scans
matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = scan_list_run1;

% run 1/faces
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).name = 'faces';
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).onset = f_onsets_run1;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).duration = f_durations_run1;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).tmod = 0;

% run 1/houses
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).name = 'houses';
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).onset = h_onsets_run1;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).duration = h_durations_run1;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).tmod = 0;

% run 1/missed
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).name = 'missed';
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).onset = run1_missed_onsets;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).duration = run1_missed_durations;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).tmod = 0;

% run 1 parametric modulators
if ~isempty(run1_modulators)
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    for iPM = 1:numel(pm_1)
        % Faces
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod(iPM).name = pm_1(iPM).name; 
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod(iPM).param = pm_1(iPM).faces_data;
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod(iPM).poly = 1;
        
        % Houses
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod(iPM).name = pm_1(iPM).name; 
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod(iPM).param = pm_1(iPM).houses_data;
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod(iPM).poly = 1;
    end

    % Do not orthogonalise (important)
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).orth = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).orth = 0;
end


% run 1 multiple regressors
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {run1_multiple_regressors_fname};

% run 1 high pass filter
matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;

% run 2 scans
matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = scan_list_run2;

% run 2/faces
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).name = 'faces';
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).onset = f_onsets_run2;
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).duration = f_durations_run2;
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).tmod = 0;


% run 2/houses
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).name = 'houses';
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).onset = h_onsets_run2;
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).duration = h_durations_run2;
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).tmod = 0;

% run 2/missed
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).name = 'missed';
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).onset = run2_missed_onsets;
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).duration = run2_missed_durations;
matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).tmod = 0;

% run 1 parametric modulators
if ~isempty(run2_modulators)
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    for iPM = 1:numel(pm_2)
        % Faces
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod(iPM).name = pm_2(iPM).name; 
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod(iPM).param = pm_2(iPM).faces_data;
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod(iPM).poly = 1;
        
        % Houses
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod(iPM).name = pm_2(iPM).name; 
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod(iPM).param = pm_2(iPM).houses_data;
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod(iPM).poly = 1;
    end

    % Do not orthogonalise (important)
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).orth = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).orth = 0;
end


% run 2 multiple regressors
matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {run2_multiple_regressors_fname};

% run 2 high pass filter
matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf = 128;

% other bits
matlabbatch{1}.spm.stats.fmri_spec.fact = struct([]);
matlabbatch{1}.spm.stats.fmri_spec.bases(1).hrf.derivs = [1,0]; % model HRF and temproal derivative
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';


% Estimation 
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = ...
    cfg_dep('fMRI model specification: SPM.mat File', ... 
    substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), ... 
    substruct('.','spmmat')); 
matlabbatch{2}.spm.stats.fmri_est.spmmat.tname = 'Select SPM.mat'; 
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0; 
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;


% save batch
save(output_batch_fname, 'matlabbatch');

% run
if runjob
    spm('Defaults','fMRI');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
end





