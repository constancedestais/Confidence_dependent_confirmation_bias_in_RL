function [reward_schedule, correct_schedule, reversal_schedule, valence_schedule, full_feedback_schedule, n_reversals_per_block] = generate_reward_schedule_one_agent(dataset_name, n_sessions, fixed_reversal_schedule)
    
    %{ 
    outputs: 
    - reward_schedule, size n_sessions x n_conditions x n_trials x n_symbols
    - correct_schedule, size n_sessions x n_conditions x n_trials
    %}

    assert(fixed_reversal_schedule == 1 | fixed_reversal_schedule ==0, 'Problem, "fixed_reversal_schedule" input to function must be equal to 0 or 1')

    %% prepare variables for task schedule except for feedback type
    if contains(dataset_name,['RL3'])
        % set useful variables
        n_conditions = 4;
        max_n_trials_by_cond = 40;
        n_symbols = 2;
        high_reward_probability = [0.2,0.8];
        % conditions: 1=low_volatility_gain; 2=_high_volatility_gain ; 3=low_volatility_loss; 4=_high_volatility_loss
        rewards_by_condition               = { [0.1,1], [0.1,1],     [-1,-0.1],  [-1,-0.1]  }; % [low,high]
        valence_by_condition               = { 1,        1,           -1,         -1        };
        % trials on/around which reversals happen 
        fixed_reversal_trial_number_by_condition = { [20],    [10,20,30],  [20],       [10,20,30] };

    elseif contains(dataset_name,["RL1"])
        % set useful variables
        n_conditions = 4;
        max_n_trials_by_cond = 30;
        n_symbols = 2;
        high_reward_probability = [0.2,0.8];
        % conditions: 1=low_volatility_gain; 2=_high_volatility_gain ; 3=low_volatility_loss; 4=_high_volatility_loss
        rewards_by_condition               = { [0.1,1], [0.1,1],     [-1,-0.1],  [-1,-0.1]  }; % [low,high]
        valence_by_condition               = { 1,        1,           -1,         -1        };
        % trials on/around which reversals happen 
        fixed_reversal_trial_number_by_condition = { [],    [15],  [],       [15] };

    elseif contains(dataset_name,["RL0"])
        % set useful variables
        n_conditions = 4;
        max_n_trials_by_cond = 24;
        n_symbols = 2;
        high_reward_probability = [0.2,0.8];
        % conditions: 1="partial_info_gain"; 2="full_info_gain"; 3="partial_info_loss"; 4="full_info_loss"]; 
        rewards_by_condition               = { [0.1,1], [0.1,1],     [-1,-0.1],  [-1,-0.1]  }; % [low,high]
        valence_by_condition               = { 1,        1,           -1,         -1        };
        % trials on/around which reversals happen 
        fixed_reversal_trial_number_by_condition = { [], [], [], [] };
    else
        msg = sprintf("Please request a different version name, other than %s",version_name);
        error(msg)
    end

    %% prepare variable for feedback type
    if contains(dataset_name,['RL3_partialfeedback', "RL1_partialfeedback"])
        full_feedback_by_condition = { 0, 0, 0, 0 };
    elseif contains(dataset_name,["RL3_completefeedback", "RL1_completefeedback" ])
        full_feedback_by_condition = { 1, 1, 1, 1 };
    elseif contains(dataset_name,["RL0_all"])
        full_feedback_by_condition = { 0, 1, 0, 1 };
    elseif contains(dataset_name,["RL0_partialfeedbacktrials"])
        full_feedback_by_condition = { 0, NaN, 0, NaN };
    elseif contains(dataset_name,["RL0_completefeedbacktrials"])
        full_feedback_by_condition = { NaN, 1, NaN, 1 };
    else 
        msg = sprintf("Please request a different version name which corresponds to a particular type of feedback (partial/complete), other than %s",version_name);
        error(msg)
    end


    %% set trials on which reversals occured - can be exactly same trial(s) or approximately same trial(s) for everyone
    if (fixed_reversal_schedule == 1)        
        reversal_trial_number_by_condition = fixed_reversal_trial_number_by_condition;    
    elseif  (fixed_reversal_schedule == 0) % different reversal schedule for each participant
        % set reversal to occur within ±2 trials around the fixed reversal trial number
        t = 2; 
        reversal_trial_number_by_condition = cell(1,numel(fixed_reversal_trial_number_by_condition));
        for i = 1:numel(fixed_reversal_trial_number_by_condition)
            % sample trial number from a range of ±t trials around each of the fixed trial numbers
            reversal_trial_number_by_condition{i} = NaN(0,numel(fixed_reversal_trial_number_by_condition{i})); 
            if isempty(fixed_reversal_trial_number_by_condition{i})
               reversal_trial_number_by_condition{i} = [];
            else
                for k = 1:numel(fixed_reversal_trial_number_by_condition{i})
                    reference_trial_number = fixed_reversal_trial_number_by_condition{i}(k);
                    reversal_trial_number_by_condition{i}(k) = randi([reference_trial_number-t,reference_trial_number+t]);
                end
            end
            clear sampled_reversal_trials
        end
    end

    %% loop over matrix dimensions to prepare final schedule matrices

    % initialise output variables with impossible values (88888888)
    reward_schedule   = ones( n_sessions, n_conditions, max_n_trials_by_cond, n_symbols )*88888888;
    correct_schedule  = ones( n_sessions, n_conditions, max_n_trials_by_cond )*88888888;
    valence_schedule  = ones( n_sessions, n_conditions, max_n_trials_by_cond )*88888888;
    full_feedback_schedule = ones( n_sessions, n_conditions, max_n_trials_by_cond )*88888888;
    n_reversals_per_block   = ones( n_sessions, n_conditions, 1 )*88888888;
    % initialise reversal_schedule with zeros
    reversal_schedule       = zeros( n_sessions, n_conditions, max_n_trials_by_cond );
    symbol_1_actual_payoff  = ones( n_sessions, n_conditions, max_n_trials_by_cond )*88888888;
    symbol_2_actual_payoff  = ones( n_sessions, n_conditions, max_n_trials_by_cond )*88888888;

    % create temporary variables, initialised with random values between 0 and 1
    symbol_1_rand  = rand( n_sessions, n_conditions, max_n_trials_by_cond);    
    symbol_2_rand  = rand( n_sessions, n_conditions, max_n_trials_by_cond);  
    
    for k_sess = 1:n_sessions

        % iterate over all the conditions
        for k_cond = 1:n_conditions
    
            % split the trials in this condition according to the different reversals
            split_points = reversal_trial_number_by_condition{k_cond};
            trials = 1:max_n_trials_by_cond;
            % Use arrayfun to create the ranges for each section of trials
            all_points = [1, split_points, max_n_trials_by_cond + 1]; % Include 1 as the starting point and the length of trials as the endpoint
            split_trials = arrayfun(@(i) trials(all_points(i):(all_points(i+1)-1)), 1:length(all_points)-1, 'UniformOutput', false);
            
            % fill in reversal variable using known index of trials with reversals
            reversal_schedule(k_sess,k_cond,[split_points]) = 1;
    
            % iterate over all of the data, segmented by the reversals
            for k_subset = 1:numel(split_trials)
                % get current subset of trial numbers
                subset = split_trials{k_subset};
        
                % get current subset of data
                symbol1_payoff_subset = symbol_1_actual_payoff(k_sess,k_cond,subset);
                symbol2_payoff_subset = symbol_2_actual_payoff(k_sess,k_cond,subset);
                symbol_1_rand_subset  = symbol_1_rand(k_sess,k_cond,subset);
                symbol_2_rand_subset  = symbol_2_rand(k_sess,k_cond,subset);
        
                % get probability of high reward for symbol 1 and 2 on these trials
                % but we need to flip this each time ---> so if k_subset is odd, use high_reward_probability(2) but if k_subset is even, use high_reward_probability(1)
                symbol1_high_reward_probability = high_reward_probability(  mod(k_subset,2) + 1 ); % if k_subset is odd, use high_reward_probability(2) but if k_subset is even, use high_reward_probability(1)
                symbol2_high_reward_probability = high_reward_probability( -mod(k_subset,2) + 2 ); % if k_subset is odd, use high_reward_probability(1) but if k_subset is even, use high_reward_probability(2)
        
                % update symbol values (0: bad outcome, 1: good outcome)
                    % if the random value if below the high_reward_probability, then the outcome on this trial is the high outcome 
                    % BUT if the random value is above the high_reward_probability, then the outcome of this symbol on this trial is the low outcome
                symbol_1_gets_good_reward = symbol_1_rand_subset < symbol1_high_reward_probability ;
                symbol_2_gets_good_reward = symbol_2_rand_subset < symbol2_high_reward_probability ;
        
                % update which is the correct symbol during these trials 
                if symbol1_high_reward_probability > symbol2_high_reward_probability
                    correct_schedule(k_sess,k_cond,subset) = 1;
                else
                    correct_schedule(k_sess,k_cond,subset) = 2;
                end
                
                % sanity check, if k_subset == 1, then option 1 should have the highest reward probability
                if k_subset == 1
                    assert( unique(correct_schedule(k_sess,k_cond,k_subset)) == 1 , 'Problem: option 1 should have the highest reward probability when starting a new block/condition' ) ;
                end

                % sanity check
                assert( isequal(size(symbol1_payoff_subset),size(symbol_1_gets_good_reward))       , 'Problem: check size of variables - it should only be a subset of trials for one participant/session/condition' ) ;
                assert( isequal(size(symbol1_payoff_subset),size(symbol_1_rand_subset))            , 'Problem: check size of variables - it should only be a subset of trials for one participant/session/condition' ) ;

                % update symbol values depending on what is the good and bad outcome in the block
                symbol1_payoff_subset(symbol_1_gets_good_reward == 0) = rewards_by_condition{k_cond}(1); % bad outcome in this condition
                symbol1_payoff_subset(symbol_1_gets_good_reward == 1) = rewards_by_condition{k_cond}(2); % good outcome in this condition
                symbol2_payoff_subset(symbol_2_gets_good_reward == 0) = rewards_by_condition{k_cond}(1); % bad outcome in this condition
                symbol2_payoff_subset(symbol_2_gets_good_reward == 1) = rewards_by_condition{k_cond}(2); % good outcome in this condition
        
                % plug in values from temporary subsets back in the main variable
                symbol_1_actual_payoff(k_sess,k_cond,subset) = symbol1_payoff_subset ;
                symbol_2_actual_payoff(k_sess,k_cond,subset) = symbol2_payoff_subset ;
        
                clear subset symbol1_payoff_subset symbol2_payoff_subset symbol1_high_reward_probability symbol2_high_reward_probability symbol_1_rand_subset symbol_2_rand_subset
            end
            clear split_points trials all_points split_trials
        end

    end

    % plug in the values from the main variables in the output variable
    reward_schedule(:, :, :, 1) = symbol_1_actual_payoff;
    reward_schedule(:, :, :, 2) = symbol_2_actual_payoff;

    % set valence and full feedback variable
    for c = 1:n_conditions
        valence_schedule(:, c, :) = valence_by_condition{c};
        full_feedback_schedule(:, c, :) = full_feedback_by_condition{c};
        n_reversals_per_block(:, c, :) = numel(fixed_reversal_trial_number_by_condition{c});
    end

    % sanity checks
    switch dataset_name
    case 'RL3'
        assert( sum( reversal_schedule(1,1,:) ) == 1 , 'Problem: there should be 1 reversal in block 1' ) ;
        assert( sum( reversal_schedule(1,2,:) ) == 3 , 'Problem: there should be 3 reversals in block 2' ) ;
        assert( sum( reversal_schedule(1,3,:) ) == 1 , 'Problem: there should be 1 reversal in block 3' ) ;
        assert( sum( reversal_schedule(1,4,:) ) == 3 , 'Problem: there should be 3 reversals in block 4' ) ;

    case 'RL1'
        assert( sum( reversal_schedule(1,1,:) ) == 0 , 'Problem: there should be 0 reversals in block 1' ) ;
        assert( sum( reversal_schedule(1,2,:) ) == 1 , 'Problem: there should be 1 reversal in block 2' ) ;
        assert( sum( reversal_schedule(1,3,:) ) == 0 , 'Problem: there should be 0 reversals in block 3' ) ;
        assert( sum( reversal_schedule(1,4,:) ) == 1 , 'Problem: there should be 1 reversal in block 4' ) ;

    case 'RL0'
        assert( sum( reversal_schedule(1,1,:) ) == 0 , 'Problem: there should be 0 reversals in block 1' ) ;
        assert( sum( reversal_schedule(1,2,:) ) == 0 , 'Problem: there should be 0 reversals in block 2' ) ;
        assert( sum( reversal_schedule(1,3,:) ) == 0 , 'Problem: there should be 0 reversals in block 3' ) ;
        assert( sum( reversal_schedule(1,4,:) ) == 0 , 'Problem: there should be 0 reversals in block 4' ) ;
    end



end