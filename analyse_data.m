function results = analyse_data(data)

C     = data.main(:,3);
P     = data.main(:,2);
Cnd   = data.main(:,1);
Cf    = data.main(:,5);
RT    = data.main(:,4);
V(1)  = mean(data.VVIQ); 
V(2)  = mean(data.ima_practice(:,2));

nTrls = length(C); 
nCnds = length(unique(Cnd));

results.V = V;
results.age = data.age;
results.ima_check = data.ima_check;
results.comments = data.comments; 
results.staircase = data.staircase;

%% Calculate d' and c per condition
% recode to responses ('pres' vs 'abs') instead of correct
R = nan(nTrls,1);
R(P==1 & C==1) = 1; R(P==0 & C==0) = 1;
R(P==0 & C==1) = 0; R(P==1 & C==0) = 0;

results.C = nan(nCnds,1); results.D = nan(nCnds,1);
results.H = nan(nCnds,1); results.FA = nan(nCnds,1);
results.acc = nan(nCnds,1);
for c = 1:nCnds   
    idx = Cnd == c;    
    if sum(idx) > 0
    H = sum(idx&P==1&R==1); results.H(c) = H/sum(idx&P==1);
    if H==0; H = 0.5; elseif H==1; H=H-0.5; end
    FA= sum(idx&P==0&R==1); results.FA(c) = FA/sum(idx&P==0);
    if FA==0; FA=0.5; elseif FA==1;FA=FA-0.5; end
    [results.D(c),results.C(c)] = dprime(H/sum(idx&P==1),FA/sum(idx&P==0));
    results.acc(c) = mean(P(idx)==R(idx));
    end
end

%% Get confidence per confiditition and per response type
results.confidence = nan(nCnds,2,2);
for c = 1:nCnds    
    for p = 1:2
        for r = 1:2
            idx = Cnd==c & P ==(p-1)  & R ==(r-1);
            results.confidence(c,p,r) = mean(Cf(idx));
        end
    end
end

results.RT = nan(nCnds,2,2);
for c = 1:nCnds    
    for p = 1:2
        for r = 1:2
            idx = Cnd==c & P ==(p-1) & R ==(r-1);
            results.RT(c,p,r) = mean(RT(idx));
        end
    end
end