function plot_vkf(r)
% plot vkf figure using output structure from sim/fitModel

u = r.u(:,1);
y = r.y;
mu1hat = r.traj.mu1hat;
learning_rate = r.traj.wt;
volatility = r.traj.volatility;
posterior_variance = r.traj.posterior_variance;

figure;

% plot volatility
subplot(3,1,1); 
hold on; 
plot(1:numel(u), volatility, 'linewidth', 2);
set(gca, 'XLim', [0, numel(u)]);
ylabel('Volatility');

% plot learning rate
subplot(3,1,2); 
hold on; 
plot(1:numel(u), learning_rate, 'linewidth', 2);
set(gca, 'XLim', [0, numel(u)]);
ylabel('Learning rate')

% plot mu1hat
subplot(3,1,3); 
hold on; 


x_w = [1:numel(u), numel(u):-1:1]';
y_w = [mu1hat + (posterior_variance/2); flipud(mu1hat - (posterior_variance/2))];
patch(x_w, y_w, [.8, .8, .8], 'edgecolor', 'none');

plot(1:numel(u), mu1hat, 'linewidth', 2);
scatter(1:numel(u), u, 8, 'k', 'filled');
scatter(1:numel(u), r.y*1.1 -.05, 8, 'r', 'filled');
set(gca, 'XLim', [0, numel(u)]);
title(gca, 'model input (black); response (red)')

if isfield(r.traj, 'contingency')
    plot(1:numel(u), r.traj.contingency)
end

set(gca, 'ylim', [-.1, 1.1]);
ylabel('Predictions')


end