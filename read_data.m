function D = read_data(cfg)

% Unpack data structure
v2struct(cfg)

% Read in text file
fid = fopen(dataFile,'r');
text = textscan(fid,'%s','Delimiter',','); 
text = text{1};

%% Reformat into something more usable
TextEnd = false;
refText = cell(length(text),1);
count1  = 1;
count2  = 1;
textToRef = [];
while ~TextEnd    
    
    textToRef(count1) = count2;
    
    % parse into text and numbers
    num = []; str = [];
    for i = 1:length(text{count1})
        if isletter(text{count1}(i))
            str = [str; i];
        elseif ~isnan(str2double(text{count1}(i)))
            num = [num; i];
        end
    end
    
    if ~isempty(str)
        if strcmp(text{count1}(str(1)),'Q') 
            str(2) = num(1);
            num(1) = [];
        end
    end
    
    % convert to strings and numbers 
    if ~isempty(num); num = str2double(text{count1}(num(1):num(end))); end
    if ~isempty(str); str = text{count1}(str(1):str(end)); end
    
    % assign to cells 
    if ~isempty(num) && ~isempty(str)
        firstNum = num(1) < str(1);       
        
        if firstNum
            refText{count2} = num;
            count2 = count2 + 1;
            refText{count2} = str;
        else
            refText{count2} = str;
            count2 = count2 + 1;
            refText{count2} = num; 
        end
    elseif ~isempty(num)
        refText{count2} = num;
    elseif ~isempty(str)        
        refText{count2} = str;
    elseif isempty(num) && isempty(str)
        refText{count2} = [];
    end      
    
    count1 = count1+1;    
    count2 = count2+1;
    
    % check end text
    if count1 > length(text)
        TextEnd = true;
    end  
end

% determine block indices
str_idx = find(cellfun(@ischar,refText)==1);
det_left = str_idx(contains(refText(str_idx),' left tilted gratings.'));
det_right = str_idx(contains(refText(str_idx),' right tilted gratings.'));
ima_no = str_idx(contains(refText(str_idx),'<strong>not</strong>'));
ima_left = str_idx(contains(refText(str_idx),'<strong>imagine left tilted gratings</strong>'));
ima_right = str_idx(contains(refText(str_idx),'<strong>imagine right tilted gratings</strong>'));
left_tilt = str_idx(contains(refText(str_idx),'  left tilted'));
right_tilt = str_idx(contains(refText(str_idx),'  right tilted'));

block_idx = sort([left_tilt;right_tilt]);
block_ids = zeros(nMainBlocks,1); 
for b = 1:nMainBlocks
    if ismember(block_idx(b),ima_no) % no imagery
        block_ids(b) = 1;
    end
    
    if (ismember(block_idx(b),det_left) && ismember(block_idx(b),ima_left)) ||...
            (ismember(block_idx(b),det_right) && ismember(block_idx(b),ima_right))
        block_ids(b) = 2; % congruent
    end
    
    if (ismember(block_idx(b),det_left) && ismember(block_idx(b),ima_right)) ||...
            (ismember(block_idx(b),det_right) && ismember(block_idx(b),ima_left))
        block_ids(b) = 3; % incongruent
    end        
end

%% Get the header
nCol = 19;
header = cell(1,nCol);
for c = 1:nCol
    header{c} = refText{c};
end

