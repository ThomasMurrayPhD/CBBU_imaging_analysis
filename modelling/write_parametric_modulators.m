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
% Actually - need to double check why I need separate pms for faces and
% houses... I think I just need the one?
% 
% Might need to email someone about this, it's not so clear

fits = importdata('cbbu_uHGF_2level_model_fits.mat');