% script to check real vs imaginary LME for pearce hall


recov = importdata('cbbu_PH_recov.mat');

real_idx = nan(size(recov.LME));
for i = 1:numel(recov.LME)
    if isreal(recov.LME(i))
        real_idx(i) = 1;
    else
        real_idx(i) = 0;
    end
end

real_idx = logical(real_idx);

figure; hold on;
scatter(tapas_logit(recov.al_0.sim(real_idx), 1), log(recov.S.sim(real_idx)));
scatter(tapas_logit(recov.al_0.sim(~real_idx), 1), log(recov.S.sim(~real_idx)));