%% Make it into an actual data spreadsheet
trial_types = {'html-keyboard-response','animation','survey-text','call-function','html-slider-response','survey-likert'};
trl_idx = find(contains(text,trial_types));
trl_idx(trl_idx < nCol) = []; %  cut off header
nTrials = length(trl_idx);
data = cell(nTrials,nCol);
data(1,:) = header;
str_idx = find(cellfun(@ischar,refText)==1);
for t = 1:nTrials
    
    ref_idx = textToRef(trl_idx(t));
    
    % check
    if ~ismember(trial_types,refText{ref_idx}) & ~strcmp(refText{ref_idx},'animation_sequence')
        error('Something is going wrong here!')
    end
    
    % do something different per trial type
    if strcmp(refText{ref_idx},trial_types{1}) % html keyboard responses
        
        if ref_idx+15 < length(refText)
            textSnip = refText(ref_idx-5:ref_idx+15); 
        else
            textSnip = refText(ref_idx-5:end); 
        end
        data{t+1,3} = trial_types{1}; % trial type        
              
        % Get them numbers and strings
        nums = find(cellfun(@isnumeric,textSnip) == 1);
        strs = find(cellfun(@ischar,textSnip) == 1);
        strs(strs < nums(1)) = [];
        for i = 1:length(strs)
            if length(textSnip(strs(i))) > 50 && length(textSnip{strs(i)+1}) > 50
                textSnip{strs(i)} = cat(2,textSnip{strs(i)},textSnip{strs(i)+1});
                strs(i+1) = [];
            end
        end    
        nums(cellfun(@isempty,textSnip(nums)) == 1) = [];
        
        % Determine sub-trial type 
        if any(contains(textSnip(strs),'fixation'))
            type_idx = contains(textSnip(strs),trial_types(1));
            data{t+1,11} = 'fixation';            
            data{t+1,4} = textSnip{strs(type_idx)+1};
            data{t+1,5} = textSnip{strs(type_idx)+2};
        elseif any(contains(textSnip(strs),'det_practice')) % detection practice
            type2_idx = find(contains(textSnip(strs),'det_practice'));
            tmp = nums(nums<strs(type2_idx));
            data{t+1,11} = 'det_practice';
            data{t+1,1} = textSnip{nums(1)}; % RT
            data{t+1,4} = textSnip{nums(2)}; % trl index
            data{t+1,5} = textSnip{nums(3)}; % time elapsed
            data{t+1,8} = textSnip{tmp(end)};
            data{t+1,13} = textSnip{strs(type2_idx+1)};
            data{t+1,14} = textSnip{strs(type2_idx+2)};
        elseif any(contains(textSnip(strs),'stair_test')) % staircase trials
            type2_idx = find(contains(textSnip(strs),'stair_test'));
            tmp = nums(nums < strs(type2_idx));
            data{t+1,11} = 'stair_test';
            data{t+1,1} = textSnip{nums(1)};
            data{t+1,4} = textSnip{nums(2)};
            data{t+1,5} = textSnip{nums(3)};
            data{t+1,8} = textSnip{tmp(end)};
            data{t+1,13} = textSnip{strs(type2_idx+1)};
            data{t+1,14} = textSnip{strs(type2_idx+2)};
        elseif any(contains(textSnip(strs),'ima_practice'))
            type1_idx = strs(contains(textSnip(strs),trial_types{1}));
            type2_idx = strs(contains(textSnip(strs),'ima_practice'));
            data{t+1,11} = 'ima_practice';
            tmp1 = nums(nums < type1_idx);
            tmp2 = nums(nums > type1_idx);
            tmp3 = nums(nums < type2_idx);
            data{t+1,1} = textSnip{tmp1(end)};
            data{t+1,4} = textSnip{tmp2(1)};
            data{t+1,5} = textSnip{tmp2(2)};
            data{t+1,15} = textSnip{tmp3(end)};
            
            % left or right tilt?
            left = str_idx(contains(refText(str_idx),'imagine  a left'));
            left = left(left < ref_idx); 
            right = str_idx(contains(refText(str_idx),'imagine  a right'));
            right = right(right < ref_idx);
            if isempty(right) 
                data{t+1,7} = 'left';
            elseif isempty(left) 
                data{t+1,7} = 'right';
            elseif left(end) > right(end) 
                data{t+1,7} = 'left';
            elseif right(end) > left(end)
                data{t+1,7} = 'right';
            end
            
        elseif any(contains(textSnip(strs),'ima_check'))
            type2_idx = find(contains(textSnip(strs),'ima_check'));
            tmp = nums(nums < strs(type2_idx));
            data{t+1,11} = 'ima_check';
            data{t+1,1} = textSnip{nums(1)};
            data{t+1,4} = textSnip{nums(2)};
            data{t+1,5} = textSnip{nums(3)};
            data{t+1,8} = textSnip{tmp(end)};
            data{t+1,13} = textSnip{strs(type2_idx+1)}; 
            data{t+1,14} = textSnip{strs(type2_idx+2)}; 
            
        elseif any(contains(textSnip(strs),'main_test')) % main trials
            type2_idx = find(contains(textSnip(strs),'main_test'));
            tmp = nums(nums < strs(type2_idx));
            data{t+1,11} = 'main_test';
            data{t+1,1} = textSnip{nums(1)};
            data{t+1,4} = textSnip{nums(2)};
            data{t+1,5} = textSnip{nums(3)};
            data{t+1,8} = textSnip{tmp(end)};
            data{t+1,13} = textSnip{strs(type2_idx+1)};
            data{t+1,14} = textSnip{strs(type2_idx+2)};   
            data{t+1,17} = textSnip{nums(end)};
        elseif any(contains(textSnip(strs),'prac_conf')) % confidence practice
            type2_idx = find(contains(textSnip(strs),'prac_conf'));
            tmp = nums(nums < strs(type2_idx));
            data{t+1,11} = 'prac_conf';
            data{t+1,1} = textSnip{nums(1)};
            data{t+1,4} = textSnip{nums(2)};
            data{t+1,5} = textSnip{nums(3)};
            data{t+1,8} = textSnip{tmp(end)};
            data{t+1,13} = textSnip{strs(type2_idx+1)};
            data{t+1,14} = textSnip{strs(type2_idx+2)};   
            data{t+1,17} = textSnip{nums(end)};
        else
            type1_idx = strs(strcmp(textSnip(strs),trial_types{1}));
            tmp = strs(strs > type1_idx);
            tmp1 = nums(nums > tmp(1));
            data{t+1,1} = textSnip{nums(1)}; % first num is RT
            data{t+1,7} = textSnip{tmp(1)}; % then comes stimulus which is txt
            data{t+1,4} = textSnip{nums(2)}; % trl idx
            
            data{t+1,5} = textSnip{nums(3)}; % time elapsed
            data{t+1,8} = textSnip{tmp1(1)}; % button press
            data{t+1,11} = 'instruction'; 
        end
        
    elseif strcmp(refText{ref_idx},trial_types{6}) % survey-likert
        textSnip = refText(ref_idx-5:ref_idx+20);
        
        % Get them numbers and strings
        nums = find(cellfun(@isnumeric,textSnip) == 1);
        strs = find(cellfun(@ischar,textSnip) == 1);
        strs(strs < nums(1)) = [];
        for i = 1:length(strs)
            if length(textSnip(strs(i))) > 50 && length(textSnip{strs(i)+1}) > 50
                textSnip{strs(i)} = cat(2,textSnip{strs(i)},textSnip{strs(i)+1});
                strs(i+1) = [];
            end
        end    
        nums(cellfun(@isempty,textSnip(nums)) == 1) = [];
        type_id = strs(contains(textSnip(strs),trial_types{6}));
        
        data{t+1,3} = textSnip{type_id}; % trial type
        tmp1 = nums(nums > type_id);
        tmp2 = nums(nums < type_id);
        data{t+1,4} = textSnip{tmp1(1)}; % trial index
        data{t+1,1} = textSnip{tmp2(end)}; % RT
        data{t+1,5} = textSnip{tmp1(2)}; % time elapsed
        
        Qs = strs(contains(textSnip(strs),'Q'));
        data{t+1,15} = zeros(length(Qs),2);
        for q = 1:length(Qs)
            data{t+1,15}(q,1) = str2double(textSnip{Qs(q)}(2));
            data{t+1,15}(q,2) = textSnip{Qs(q)-1};            
        end
    elseif strcmp(refText{ref_idx},trial_types{4}) % call-function
            
        if ref_idx+15 < length(refText)
            textSnip = refText(ref_idx-5:ref_idx+15); 
        else
            textSnip = refText(ref_idx-5:end); 
        end
        data{t+1,4} = trial_types{4}; % trial type        
              
        % Get them numbers and strings
        nums = find(cellfun(@isnumeric,textSnip) == 1);
        strs = find(cellfun(@ischar,textSnip) == 1);
        strs(strs < nums(1)) = [];
        for i = 1:length(strs)
            if length(textSnip(strs(i))) > 50 && length(textSnip{strs(i)+1}) > 50
                textSnip{strs(i)} = cat(2,textSnip{strs(i)},textSnip{strs(i)+1});
                strs(i+1) = [];
            end
        end    
        nums(cellfun(@isempty,textSnip(nums)) == 1) = [];
        
        % determine sub-trial type
        if any(contains(textSnip(strs),'stair_update')) % staircase update
            type2_idx = contains(textSnip(strs),'stair_update');
            data{t+1,11} = 'stair_update';
            data{t+1,1} = textSnip{nums(1)}; % RT
            data{t+1,5} = textSnip{nums([textSnip{nums}]>20000)};
            data{t+1,4} = textSnip{nums([textSnip{nums}]>20000)-1};
            id = find(nums > strs(type2_idx));
            data{t+1,17} = textSnip{nums(id(1))};
            data{t+1,16} = textSnip{nums(id(2))};
        end
        
    elseif strcmp(refText{ref_idx},trial_types{2}) % animation
        textSnip = refText(ref_idx:ref_idx+num_steps*4+10);
        textSnip(cellfun(@isempty,textSnip) == 1) = [];
        nums = find(cellfun(@isnumeric,textSnip) == 1);
        data{t+1,3} = trial_types{2};
        data{t+1,4} = textSnip{nums(1)};
        data{t+1,5} = textSnip{nums(2)};        
        data{t+1,12} = cell(num_steps,2); i = 1; j = 1;
        while j < length(textSnip)+1
            if ~ischar(textSnip{j})
                j = j + 1;
            elseif ~(contains(textSnip{j},'stim_') || contains(textSnip{j},'noise_'))
                j = j+1;
            elseif (contains(textSnip{j},'stim_') || contains(textSnip{j},'noise_'))
                if (contains(textSnip{j},'stim_'))
                    id = strfind(textSnip{j},'stim_');  
                else
                    id = strfind(textSnip{j},'noise_');
                end
                data{t+1,12}{i,1} = textSnip{j}(id:end);
                j = j+1;
                stp = j+2;
                if stp > length(textSnip); stp = length(textSnip); end
                for k = j:stp
                    if isnumeric(textSnip{k}) && ~isnan(textSnip{k})
                        data{t+1,12}{i,2} = textSnip{k};
                    end
                end                
                i = i + 1;
                j = k + 1;
            end
        end
        
   
     elseif strcmp(refText{ref_idx},trial_types{3}) % survey text
        textSnip = refText(ref_idx-5:ref_idx+20);
        
        % Get them numbers and strings
        nums = find(cellfun(@isnumeric,textSnip) == 1);
        strs = find(cellfun(@ischar,textSnip) == 1);
        strs(strs < nums(1)) = [];
        for i = 1:length(strs)
            if length(textSnip(strs(i))) > 50 && length(textSnip{strs(i)+1}) > 50
                textSnip{strs(i)} = cat(2,textSnip{strs(i)},textSnip{strs(i)+1});
                strs(i+1) = [];
            end
        end    
        nums(cellfun(@isempty,textSnip(nums)) == 1) = [];
        type_id = strs(contains(textSnip(strs),trial_types{3}));
        
        data{t+1,4} = textSnip{type_id};
        tmp1 = nums(nums > type_id);
        tmp2 = nums(nums < type_id);
        data{t+1,5} = textSnip{tmp1(1)};
        data{t+1,1} = textSnip{tmp2(end)};
        data{t+1,6} = textSnip{tmp1(2)};
        
        Qs = strs(contains(textSnip(strs),'Q'));
        if length(Qs)==1
            tmp = strfind(textSnip{Qs},'"\"');
            data{t+1,14} = textSnip{Qs}(tmp(end)+3:end-1);
        else
        data{t+1,14} = cell(length(Qs),2);
        for q = 1:length(Qs)
            data{t+1,14}{q,1} = textSnip{Qs(q)}(1:2);  
            if q == 1 % age
                tmp = nums(nums < Qs(1));
                if ~isempty(tmp)
                data{t+1,14}{q,2} = textSnip{tmp(end)};
                end
            else
            data{t+1,14}{q,2} = textSnip{Qs(q)}(12:end);  
            end
        end 
        end
        
    elseif strcmp(refText{ref_idx},'animation_sequence')
        % something weird
    
    elseif strcmp(refText{ref_idx},trial_types{5}) % html-slider-response
        
        textSnip = refText(ref_idx-5:ref_idx+20); 
        
       % Get them numbers and strings
        nums = find(cellfun(@isnumeric,textSnip) == 1);
        strs = find(cellfun(@ischar,textSnip) == 1);
        strs(strs < nums(1)) = [];
        for i = 1:length(strs)
            if length(textSnip(strs(i))) > 50 && length(textSnip{strs(i)+1}) > 50
                textSnip{strs(i)} = cat(2,textSnip{strs(i)},textSnip{strs(i)+1});
                strs(i+1) = [];
            end
        end    
        nums(cellfun(@isempty,textSnip(nums)) == 1) = [];
        
        tt_idx = find(strcmp(textSnip,trial_types{5}));
        cf_idx = strs(contains(textSnip(strs),'confident'));
        
        % fill out the things
        tmp1 = nums(nums<tt_idx); 
        data{t+1,1} = textSnip{tmp1(end)};
        data{t+1,3} = trial_types{5};
        data{t+1,7} = textSnip{cf_idx};
        tmp2 = nums(nums>cf_idx);
        data{t+1,18} = textSnip{tmp2(1)};      
        
        
    end 
    

