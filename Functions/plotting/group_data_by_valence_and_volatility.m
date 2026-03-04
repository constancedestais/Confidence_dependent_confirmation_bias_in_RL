function [my_table,my_vectors] = group_data_by_valence_and_volatility(data_array_by_version, version_names)
%{
- function creates vectors and table columns for pCorrect, pSwitch and confidence averaged for each participant and for specific features: valence, volatility
- specifically, these are the groups that are returned:
    task_versions                                 
    participants                                   
    interleaved_valence                            
    feedback                                       
    
    mean_correct                                   
    mean_correct_gain                              
    mean_correct_loss                              
    mean_correct_stable                            
    mean_correct_volatile                          
    mean_correct_difference_valence                
    mean_correct_difference_volatility             
    mean_correct_difference_valence_volatility             
    
    mean_switch                                    
    mean_switch_gain                               
    mean_switch_loss                               
    mean_switch_stable                            
    mean_switch_volatile                           
    mean_switch_difference_valence                 
    mean_switch_difference_volatility              
    mean_switch_difference_valence_volatility 
    
    mean_confidence                                
    overconfidence                                 
    mean_confidence_gain                           
    mean_confidence_loss                           
    mean_confidence_stable                         
    mean_confidence_volatile                       
    mean_confidence_difference_valence             
    mean_confidence_difference_volatility          
    mean_confidence_difference_valence_volatility 
    mean_confidence_difference_correct   
    
    median_RT                                
    median_RT_gain                           
    median_RT_loss                           
    median_RT_stable                         
    median_RT_volatile                       
    median_RT_difference_valence             
    median_RT_difference_volatility          
    median_RT_difference_valence_volatility 
    median_RT_difference_correct   
- data format: 
    - my_table: one line per participant, columns are not split by versions but there is a "versions" column --> allows to compute effect of versions
    - my_vectors: dimensions: variable{n_versions}[1,n_participants]

%}

% check inputs
assert(  numel(version_names) == numel(data_array_by_version) , "There should be as many versions in the data as in the version names")
assert(  istable( data_array_by_version{1} ) , "the data for each version should be stored as a table ")

%% prepare data  

%% Compute : differences in pcorrect/confidence between different conditions 
% for plots: need cell arrays of size n_versions * 1, with each cell containing a row vector of 1 x n_participants (this allows for different numbers of participants per task version)
% for stats: need columns/tables 

% set useful variables 
n_versions = numel(version_names);
unique_valence = [-1, 1];

% initialise vectors for table columns
col_task_versions                      = [];
col_participants                       = [];
col_interleaved_valence                = [];
col_feedback                           = [];

col_mean_correct                                  = [];
col_mean_correct_gain                             = [];
col_mean_correct_loss                             = [];
col_mean_correct_difference_valence               = [];
col_mean_correct_difference_volatility            = [];
col_mean_correct_difference_valence_volatility    = [];

col_mean_switch                               = [];
col_mean_switch_gain                          = [];
col_mean_switch_loss                          = [];
col_mean_switch_stable                        = [];
col_mean_switch_volatile                      = [];
col_mean_switch_difference_valence            = [];
col_mean_switch_difference_volatility         = [];
col_mean_switch_difference_valence_volatility = [];

col_mean_confidence                               = [];
col_overconfidence                                = [];
col_mean_confidence_gain                          = [];
col_mean_confidence_loss                          = [];
col_mean_confidence_difference_valence            = [];
col_mean_confidence_difference_volatility         = [];
col_mean_confidence_difference_valence_volatility = [];

col_median_RT                               = [];
col_median_RT_gain                          = [];
col_median_RT_loss                          = [];
col_median_RT_difference_valence            = [];
col_median_RT_difference_volatility         = [];
col_median_RT_difference_valence_volatility = [];

% for each variable, have one cell array containing one vector PER version, so if 4 versions, want a cell array with 4 elements (this allows for different numbers of participants per task version)
task_versions                                 = cell(n_versions,1) ;
participants                                  = cell(n_versions,1) ; 
interleaved_valence                           = cell(n_versions,1) ; 
feedback                                      = cell(n_versions,1) ; 

