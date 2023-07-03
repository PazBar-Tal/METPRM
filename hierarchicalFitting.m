function fit = hierarchicalFitting(group_data)
% function hierarchicalFitting(group_data)
%
% uses the hmeta-d' toolbox to infer effects of imagery condition on type 2
% criterion setting, allowing for unequal positve and negative criteria
% such that we can model insight (type-2 c diverging from type-1 c)
%

% get data in right format
nSub = length(group_data);
for i = 1:nSub

    data = group_data{i};
    
    C     = data.main(:,3); % correct
    P     = data.main(:,2); % presence
    R     = nan(length(C),1); R(P&C) = 1; R(P&~C) = 0; R(~P&C) = 0; R(~P&~C) = 1;
    Cnd   = data.main(:,1); % condition
    Cf    = data.main(:,5); % confidence

    % z-score confidence data
    Cf = zscore(Cf); 

    % No imagery condition - noise
    nR_S1(1).counts{i}(1) = sum(Cnd==1 & P==0 & R==0 & Cf>0); % high confidence CR
    nR_S1(1).counts{i}(2) = sum(Cnd==1 & P==0 & R==0 & Cf<0); % low confidence CR
    nR_S1(1).counts{i}(3) = sum(Cnd==1 & P==0 & R==1 & Cf<0); % low confidence FA
    nR_S1(1).counts{i}(4) = sum(Cnd==1 & P==0 & R==1 & Cf>0); % high confidence FA

    % No imagery condition - signal
    nR_S2(1).counts{i}(1) = sum(Cnd==1 & P==1 & R==0 & Cf>0); % high confidence miss 
    nR_S2(1).counts{i}(2) = sum(Cnd==1 & P==1 & R==0 & Cf<0); % low confidence miss 
    nR_S2(1).counts{i}(3) = sum(Cnd==1 & P==1 & R==1 & Cf<0); % low confidence hit 
    nR_S2(1).counts{i}(4) = sum(Cnd==1 & P==1 & R==1 & Cf>0); % high confidence hit 

    % congruent imagery condition - noise
    nR_S1(2).counts{i}(1) = sum(Cnd==2 & P==0 & R==0 & Cf>0); % high confidence CR
    nR_S1(2).counts{i}(2) = sum(Cnd==2 & P==0 & R==0 & Cf<0); % low confidence CR
    nR_S1(2).counts{i}(3) = sum(Cnd==2 & P==0 & R==1 & Cf<0); % low confidence FA
    nR_S1(2).counts{i}(4) = sum(Cnd==2 & P==0 & R==1 & Cf>0); % high confidence FA

    % congruent imagery condition - signal
    nR_S2(2).counts{i}(1) = sum(Cnd==2 & P==1 & R==0 & Cf>0); % high confidence miss 
    nR_S2(2).counts{i}(2) = sum(Cnd==2 & P==1 & R==0 & Cf<0); % low confidence miss 
    nR_S2(2).counts{i}(3) = sum(Cnd==2 & P==1 & R==1 & Cf<0); % low confidence hit 
    nR_S2(2).counts{i}(4) = sum(Cnd==2 & P==1 & R==1 & Cf>0); % high confidence hit 

end

% fit the model
mcmc_params = fit_meta_d_params;
fit = fit_meta_d_criterion_insight_model(nR_S1, nR_S2, mcmc_params);
