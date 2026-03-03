function [modelling_outputs] = fit_several_models(data, fitting_models, fmincon_options, n_repetition_of_parameter_estimation, use_parallel, models_info, version_name )

    % set variables that determine the dimensions of main output matrices
    [n_subj,n_sess,n_cond,n_trials_max] = size(data.correct);

    % deal with MLNSG_0reversals with partial/complete feedback trials
    % set which conditions should be empty 
    conditions_to_remove = [];
    if strcmp(version_name, "MLNSG_0reversals_partialfeedbacktrials")
        % condition_names = ["partial_info_gain" ; "full_info_gain" ; "partial_info_loss" ; "full_info_loss"];
        conditions_to_remove = [2,4];
    elseif strcmp(version_name, "MLNSG_0reversals_completefeedbacktrials")
        % condition_names = ["partial_info_gain" ; "full_info_gain" ; "partial_info_loss" ; "full_info_loss"];
        conditions_to_remove = [1,3];
    end
    % SANITY CHECKS to deal with MLNSG_0reversals with partial/complete feedback trials only : check that values in absent conditions are NaNs
    if strcmp(version_name, "MLNSG_0reversals_partialfeedbacktrials") || strcmp(version_name, "MLNSG_0reversals_completefeedbacktrials")
        % check in variables that all values in "absent" conditions are filled with NaNs
        assert(sum(isnan(data.correct(   :,:,conditions_to_remove,:)),"all") == numel(data.correct(   :,:,conditions_to_remove,:)), "Problem, in sub-task with partial/complete feedback, values in conditions with opposite type of feedback should be NaNs")
        assert(sum(isnan(data.confidence(:,:,conditions_to_remove,:)),"all") == numel(data.confidence(:,:,conditions_to_remove,:)), "Problem, in sub-task with partial/complete feedback, values in conditions with opposite type of feedback should be NaNs")
        assert(sum(isnan(data.chosen(    :,:,conditions_to_remove,:)),"all") == numel(data.chosen(    :,:,conditions_to_remove,:)), "Problem, in sub-task with partial/complete feedback, values in conditions with opposite type of feedback should be NaNs")
    end


    % initialise variables updated inside the loops
    parameters    = cell(1, numel(models_info)); % dimensions: {n_models} n_subj x n_params
    gradient_nLPP = cell(n_subj, numel(models_info));
    hessian_nLPP  = cell(n_subj, numel(models_info));
    nLPP          = NaN(n_subj,  numel(models_info));
    LAME          = NaN(n_subj,  numel(models_info));
    nLL           = NaN(n_subj,  numel(models_info));  
    BIC           = NaN(n_subj,  numel(models_info)); 
    Q             = cell(1, numel(models_info)); % dimensions: {n_models} (n_subj x n_conditions x n_trials_max+1?? x 2 for the two presented options)
    PChosen       = cell(1, numel(models_info)); % dimensions: {n_models} (n_subj x  n_conditions x n_trials)
    PCorrect      = cell(1, numel(models_info)); % dimensions: {n_models} (n_subj x  n_conditions x n_trials)
    PSwitch       = cell(1, numel(models_info)); % dimensions: {n_models} (n_subj x  n_conditions x n_trials)
    participant_ID_modelfit = strings(n_subj,1); % will be filled with strings, dimensions: {n_models}(n_subj x 1)

    % create object with behavioural data for current participant, and with the necessary variables only
    % for efficiency: cache per-subject behaviour once
    participant_behaviour_all = cell(n_subj,1);
    for k_subj = 1:n_subj
        beh = struct();
        beh.correct        = reshape(data.correct(        k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.confidence     = reshape(data.confidence(     k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.chosen         = reshape(data.chosen(         k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.outcome        = reshape(data.outcome(        k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.cf_outcome     = reshape(data.cf_outcome(     k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.exp_ID         = reshape(data.exp_ID(         k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.participant_ID = reshape(data.participant_ID( k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.condition      = reshape(data.condition(      k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        beh.full_feedback  = reshape(data.full_feedback(  k_subj,:,:,:), n_sess, n_cond, n_trials_max);
        participant_behaviour_all{k_subj} = beh;
    end

    %% fit parameters for each model
    for j = 1:numel(fitting_models)
        fitting_model = fitting_models(j);

        % initialise a few model-specific variables which will then be placed in the larger, final variables
        parameters_for_current_fitting_model = NaN(n_subj,models_info{fitting_model}.param_num);   %n_subj x n_params
        Q_for_current_fitting_model          = NaN(n_subj,n_sess,n_cond,n_trials_max,2); % dimensions: n_subj x n_conditions x n_trials_max x 2 (for the two presented options)
        PChosen_for_current_fitting_model    = NaN(n_subj,n_sess,n_cond,n_trials_max);  % dimensions: (n_subj x  n_conditions x n_trials)
        PCorrect_for_current_fitting_model   = NaN(n_subj,n_sess,n_cond,n_trials_max);  % dimensions: (n_subj x  n_conditions x n_trials)
        PSwitch_for_current_fitting_model    = NaN(n_subj,n_sess,n_cond,n_trials_max);  % dimensions: (n_subj x  n_conditions x n_trials)
        

        % Precompute random starting points on the CLIENT (deterministic after rng(seed))
        n_params = models_info{fitting_model}.param_num;
        precomputed_starts = cell(n_subj,1);   % each cell: [n_repetition x n_params]
        for k_subj = 1:n_subj
            starts = NaN(n_repetition_of_parameter_estimation, n_params);
            for k_rep = 1:n_repetition_of_parameter_estimation
                starts(k_rep,:) = models_info{fitting_model}.get_param_start();
            end
            precomputed_starts{k_subj} = starts;
        end

        %% Likelihood Maximization - fit model at the subject-level

        % TO DEFINE: use parallel processing
        if use_parallel
            % Create parallel pool if it does not exist 
            if isempty(gcp('nocreate'))
                parpool()
            end
        else
            % Delete parallel pool if it exists
            delete(gcp('nocreate'));
        end
        
        % parallel processing: replace for by parfor
        parfor k_subj = 1:n_subj
        % for k_subj = 1:n_subj
           
            %% fit model parameters to one participant

            participant_behaviour = participant_behaviour_all{k_subj};
            % call fmincon            
            participant_fit = call_fmincon_on_one_participant( ...
                                participant_behaviour, ...
                                fitting_model, ...
                                fmincon_options, ...
                                n_repetition_of_parameter_estimation, ...
                                models_info, ...
                                precomputed_starts{k_subj});
            % sanity checks
            %{
            if ( isnan(participant_fit.LAME) || isempty(participant_fit.LAME)  )
                warning('participant_fit.LAME is empty or NaN')
            end
            if ( any(isnan(participant_fit.gradient_nLPP),'all') || any(isempty(participant_fit.gradient_nLPP)) )
                warning('participant_fit.gradient_nLPP is empty or NaN')
            end
            if ( any(isnan(participant_fit.hessian_nLPP),'all') || any(isempty(participant_fit.hessian_nLPP))  )
                warning('participant_fit.hessian_nLPP is empty or NaN')
            end
            if ( isnan(participant_fit.nLPP) || isempty(participant_fit.nLPP)  )
                warning('participant_fit.nLPP is empty or NaN')
            end
            %}
            %% store output data from fmincon and Modelling_timeseries

            % save some fitting outputs in temporary, model-specific variables to facilitate paraellelisation  
            parameters_for_current_fitting_model(k_subj,:) = participant_fit.parameters;
            assert(~any(isnan(participant_fit.parameters)),"Problem in fit_several_models.m: some fitted parameters are NaN")
            
            % save some variables in final saving variables
            participant_ID_modelfit(k_subj)  = participant_fit.current_ID;
            LAME(          k_subj, fitting_model)    = participant_fit.LAME;
            gradient_nLPP{ k_subj, fitting_model}    = participant_fit.gradient_nLPP; 
            hessian_nLPP{  k_subj, fitting_model}    = participant_fit.hessian_nLPP;
            nLPP(          k_subj, fitting_model)    = participant_fit.nLPP;
            nLL(           k_subj, fitting_model)    = participant_fit.nLL; 
            BIC(           k_subj, fitting_model)    = participant_fit.BIC;

            % save some variables in temporary, model-specific variables
            PChosen_for_current_fitting_model( k_subj,:,:,:)   = participant_fit.timeseries.pChosen;
            PCorrect_for_current_fitting_model(k_subj,:,:,:)   = participant_fit.timeseries.pCorrect;
            PSwitch_for_current_fitting_model( k_subj,:,:,:)   = participant_fit.timeseries.pSwitch; 
            try 
                Q_for_current_fitting_model(       k_subj,:,:,:,:) = participant_fit.timeseries.Q;
            catch
                warning("Problem saving Q timeseries in fit_several_models.m")
            end


            if sum( isnan(PCorrect_for_current_fitting_model(k_subj,:,:,:)) ) > 5;
                assert(sum( isnan(PCorrect_for_current_fitting_model(k_subj,:,:,:)) ) <= 5, 'Problem: too many NaNs in PCorrect_for_current_fitting_model')
            end
            fprintf(' -------- fit parameters of model %i to participant %i in %s --------\n',fitting_model,k_subj,version_name)

           
        end         

        % sanity checks 
        % if there is more than one row (aka not fitting at population level), check that estimated parameters are not all equal to each other
        if size(parameters_for_current_fitting_model,1) > 1
            assert(range(parameters_for_current_fitting_model(:,1))~=0,'Problem in fit_several_models.m: estimated parameters are all equal to each other') ;
        end
        assert(~any(isnan(parameters_for_current_fitting_model),"all"),'Problem in fit_several_models.m: some estimated parameters are NaN') ;
    
        % store model-specific variables in larger, final output variable modelling_outputs - with cell array for each fitting model
        parameters{fitting_model} = parameters_for_current_fitting_model;
        Q{fitting_model}          = Q_for_current_fitting_model ;
        PChosen{fitting_model}    = PChosen_for_current_fitting_model;
        PCorrect{fitting_model}   = PCorrect_for_current_fitting_model;
        PSwitch{fitting_model}    = PSwitch_for_current_fitting_model;  

        % delete model-specific variables in larger variables 
        clear parameters_for_current_fitting_model Q_for_current_fitting_model PChosen_for_current_fitting_model PCorrect_for_current_fitting_model PSwitch_for_current_fitting_model

    end
    
    % store variables already containing multiple fitting_models in the larger, final output variable modelling_outputs 
    modelling_outputs.participant_ID_modelfit   = participant_ID_modelfit;
    modelling_outputs.LAME                      = LAME;
    modelling_outputs.gradient_nLPP             = gradient_nLPP;
    modelling_outputs.hessian_nLPP              = hessian_nLPP;
    modelling_outputs.nLPP                      = nLPP;
    modelling_outputs.nLL                       = nLL;
    modelling_outputs.BIC                       = BIC;    

    % store model-specific variables in larger, final output variable modelling_outputs - with cell array for each fitting model
    modelling_outputs.parameters = parameters;
    modelling_outputs.Q          = Q ;
    modelling_outputs.PChosen    = PChosen;
    modelling_outputs.PCorrect   = PCorrect;
    modelling_outputs.PSwitch    = PSwitch;  

end