mean_correct                                  = cell(n_versions,1) ; 
mean_correct_gain                             = cell(n_versions,1) ; 
mean_correct_loss                             = cell(n_versions,1) ; 
mean_correct_stable                           = cell(n_versions,1) ; 
mean_correct_volatile                         = cell(n_versions,1) ; 
mean_correct_difference_valence               = cell(n_versions,1) ; 
mean_correct_difference_volatility            = cell(n_versions,1) ; 
mean_correct_difference_valence_volatility    = cell(n_versions,1) ;

mean_switch                                   = cell(n_versions,1) ; 
mean_switch_gain                              = cell(n_versions,1) ; 
mean_switch_loss                              = cell(n_versions,1) ; 
mean_switch_stable                            = cell(n_versions,1) ;
mean_switch_volatile                          = cell(n_versions,1) ; 
mean_switch_difference_valence                = cell(n_versions,1) ; 
mean_switch_difference_volatility             = cell(n_versions,1) ; 
mean_switch_difference_valence_volatility     = cell(n_versions,1) ;

mean_confidence                               = cell(n_versions,1) ; 
overconfidence                                = cell(n_versions,1) ; 
mean_confidence_gain                          = cell(n_versions,1) ; 
mean_confidence_loss                          = cell(n_versions,1) ; 
mean_confidence_stable                        = cell(n_versions,1) ; 
mean_confidence_volatile                      = cell(n_versions,1) ; 
mean_confidence_difference_valence            = cell(n_versions,1) ; 
mean_confidence_difference_volatility         = cell(n_versions,1) ; 
mean_confidence_difference_valence_volatility = cell(n_versions,1) ;
mean_confidence_difference_correct            = cell(n_versions,1) ;

median_RT                                   = cell(n_versions,1) ; 
median_RT_gain                              = cell(n_versions,1) ; 
median_RT_loss                              = cell(n_versions,1) ; 
median_RT_stable                            = cell(n_versions,1) ;
median_RT_volatile                          = cell(n_versions,1) ; 
median_RT_difference_valence                = cell(n_versions,1) ; 
median_RT_difference_volatility             = cell(n_versions,1) ; 
median_RT_difference_valence_volatility     = cell(n_versions,1) ;
median_RT_difference_correct            = cell(n_versions,1) ;



