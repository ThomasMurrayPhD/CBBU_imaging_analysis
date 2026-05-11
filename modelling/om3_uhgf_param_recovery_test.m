% script to test out parameter recovery with uHGF in new toolbox


toolboxroot = 'C:\Users\Tom\Documents\MATLAB\Toolboxes\hgf-toolbox-main\hgf-toolbox-main';
run(fullfile(toolboxroot, 'setup.m'));

% get input
run1 = importdata('sub-01_facehouse-MRI_run1_15-01-24_11-23-08.mat');
run2 = importdata('sub-01_facehouse-MRI_run2_15-01-24_11-35-43.mat');
u = [run1.cue == run1.outcome; run2.cue == run2.outcome];

% load configs
prc_config = uhgf_binary_config();
obs_config = unitsq_sgm_config();
optim_config = tapas_quasinewton_optim_config;
% optim_config.nRandInit = 4;

% set priors
prc_config.ommu(2) = -3;
prc_config.omsa(2) = 4;
prc_config.ommu(3) = -3;
prc_config.omsa(3) = 4;
prc_config.logkasa(2) = 0; % free kappa2, fix om2 (a la Iglesias)
prc_config.update_type = 'uhgf';
prc_config = align_priors(prc_config);



% run recovery
N=200;

% preallocate space
recov.om2.sim = nan(N, 1);
recov.om2.est = nan(N, 1);
recov.om2.space = 'native';
recov.om3.sim = nan(N, 1);
recov.om3.est = nan(N, 1);
recov.om3.space = 'native';
% recov.ka.sim = nan(N, 1);
% recov.ka.est = nan(N, 1);
% recov.ka.space = 'log';
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
        sim = sampleModel(u, prc_config, obs_config);

        % store simulated params
        recov.om2.sim(i) = sim.p_prc.om(2);
        recov.om3.sim(i) = sim.p_prc.om(3);
        % recov.ka.sim(i) = sim.p_prc.ka(2);
        recov.ze.sim(i) = sim.p_obs.ze;

        % recover
        est = fitModel(...
                    sim.y,...
                    sim.u,...
                    prc_config,...
                    obs_config,...
                    optim_config);
    
        % store recovered params
        recov.om2.est(i) = est.p_prc.om(2);
        recov.om3.est(i) = est.p_prc.om(3);
        % recov.ka.est(i) = est.p_prc.ka(2);
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


save('uHGF_3level_test_recov2.mat', 'recov');
recovery_figures(recov);
