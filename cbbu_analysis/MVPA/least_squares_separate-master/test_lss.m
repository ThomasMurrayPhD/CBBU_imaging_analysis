function test_lss
% function is_functional = test_lss
%
% This function tests all possible combinations to make sure no bugs made its way into the
% code when we change stuff. Obviously with new functionality and options, the tests need
% to be adapted as well.
%
% We'll use a limited dataset for this, 2 runs with 50 volumes each. These tests don't
% check for reasonable results, just whether the code runs through

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collect data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cwd = fileparts(which('test_lss'));
datadir = fullfile(cwd, 'testdata');
outdir = fullfile(cwd, 'tmp');
mkdir(outdir);

onset_files = spm_select('FPList', datadir, '.*events.*');
nuisance_files = spm_select('FPList', datadir, '.*nuisance.*');
n_runs = size(onset_files, 1);
VY = cell(1, n_runs);
onsets = cell(1, n_runs);
durations = cell(1, n_runs);
cov_onsets = cell(1, n_runs);
cov_onsets = cell(1, n_runs);
nuisance = cell(1, n_runs);
onsets_full = cell(1, n_runs);
cov_onsets_full = cell(1, n_runs);

for run = 1:n_runs
    VY{run} = spm_vol(spm_select('FPList', datadir, sprintf('.*run-%d.*nii$', run)));
    dummy = dlmread(onset_files(run, :), '\t', 1, 0);
    onsets{run} = dummy(dummy(:, 3) == 1, 1);
    durations{run} = dummy(dummy(:, 3) == 1, 2);
    cov_onsets{run} = dummy(dummy(:, 3) == 2, 1);
    cov_durations{run} = dummy(dummy(:, 3) == 2, 2);
    onsets_full{run} = struct('onset', onsets{run}, 'duration', durations{run});
    cov_onsets_full{run} = struct('onset', cov_onsets{run}, 'duration', cov_durations{run});
    nuisance{run} = load(nuisance_files(run, :));
end
hparam = 128;
TR = 1.526;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Single run checks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

n_checks = 12;
check = 1;
valid = 0;

% first, one run, only onsets, no duration, no nuisance
fprintf('Checking single run combinations\n');

% One run, only onsets no covariates, no durations, no nuisance
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY{1}, onsets{1}, outdir, TR);');
    fprintf('Passed!\n')
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, give nuisance parameter
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY{1}, onsets{1}, outdir, TR, nuisance{1});');
    fprintf('Passed!\n')
    valid = valid + 1;

catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, give cov_onsets, but no nuisance
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY{1}, onsets{1}, outdir, TR, [], cov_onsets{1});');        
    fprintf('Passed!\n')
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, hparam, but no cov_onsets or nuisance
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY{1}, onsets{1}, outdir, TR, [], [], hparam);');
    fprintf('Passed!\n')
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;

delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, all arguments
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY{1}, onsets{1}, outdir, TR, nuisance{1}, cov_onsets{1}, hparam);');
    fprintf('Passed!\n')
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, all arguments, onsets and cov_onsets as structure including durations
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY{1}, onsets_full{1}, outdir, TR, nuisance{1}, cov_onsets_full{1}, hparam);');
    fprintf('Passed!\n')
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
delete(fullfile(outdir, 'lss_beta*.nii'));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multi-run checks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% then multiple runs
fprintf('\nChecking multi run combinations:\n');

% One run, only onsets no covariates, no durations, no nuisance
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY, onsets, outdir, TR);');
    fprintf('Passed!\n');
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, give nuisance parameter
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY, onsets, outdir, TR, nuisance);');
    fprintf('Passed!\n');
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, give cov_onsets, but no nuisance
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY, onsets, outdir, TR, [], cov_onsets);');
    fprintf('Passed!\n');
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, hparam, but no cov_onsets or nuisance
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY, onsets, outdir, TR, [], [], hparam);');
    fprintf('Passed!\n');
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, all arguments
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY, onsets, outdir, TR, nuisance, cov_onsets, hparam);');
    fprintf('Passed!\n');
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
check = check + 1;
delete(fullfile(outdir, 'lss_beta*.nii'));

% One run, all arguments, onsets and cov_onsets as structure including durations
fprintf('Check %d/%d... ', check, n_checks);
try
    evalc('least_squares_separate(VY, onsets_full, outdir, TR, nuisance, cov_onsets_full, hparam);');
    fprintf('Passed!\n');
    valid = valid + 1;
catch
    fprintf('Failed!\n');
end
delete(fullfile(outdir, 'lss_beta*.nii'));

fprintf('%d/%d checks ran successfully...\n', valid, n_checks);

rmdir(outdir);

end