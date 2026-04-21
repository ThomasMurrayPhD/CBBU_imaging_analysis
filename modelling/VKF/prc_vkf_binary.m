function [traj, infStates] = prc_vkf_binary(r, p, varargin)
% VKF model (Piray & Daw, 2020, PLOS Comp Biol) for binary inputs.



% Transform paramaters back to their native space if needed   %%% Check if needed...
if ~isempty(varargin) && strcmp(varargin{1},'trans')
    p = prc_vkf_binary_transp(r, p);
end

% unpack parameters
lambda  = p(1);
v0      = p(2);
omega   = p(3);
w0      = p(4);

% inputs
u = r.u(:,1);
n = numel(u);

% initial values
m0=0;
m = m0;
w = w0;
v = v0;

% states
predictions = nan(n,1);
learning_rate = nan(n,1);
volatility = nan(n,1);
prediction_error = nan(n,1);
volatility_error = nan(n,1);

sigmoid = @(x)1./(1+exp(-x));

for t  = 1:n      
    o = u(t);
    predictions(t) = m;    
    volatility(t) = v;    
    
    mpre        = m;
    wpre        = w;
    
    delta_m     = o - sigmoid(m);    
    k           = (w+v)./(w+v+ omega);                              % Eq 14
    alpha       = sqrt(w+v);                                        % Eq 15
    m           = m + alpha.*delta_m;                               % Eq 16
    w           = (1-k).*(w+v);                                     % Eq 17
    
    wcov        = (1-k).*wpre;                                      % Eq 18
    delta_v     = (m-mpre).^2 + w + wpre - 2*wcov - v;    
    v           = v +lambda.*delta_v;                               % Eq 19
    
    learning_rate(t) = alpha;
    prediction_error(t) = delta_m;
    volatility_error(t) = delta_v;    
end


% predictions = mu2hat
% mu1hat = sigmoid transform of predictions
mu1hat = 1./(1+exp(-predictions));

% prediction errors are 'da' in HGF
da = [mu1hat-u, prediction_error, volatility_error];

% learning rate is 'wt'
wt = learning_rate;


% get muhat equivalent
muhat = [mu1hat, predictions, volatility];

% get mu equivalent
mu = [u, [predictions(2:end); m], [volatility(2:end); v]]; % Bit of a hack


% Assumed structure of infStates:
% dim 1: time (ie, input sequence number)
% dim 2: HGF level
% dim 3: 1: muhat, 2: sahat, 3: mu, 4: sa
infStates = cat(3, muhat, nan(size(muhat)), mu, nan(size(mu)));


% create result data structure
traj = struct;
traj.mu1hat = mu1hat;
traj.predictions = predictions;
traj.volatility = volatility;
traj.wt = wt;
traj.da = da;




end