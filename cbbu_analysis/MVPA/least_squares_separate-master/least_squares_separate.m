function least_squares_separate(VY, onsets, outdir, TR, nuisance, cov_onsets, hparam)
% function least_squares_separate(VY, onsets, outdir, TR, [nuisance], [cov_onsets], ...
%                                   [hparam])
%
% Computes a Mumford style Least Squares Separate (LSS) model. That means it computes one
% GLM per trial. In each GLM we have one regressor for the trial in question and one
% regressor for all other trials combined. Because this means a lot of GLMs, we'll hijack
% the SPM internals. The relevant part of the function is shamelessly stolen from Selim
% Onat: https://github.com/selimonat/fancycarp/blob/mrt/fearamy/Subject.m, but brought
% into a more generally usuable form.
%
% least_squares_separate features support for multiple runs. In this case you have to pass
% VY, onsets (and nuisance and cov_onsets, if these are provided) as cell arrays with the
% same number of entries. The runs are fitted separately. Since the regressors between
% runs are orthogonal anyway, this shouldn't change the results but dramatically reduces
% the computation time.
%
% This function computes one beta image per trial, independently of whether there are
% repeated stimulus presentations. If you want one beta per stimulus over multiple
% presentations, you will have to write a new function.
%
% Input:
%
%   VY:
%       accepted type(s):
%           struct with one entry per volume and the following fieldnames:
%               fname, dim, dt, pinfo, mat, n, descrip, private
%           OR
%           cell array of such structures
%       description:
%           The requested VY format is the output of spm_vol or the SPM.xY.VY field in a
%           SPM.mat. These are the timecourses that you want to fit as single volumes. To
%           create the necessary structure format, you could do something like this:
%               VY = spm_vol(spm_select('ExtFPList', directory, regex))
%           or just get the VY of a firstlevel model that you already ran. If you want to
%           fit multiple runs at once, you can provide a cell array, where every cell
%           contains the VY structure for one run. In this case onsets (and nuisance and
%           cov_onsets, if these are provided) needs to be a cell array as well. The
%           onsets in the cells need to be relative to the first volume of the respective
%           run.
%
%   onsets:
%       accepted type(s):
%           numeric column vector
%           OR
%           structure with fields {'onset', 'duration'}
%           OR
%           cell array of the aforementioned types
%       description:
%           Onsets of the single trials in SECONDS. If you provide a (cell array of)
%           vector(s), the duration defaults to 0. To define duration for the onsets, you
%           need to provide a structure instead, where every element defines the onset and
%           duration of one event.
%           If you combine multiple runs make sure that onsets are relative to the first
%           volume of the respective run. The beta images will be named consistently over
%           runs with increasing integers. Within run the naming follows the order of
%           onsets, so if you want some structure in there, bring it into the vector(s)
%           BEFORE.
%
%   outdir:
%       accepted type(s):
%           string
%           OR
%           char
%       description:
%           defines the output directory, i.e. the folder in which the beta images will be
%           written. If the path doesn't exist, it will be created. There are no checks,
%           so there's a possibility of overwriting files if you're not careful.
%
%   TR:
%       accepted type(s):
%           numeric scalar
%       description:
%           repetition time of the fMRI acquisition, i.e. the time it takes to collect one
%           volume. Is assumed to be the same for all runs (if you provide multiple).
%
%   nuisance (optional):
%       accepted type(s):
%           matrix of dimensions (n_volumes x n_nuisance)
%           OR
%           cell array of such matrices
%           OR
%           nothing
%       description:
%           optional e.g. movement regressors. These are treated as covariates and won't
%           be convolved with an HRF. If you provide multiple runs, this needs to be cell
%           array with one entry per run.
%       default:
%           [] for single runs
%           cell(1, n_runs) for multiple runs
%
%   cov_onsets (optional):
%       accepted type(s):
%           numeric column vector
%           OR
%           structure with fieldnames {'onset', 'duration'}
%           OR
%           cell array of one the aforementioned types
%           OR
%           nothing
%       description:
%           onsets of covariate events, i.e. stuff that you want to control for but where
%           you're not intersted in single-trial beta images. This could e.g. be the UCS
%           in a condititioning paradigm. You get the idea by now - multiple runs means a
%           cell array with one entry per run.
%           The accepted inputs are equivalent to 'onsets' - if you provide a vector, the
%           duration is considered to be 0, if you want to define duration, provide a
%           structure.
%       default:
%           [] for single runs
%           cell(1, n_runs) for multiple runs
%
%   hparam (optional):
%       accepted type(s):
%           int
%       description:
%           This is the cutoff for the highpass filter in seconds (i.e. 1/hertz) which
%           means any signal component that is slower than 1/hparam will be removed from
%           the data and the design matrix.
%       default:
%           128
%
%
% Written files:
%
%   lss_beta_%04d.nii
%       description:
%           One beta image per trial in onsets. The run won't be in the name, all images
%           follow the same naming pattern.
%
% Output:
%
%   No output, this function only has side effects, namely it writes files. See above.
%
% Lukas Neugebauer (l.neugebauer@uke.de) 06/08/2022

