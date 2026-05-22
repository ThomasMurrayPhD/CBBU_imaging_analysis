% function to run parameter recovery on Pearce Hall model

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = double([run1.cue == run1.outcome; run2.cue == run2.outcome]);

% load models
[prc_config, obs_config] = cbbu_PH_config;

% load optim algorithm
optim_config = tapas_quasinewton_optim_config;
optim_config.nRandInit = 4;

% run recovery
N=200;

% preallocate space
recov.al_0.sim = nan(N, 1);
recov.al_0.est = nan(N, 1);
recov.al_0.space = 'logit';
recov.S.sim = nan(N, 1);
recov.S.est = nan(N, 1);
recov.S.space = 'log';
recov.ze.sim = nan(N, 1);
recov.ze.est = nan(N, 1);
recov.ze.space = 'log';
recov.LME = nan(N, 1); % store LME
recov.AIC = nan(N, 1); % store AIC
recov.BIC = nan(N, 1); % store BIC

recov.sim = cell(N, 1);
recov.est = cell(N, 1);

% Loop
for i = 1:N
    
    try
        % simulate data with sampleModel
        sim = tapas_sampleModel(u, prc_config, obs_config);

        if any(isnan(sim.y))
            x=1;
        end
        
        % store simulated params
        recov.al_0.sim(i) = sim.p_prc.al_0;
        recov.S.sim(i) = sim.p_prc.S;
        recov.ze.sim(i) = sim.p_obs.ze;

        % recover
        est = tapas_fitModel(...
                    sim.y,...
                    sim.u,...
                    prc_config,...
                    obs_config,...
                    optim_config);
    
        % store recovered params
        recov.al_0.est(i) = est.p_prc.al_0;
        recov.S.est(i) = est.p_prc.S;
        recov.ze.est(i) = est.p_obs.ze;

        if ~isreal(est.optim.LME)
            x=1;
        end

        % store fit metrics
        if ~isinf(est.optim.LME)
            recov.LME(i) = est.optim.LME;
            recov.AIC(i) = est.optim.AIC;
            recov.BIC(i) = est.optim.BIC;
        end

        % store sim and est
        recov.sim{i} = sim;
        recov.est{i} = est;
    catch  
    end
    
end

save('cbbu_PH_recov.mat', 'recov');
recovery_figures(recov);


