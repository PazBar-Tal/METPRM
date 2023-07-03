function [sub_info,data] = check_data(data,results)
% checks the data based on exclusion criteria https://osf.io/9xych/

nTrlBlock = 24; 
nConds  = length(unique(data.main(:,1)));

incl = 1; acc = 2; imaCheck = 3; imaComment = 4; confVar = 5; nFA = 6; nM = 7;
sub_info = nan(1,7);
%% Get all the info
% Mean detection accuracy 
sub_info(acc) = mean(results.acc);

% imagery check per condition
cBlcks = nan(nConds,1);
for c = 1:nConds
    idx = data.main(:,1)==c;    
    cBlcks(c) = sum(data.main(idx,6))/nTrlBlock;    
end
sub_info(imaCheck) = min(cBlcks); % condition with the least correct ima checks

% imagery comment check
tmp = find(contains({'Yes','Sometimes','No'},data.ima_check));
if ~isempty(tmp); sub_info(imaComment) = tmp; else; sub_info(imaComment) = 0; end

% enough variance in confidence
resp = nan(length(data.main),1); 
resp(data.main(:,2)==1 & data.main(:,3)==1) = 1;
resp(data.main(:,2)==0 & data.main(:,3)==0) = 1;
resp(data.main(:,2)==0 & data.main(:,3)==1) = 0;
resp(data.main(:,2)==1 & data.main(:,3)==0) = 0;
maxPercConf = nan(2,1);
for r = 1:2
    idx = resp==(r-1);
    uConf = unique(data.main(idx,5));
    duC   = nan(length(uConf),1);
    for u = 1:length(uConf)        
        duC(u) = sum(data.main(idx,5)==uConf(u))/sum(idx);
    end
    maxPercConf(r) = max(duC);
end
sub_info(confVar) = max(maxPercConf);

% FA's and misses
sub_info(nFA) = min(results.FA);
sub_info(nM)  = min(1-results.H);

%% Exclusion
if (sub_info(acc) < 0.55) ||... % too low accuracy
        sub_info(imaCheck) < 2 || ... % failed imagery check too often
        sub_info(imaComment)==3 || ... % didn't actually imagine the stimuli
        sub_info(confVar) > 0.9  % indicated the same confidence too often
    sub_info(incl) = false;
else
    sub_info(incl) = true;
end



