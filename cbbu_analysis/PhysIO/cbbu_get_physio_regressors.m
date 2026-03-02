function cbbu_get_physio_regressors(physio_path, physio_output, c_data, r_data, rp)
% function to get physiological noise regressors (compatible on HPC)
% 
% input
%   physio_path = path to toolbox
%   physio_output = path to output directory
%   c_data = cardiac json
%   r_data = respiratory json
%   rp = realignment_parameters
% 
% Note - this script is specific for CBBU functional data (e.g. TR, nVols,
% etc)

p = genpath(physio_path);

addpath(p);

% get run N
[~, n, ~] = fileparts(c_data);
run = extractBefore(extractAfter(n, 'acq-'), '_dir');

% Change realignment parameters from .par to .txt
if strcmp(rp(end-3:end), '.par')
    rp_data = importdata(rp);
    writematrix(rp_data, [rp(1:end-4), '.txt']);
    rp = [rp(1:end-4), '.txt'];
end


% Create default parameter structure with all fields
physio = tapas_physio_new('RETROICOR');


physio.save_dir = {physio_output}; % directory to save output to
physio.log_files.vendor = 'BIDS'; % We use bids format (.tsv.gz)
physio.log_files.cardiac = {c_data};
physio.log_files.respiration = {r_data};

% This is a mistake in the toolbox - set to [] as it gets set from json file
% in tapas_physio_read_physlogfiles_bids.m
physio.log_files.relative_start_acquisition = [];
physio.log_files.align_scan = 'last';


physio.scan_timing.sqpar.Nslices = 78; % number of slices
physio.scan_timing.sqpar.TR = 3;
physio.scan_timing.sqpar.Ndummies = 0;
physio.scan_timing.sqpar.Nscans = 210;
physio.scan_timing.sqpar.onset_slice = 1; % not sure about this one, we used multiband
physio.scan_timing.sync.method = 'scan_timing_log'; % Method to determine slice acquisition onset times

physio.preproc.cardiac.modality = 'PPU';
physio.preproc.cardiac.filter.include = false;
physio.preproc.cardiac.filter.type = 'butter';
physio.preproc.cardiac.filter.passband = [0.3 9];
physio.preproc.cardiac.initial_cpulse_select.method = 'auto_matched';
physio.preproc.cardiac.initial_cpulse_select.max_heart_rate_bpm = 100;
% physio.preproc.cardiac.initial_cpulse_select.file = 'initial_cpulse_kRpeakfile.mat';
physio.preproc.cardiac.initial_cpulse_select.min = 0.4;
physio.preproc.cardiac.posthoc_cpulse_select.method = 'off';
physio.preproc.cardiac.posthoc_cpulse_select.percentile = 80;
physio.preproc.cardiac.posthoc_cpulse_select.upper_thresh = 60;
physio.preproc.cardiac.posthoc_cpulse_select.lower_thresh = 60;

physio.preproc.respiratory.filter.passband = [0.01 2];
physio.preproc.respiratory.despike = false;

physio.model.orthogonalise = 'none';
physio.model.censor_unreliable_recording_intervals = true;
physio.model.output_multiple_regressors = ['run-', run, '_physio_regressors.txt'];
physio.model.output_physio = ['run-', run, '_physio.mat'];


physio.model.retroicor.include = true; % as in Glover et al., MRM 44, 2000
physio.model.retroicor.order.c = 3;
physio.model.retroicor.order.r = 4;
physio.model.retroicor.order.cr = 1;

physio.model.rvt.include = false; % respiratory volume time, as in Birn et al., 2006/8
physio.model.rvt.method = 'hilbert';
physio.model.rvt.delays = 0;

physio.model.hrv.include = false; % heart rate variability, as in Chang et al., 2009
physio.model.hrv.delays = 0;

physio.model.noise_rois.include = false;
physio.model.noise_rois.thresholds = 0.9;
physio.model.noise_rois.n_voxel_crop = 0;
physio.model.noise_rois.n_components = 1;
physio.model.noise_rois.force_coregister = 1;

physio.model.movement.include = true;
physio.model.movement.file_realignment_parameters = rp;
physio.model.movement.order = 6;
physio.model.movement.censoring_threshold = 5000;% set a silly threshold to keep all scans
physio.model.movement.censoring_method = 'FD';

physio.model.other.include = false;

physio.verbose.level = 0; % set to 0 on hpc
physio.verbose.process_log = cell(0, 1);
physio.verbose.fig_handles = zeros(1, 0);
physio.verbose.use_tabs = false;
physio.verbose.show_figs = false;
physio.verbose.save_figs = false;
physio.verbose.close_figs = false;

physio.ons_secs.c_scaling = 1;
physio.ons_secs.r_scaling = 1;
physio.write_bids.bids_step = 0;



[physio, R, ons_secs] = tapas_physio_main_create_regressors(physio);


end