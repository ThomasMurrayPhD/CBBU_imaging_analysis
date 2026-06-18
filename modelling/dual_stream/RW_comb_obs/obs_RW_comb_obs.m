function [logp, yhat, res, logp_split] = obs_RW_comb_obs(r, infStates, ptrans)

%% Separate parameters
% Transform parameters to their native space

% Binary parameters
zeta = exp(ptrans(1));

% LogRT parameters
be0  = ptrans(2);
be1  = ptrans(3);
sa   = exp(ptrans(4));



%% binary part of the response model
% compute log likelihood (binary responses)


% Predictions or posteriors?
pop = 1; % Default: predictions
if r.c_obs.predorpost == 2
    pop = 3; % Alternative: posteriors
end


% Initialize returned log-probabilities as NaNs so that NaN is
% returned for all irregualar trials
n = size(infStates,1);
logp_binary = NaN(n,1);
yhat_binary = NaN(n,1);
res_binary  = NaN(n,1);

% Weed irregular trials out from inferred states and responses
x_state = infStates(:,1,pop);
x_state(r.irr) = [];
y = r.y(:,1);
y(r.irr) = [];


% Avoid any numerical problems when taking logarithms close to 1
logx = log(x_state);
log1pxm1 = log1p(x_state-1);
logx(1-x_state<1e-4) = log1pxm1(1-x_state<1e-4);
log1mx = log(1-x_state);
log1pmx = log1p(-x_state);
log1mx(x_state<1e-4) = log1pmx(x_state<1e-4); 


% Calculate log-probabilities for non-irregular trials
reg = ~ismember(1:n,r.irr);
logp_binary(reg) = y.*zeta.*(logx -log1mx) +zeta.*log1mx -log((1-x_state).^zeta +x_state.^zeta);
yhat_binary(reg) = x_state;
res_binary(reg) = (y-x_state)./sqrt(x_state.*(1-x_state));





%% continuous part of the response model
% Compute the log likelihood (logRTs)


% Initialize returned log-probabilities, predictions,
% and residuals as NaNs so that NaN is returned for all
% irregualar trials
n = size(infStates,1);
logp_reactionTime = NaN(n,1);
yhat_reactionTime = NaN(n,1);
res_reactionTime  = NaN(n,1);

% Weed irregular trials out from responses and inputs
y = r.y(:,2);
y(r.irr) = [];
y_resp = r.y(:,1);
u = r.u(:,1);


% Post error slowing
correct_resp = y_resp==u;
post_error_idx = find(correct_resp==0)+1;
post_error = zeros(size(u));
post_error(post_error_idx(post_error_idx <= size(u))) = 1;


% Calculate predicted log-reaction time
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
logrt = be0 +be1.*post_error;

% Remove missed/"irregular" trials
logrt(r.irr) = [];


% Calculate log-probabilities for non-irregular trials
% Note: 8*atan(1) == 2*pi (this is used to guard against
% errors resulting from having used pi as a variable).
reg = ~ismember(1:n,r.irr);
logp_reactionTime(reg) = -1/2.*log(8*atan(1).*sa) -(y-logrt).^2./(2.*sa);
yhat_reactionTime(reg) = logrt;
res_reactionTime(reg) = y-logrt;


%% get combined log likelihood of two response data modalities
logp = logp_binary + logp_reactionTime;
logp_split = [logp_binary logp_reactionTime];

%% return predictions and responses for each response data modality
yhat = [yhat_binary yhat_reactionTime];
res = [res_binary res_reactionTime];

end
