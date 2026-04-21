function c = prc_vkf_binary_config
% config for the VKF model a la Piray & Daw (2020) for binary inputs

% Parameters:
% lambda    - volatility learning rate (0 < lambda < 1)
% v0        - initial volatility (v0 > 0)
% omega     - noise parameter (omega > 0)
% w0        - initial variance (w0 > 0)


% Config structure
c = struct;

% Model name
c.model = 'prc_vkf_binary';


% Lambda (Logit space)
c.logitlambdamu = tapas_logit(0.5, 1);
c.logitlambdasa = 2;

% v0 (Log space)
c.logv0mu = log(.2);
c.logv0sa = 2;

% omega (Log space)
c.logomegamu = log(.2);
c.logomegasa = 2;

% w0 (Log space)
c.logw0mu = log(.2);
c.logw0sa = 2;


% Gather prior settings in vectors
c.priormus = [
    c.logitlambdamu,...
    c.logv0mu,...
    c.logomegamu,...
    c.logw0mu,...
         ];

c.priorsas = [
    c.logitlambdasa,...
    c.logv0sa,...
    c.logomegasa,...
    c.logw0sa,...
         ];

% Model function handle
c.prc_fun = @prc_vkf_binary;

% Handle to function that transforms perceptual parameters to their native space
% from the space they are estimated in
c.transp_prc_fun = @prc_vkf_binary_transp;

end