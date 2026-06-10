% script to write pm.mat for use in SPM
% 
%   structure:
%       pm(1).name = 'variable 1'
%       pm(1).faces_data = [ ... ]
%       pm(1).houses_data = [ ... ]
%       pm(2).name = 'variable 2'
%       pm(2).faces_data = [ ... ]
%       pm(2).houses_data = [ ... ] etc.
% 
% Original Iglesias paper uses: 
% e2 - the precision-weighted PE about visual stimulus outcome (that serves
%       to update the estimate of visual stimulus probabilities in logit
%       space);
% e3 - the precision-weighted PE about cue-outcome contingency (that serves
%       to update the estimate of log-volatility); 
% psi2 - precision weight at the second level; this corresponds to the
%       learning rate by which estimates of cue-outcome contingency are updated;
% psi3 - precision weight at the third level; this is proportional to the
%       learning rate by which log-volatility estimates are updated; 
% mu3 - the predicted log-volatility 
% e_ch - the choice prediction error



fits = importdata('cbbu_uHGF_2level_model_fits.mat');

