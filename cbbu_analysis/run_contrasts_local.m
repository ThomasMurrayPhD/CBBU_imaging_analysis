% script to run contrasts on lab desktop

BIDS_root = 'F:\cbbu_BIDS\';
subs = [1:18, 20:44];
for iSub = subs
    glm_root = [BIDS_root, 'sub-' num2str(iSub, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators'];
    output_batch_fname = [BIDS_root, 'sub-' num2str(iSub, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\first_level_contrasts_batch.mat'];
    specify_first_level_contrasts(glm_root, output_batch_fname)
end