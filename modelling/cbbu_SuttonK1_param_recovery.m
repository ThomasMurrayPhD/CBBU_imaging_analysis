% function to run parameter recovery on Sutton K1 model


% zeta parameter recovers reasonably well (r=.591)
% h1 parameter does not recover
% vhat_1 parameter MAYBE recovers between -2 and 2,


% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = double([run1.cue == run1.outcome; run2.cue == run2.outcome]);

% load models
[prc_config, obs_config] = cbbu_SuttonK1_config;

% load optim algorithm
optim_config = tapas_quasinewton_optim_config;
optim_config.nRandInit = 4;

% run recovery
N=200;

% preallocate space
recov.mu.sim = nan(N, 1);
recov.mu.est = nan(N, 1);
recov.mu.space = 'log';
recov.vhat_1.sim = nan(N, 1);
recov.vhat_1.est = nan(N, 1);
recov.vhat_1.space = 'logit';
recov.h_1.sim = nan(N, 1);
recov.h_1.est = nan(N, 1);
recov.h_1.space = 'log';
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

        % store simulated params
        recov.mu.sim(i) = sim.p_prc.mu;
        recov.vhat_1.sim(i) = sim.p_prc.vhat_1;
        recov.h_1.sim(i) = sim.p_prc.h_1;
        recov.ze.sim(i) = sim.p_obs.ze;

        % recover
        est = tapas_fitModel(...
                    sim.y,...
                    sim.u,...
                    prc_config,...
                    obs_config,...
                    optim_config);
    
        % store recovered params
        recov.mu.est(i) = est.p_prc.mu;
        recov.vhat_1.est(i) = est.p_prc.vhat_1;
        recov.h_1.est(i) = est.p_prc.h_1;
        recov.ze.est(i) = est.p_obs.ze;

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

save('cbbu_SuttonK1_recov.mat', 'recov');
recovery_figures(recov);


