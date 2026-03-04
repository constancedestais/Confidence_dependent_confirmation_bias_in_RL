function output = simulate_task_schedule( n_agents, ...
                                        generative_parameters_current_model, ...
                                        generative_model, ...
                                        real_behaviour, ...
                                        n_sessions, ...
                                        n_conditions, ...
                                        n_trials_by_cond, ...
                                        fixed_reversal_schedule, ...
                                        reward_schedule_generation_method, ...
                                        outcome_encoding_for_fitting, ...
                                        models_info, ...
                                        version_name)
    %{
    INPUTS
    - n_agents (int): number of simulated agents
    - generative_parameters_current_model
    - generative_model (int)
    - generative_parameters_current_model
    - real_behaviour: dataset from real participants containing similar variables
    - version_name
    - n_sessions
    - n_conditions
    - n_trials_by_cond
    - condition_names_all (vector of strings)
    - fixed_reversal_schedule (0/1)
    - reward_schedule_generation_method ("fake"/"real"): use real participant's reward schedule (same participant as for confidence) VS. generate new reward schedule
    - models_info
    
    OUTPUTS
    - structure with the following fields (all of the size n_agents x n_sessions x n_conditions x n_trials_by_cond, except generative_parameters and reward_schedule_SUBJ)
        [fields necessary for Modelling_simulate_dataset]
            - generative_parameters - contains matrix of size n_participants x n_parameters 
            - reward_schedule - combines symbol_1_actual_payoff and symbol_2_actual_payoff - size n_agents x n_sessions x n_conditions x n_trials_by_cond x 2
            - correct_schedule
            - condition
            - real_confidence
        [extra fields  for model fitting later on]
            - exp_ID                 
            - participant_ID
            - valence
            - session    
            - condition_name
            - trial_by_condition
            - reversal
            - symbol_1_actual_payoff
            - symbol_2_actual_payoff
    
    GOAL:
    - create the fields and format of output required for Modelling_simulate_one_agent() called in Modelling_simulate_dataset() 
    - also create the fields and format of output required later on when fitting the simulated data
    
    %}

    assert(strcmp(outcome_encoding_for_fitting, "actual"), "simulate_task_schedule.m: currently do not simulate with 'relative' or 'semi-relative' outcome encoding. Only 'actual' outcome encoding.")

    % double check that input data has the same number of conditions and n_trials by cond as requested
    assert(n_conditions == size(real_behaviour.exp_ID,3), '\nThe requested number of conditions (n_conditions) must be the same as those in the real_behaviour dataset, if you want to use real participant reward schedules and/or confidence.\')
    assert(n_trials_by_cond == size(real_behaviour.exp_ID,4), '\nThe requested number of trials (n_trials_by_cond) must be the same as those in the real_behaviour dataset, if you want to use real participant reward schedules and/or confidence.\n')
    
    % need to create extra variable in real dataframe
    % Initialize correct_schedule with the same size as the input matrices
    real_behaviour.correct_schedule = NaN(size(real_behaviour.exp_ID));
    % case 1: symbol 1 is the correct symbol
    idx1 = ((real_behaviour.chose_symbol_1 == 1) & (real_behaviour.chose_highest == 1)) | ...
           ((real_behaviour.chose_symbol_1 == 0) & (real_behaviour.chose_highest == 0));
    real_behaviour.correct_schedule(idx1) = 1;
    % case 2: symbol 2 is the correct symbol
    idx2 = ((real_behaviour.chose_symbol_1 == 1) & (real_behaviour.chose_highest == 0)) | ...
           ((real_behaviour.chose_symbol_1 == 0) & (real_behaviour.chose_highest == 1));
    real_behaviour.correct_schedule(idx2) = 2;
    
    % loop over agents I want to create
    for i_agent = 1:n_agents
    
        params_SUBJ = generative_parameters_current_model(i_agent,:);
        assert(numel(params_SUBJ)==models_info{generative_model}.param_num, "Problem: the # of generated parameters for this participant does not match the # of parameters in the model")
                    
        %% prepare data from real participants in case it is needed
     
        % select random participants from whom we will use real data 
        % may need more than one if we are requesting more sessions then there are per participant
        n_sessions_per_real_participant = size(real_behaviour.exp_ID,2);
        n_participants_needed_for_requested_number_of_sessions = ceil(n_sessions/n_sessions_per_real_participant);
        n_available_real_participants = size(real_behaviour.confidence_rating,1);
        randomly_selected_real_subjects = randi(n_available_real_participants, [1,n_participants_needed_for_requested_number_of_sessions]);

        % get real participants' confidence in any case -> whether we use this or generate new confidence is decided in the generate_confidence.m function later on 
        % initialise
        real_confidence_SUBJ        = NaN(n_sessions,n_conditions,n_trials_by_cond); 
        real_reward_schedule_SUBJ   = NaN(n_sessions,n_conditions,n_trials_by_cond,2); 
        real_correct_schedule_SUBJ  = NaN(n_sessions,n_conditions,n_trials_by_cond); 
        real_reversal_schedule_SUBJ = NaN(n_sessions,n_conditions,n_trials_by_cond); 
        real_valence_schedule_SUBJ  = NaN(n_sessions,n_conditions,n_trials_by_cond); 
        real_full_feedback_SUBJ     = NaN(n_sessions,n_conditions,n_trials_by_cond); 
        real_trial_by_condition_SUBJ = NaN(n_sessions,n_conditions,n_trials_by_cond); 
        real_n_reversals_per_block_SUBJ   = NaN(n_sessions,n_conditions,n_trials_by_cond);

        % Track sessions filled so far
        sessions_filled = 0;        
        % Loop over randomly selected participants
        for p = 1:length(randomly_selected_real_subjects)
            real_subject = randomly_selected_real_subjects(p);
            
            % Calculate how many sessions to take from this participant
            sessions_to_take = min(n_sessions_per_real_participant, n_sessions - sessions_filled); 

            % Define target indices in output matrix
            target_indices = sessions_filled+1 : sessions_filled+sessions_to_take;
            
            % Copy all sessions at once using array indexing
            % confidence
            real_confidence_SUBJ(target_indices,:,:) = real_behaviour.confidence_rating(real_subject, 1:sessions_to_take, :, :);  
            % task schedule
            real_reward_schedule_SUBJ(target_indices,:,:,1)  = real_behaviour.symbol_1_actual_payoff(real_subject, 1:sessions_to_take, :, :);
            real_reward_schedule_SUBJ(target_indices,:,:,2)  = real_behaviour.symbol_2_actual_payoff(real_subject, 1:sessions_to_take, :, :);
            real_correct_schedule_SUBJ(target_indices,:,:)   = real_behaviour.correct_schedule(real_subject, 1:sessions_to_take, :, :);
            real_reversal_schedule_SUBJ(target_indices,:,:)  = real_behaviour.reversal(real_subject, 1:sessions_to_take, :, :);
            real_valence_schedule_SUBJ(target_indices,:,:)   = real_behaviour.valence(real_subject, 1:sessions_to_take, :, :);
            real_full_feedback_SUBJ(target_indices,:,:)      = real_behaviour.full_feedback(real_subject, 1:sessions_to_take, :, :);
            real_trial_by_condition_SUBJ(target_indices,:,:) = real_behaviour.trial_by_condition(real_subject, 1:sessions_to_take, :, :);
            real_n_reversals_per_block_SUBJ(target_indices,:,:)   = real_behaviour.n_reversals_per_block(real_subject, 1:sessions_to_take, :, :);
            
            % Update the counter
            sessions_filled = sessions_filled + sessions_to_take;            
            % Check if we've filled all requested sessions
            if sessions_filled >= n_sessions
                break;
            end
        end
        
        %% prepare task schedule - it can be simulated ("fake") or taken from real participants ("real")
        if reward_schedule_generation_method == "real" % get real reward schedule, from same participant as confidence 
            % fprintf("\nUse a real reward schedule, from same participant as confidence\n")
            reward_schedule_SUBJ   = real_reward_schedule_SUBJ;
            correct_schedule_SUBJ  = real_correct_schedule_SUBJ;
            reversal_schedule_SUBJ = real_reversal_schedule_SUBJ;
            valence_schedule_SUBJ  = real_valence_schedule_SUBJ;
            full_feedback_schedule_SUBJ = real_full_feedback_SUBJ;
            trial_by_condition_SUBJ = real_trial_by_condition_SUBJ;
            n_reversals_per_block_SUBJ = real_n_reversals_per_block_SUBJ;
        
        else
            error("Currently only support using real reward schedules from real participants.")
        end
        clear random_subject other_random_subject
        clear real_correct_schedule_SUBJ real_reversal_schedule_SUBJ real_valence_schedule_SUBJ real_reward_schedule_SUBJ

    
        % create extra variables not needed for data generation (for now) but needed later for model fitting
        % variable reflecting sessions
        session_SUBJ = ones(n_sessions,n_conditions,n_trials_by_cond); % need variable to exist for Model_Params.m input
        for s = 1:n_sessions
            session_SUBJ(s,:,:) = s;
        end

        % TO PUT IN A FUNCTION//OBJECT?
        % prepare names of conditions - depends on real dataset from which we will use confidence and outcomes
        if version_name == "RL0_partialfeedbacktrials"
            condition_names_all  = ["partial_info_gain"; ""; "partial_info_loss"; ""]; 
        elseif version_name == "RL0_completefeedbacktrials" 
            condition_names_all  = [""; "full_info_gain"; ""; "full_info_loss"]; 
        elseif version_name == "RL0_all" 
            condition_names_all  = ["partial_info_gain"; "full_info_gain"; "partial_info_loss"; "full_info_loss"]; 
        elseif contains(version_name,[ "RL1_partialfeedback","RL1_completefeedback","RL3_partialfeedback","RL3_completefeedback"]) 
            condition_names_all  = ["low_volatility_gain"; "high_volatility_gain"; "low_volatility_loss"; "high_volatility_loss"]; 
        else
            condition_names_all  = ["low_volatility_gain"; "high_volatility_gain"; "low_volatility_loss"; "high_volatility_loss"]; 
        end
        % variable reflecting conditions
        condition_SUBJ      = ones(n_sessions,n_conditions,n_trials_by_cond); % need variable to exist for Model_Params.m input
        condition_name_SUBJ = strings(n_sessions,n_conditions,n_trials_by_cond); % need variable to exist for Model_Params.m input
        for c = 1:n_conditions
            condition_SUBJ(:,c,:) = c;
            condition_name_SUBJ(:,c,:) = condition_names_all(c);
        end

        % variable for simulated participant's ID
        participant_ID_SUBJ = strings(n_sessions,n_conditions,n_trials_by_cond);
        participant_ID_SUBJ(:) = string(i_agent);
        % variable for exp_ID
        exp_ID_SUBJ = strings(n_sessions,n_conditions,n_trials_by_cond);
        exp_ID_SUBJ(:) = sprintf('simulated_generativemodel%i.png',generative_model);  

        %% sanity checks

        % check size
        assert( isequal(size(exp_ID_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, exp_ID_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(participant_ID_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, participant_ID_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(full_feedback_schedule_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, full_feedback_schedule_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(valence_schedule_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, valence_schedule_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(session_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, session_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(condition_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, condition_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(condition_name_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, condition_name_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(trial_by_condition_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, trial_by_condition_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(correct_schedule_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, correct_schedule_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(reversal_schedule_SUBJ), [n_sessions,n_conditions, n_trials_by_cond]), 'Problem, reversal_schedule_SUBJ should be of size [1,n_sessions,n_conditions, n_trials_by_cond]');
        assert( isequal(size(reward_schedule_SUBJ), [n_sessions,n_conditions, n_trials_by_cond, 2]), 'Problem, reward_schedule should be of size [1,n_sessions,n_conditions, n_trials_by_cond, 2]');

        % check that the entire thing is not full of NaNs
        assert( sum(isempty(exp_ID_SUBJ),"all") < numel(exp_ID_SUBJ) , 'Problem, exp_ID_SUBJ is full of NaNs');
        assert( sum(isempty(participant_ID_SUBJ),"all") < numel(participant_ID_SUBJ) , 'Problem, participant_ID_SUBJ is full of NaNs');
        assert( sum(isnan(full_feedback_schedule_SUBJ),"all") < numel(full_feedback_schedule_SUBJ) , 'Problem, full_feedback_schedule_SUBJ is full of NaNs');
        assert( sum(isnan(valence_schedule_SUBJ),"all") < numel(valence_schedule_SUBJ) , 'Problem, valence_schedule_SUBJ is full of NaNs');
        assert( sum(isnan(session_SUBJ),"all") < numel(session_SUBJ) , 'Problem, session_SUBJ is full of NaNs');
        assert( sum(isnan(condition_SUBJ),"all") < numel(condition_SUBJ) , 'Problem, condition_SUBJ is full of NaNs');
        assert( sum(isempty(condition_name_SUBJ),"all") < numel(condition_name_SUBJ) , 'Problem, condition_name_SUBJ is full of NaNs');
        assert( sum(isnan(trial_by_condition_SUBJ),"all") < numel(trial_by_condition_SUBJ) , 'Problem, trial_by_condition_SUBJ is full of NaNs');
        assert( sum(isnan(correct_schedule_SUBJ),"all") < numel(correct_schedule_SUBJ) , 'Problem, correct_schedule_SUBJ is full of NaNs');
        assert( sum(isnan(reversal_schedule_SUBJ),"all") < numel(reversal_schedule_SUBJ) , 'Problem, reversal_schedule_SUBJ is full of NaNs');
        assert( sum(isnan(reward_schedule_SUBJ),"all") < numel(reward_schedule_SUBJ) , 'Problem, reward_schedule_SUBJ is full of NaNs');


        %% store variables
        output.generative_parameters(     i_agent,:)       = params_SUBJ; % generative_parameters{k_rep_of_generation, generative_model} - contains matrix of size n_participants x n_parameters 
        output.exp_ID(                    i_agent,:,:,:)   = exp_ID_SUBJ;
        output.participant_ID(            i_agent,:,:,:)   = participant_ID_SUBJ;
        output.full_feedback(             i_agent,:,:,:)   = full_feedback_schedule_SUBJ;
        output.valence(                   i_agent,:,:,:)   = valence_schedule_SUBJ;
        output.session(                   i_agent,:,:,:)   = session_SUBJ;
        output.condition(                 i_agent,:,:,:)   = condition_SUBJ;
        output.condition_name(            i_agent,:,:,:)   = condition_name_SUBJ;
        output.trial_by_condition(        i_agent,:,:,:)   = trial_by_condition_SUBJ;
        output.correct_schedule(          i_agent,:,:,:)   = correct_schedule_SUBJ;
        output.reversal(                  i_agent,:,:,:)   = reversal_schedule_SUBJ;
        output.symbol_1_actual_payoff(    i_agent,:,:,:)   = reward_schedule_SUBJ(:,:,:,1);
        output.symbol_2_actual_payoff(    i_agent,:,:,:)   = reward_schedule_SUBJ(:,:,:,2);
        output.reward_schedule(           i_agent,:,:,:,:) = reward_schedule_SUBJ(:,:,:,:);
        output.real_confidence(           i_agent,:,:,:)   = real_confidence_SUBJ;
        output.n_reversals_per_block(     i_agent,:,:,:)   = n_reversals_per_block_SUBJ;

        clear params_SUBJ exp_ID_SUBJ participant_ID_SUBJ full_feedback_schedule_SUBJ valence_schedule_SUBJ  valence_schedule_SUBJ session_SUBJ condition_SUBJ condition_name_SUBJ trial_by_condition_SUBJ reward_schedule_SUBJ correct_schedule_SUBJ reversal_schedule_SUBJ
        
    end % for i_agent = 1:n_participants  
end