%=========================================================================================
%% Check inputs
%=========================================================================================

if iscell(VY)
    n_runs = length(VY);
    n_vols = nan(1, n_runs);
    for i = 1:n_runs
        if ~check_valid_VY(VY{i})
            error('Invalid input for VY. Please check the help text.');
        end
        n_vols(i) = length(VY{i});
    end
elseif isstruct(VY)
    if ~check_valid_VY(VY)
        error('Invalid input for VY. Please check the help text.');
    end
    n_runs = 1;
    n_vols = length(VY);
else
    error('Invalid input for VY. Must be structure or cell. Read the help text.');
end

% checking for input is done within the function
[onsets, duration, n_trials] = parse_onsets(onsets, n_runs);
if ~exist('cov_onsets', 'var')
    if n_runs == 1
        cov_onsets = [];
    else
        cov_onsets = cell(1, n_runs);
    end
elseif n_runs > 1 && isempty(cov_onsets) && ~iscell(cov_onsets)
    cov_onsets = cell(1, n_runs);
end
[cov_onsets, cov_duration] = parse_onsets(cov_onsets, n_runs);

if ~ischar(outdir) && ~isstring(outdir)
    error('outdir must be string or character array.');
end
if ~exist(outdir, 'dir')
    mkdir(outdir);
    fprintf('Created the output directory: %s\n', outdir);
end

if ~isscalar(TR) || ~isnumeric(TR)
    error('TR must be a numeric scalar.');
end

if ~exist('nuisance', 'var')
    if n_runs == 1
        nuisance = [];
    else
        nuisance = cell(1, n_runs);
    end
elseif iscell(nuisance)
    if length(nuisance) ~= n_runs
        error('Invalid input. There are %d runs in VY, but %d runs in nuisance.', ...
                length(nuisance), n_runs);
    end
    for i = 1:n_runs
        if isempty(nuisance{i})
            continue
        elseif ~ismatrix(nuisance{i}) || size(nuisance{i}, 1) ~= n_vols(i)
            error('Number of rows in nuisance for run %d must be %d.', i, n_vols(i));
        end
    end
elseif ismatrix(nuisance) && ~isempty(nuisance)
    if n_runs > 1
        error('If VY is a cell array, nuisance needs to be one too.');
    elseif size(nuisance, 1) ~= n_vols
        error('Wrong number of rows in nuisance. Must be %d.', n_vols);
    end
elseif isempty(nuisance)
    if n_runs > 1 && ismatrix(nuisance)
        nuisance = cell(1, n_runs);
    end
else
    error('Invalid input for nuisance.');
end

if ~exist('hparam', 'var')
    hparam = 128;
elseif ~isscalar(hparam) || ~isnumeric(hparam)
    error('hparam must be of type int.');
end

%=========================================================================================
% The actual beta fitting, relies heavily on secondary functions
%=========================================================================================

fprintf('Computing betas:\n');
if n_runs == 1
    betas = compute_betas(VY, onsets, duration, TR, nuisance, cov_onsets, ...
                            cov_duration, hparam);