end

clear refText Text

%% Now we turn this into actual things that we can do analyses on
D = [];

% prolific ID
idx = find(strcmp(data(:,4),'survey-text'));
D.prolificID = data{idx(1),14};

% - practice - %
test_id = find(strcmp(data(:,11),'det_practice'));
pracTrials = length(test_id);
D.det_practice = zeros(pracTrials,2);
for p = 1:pracTrials
    if strcmp(data{test_id(p),14},'true')
        D.det_practice(p,1) = 1;
    end
    D.det_practice(p,2) = data{test_id(p),1};
end

% - surveys - %
survey_id = find(strcmp(data(:,3),'survey-likert'));
nVVIQ     = length(survey_id);
D.VVIQ = []; v = 1; i = 1;
while v < nVVIQ+1
    qs = data{survey_id(i),15};
    nQs = size(qs,1);
    D.VVIQ = cat(1,D.VVIQ,qs(:,2));
    v = v+nQs; i = i+1;  
end

% - staircase - %
update_id = find(strcmp(data(:,11),'stair_update'));
stairTrls_id = find(strcmp(data(:,11),'stair_test'));
nStairs = length(update_id); nStairTrls = length(stairTrls_id)/nStairs;
D.staircase = cell(nStairs,4);
for n = 1:nStairs
    if n == 1
        D.staircase{n,1} = startVis; % previous vis level
        stair_idx = stairTrls_id(stairTrls_id < update_id(n));
    else
        D.staircase{n,1} = data{update_id(n-1),17};
        stair_idx = stairTrls_id(stairTrls_id>update_id(n-1) & ...
            stairTrls_id < update_id(n));
    end   
    D.staircase{n,2} = data{update_id(n),16};  % accuracy
    D.staircase{n,3} = data{update_id(n),17};  % updated vis level
    D.staircase{n,4} = zeros(nStairTrls,2);
    
    for s = 1:nStairTrls
        if strcmp(data{stair_idx(s),14},'true')
            D.staircase{n,4}(s,1) = 1;
        end
        D.staircase{n,4}(s,2) = data{stair_idx(s),1};
    end
