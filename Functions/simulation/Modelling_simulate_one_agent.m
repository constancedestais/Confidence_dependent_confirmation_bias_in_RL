function [output_stucture] = Modelling_simulate_one_agent(model,params,reward_schedule,correct_schedule,full_feedback_schedule,condition_schedule,real_confidence,confidence_generation_method)
%% simulation timeseries: uses set parameters and choice function to determine actions and then learn (with Q values)
%{ 

INPUTS (all are participant-level data)
    - model (int) : one number
    - params : matrix (1 x n_parameters_in_model)
    - reward_schedule : matrix (n_sessions x n_conditions x n_trials x n_options_per_trial)
    - correct_schedule : matrix (n_sessions x n_conditions x n_trials)
    - full_feedback_schedule : matrix (n_sessions x n_conditions x n_trials)
    - condition_schedule : matrix (n_sessions x n_conditions x n_trials)
    - real_confidence : matrix (n_sessions x n_conditions x n_trials)

GOAL
    This function contains an RL algorithm which it runs to record the variables at each time step
    Steps: 
    1. get P(A) using set parameters and Q values
    2. get choice by comparing P(A) to random number
    3. using choice and outcome matrix, get "actual" reward on that trial (similarly can get counterfactual reward)
    4. update Q values as do in non-simulation scripts
%}

    % Task characteristics
    [n_sess, n_cond, n_trial] = size(correct_schedule);
    
    % sanity checks
    assert(size(params, 1) == 1, '\nModelling_simulate_one_agent(): problem with inputs. "params" must have only one row (it reflects parameters for one agent)\n');
    assert(isequal(size(reward_schedule),       [n_sess, n_cond, n_trial, 2]), '\nModelling_simulate_one_agent(): problem with inputs. "reward_schedule" must be of size: n_sessions x n_conditions x n_trials x n_options_per_trial\n');
    assert(isequal(size(correct_schedule),      [n_sess, n_cond, n_trial]), '\nModelling_simulate_one_agent(): problem with inputs. "correct_schedule" must be of size: n_sessions x n_conditions x n_trials\n');
    assert(isequal(size(full_feedback_schedule),[n_sess, n_cond, n_trial]), '\nModelling_simulate_one_agent(): problem with inputs. "full_feedback_schedule" must be of size: n_sessions x n_conditions x n_trials\n');
    assert(isequal(size(condition_schedule),    [n_sess, n_cond, n_trial]), '\nModelling_simulate_one_agent(): problem with inputs. "condition_schedule" must be of size: n_sessions x n_conditions x n_trials\n');
    assert(isequal(size(real_confidence),       [n_sess, n_cond, n_trial]), '\nModelling_simulate_one_agent(): problem with inputs. "real_confidence" must be of size: n_sessions x n_conditions x n_trials\n');
    
    % initialise hidden variables that this scripts outputs
    Q                = ones(n_sess,n_cond,n_trial,2)*88888888;
    actions          = ones(n_sess,n_cond,n_trial)*88888888; % = stim 1 or stim 2
    outcomes         = ones(n_sess,n_cond,n_trial)*88888888; 
    cf_outcomes      = ones(n_sess,n_cond,n_trial)*88888888; 
    correct          = ones(n_sess,n_cond,n_trial)*88888888; % = 0 or 1
    confidence       = ones(n_sess,n_cond,n_trial)*88888888; % = 0-1
    switched_choice  = ones(n_sess,n_cond,n_trial)*88888888; % = 0 or 1
    chose_symbol_1   = ones(n_sess,n_cond,n_trial)*88888888;
    % symbol_1_actual_payoff = ones(n_sess,n_cond,n_trial)*88888888; 
    % symbol_2_actual_payoff = ones(n_sess,n_cond,n_trial)*88888888; 
    
    % loop over sessions
    for s = 1:n_sess
    
        for c = 1:n_cond
        
            Q(s,c,1,[1 2])  = [0,0];   % Initial option values (all Models) as a function of condition 
        
            for t = 1:n_trial
    
                % check for NaN values, if NaN, fill ouput variables with NaNs (except Q values) and move on to next trial
                % NaN values reflects either a missed trial OR that experiments of different sizes are combined in a matrix
                if isnan(correct_schedule(s,c,t)) || isnan(real_confidence(s,c,t)) || (isnan(reward_schedule(s,c,t,1)) && isnan(reward_schedule(s,c,t,2))) 
                    % fill in variables with NaN (except Q values which should stay the same)
                    actions(s,c,t) = NaN;
                    outcomes(s,c,t) = NaN;
                    cf_outcomes(s,c,t) = NaN;
                    correct(s,c,t) = NaN;
                    confidence(s,c,t) = NaN;
                else
                    % create set of inputs
                    input = {};
                    input.params                 = params;
                    input.Q                      = squeeze(Q(s,c,t,:));
                    input.reward_schedule        = squeeze(reward_schedule(s,c,t,:));
                    input.correct_schedule       = correct_schedule(s,c,t);
                    input.full_feedback_schedule = full_feedback_schedule(s,c,t);
                    input.condition_schedule     = condition_schedule(s,c,t);
                    input.real_confidence        = real_confidence(s,c,t);
                    input.confidence_generation_method = confidence_generation_method;
        
                    % checks for debugging
                    assert(numel(input.Q) == 2, "Problem: with inputs for model simulation functions - there should be 2 values in variable Q")
                    assert(numel(input.reward_schedule) == 2, "Problem: with inputs for model simulation functions - there should be 2 values in variable reward_schedule")                
                    assert(numel(input.correct_schedule) == 1, "Problem: with inputs for model simulation functions - there should be 1 value in variable correct_schedule")
                    assert(~isnan(input.correct_schedule), "Problem: with inputs for model simulation functions - there should not be NaNs in variable correct_schedule")    
                    assert(numel(input.full_feedback_schedule) == 1, "Problem: with inputs for model simulation functions - there should be 1 value in variable full_feedback_schedule")
                    assert(~isnan(input.full_feedback_schedule), "Problem: with inputs for model simulation functions - there should not be NaNs in variable full_feedback_schedule")    
                    assert(numel(input.condition_schedule) == 1, "Problem: with inputs for model simulation functions - there should be 1 value in variable condition")
                    assert(~isnan(input.condition_schedule), "Problem: with inputs for model simulation functions - there should not be NaNs in variable condition")
        
                    % prepare previous_confidence variable
                    if (t == 1 | isnan(confidence(s,c,t-1))) % if first trial or if previous confidence was NaN, fix at 0.75
                        input.previous_confidence = 0.75;   
                    else 
                        input.previous_confidence = confidence(s,c,t-1); % otherwise take previous confidence rating
                    end
        
                    switch model
                        % Model 1: Q-learning with 2 LR for confirmatory and disconfirmatory feedbacks
                        case 1 
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_1( input );
            
                        % Model 2: confidence-dependent Q-learning
                        case 2
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_2( input );
            
                        % Model 3: Q-learning + confidence-dependent choice temperature
                        case 3
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_3( input );
            
                        % Model 4: confidence-dependent Q-learning + confidence-dependent choice temperature
                        case 4
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_4( input );
            
                        % Model 5: confidence-dependent confirmatory Q-learning
                        case 5
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_5( input );
            
                        % Model 6: confidence-dependent disconfirmatory Q-learning
                        case 6
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_6( input );
                        
                        % Model 7: Q-learning with 1 LR (no confirmatory bias)
                        case 7
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_7( input );
                        
                        % Model 8: Q-learning with 4 LR for confirmatory/disconfirmatory X chosen/unchosen 
                        case 8
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_8( input );
                        
                        % Model 9: confidence-dependent learning, without differentiating confirmatory/disconfirmatory
                        case 9
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_9( input );
                       
                        % Model 10: confidence-dependent Q-learning with only one intercept
                        case 10
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_10( input );
                        
                        % Model 11: confidence-dependent Q-learning with only one intercept + confidence-dependent choice temperature
                        case 11
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_11( input );
            
                        % Model 12: Q-learning with 4 LR for valence x volatility, without differentiating confirmatory/disconfirmatory
                        case 12
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_12( input );
                        
                        % Model 13: Q-learning with 8 LR for valence x volatility x confirmatory/disconfirmatory 
                        case 13
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_13( input );
        
                        % Model 14: Q-learning with 4 LR for volatility x confirmatory/disconfirmatory 
                        case 14
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_14( input );
        
                        % Model 15: Q-learning with 4 LR for valence x confirmatory/disconfirmatory 
                        case 15
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_15( input );
                        % Model 16: Q learning with confidence-dependent learning: valence x confirmatory/disconfirmatory 
                        case 16 
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_16( input );
                        % Model 17: Q learning with confidence-dependent choice & confidence-dependent learning: valence x confirmatory/disconfirmatory 
                        case 17 
                            [Q(s,c,t+1,:),actions(s,c,t),outcomes(s,c,t),cf_outcomes(s,c,t),correct(s,c,t),confidence(s,c,t)] = generate_model_17( input );
                        %%
                        otherwise 
                            warning('Model %t does not exist in generate_data.m', model)
                            return
                    end 
            
                    assert(~isnan(confidence(s,c,t)),'Problem: in the simulations, confidence should not be equal to NaN in simulations')

                    assert(sum(isnan(Q(s,c,t+1,:)))==0,'Problem: in the simulations, Q-values must never be equal to NaN, because they will be stuck at NaN values from then on')
                    % temporary
                    if (t == n_trial)
                        Q(s,c,t+1,1) = NaN;
                        Q(s,c,t+1,2) = NaN;
                        %confidence(s,c,t+1) = NaN;
                    end
     
                    clear input
                end
            end
        end
    end
    
    %% fill in extra variables which can be deduced from the principal variables we have just computed
    
    % fill in switched_choice variable reflecting whether a participant changed their choice from one trial to the next
    next_action_differs_from_previous_action = (actions(:,:,2:end) ~= actions(:,:,1:end-1));
    switched_choice(next_action_differs_from_previous_action) = 1;
    % switched_choice is always 0 on first trial
    switched_choice(:,:,1) = 0;
    % switched_choice is NaN on trials where there was no choice
    switched_choice(isnan(actions)) = NaN;
    
    % fill in chose_symbol_1
    chose_symbol_1(actions == 1) = 1;
    chose_symbol_1(actions == 2) = 0;
    chose_symbol_1(isnan(actions)) = NaN;
    
    %{
    % fill in symbol_1_actual_payoff & symbol_2_actual_payoff
    % create temporary variables for current condition
    symbol_1_actual_payoff_here = symbol_1_actual_payoff(s,c,:);
    symbol_2_actual_payoff_here = symbol_2_actual_payoff(s,c,:);
    outcomes_here               = outcomes(s,c,:);    
    cf_outcomes_here            = cf_outcomes(s,c,:); 
    actions_here                = actions(s,c,:);
    % use information about chosen opetion (action) and about obtained outcome (outcome) vs counterfactual outcome (cf_outcome) to fill in the two temporary variables
    symbol_1_actual_payoff_here(actions_here == 1) = outcomes_here(actions_here == 1);        
    symbol_2_actual_payoff_here(actions_here == 2) = outcomes_here(actions_here == 2);
    symbol_1_actual_payoff_here(actions_here == 2) = cf_outcomes_here(actions_here == 2);
    symbol_2_actual_payoff_here(actions_here == 1) = cf_outcomes_here(actions_here == 1);
    % replace temporary variables in main variables
    symbol_1_actual_payoff(s,c,:) = symbol_1_actual_payoff_here;
    symbol_2_actual_payoff(s,c,:) = symbol_2_actual_payoff_here;
    clear symbol_1_actual_payoff_here symbol_2_actual_payoff_here outcomes_here cf_outcomes_here actions_here
    %}
    
    % combine the variables into a structure for the output
    output_stucture = {};
    output_stucture.symbol_chosen_id_relative     = actions;
    output_stucture.symbol_chosen_actual_payoff   = outcomes;
    output_stucture.symbol_unchosen_actual_payoff = cf_outcomes;
    output_stucture.chose_highest                 = correct;
    output_stucture.confidence_rating             = confidence;
    output_stucture.switched_choice               = switched_choice;
    output_stucture.chose_symbol_1                = chose_symbol_1;
    % output_stucture.symbol_1_actual_payoff      = symbol_1_actual_payoff;
    % output_stucture.symbol_2_actual_payoff      = symbol_2_actual_payoff;
    
    %% sanity checks

    % check NaN values    assert(sum( isnan(output_stucture.confidence_rating ), "all") == 0, "There are still NaN confidence values in data.")
    assert(sum( isnan(output_stucture.chose_symbol_1 ), "all") == 0, "There are still NaN chose_symbol_1 values in data.")
    assert(sum( isnan(output_stucture.symbol_chosen_actual_payoff ), "all") == 0, "There are still NaN symbol_chosen_actual_payoff values in data.")

    % check if fields still contain value used to initialise (88888888)
    fields = fieldnames(output_stucture);
    for i = 1:length(fields)
        field = fields{i};
        % Check if the field contains numeric data
        if isnumeric(output_stucture.(field))
            % Use assert to check for forbidden value
            assert(~any(output_stucture.(field)(:) == 8888888),'Field "%s" contains the forbidden value 8888888 (used to initialise matrices)', field);
        end
    end
    
    % check size
    %assert( isequal(unique( output_stucture.symbol_chosen_id_relative ), [1;2]) , 'Problem: the only values in chosen_SUBJ should be 1 and 2' ) ;
    assert( isequal(size(   output_stucture.symbol_chosen_id_relative ), [n_sess, n_cond, n_trial]) ,   'Problem: the dimensions of symbol_chosen_id_relative should be: n_sess, n_cond, n_trial' ) ;  
    assert( isequal(size(   output_stucture.symbol_chosen_actual_payoff ), [n_sess, n_cond, n_trial]) ,   'Problem: the dimensions of symbol_chosen_actual_payoff should be: n_sess, n_cond, n_trial' ) ;
    assert( isequal(size(   output_stucture.symbol_unchosen_actual_payoff ), [n_sess, n_cond, n_trial]) ,   'Problem: the dimensions of symbol_chosen_actual_payoff should be: n_sess, n_cond, n_trial' ) ;
    %assert( isequal(unique( output_stucture.chose_highest ), [0;1]) , 'Problem: the only values in chosen_SUBJ should be 0 and 1' ) ;
    assert( isequal(size(   output_stucture.chose_highest ), [n_sess, n_cond, n_trial]) ,   'Problem: the dimensions of chose_highest should be: n_sess, n_cond, n_trial' ) ;
    %assert( isequal(size(   output_stucture.confidence_rating ), [n_sess, n_cond, n_trial+1]) , 'Problem: the dimensions of confidence_rating should be: n_sess, n_cond, n_trial+1' ) ;
    assert( isequal(size(   output_stucture.confidence_rating ), [n_sess, n_cond, n_trial]) , 'Problem: the dimensions of confidence_rating should be: n_sess, n_cond, n_trial+1' ) ;
    assert( isequal(size(   output_stucture.switched_choice ), [n_sess, n_cond, n_trial]) ,   'Problem: the dimensions of switched_choice should be: n_sess, n_cond, n_trial' ) ;
    
    % check for NaNs
    % CONSTANCE: TO BE DEALT WITH
    %{
    assert( sum(isnan(output_stucture.symbol_chosen_id_relative),"all") < numel(output_stucture.symbol_chosen_id_relative) , 'Problem, symbol_chosen_id_relative is full of NaNs');
    assert( sum(isnan(output_stucture.symbol_chosen_actual_payoff),"all") < numel(output_stucture.symbol_chosen_actual_payoff) , 'Problem, symbol_chosen_actual_payoff is full of NaNs');
    assert( sum(isnan(output_stucture.symbol_unchosen_actual_payoff),"all") < numel(output_stucture.symbol_unchosen_actual_payoff) , 'Problem, symbol_unchosen_actual_payoff is full of NaNs');
    assert( sum(isnan(output_stucture.chose_highest),"all") < numel(output_stucture.chose_highest) , 'Problem, chose_highest is full of NaNs');
    assert( sum(isnan(output_stucture.confidence_rating),"all") < numel(output_stucture.confidence_rating) , 'Problem, confidence_rating is full of NaNs');
    assert( sum(isnan(output_stucture.switched_choice),"all") < numel(output_stucture.switched_choice) , 'Problem, switched_choice is full of NaNs');
    %}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