else
    betas = cell(1, n_runs);
    for i = 1:n_runs
        fprintf('\tRun %d/%d:', i, n_runs);
        betas{i} = compute_betas(VY{i}, onsets{i}, duration{i}, TR, nuisance{i}, ...
                                    cov_onsets{i}, cov_duration{i}, hparam);
    end
    betas = cat(4, betas{:});
    n_trials = sum(n_trials);
end


%=========================================================================================
% Write beta images
%=========================================================================================

% inherit header information from existing epi image
if iscell(VY)
    V0 = VY{1}(1);
else
    V0 = VY(1);
end
V0.dt       = [16 0];
V0.pinfo    = [1 0 0]';

% loop over trials, write one beta-image per trial
fprintf('\nWriting %d beta images:\n\tImage ', n_trials);
for trial = 1:n_trials
    n_char = fprintf('%4d/%4d', trial, n_trials);
    V0.fname = fullfile(outdir, sprintf('lss_beta_%04d.nii', trial));
    spm_write_vol(V0, betas(:, :, :, trial));
    fprintf(repmat('\b', 1, n_char));
end
fprintf('\nDone!\n');


%=========================================================================================
% End of main function
%=========================================================================================

end


%=========================================================================================
% Secondary functions
%=========================================================================================

function isvalid = check_valid_VY(VY)
% make sure the input VY has the correct format and can be used
    canonical_fieldnames = {'fname', 'dim', 'dt', 'pinfo', 'mat', 'n', 'descrip', ...
                                'private'};
    isvalid = true;
    for f = fieldnames(VY)'
        if ~ismember(f{1}, canonical_fieldnames)
            isvalid = false;
            break
        end
    end
end

function [onsets, duration, n_trials] = parse_onsets(onsets, n_runs)
% check if input for onsets and cov_onsets is valid, parse into onsets and duration and
% apply reasonable defaults

    if iscell(onsets)
        if length(onsets) ~= n_runs
            error('Invalid input. There are %d runs in VY, but %d runs in onsets.', ...
                    n_runs, length(onsets));
        end
        dummy = onsets;
        [onsets, duration] = deal(cell(1, n_runs));
        n_trials = nan(1, n_runs);
        for i = 1:n_runs
            % use recursion to parse single run onsets. needs to set n_runs to 1 to avoid
            % throwing unwanted errors
            [onsets{i}, duration{i}, n_trials(i)] = parse_onsets(dummy{i}, 1);
        end
    elseif isstruct(onsets)
        if n_runs > 1
            error('If VY is a cell, you need to provide onsets as cell array as well.');
        end
        dummy = onsets;
        try
            onsets = [dummy(:).onset];
            duration = [dummy(:).duration];
        catch
            error('onset structure must contain the fields "onset" and "duration".');
        end
        n_trials = length(onsets);
    elseif iscolumn(onsets) || isempty(onsets)
        if n_runs > 1
            error('If VY is a cell, you need to provide onsets as cell array as well.');
        end
        n_trials = length(onsets);
        duration = zeros(size(onsets));
    else
        error('Invalid input for onsets. Read the help text.');
    end
end

function [K] = define_highpass_filter(n_vols, TR, hparam)
% prepare the highpass filter object to be used for data and design matrices
    K = struct('HParam', hparam, 'row', [], 'RT', TR, 'X0', []);
    K.row = 1:n_vols;
    K = spm_filter(K);
    % I assume that means also mean correcting? Since we have different intercepts
    % for the different runs, that seems unnecessary
    % K.X0 = [ones(length(K.row), 1) * std(K.X0(:)), K.X0];
end

function condit = define_generic_condit(onsets, duration, name)
% outsource repetitive stuff to keep the script somewhat short and readable
    condit = [];
    condit.name = name;
    condit.onset = onsets;
    condit.duration = duration;
    condit.tmod = [];
    condit.pmod = struct('name', {}, 'param', {}, 'poly', {});
end

