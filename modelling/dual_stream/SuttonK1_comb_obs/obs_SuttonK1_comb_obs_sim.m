function [y, yhat] = obs_SuttonK1_comb_obs_sim(r, infStates, p)



%% Separate parameters

% parameters for the sigmoid model
zeta = p(1);

% parameters for the RT model
be0  = p(2);
be1  = p(3);
be2  = p(4);
sa   = p(5);


%% Run sim for binary predictions

% Predictions or posteriors?
pop = 1; % Default: predictions
if r.c_obs.predorpost == 2
    pop = 3; % Alternative: posteriors
end

x_state = infStates(:,1,pop);


% Assumed structure of infStates:
% dim 1: time (ie, input sequence number)
% dim 2: HGF level
% dim 3: 1: muhat, 2: sahat, 3: mu, 4: sa


% Apply the unit-square sigmoid to the inferred states
prob = x_state.^zeta./(x_state.^zeta+(1-x_state).^zeta);

% Initialize random number generator
if isnan(r.c_sim.seed)
    rng('shuffle');
else
    rng(r.c_sim.seed);
end

% Simulate responses
y_binary = binornd(1, prob);
yhat_binary = prob;


%% Run sim for continuous data modality (logRTs)

% Number of trials
n = size(infStates,1);

% Inputs
u = r.u(:,1);


% Extract trajectories of interest from infStates
da = r.traj.da; % prediction error
be = r.traj.be; % beta - unconstrained learning rate (log gain)
al = r.traj.al; % alpha
h = r.traj.h; % h (not sure)
v = r.traj.v; % posterior
vhat = r.traj.vhat; % prediction


% Post error slowing (TM)
correct_resp = y_binary==u;
post_error_idx = find(correct_resp==0)+1;
post_error = zeros(size(u));
post_error(post_error_idx(post_error_idx <= size(u))) = 1;


% Calculate predicted log-reaction time
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
logrt = be0 +be1.*al +be2.*post_error;


% Initialize random number generator
if isnan(r.c_sim.seed)
    rng('shuffle');
else
    rng(r.c_sim.seed);
end

% Simulate
y_reactionTime = logrt+sqrt(sa)*randn(n, 1);
yhat_reactionTime = logrt;



%% save values for both response data modalities
y = [y_binary y_reactionTime];
yhat = [yhat_binary yhat_reactionTime];

end

