function recov = parameter_recovery_master_parallel(u,...
    prc_config,...
    obs_config,...
    optim_config,...
    N,...
    n_workers,...
    prc_param_names,...
    prc_param_idx,...
    prc_param_space,...
    obs_param_names,...
    obs_param_idx,...
    obs_param_space)
% master function to perform parameter recovery
%
% input:
%   u                   - model input
%   prc_model_config
%   obs_model_config
%   optim_config
%   N                   - N simulations
%   n_workers           - number of parallel workers
%   prc_params          - cell with names of perceptual model params
%   prc_param_space     - cell with names of space (e.g {'log', 'native',}
%   prc_param_idx       - array with idxs of params in prc_params
%   obs_params          - cell with names of observation model params
%   obs_param_idx       - array with idxs of params in obs_params
%   obs_param_space     - cell with names of space (e.g {'log', 'native',}

% --- Start parallel pool ---
pool = gcp('nocreate');
if isempty(pool)
    parpool('local', n_workers);
elseif pool.NumWorkers ~= n_workers
    delete(pool);
    parpool('local', n_workers);
end

all_params = [prc_param_names, obs_param_names];
n_prc      = numel(prc_param_names);
n_obs      = numel(obs_param_names);
n_all      = numel(all_params);

% --- Pre-allocate a results struct array (one entry per iteration) ---
% Each element holds sim/est param vectors, fit metrics, and full structs.
% Using a struct array (rather than a nested struct with dynamic fields)
% is required for parfor compatibility.
empty_result = struct(...
    'sim_prc',  nan(1, n_prc), ...   % simulated prc params
    'sim_obs',  nan(1, n_obs), ...   % simulated obs params
    'est_prc',  nan(1, n_prc), ...   % estimated prc params
    'est_obs',  nan(1, n_obs), ...   % estimated obs params
    'LME',      nan, ...
    'AIC',      nan, ...
    'BIC',      nan, ...
    'sim',      [], ...              % full sim struct
    'est',      []);                 % full est struct

results(N) = empty_result;  % pre-allocate array

completion_times = zeros(N, 1);
start_time       = tic;

parfor i = 1:N
    iter_start = tic;
    result     = empty_result;  % local copy; avoids parfor broadcast issues

    sim        = sampleModel(u, prc_config, obs_config);
    result.sim = sim;

    % Store simulated prc params
    for iP = 1:n_prc
        result.sim_prc(iP) = sim.p_prc.p(prc_param_idx(iP));
    end

    % Store simulated obs params
    for iP = 1:n_obs
        result.sim_obs(iP) = sim.p_obs.p(obs_param_idx(iP));
    end

    % Fit model (only if no missing trials)
    if ~any(isnan(sim.y))
        success = false;
        attempt = 1;
        max_attempts = 5;
        while ~success && attempt < max_attempts
            try
                est = fitModel(...
                    sim.y,...
                    sim.u,...
                    prc_config,...
                    obs_config,...
                    optim_config);
                if isequaln(est.p_prc.ptrans, est.c_prc.priormus) && isequaln(est.p_obs.ptrans, est.c_obs.priormus)
                    % unsuccessul fit
                    success = false;
                    attempt = attempt + 1;
                else
                    % successful fit
                    success = true;
                    result.est = est;
                    if ~isinf(est.optim.LME)
                        result.LME = est.optim.LME;
                        result.AIC = est.optim.AIC;
                        result.BIC = est.optim.BIC;
        
                        for iP = 1:n_prc
                            result.est_prc(iP) = est.p_prc.p(prc_param_idx(iP));
                        end
                        for iP = 1:n_obs
                            result.est_obs(iP) = est.p_obs.p(obs_param_idx(iP));
                        end
                    end
                end
                
            catch err
                warning('parameter_recovery:fitFailed', ...
                    'Iteration %i failed: %s', i, err.message);
                attempt = attempt + 1;
            end
        end%while

    end

    completion_times(i) = toc(iter_start);
    results(i)          = result;
end

% --- Unpack results into the recov struct ---
% This runs on the main thread after parfor, so dynamic field names are fine.
for iP = 1:n_all
    recov.(all_params{iP}).sim   = nan(N, 1);
    recov.(all_params{iP}).est   = nan(N, 1);
end
recov.LME = nan(N, 1);
recov.AIC = nan(N, 1);
recov.BIC = nan(N, 1);
recov.sim = cell(N, 1);
recov.est = cell(N, 1);

for i = 1:N
    recov.sim{i} = results(i).sim;
    recov.est{i} = results(i).est;
    recov.LME(i) = results(i).LME;
    recov.AIC(i) = results(i).AIC;
    recov.BIC(i) = results(i).BIC;

    for iP = 1:n_prc
        recov.(prc_param_names{iP}).sim(i)   = results(i).sim_prc(iP);
        recov.(prc_param_names{iP}).est(i)   = results(i).est_prc(iP);
        recov.(prc_param_names{iP}).space    = prc_param_space{iP};
    end
    for iP = 1:n_obs
        recov.(obs_param_names{iP}).sim(i)   = results(i).sim_obs(iP);
        recov.(obs_param_names{iP}).est(i)   = results(i).est_obs(iP);
        recov.(obs_param_names{iP}).space    = obs_param_space{iP};
    end
end

% --- Summary ---
total_time = toc(start_time);
fprintf('\nParameter recovery complete (%i iterations).\n', N);
fprintf('Total wall time : %im %1.2fs\n', floor(total_time/60), rem(total_time,60));
fprintf('Mean per-iteration: %1.2fs\n',   mean(completion_times));
fprintf('Slowest iteration : %1.2fs\n',   max(completion_times));

end