function conditions = define_conditions(onsets, duration, cov_onsets, cov_duration)
% bring conditions into a format that SPM understands
    % prepare covariate onsets, they're always the same
    if ~isempty(cov_onsets)
        cov_condit = define_generic_condit(cov_onsets, cov_duration, 'covariates');
    end
    n_trials = length(onsets);
    conditions = cell(1, n_trials);
    for c = 1:n_trials
        dummy_condit(1) = define_generic_condit(onsets(c), duration(c), ...
                                sprintf('trial_%d', c));
        dummy_condit(2) = define_generic_condit(setdiff(onsets, onsets(c)), ...
                            duration(setdiff(1:n_trials, c)), 'all_other_trials');
        if ~isempty(cov_onsets)
            dummy_condit(3) = cov_condit;
        end
        conditions{c} = dummy_condit;
    end
end

function X = cond2designmatrix(condit, TR, n_vols)
% turn conditions structure into a design matrix for OLS regression. this includes
% convolution with the HRF
    % define the timing
    xBF             = [];
    fMRI_T          = 16;
    fMRI_T0         = 1;
    xBF.T           = fMRI_T;
    xBF.T0          = fMRI_T0;
    xBF.dt          = TR/xBF.T;
    xBF.UNITS       = 'secs';
    xBF.Volterra    = 1;
    xBF.name        = 'hrf';
    xBF             = spm_get_bf(xBF);

    % bring the conditions into correct format
    Sess = [];
    for i = 1:length(condit)
        Sess.U(i).dt     = xBF.dt;
        Sess.U(i).ons    = condit(i).onset;
        Sess.U(i).name   = {sprintf('%02d', i)};
        Sess.U(i).dur    = condit(i).duration;
        Sess.U(i).P.name =  'none';
        Sess.U(i).P.P    =  'none';
        Sess.U(i).P.h    =  0;
        Sess.U(i).P.i    =  1;
    end

    % bring it all together
    SPM.xBF     = xBF;
    SPM.nscan   = n_vols;
    SPM.Sess    = Sess;
    SPM.Sess.U  = spm_get_ons(SPM, 1);

    % Convolve delta function of onsets with HRF
    X = spm_Volterra(SPM.Sess.U, SPM.xBF.bf, SPM.xBF.Volterra);

    % Resample regressors at acquisition times (32 bin offset)
    X = X((0:(n_vols - 1)) * fMRI_T + fMRI_T0 + 32, :);

end

function betas = compute_betas(VY, onsets, duration, TR, nuisance, cov_onsets, ...
                                    cov_duration, hparam)
% after checking the input, loop over slices and trials, compute beta images

    % gather necessary information
    n_vols = length(VY);
    [nx, ny, nz] = deal(VY(1).dim(1), VY(1).dim(2), VY(1).dim(3));
    n_slices = nz;
    n_trials = length(onsets);
    hpfilter = define_highpass_filter(n_vols, TR, hparam);
    constant = ones(n_vols, 1);
    conditions = define_conditions(onsets, duration, cov_onsets, cov_duration);

    % prepare design matrices in advance. this is heavier on RAM but saves time because we
    % don't need to recreate them for every slice
    % note that these are actually the pseudo-inverses of the design matrix
    inv_Xs = cell(1, n_trials);
    for trial = 1:n_trials
        X = cond2designmatrix(conditions{trial}, TR, n_vols);
        X = [X, nuisance, constant];
        X = spm_filter(hpfilter, X);
        % store pseudo-inverse
        inv_Xs{trial} = spm_sp('x-', spm_sp('Set', X));
    end

    % prepare beta array
    betas = nan(nx, ny, nz, n_trials);

    % loop over slices
    fprintf('\tSlice', n_slices);
    for slice = 1:n_slices
        n_char_slice = fprintf(' %3d/%3d', slice, n_slices);
        % collect the data from the slice, is of dimensions X x Y x volumes
        Y = squeeze(spm_data_read(VY, 'slice', slice));
        Y = reshape(Y, prod(size(Y, 1:2)), size(Y, 3))';
        % highpass filter the data
        Y = spm_filter(hpfilter, Y);
        % loop over trials
        for trial = 1:n_trials
            betas_trial = inv_Xs{trial} * Y; % OLS regression
            % we're only interested in the first one here
            betas(:, :, slice, trial) = reshape(betas_trial(1, :)', nx, ny);
        end
        fprintf(repmat('\b', 1, n_char_slice));
    end
    fprintf('\n');

end