end

% -confidence practice - %
test_id = find(strcmp(data(:,11),'prac_conf'));
nPracConf = length(test_id);
D.conf_practice = zeros(nPracConf,3);
for p = 1:nPracConf
    if strcmp(data{test_id(p),14},'true')
        D.conf_practice(p,1) = 1;
    end
    D.conf_practice(p,2) = data{test_id(p),1};
    D.conf_practice(p,3) = data{test_id(p)+1,18};
end

% - imagery practice - %
test_id = find(strcmp(data(:,11),'ima_practice'));
nTrials = length(test_id);
D.ima_practice = zeros(nTrials,3);
for t = 1:nTrials
    if strcmp(data{test_id(t),7},'right')
        D.ima_practice(t,1) = 1;
    end
    D.ima_practice(t,2) = data{test_id(t),15}-48;
    D.ima_practice(t,3) = data{test_id(t),1};
end

% - main blocks - %
test_id = find(strcmp(data(:,11),'main_test')); % this does not work now because the conf practice are also labeled as main test trials!
nMainTrials = length(test_id)/nMainBlocks;
D.main = zeros(nMainTrials*nMainBlocks,6); c = 1;
str_idx = find(cellfun(@ischar,data(:,11)) == 1);
for m = 1:nMainBlocks
   idx = (m-1)*nMainTrials+1:nMainTrials*m;
   
   % condition ID
   D.main(idx,1) = block_ids(m);
   
   % fill out details trials
   for t = 1:nMainTrials
       
       if contains(data{test_id(idx(t))-1,12}{1},'stim')
            D.main(idx(t),2) = 1; % stim present
       end  
       
       if strcmp(data{test_id(idx(t)),14},'true')
            D.main(idx(t),3) = 1; % response - correct or not
       end
              
       D.main(idx(t),4) = data{test_id(idx(t)),1}; % RT detection
        
       D.main(idx(t),5) = data{test_id(idx(t))+1,18}; % confidence        
        
       c = c+1;
   end   
   
   % imagery check
   check_idx = str_idx(find(str_idx==test_id(c-1))+1);
   if strcmp(data{check_idx,14},'true')
       D.main(idx,6) = 1; % imagery check 
   end
end

% -- debrief questions -- %
idx = find(strcmp(data(:,4),'survey-text'));
questions = data{idx(2),14};
D.age = questions{1,2};
D.ima_check = questions{2,2};
D.insight = questions{3,2};
D.comments = questions{4,2};

fclose('all');
