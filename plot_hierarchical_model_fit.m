function plot_hierarchical_model_fit(fit)

figure;
subplot(1,3,1:2); ylim([0 2000])
noimc2n = squeeze(fit.mcmc.samples.groupMu_c2n(:,:,1)); % no imagery
h = histogram(noimc2n(:)+mean(fit.c1(:,1))); hold on; h.FaceAlpha = 0.2; h.EdgeAlpha = 0.2;
h.FaceColor = 'k'; h.EdgeColor = 'k';
noimc2p = squeeze(fit.mcmc.samples.groupMu_c2p(:,:,1)); 
h = histogram(noimc2p(:)+mean(fit.c1(:,1))); hold on; h.FaceAlpha = 0.2; h.EdgeAlpha = 0.2;
h.FaceColor = 'k'; h.EdgeColor = 'k';

coimc2n = squeeze(fit.mcmc.samples.groupMu_c2n(:,:,2)); % imagery
h = histogram(coimc2n(:)+mean(fit.c1(:,2))); hold on; h.FaceAlpha = 0.2; h.EdgeAlpha = 0.2;
h.FaceColor = 'b'; h.EdgeColor = 'b';

coimc2p = squeeze(fit.mcmc.samples.groupMu_c2p(:,:,2)); 
h = histogram(coimc2p(:)+mean(fit.c1(:,2))); hold on; h.FaceAlpha = 0.2; h.EdgeAlpha = 0.2;
h.FaceColor = 'b'; h.EdgeColor = 'b';

% plot the c1's
hold on; plot([mean(fit.c1(:,1)) mean(fit.c1(:,1))],ylim,'k','LineWidth',2)
hold on; plot([mean(fit.c1(:,2)) mean(fit.c1(:,2))],ylim,'b','LineWidth',2)

% plot the mean C2's
hold on; plot([mean(noimc2n(:))+mean(fit.c1(:,1)) mean(noimc2n(:))+mean(fit.c1(:,1))],...
    ylim,'k--','LineWidth',2)
hold on; plot([mean(noimc2p(:))+mean(fit.c1(:,1)) mean(noimc2p(:))+mean(fit.c1(:,1))],...
    ylim,'k--','LineWidth',2)
hold on; plot([mean(coimc2n(:))+mean(fit.c1(:,2)) mean(coimc2n(:))+mean(fit.c1(:,2))],...
    ylim,'b--','LineWidth',2)
hold on; plot([mean(coimc2p(:))+mean(fit.c1(:,2)) mean(coimc2p(:))+mean(fit.c1(:,2))],...
    ylim,'b--','LineWidth',2)

title('Empirical data')

subplot(1,3,3); 
noimc2_diff = noimc2p-abs(noimc2n); 
coimc2_diff = coimc2p-abs(coimc2n);

h = histogram(noimc2_diff(:)); h.FaceAlpha = 0.2; h.EdgeAlpha = 0.2;
h.FaceColor = 'k'; h.EdgeColor = 'k'; hold on;
h = histogram(coimc2_diff(:)); h.FaceAlpha = 0.2; h.EdgeAlpha = 0.2;
h.FaceColor = 'b'; h.EdgeColor = 'b'; hold on;
xlabel('c2p - abs(c2n)')
title('Insight')
