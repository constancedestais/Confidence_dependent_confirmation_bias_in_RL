function output = simulate_dataset(generative_model,task_schedule,confidence_generation_method)
%{
INPUTS
- generative_model (int)
- structure containing following fields
    - generative_parameters - matrix of size n_participants x n_parameters 
    - reward_schedule - n_agents x n_sessions x n_conditions x n_trials_by_cond x n_symbols
    - correct_schedule - n_agents x n_sessions x n_conditions x n_trials_by_cond
    - full_feedback (0/1) - n_agents x n_sessions x n_conditions x n_trials_by_cond
    - condition - n_agents x n_sessions x n_conditions x n_trials_by_cond
    - real_confidence - n_agents x n_sessions x n_conditions x n_trials_by_cond --> real participants's confidence, may be used by function generate_confidence()
- confidence_generation_method: "real" or "fake" (necessary for the generate_confidence.m function)

OUTPUTS
- structure with the following fields of size n_agents x n_sessions x n_conditions x n_trials_by_cond 
    - symbol_chosen_id_relative
    - symbol_chosen_actual_payoff
    - symbol_unchosen_actual_payoff
    - chose_highest
    - confidence_rating
    - switched_choice
    - chose_symbol_1

GOAL

%}
    
    % Task characteristics
    %{
    [n_agents, n_sessions, n_conditions, max_trials] = size(task_schedule.full_feedback);
    % set n_trial based on trials which are not full of NaNs
    trial_has_values = arrayfun(@(t) ~all(isnan(task_schedule.full_feedback(:,:,:,t)), 'all'), 1:max_trials);
    n_trials_by_cond = find(trial_has_values, 1, 'last');
    %}
    [n_agents, n_sessions, n_conditions, n_trials_by_cond] = size(task_schedule.full_feedback);


    % initalise output
    output.symbol_chosen_id_relative     = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    output.symbol_chosen_actual_payoff   = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    output.symbol_unchosen_actual_payoff = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    output.chose_highest      = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    output.confidence_rating  = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    output.switched_choice    = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    output.chose_symbol_1     = NaN(n_agents, n_sessions, n_conditions, n_trials_by_cond);
    
    % loop over agents I want to create
    for k_subj = 1:n_agents
    
        %% simulate behaviour of one agent inside established task schedule
    
        % generate task_schedule for one participant using specified model
        % want: chosen = 1/2, outcome/cf_outcome = -1/1, correct = 0/1, confidence between 0 and 1
        % inputs should be of size n_sessions x n_conditions x n_trials (x n_symbols for the reward_schedule)
        
        % reshape participant-level task_schedule so that it is of size n_sessions x n_conditions x n_trials (cannot use squeeze() because when n_sessions = 1, it squeezes out the sessions dimension)
        generative_parameters = squeeze(task_schedule.generative_parameters( k_subj,:));
        reward_schedule  = reshape(task_schedule.reward_schedule(  k_subj,:,:,:,:),  n_sessions, n_conditions, n_trials_by_cond, 2);
        correct_schedule = reshape(task_schedule.correct_schedule( k_subj,:,:,:), n_sessions, n_conditions, n_trials_by_cond);
        full_feedback    = reshape(task_schedule.full_feedback(    k_subj,:,:,:),    n_sessions, n_conditions, n_trials_by_cond);
        condition        = reshape(task_schedule.condition(        k_subj,:,:,:), n_sessions, n_conditions, n_trials_by_cond);
        real_confidence  = reshape(task_schedule.real_confidence(  k_subj,:,:,:),  n_sessions, n_conditions, n_trials_by_cond);
        % call function that simulates the behaviour of one agent using the specified generative model
        [choice_data_SUBJ] = Modelling_simulate_one_agent(generative_model, ...
                                                         generative_parameters, ...
                                                         reward_schedule, ...
                                                         correct_schedule, ...
                                                         full_feedback, ...
                                                         condition, ...
                                                         real_confidence, ...
                                                         confidence_generation_method ...
                                                        );
        clear generative_parameters reward_schedule correct_schedule full_feedback condition real_confidence


        %% sanity checks
        
        % check size
        %assert( isequal(unique( choice_data_SUBJ.symbol_chosen_id_relative ), [1;2]) , 'Problem: the only values in chosen_SUBJ should be 1 and 2' ) ;
        assert( isequal(size(   choice_data_SUBJ.symbol_chosen_id_relative ), [n_sessions,n_conditions, n_trials_by_cond]) ,   'Problem: the dimensions of symbol_chosen_id_relative should be: n_sessions,n_conditions, n_trials_by_cond' ) ;  
        assert( isequal(size(   choice_data_SUBJ.symbol_chosen_actual_payoff ), [n_sessions,n_conditions, n_trials_by_cond]) ,   'Problem: the dimensions of symbol_chosen_actual_payoff should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(   choice_data_SUBJ.symbol_unchosen_actual_payoff ), [n_sessions,n_conditions, n_trials_by_cond]) ,   'Problem: the dimensions of symbol_chosen_actual_payoff should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        %assert( isequal(unique( choice_data_SUBJ.chose_highest ), [0;1]) , 'Problem: the only values in chosen_SUBJ should be 0 and 1' ) ;
        assert( isequal(size(   choice_data_SUBJ.chose_highest ), [n_sessions,n_conditions, n_trials_by_cond]) ,   'Problem: the dimensions of chose_highest should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        %assert( isequal(size(   choice_data_SUBJ.confidence_rating ), [n_sessions,n_conditions, n_trials_by_cond+1]) , 'Problem: the dimensions of confidence_rating should be: n_sessions,n_conditions, n_trials_by_cond+1' ) ;
        assert( isequal(size(   choice_data_SUBJ.confidence_rating ), [n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of confidence_rating should be: n_sessions,n_conditions, n_trials_by_cond+1' ) ;
        assert( isequal(size(   choice_data_SUBJ.switched_choice ), [n_sessions,n_conditions, n_trials_by_cond]) ,   'Problem: the dimensions of switched_choice should be: n_sessions,n_conditions, n_trials_by_cond' ) ;

        % check for NaNs
        assert( sum(isnan(choice_data_SUBJ.symbol_chosen_id_relative),"all") < numel(choice_data_SUBJ.symbol_chosen_id_relative) , 'Problem, symbol_chosen_id_relative is full of NaNs');
        assert( sum(isnan(choice_data_SUBJ.symbol_chosen_actual_payoff),"all") < numel(choice_data_SUBJ.symbol_chosen_actual_payoff) , 'Problem, symbol_chosen_actual_payoff is full of NaNs');
        assert( sum(isnan(choice_data_SUBJ.symbol_unchosen_actual_payoff),"all") < numel(choice_data_SUBJ.symbol_unchosen_actual_payoff) , 'Problem, symbol_unchosen_actual_payoff is full of NaNs');
        assert( sum(isnan(choice_data_SUBJ.chose_highest),"all") < numel(choice_data_SUBJ.chose_highest) , 'Problem, chose_highest is full of NaNs');
        assert( sum(isnan(choice_data_SUBJ.confidence_rating),"all") < numel(choice_data_SUBJ.confidence_rating) , 'Problem, confidence_rating is full of NaNs');
        assert( sum(isnan(choice_data_SUBJ.switched_choice),"all") < numel(choice_data_SUBJ.switched_choice) , 'Problem, switched_choice is full of NaNs');

        
        %% store variables
        output.symbol_chosen_id_relative( k_subj,:,:,:)   = choice_data_SUBJ.symbol_chosen_id_relative;
        output.symbol_chosen_actual_payoff(k_subj,:,:,:)   = choice_data_SUBJ.symbol_chosen_actual_payoff;
        output.symbol_unchosen_actual_payoff(k_subj,:,:,:) = choice_data_SUBJ.symbol_unchosen_actual_payoff;
        output.chose_highest(             k_subj,:,:,:)   = choice_data_SUBJ.chose_highest;
        output.switched_choice(           k_subj,:,:,:)   = choice_data_SUBJ.switched_choice;
        output.chose_symbol_1(            k_subj,:,:,:)   = choice_data_SUBJ.chose_symbol_1;
        output.confidence_rating(         k_subj,:,:,:)   = choice_data_SUBJ.confidence_rating(:,:,1:n_trials_by_cond);

        clear choice_data_SUBJ
        
        
        % fprintf(' -------- simulated behavioural task_schedule for model %i to participant %i (repetition no. %i) --------\n',generative_model,k_subj,k_rep_of_generation)
  

    end % for k_subj = 1:n_participants  

    clear has_duplicates field_names
end