for v = 1:n_versions

    % get data for current version 
    data = data_array_by_version{v};

    % set useful variables
    n_participants_version      = numel(unique(data.participant_ID));
    unique_participants_version = unique(data.participant_ID);
    
    % set which conditions correspond to low/no volatility and high volatility 
    if contains(version_names(v), "RL3") ||  contains(version_names(v), "RL1")
        % RL3 conditions: 1=low_volatility_gain; 2=_high_volatility_gain ; 3=low_volatility_loss; 4=_high_volatility_loss    
        % RL1 conditions: 1 = stable_gain; 2 = volatile_gain; 3 = stable_loss; 4 = volatile_loss
        low_volatility_conditions  = [1,3];
        high_volatility_conditions = [2,4];
    elseif contains(version_names(v), "RL0")
        % conditions: 1: gain & partial feedback ; 2: gain & complete feedback ; 3: loss & partialfeedback ; 4: loss & complete feedback
        high_volatility_conditions = [];
        low_volatility_conditions  = [1,2,3,4];
    else
        error("Unknown version name: %s", string(version_names(v)));

    end

    for p = 1:n_participants_version
        % create logical indexes to identify trials with different caracteristics
        index_generic   = data.timeout ~= 1 & data.participant_ID == unique_participants_version(p);
        index_loss      = data.valence==-1        & data.timeout ~= 1    & data.participant_ID == unique_participants_version(p);
        index_gain      = data.valence==1         & data.timeout ~= 1    & data.participant_ID == unique_participants_version(p);
        index_volatile  = ismember(data.condition,high_volatility_conditions)     & data.timeout ~= 1    & data.participant_ID == unique_participants_version(p);
        index_stable    = ismember(data.condition,low_volatility_conditions)      & data.timeout ~= 1    & data.participant_ID == unique_participants_version(p);
        index_correct   = data.chose_highest==1                  & data.timeout ~= 1    & data.participant_ID == unique_participants_version(p);
        index_incorrect = data.chose_highest==0                  & data.timeout ~= 1    & data.participant_ID == unique_participants_version(p);
  
        % fill in vector for task version v 
        task_versions{v}(p)         = unique(data.exp_ID(index_generic));
        participants{v}(p)          = unique_participants_version(p);
        interleaved_valence{v}(p)   = unique(data.interleaved_valence(index_generic));
        % skip feedback index for RL0_all design, since feedback is a within-participant condition there
        %{
        if unique(data.exp_ID(index_generic)) ~= "RL0_all"
            feedback{v}(p) = unique(data.full_feedback(index_generic));
        end
        %}

        mean_correct{v}(p) = mean(data.chose_highest(index_generic), "all",'omitnan');
        % pcorrect: gain  & loss
        mean_correct_gain{v}(p) = mean(data.chose_highest(index_gain), "all"); 
        mean_correct_loss{v}(p) = mean(data.chose_highest(index_loss), "all"); 
        % pcorrect: stable & volatile
        mean_correct_stable{v}(p) = mean(data.chose_highest(index_stable), "all");
        mean_correct_volatile{v}(p) = mean(data.chose_highest(index_volatile), "all");
        % pcorrect: gain - loss
        mean_correct_difference_valence{v}(p) = mean(data.chose_highest(index_gain), "all") - mean(data.chose_highest(index_loss), "all");
        % pcorrect: stable - volatile
        mean_correct_difference_volatility{v}(p) = mean(data.chose_highest(index_stable), "all") - mean(data.chose_highest(index_volatile), "all");
        % pcorrect: (gain_stable - gain_volatile) - (loss_stable - loss_volatile)
        mean_correct_difference_valence_volatility{v}(p) = (mean(data.chose_highest(index_gain & index_stable), "all") - mean(data.chose_highest(index_gain & index_volatile), "all")) - ... 
                                                           (mean(data.chose_highest(index_loss & index_stable), "all") - mean(data.chose_highest(index_loss & index_volatile), "all"));
       

        mean_switch{v}(p) = mean(data.switched_choice(index_generic), "all",'omitnan');
        % p_switch: gain & loss
        mean_switch_gain{v}(p) = mean(data.switched_choice(index_gain), "all");
        mean_switch_loss{v}(p) = mean(data.switched_choice(index_loss), "all");
        % p_switch: stable & volatile
        mean_switch_stable{v}(p) = mean(data.switched_choice(index_stable), "all");
        mean_switch_volatile{v}(p) = mean(data.switched_choice(index_volatile), "all");
        % p_switch: loss - gain
        mean_switch_difference_valence{v}(p) = mean(data.switched_choice(index_loss), "all") - mean(data.switched_choice(index_gain), "all");
        % p_switch: volatile - stable
        mean_switch_difference_volatility{v}(p) = mean(data.switched_choice(index_volatile), "all") - mean(data.switched_choice(index_stable), "all");
        % p_switch: (loss_volatile - loss_stable) - (gain_volatile - gain_stable)
        mean_switch_difference_valence_volatility{v}(p) = (mean(data.switched_choice(index_loss & index_volatile ), "all") - mean(data.switched_choice(index_loss & index_stable), "all")) - ... 
                                                          (mean(data.switched_choice(index_gain & index_volatile), "all") - mean(data.switched_choice(index_gain & index_stable), "all"));


        mean_confidence{v}(p) = mean(data.confidence_rating(index_generic), "all",'omitnan');
        overconfidence{v}(p)  = mean_confidence{v}(p) - (100*mean_correct{v}(p));
        % confidence: correct - incorrect
        mean_confidence_difference_correct{v}(p) = mean(data.confidence_rating(index_correct), "all") - mean(data.confidence_rating(index_incorrect), "all");
        % confidence: gain & loss
        mean_confidence_gain{v}(p) = mean(data.confidence_rating(index_gain), "all");
        mean_confidence_loss{v}(p) = mean(data.confidence_rating(index_loss), "all");
        % confidence: stable & volatile
        mean_confidence_stable{v}(p) = mean(data.confidence_rating(index_stable), "all");
        mean_confidence_volatile{v}(p) = mean(data.confidence_rating(index_volatile), "all");
        % confidence: gain - loss
        mean_confidence_difference_valence{v}(p) = mean(data.confidence_rating(index_gain), "all") - mean(data.confidence_rating(index_loss), "all");
        % confidence: stable - volatile
        mean_confidence_difference_volatility{v}(p) = mean(data.confidence_rating(index_stable), "all") - mean(data.confidence_rating(index_volatile), "all");
        % confidence: (gain_stable - gain_volatile) - (loss_stable - loss_volatile)
        mean_confidence_difference_valence_volatility{v}(p) = (mean(data.confidence_rating(index_gain & index_stable), "all") - mean(data.confidence_rating(index_gain & index_volatile), "all")) - ... 
                                                              (mean(data.confidence_rating(index_loss & index_stable), "all") - mean(data.confidence_rating(index_loss & index_volatile), "all"));


        median_RT{v}(p) = median(data.rt_choice(index_generic), "all",'omitnan');
        % RT: correct - incorrect
        median_RT_difference_correct{v}(p) = median(data.rt_choice(index_correct), "all") - median(data.rt_choice(index_incorrect), "all");
        % RT: gain & loss
        median_RT_gain{v}(p) = median(data.rt_choice(index_gain), "all");
        median_RT_loss{v}(p) = median(data.rt_choice(index_loss), "all");
        % RT: stable & volatile
        median_RT_stable{v}(p) = median(data.rt_choice(index_stable), "all");
        median_RT_volatile{v}(p) = median(data.rt_choice(index_volatile), "all");
        % RT: gain - loss
        median_RT_difference_valence{v}(p) = median(data.rt_choice(index_gain), "all") - median(data.rt_choice(index_loss), "all");
        % RT: stable - volatile
        median_RT_difference_volatility{v}(p) = median(data.rt_choice(index_stable), "all") - median(data.rt_choice(index_volatile), "all");
        % RT: (gain_stable - gain_volatile) - (loss_stable - loss_volatile)
        median_RT_difference_valence_volatility{v}(p) = (median(data.rt_choice(index_gain & index_stable), "all") - median(data.rt_choice(index_gain & index_volatile), "all")) - ... 
                                                              (median(data.rt_choice(index_loss & index_stable), "all") - median(data.rt_choice(index_loss & index_volatile), "all"));


    end


    % make vectors into table columns 
    col_task_versions                                 = [ col_task_versions                                 ; task_versions{v}' ];
    col_participants                                  = [ col_participants                                  ; participants{v}' ];
    col_interleaved_valence                           = [ col_interleaved_valence                           ; interleaved_valence{v}' ];
    %{
    if unique(data.exp_ID(index_generic)) ~= "RL0_all"
        col_feedback                                      = [ col_feedback                                      ; feedback{v}' ];
    end
    %}
    col_mean_correct                                  = [ col_mean_correct                                  ; mean_correct{v}' ];
    col_mean_correct_gain                             = [ col_mean_correct_gain                             ; mean_correct_gain{v}' ];
    col_mean_correct_loss                             = [ col_mean_correct_loss                             ; mean_correct_loss{v}' ];
    col_mean_correct_difference_valence               = [ col_mean_correct_difference_valence               ; mean_correct_difference_valence{v}' ];
    col_mean_correct_difference_volatility            = [ col_mean_correct_difference_volatility            ; mean_correct_difference_volatility{v}' ];
    col_mean_correct_difference_valence_volatility    = [ col_mean_correct_difference_valence_volatility    ; mean_correct_difference_valence_volatility{v}' ];

    col_mean_switch                                   = [ col_mean_switch                                   ; mean_switch{v}' ];
    col_mean_switch_gain                              = [ col_mean_switch_gain                              ; mean_switch_gain{v}' ];
    col_mean_switch_loss                              = [ col_mean_switch_loss                              ; mean_switch_loss{v}' ];
    col_mean_switch_stable                            = [ col_mean_switch_stable                            ; mean_switch_stable{v}' ];
    col_mean_switch_volatile                          = [ col_mean_switch_volatile                          ; mean_switch_volatile{v}' ];
    col_mean_switch_difference_valence                = [ col_mean_switch_difference_valence                ; mean_switch_difference_valence{v}' ];
    col_mean_switch_difference_volatility             = [ col_mean_switch_difference_volatility             ; mean_switch_difference_volatility{v}' ];
    col_mean_switch_difference_valence_volatility     = [ col_mean_switch_difference_valence_volatility     ; mean_switch_difference_valence_volatility{v}' ];

    col_mean_confidence                               = [ col_mean_confidence                               ; mean_confidence{v}' ];
    col_overconfidence                                = [ col_overconfidence                                ; overconfidence{v}' ];
    col_mean_confidence_gain                          = [ col_mean_confidence_gain                          ; mean_confidence_gain{v}' ];
    col_mean_confidence_loss                          = [ col_mean_confidence_loss                          ; mean_confidence_loss{v}' ];
    col_mean_confidence_difference_valence            = [ col_mean_confidence_difference_valence            ; mean_confidence_difference_valence{v}' ];
    col_mean_confidence_difference_volatility         = [ col_mean_confidence_difference_volatility         ; mean_confidence_difference_volatility{v}' ];
    col_mean_confidence_difference_valence_volatility = [ col_mean_confidence_difference_valence_volatility ; mean_confidence_difference_valence_volatility{v}' ];

    col_median_RT                               = [ col_median_RT                               ; median_RT{v}' ];
    col_median_RT_gain                          = [ col_median_RT_gain                          ; median_RT_gain{v}' ];
    col_median_RT_loss                          = [ col_median_RT_loss                          ; median_RT_loss{v}' ];
    col_median_RT_difference_valence            = [ col_median_RT_difference_valence            ; median_RT_difference_valence{v}' ];
    col_median_RT_difference_volatility         = [ col_median_RT_difference_volatility         ; median_RT_difference_volatility{v}' ];
    col_median_RT_difference_valence_volatility = [ col_median_RT_difference_valence_volatility ; median_RT_difference_valence_volatility{v}' ];

end

%% create output structure for vectors
my_vectors = struct();
my_vectors.task_versions                                 = task_versions;
my_vectors.participants                                  = participants ; 
my_vectors.interleaved_valence                           = interleaved_valence ; 
my_vectors.feedback                                      = feedback ; 

my_vectors.mean_correct                                  = mean_correct ; 
my_vectors.mean_correct_gain                             = mean_correct_gain ; 
my_vectors.mean_correct_loss                             = mean_correct_loss ; 
my_vectors.mean_correct_stable                           = mean_correct_stable ; 
my_vectors.mean_correct_volatile                         = mean_correct_volatile ; 
my_vectors.mean_correct_difference_valence               = mean_correct_difference_valence ; 
my_vectors.mean_correct_difference_volatility            = mean_correct_difference_volatility ; 
my_vectors.mean_correct_difference_valence_volatility    = mean_correct_difference_valence_volatility ;

my_vectors.mean_switch                                   = mean_switch ; 
my_vectors.mean_switch_gain                              = mean_switch_gain ; 
my_vectors.mean_switch_loss                              = mean_switch_loss ; 
my_vectors.mean_switch_stable                            = mean_switch_stable ;
my_vectors.mean_switch_volatile                          = mean_switch_volatile ; 
my_vectors.mean_switch_difference_valence                = mean_switch_difference_valence ; 
my_vectors.mean_switch_difference_volatility             = mean_switch_difference_volatility ; 
my_vectors.mean_switch_difference_valence_volatility     = mean_switch_difference_valence_volatility ;

my_vectors.mean_confidence                               = mean_confidence ; 
my_vectors.overconfidence                                = overconfidence ; 
my_vectors.mean_confidence_gain                          = mean_confidence_gain ; 
my_vectors.mean_confidence_loss                          = mean_confidence_loss ; 
my_vectors.mean_confidence_stable                        = mean_confidence_stable ; 
my_vectors.mean_confidence_volatile                      = mean_confidence_volatile ; 
my_vectors.mean_confidence_difference_valence            = mean_confidence_difference_valence ; 
my_vectors.mean_confidence_difference_volatility         = mean_confidence_difference_volatility ; 
my_vectors.mean_confidence_difference_valence_volatility = mean_confidence_difference_valence_volatility ;
my_vectors.mean_confidence_difference_correct            = mean_confidence_difference_correct ;

my_vectors.median_RT                               = median_RT ; 
my_vectors.median_RT_gain                          = median_RT_gain ; 
my_vectors.median_RT_loss                          = median_RT_loss ; 
my_vectors.median_RT_stable                        = median_RT_stable ; 
my_vectors.median_RT_volatile                      = median_RT_volatile ; 
my_vectors.median_RT_difference_valence            = median_RT_difference_valence ; 
my_vectors.median_RT_difference_volatility         = median_RT_difference_volatility ; 
my_vectors.median_RT_difference_valence_volatility = median_RT_difference_valence_volatility ;
my_vectors.median_RT_difference_correct            = median_RT_difference_correct ;


%% Combine columns into table for ANOVA stats
my_table = table(col_task_versions, col_participants, col_interleaved_valence, ... % col_feedback,...
                    col_mean_correct, ...
                    col_mean_correct_gain, ...
                    col_mean_correct_loss, ...
                    col_mean_correct_difference_valence, ...
                    col_mean_correct_difference_volatility, ...
                    col_mean_correct_difference_valence_volatility, ...                    
                    col_mean_switch, ...
                    col_mean_switch_gain, ...
                    col_mean_switch_loss, ...
                    col_mean_switch_stable, ...
                    col_mean_switch_volatile, ...
                    col_mean_switch_difference_valence, ...
                    col_mean_switch_difference_volatility, ...
                    col_mean_switch_difference_valence_volatility, ...
                    col_mean_confidence, ...
                    col_overconfidence, ...
                    col_mean_confidence_gain, ...
                    col_mean_confidence_loss, ...
                    col_mean_confidence_difference_valence, ...
                    col_mean_confidence_difference_volatility, ...
                    col_mean_confidence_difference_valence_volatility, ...                   
                    col_median_RT, ...
                    col_median_RT_gain, ...
                    col_median_RT_loss, ...
                    col_median_RT_difference_valence, ...
                    col_median_RT_difference_volatility, ...
                    col_median_RT_difference_valence_volatility ...    
                    ) ; 
% change some variables to categorical variables (necessary for ANOVAs)
my_table.col_task_versions           = categorical(my_table.col_task_versions);
my_table.col_participants            = categorical(my_table.col_participants);
my_table.col_interleaved_valence     = categorical(my_table.col_interleaved_valence);
% my_table.col_feedback                = categorical(my_table.col_feedback);    

clear col_task_versions ...
    col_participants ...
    col_interleaved_valence ...
    col_mean_correct ...
    col_mean_correct_gain ...
    col_mean_correct_loss ...
    col_mean_correct_difference_valence ...
    col_mean_correct_difference_volatility ...
    col_mean_correct_difference_valence_volatility ...
    col_mean_switch ...
    col_mean_switch_gain ...
    col_mean_switch_loss ...
    col_mean_switch_stable ...
    col_mean_switch_volatile ...
    col_mean_switch_difference_valence ...
    col_mean_switch_difference_volatility ...
    col_mean_switch_difference_valence_volatility ...
    col_mean_confidence ...
    col_overconfidence ...
    col_mean_confidence_gain ...
    col_mean_confidence_loss ...
    col_mean_confidence_difference_valence ...
    col_mean_confidence_difference_volatility ...
    col_mean_confidence_difference_valence_volatility ...
    col_median_RT ...
    col_median_RT_gain ...
    col_median_RT_loss ...
    col_median_RT_difference_valence ...
    col_median_RT_difference_volatility ...
    col_median_RT_difference_valence_volatility ...

end % function