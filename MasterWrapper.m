clear all;
restoredefaultpath;
addpath('Utilities')
dataDir{1} = 'D:\METPRM\Data\CollectionSept2021'; 
dataDir{2} = 'D:\METPRM\Data\CollectionNov2022'; 

resultDir = cell(length(dataDir),1);

for d = 1:length(dataDir)
    [~,name] = fileparts(dataDir{d});
    resultDir{d} = fullfile('D:\METPRM\Results',name);
    if d == 1
        dataFiles = str2fullfile(dataDir{d},'*.txt');
        dataID    = [ones(length(dataFiles),1) (1:length(dataFiles))'];
    else
        dataFiles = cat(2,dataFiles,str2fullfile(dataDir{d},'*.txt'));
        nSub      = length(str2fullfile(dataDir{d},'*.txt'));
        dataID    = cat(1,dataID,[ones(nSub,1)*d (1:nSub)']);
    end
end

nSubs     = length(dataFiles);

% inclusion info
sub_info    = zeros(nSubs,7);
prolificIDs = cell(nSubs,1);

%% Analyze the data
for sub = 1:nSubs
    
    fprintf('Processing sub %d out of %d \n',sub,nSubs)

    % load the data
    load(fullfile(resultDir{dataID(sub)},sprintf('sub_%03d.mat',dataID(sub,2))),'data')
    prolificIDs{sub} = data.prolificID;
      
    % Analyse the data
    dataClean = data;
    dataClean.main = data.main(data.main(:,6)==1,:); % only correct ima check
    results = analyse_data(dataClean);      

    % Save the results
    save(fullfile(resultDir{dataID(sub)},sprintf('sub_%03d.mat',dataID(sub,2))),'results','-append')

    % Check inclusion criteria
    sub_info(sub,:) = check_data(data,results);  
    clear data results;

end

%% Collect good subjects
group_results = cell(nSubs,1); group_data = cell(nSubs,1);
for sub = 1:nSubs
    load(fullfile(resultDir{dataID(sub,1)},sprintf('sub_%03d.mat',dataID(sub,2))),'results','data')
    group_results{sub} = results;
    group_data{sub} = data;
    clear results data
end
group_data = group_data(sub_info(:,1)==1);
group_results = group_results(sub_info(:,1)==1);
prolificIDs = prolificIDs(sub_info(:,1)==1);

% check duplicate participants
[Au, idx ,idx2] = uniquecell(prolificIDs);
group_results = group_results(idx);
group_data = group_data(idx);
nSubs = length(group_results);

% collect data in matrix format
A = nan(nSubs,1); 
C = nan(nSubs,3); Acc = nan(nSubs,3);
V = nan(nSubs,2); Dp = nan(nSubs,3);
H = nan(nSubs,3); FA = nan(nSubs,3);
Cf = nan(nSubs,3,2,2); RT = nan(nSubs,3,2,2);
for sub = 1:nSubs
    Acc(sub,:) = group_results{sub}.acc;
    A(sub) = group_results{sub}.age;
    V(sub,:) = group_results{sub}.V;
    C(sub,:) = group_results{sub}.C;
    Dp(sub,:) = group_results{sub}.D;
    Cf(sub,:,:,:) = group_results{sub}.confidence;
    RT(sub,:,:,:) = group_results{sub}.RT;
end

%% Plot results
conditions = {'No imagery','Congruent','Incongruent'};

% d' and c
figure; alpha = 0.3;
subplot(2,1,1); barwitherr(std(C)/sqrt(nSubs),mean(C,1));
hold on; s = scatter((randn(nSubs,1)./10)+[1:3],C,20,'filled');
for c = 1:3; s(c).MarkerFaceAlpha = alpha; s(c).MarkerEdgeAlpha = alpha; end
title('Criterion'); set(gca,'XTickLabels',conditions);
subplot(2,1,2); barwitherr(std(Dp)/sqrt(nSubs),mean(Dp,1));
hold on; s = scatter((randn(nSubs,1)./10)+[1:3],Dp,20,'filled');
for c = 1:3; s(c).MarkerFaceAlpha = alpha; s(c).MarkerEdgeAlpha = alpha; end
title("d'"); set(gca,'XTickLabels',conditions);

% confidence 
figure;
nan_idx = any(isnan(Cf),[2 3 4]); % only participants without 0 cells
datM = []; datSEM = [];
for p = 1:2
    datM = [datM; squeeze(nanmean(Cf(~nan_idx,:,p,:),1))'];
    datSEM = [datSEM; squeeze(nanstd(Cf(~nan_idx,:,p,:),1))'./sqrt(sum(~nan_idx))];
end
barwitherr(datSEM,datM);
set(gca,'XTickLabels',{'CR','FA','Miss','Hit'}); legend(conditions);
ylim([40 70])
ylabel('Confidence')


%% Hierarchical model fitting

addpath(genpath('HMeta-d-master'));

% copy custom code to package
HMetad = which('Bayes_metad_group.txt');
model_txtfile = 'Bayes_metad_criterion_insight_model.txt';
model_wrapper = 'fit_meta_d_criterion_insight_model.m';
copyfile(model_txtfile,fullfile(fileparts(HMetad),model_txtfile));
copyfile(model_wrapper,fullfile(fileparts(HMetad),model_wrapper));

% do the fitting
fit = hierarchicalFitting(group_data);

% plot results
plot_hierarchical_model_fit(fit)
