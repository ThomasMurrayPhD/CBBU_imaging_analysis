function [y, yhat] = obs_HGF_comb_obs_sim(r, infStates, p)



%% Separate parameters

% parameters for the sigmoid model
zeta = p(1);

% parameters for the RT model
be0  = p(2);
be1  = p(3);
be2  = p(4);
be3  = p(5);
be4  = p(6);
be5  = p(7);
sa   = p(8);


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
mu1hat = infStates(:,1,1);
sa1hat = infStates(:,1,2);
mu2    = infStates(:,2,3);
sa2    = infStates(:,2,4);
mu3    = infStates(:,3,3);


% Surprise
% ~~~~~~~~
poo = mu1hat.^u.*(1-mu1hat).^(1-u); % probability of observed outcome
surp = -log2(poo);
surp_shifted = [1; surp(1:(length(surp)-1))];

% Bernoulli variance (aka irreducible uncertainty, risk) 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bernv = sa1hat;

% Inferential variance (aka informational or estimation uncertainty, ambiguity)
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
inferv = tapas_sgm(mu2, 1).*(1 -tapas_sgm(mu2, 1)).*sa2; % transform down to 1st level


% Phasic volatility (aka environmental or unexpected uncertainty)
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pv = tapas_sgm(mu2, 1).*(1-tapas_sgm(mu2, 1)).*exp(mu3); % transform down to 1st level

% Post error slowing (TM)
correct_resp = y_binary==u;
post_error_idx = find(correct_resp==0)+1;
post_error = zeros(size(u));
post_error(post_error_idx(post_error_idx <= size(u))) = 1;


% Calculate predicted log-reaction time
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
logrt = be0 +be1.*surp_shifted +be2.*bernv +be3.*inferv +be4.*pv + be5.*post_error;


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

