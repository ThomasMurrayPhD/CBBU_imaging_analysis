% script to visualise mu3/om3

close all

fits = importdata('dual_stream\cbbu_uHGF_3level_comb_obs2_model_fits.mat');

om3s = arrayfun(@(x) fits.model_fits{x}.p_prc.om(3), 1:numel(fits.model_fits));

cmap = parula(256);
cnorm = (om3s - min(om3s)) / (max(om3s) - min(om3s));
idx = max(1, round(cnorm * 255) + 1);

figure; hold on;
for i = 1:numel(fits.model_fits)
    plot(1:320, fits.model_fits{i}.traj.mu(:, 3), 'Color', cmap(idx(i),:));
end

colormap(cmap)
cb = colorbar;
cb.Label.String = 'Continuous variable';
clim([min(om3s) max(om3s)]);

xlabel('trial');
ylabel('mu3');
