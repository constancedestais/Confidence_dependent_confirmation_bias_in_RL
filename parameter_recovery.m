%{
Script to simulate data with generative models and then fit the simulated data with a set of fitting models

The script does this ONCE. If you want to repeat the process


The script is split into three parts
    1.) settings: define settings of how the data must be simulated/fitted
        - saves a file "settings_repetitionR.mat"

    2.) simulation: 
        - creates agents (sets of parameters)
        - creates task schedules for each agent
        - simulates behaviour for each agent
        - Saves a file "simulated_data_generativemodelX_repetitionR.mat"

    3.) recovery/fitting
        - Fits each of the fitting models onto the simulated dataset
        - Based on fit_parameters_to_participants, modelling_outputs are of following dimensions:
            - LAME: matrix (k_subj x n_fitting_models)
            - gradient_nLPP: cell array (k_subj x n_fitting_models)
            - hessian_nLPP: cell array (k_subj x n_fitting_models)
            - nLPP: (k_subj x n_fitting_models)
            - nLL: (k_subj x n_fitting_models)
            - BIC: (k_subj x n_fitting_models)
            - parameters: cell array {n_fitting_models} with matrices (n_agents x n_params)
            - Q: cell array {n_fitting_models} with matrices (n_agents x n_conditions x n_trials_max+1?? x 2 for the two presented options)
            - PChosen: cell array {n_fitting_models} with matrices (n_agents x  n_conditions x n_trials)
            - PCorrect: cell array {n_fitting_models} with matrices (n_agents x  n_conditions x n_trials)
            - PSwitch: cell array {n_fitting_models} with matrices (n_agents x  n_conditions x n_trials)  
        - Just like in fit_parameters_to_participants, some of these variables are initialised at the beginning and then progressively filled, while others are filled at the level of the current_fitting_model, and placed in the final variables after finishing the fititng process for each model 
        - Saves a file "modelling_outcomes_generativemodelX_repetitionR.mat"
    
    - All these files are stored in a folder in Outputs/Simulations_recovery/generativemodels_ZZZ_fittingmodels_ZZ_ZZ_ZZ/
        And that the "repetition" number R is computed based on files which already exist in this directory. E.g. if the file "simulated_data_generativemodel1_repetition1.mat" exists, 
        and I run the script again with the same generative model and fitting models, then the next file will be called "simulated_data_generativemodel1_repetition2.mat"
%}


%% Setup workspace/directories/paths

% load_working_environment; 
clear all
close all
clc
format longg

% set whether this is running on external server or not
running_on_external_server = 1;
% set reference directory
if (running_on_external_server == 1)
    filePath = mfilename('fullpath'); 
else
    filePath = matlab.desktop.editor.getActiveFilename;
end

% set working directories
cwd = fileparts(filePath);
    fprintf('cwd = %s\n',cwd);
cd(cwd);
data_dir         = fullfile(cwd,'Data');
output_dir       = fullfile(cwd,'Outputs');  
figures_dir      = fullfile(output_dir,'Figures');  
recovery_dir     = fullfile(output_dir,'Simulations_recovery');  

% set path
restoredefaultpath
addpath(genpath('Functions'), genpath('Data'), genpath('Outputs'))  % add folder and contained folders
addpath(genpath('../MBB-team_VBA-toolbox')); % add folder and contained folders

% number of simulations + recovery to run 
n_iterations = 40;
w=0;
while w < n_iterations
    w=w+1;
    %% reproducibility: seed
    % set seed myself -> save seed in settings
    seed = str2double(string(datetime('now','Format','MMddHHmmss')));
    rng(seed)
    
    
    %% set important variables
    
    % Load information about model parameters and priors
    [models_info,models_info_extra] = load_models_info(); 
    max_number_of_models = numel(models_info);
    
    % Version_names - IMPORTANT: this used to get task contingencies (task schedule, including real participants' confidence) and real participant parameters 
    % options: 
    %   "CDAG_partialfeedback"  
    %   "CDAG_completefeedback"   
    %   "MLNSG_1reversal_partialfeedback"  
    %   "MLNSG_1reversal_completefeedback"   
    %   "MLNSG_0reversals_all"  
    % Do NOT request "CDAG_all" or "MLNSG_1_all" because it will randomly draw participant data with either Complete or Partial Info (between-participant factor)
    % Do NOT request "MLNSG_0_reversals_partialfeedback" or "MLNSG_0_reversals_completefeedback" because feedback was a within-participant factor in this dataset

    version_name = "CDAG_completefeedback";

    % generic version name
    if contains(version_name, "CDAG")
        reward_structure_dataset_name = 'CDAG';
    elseif contains(version_name, "MLNSG_0")
        reward_structure_dataset_name = 'MLNSG_0reversals';
    elseif contains(version_name, "MLNSG_1")
        reward_structure_dataset_name = 'MLNSG_1reversal';  
    end

    % Use "relative" vs "semirelative" vs "actual" outcomes ; relative: -1 vs 1 for best and worst outcomes in a trial; semi-relative: rescale two outcomes compared to their mean; 
    outcome_encoding_for_fitting = "actual";
    
    % Models used for generating data
    % models = [1,2,4];
    generative_models = [1,2,4];
    
    % Models used for fitting - models on n-th line correspond to models to be fitted for n-th generative model stored in generative_models  
    % e.g.  if generative_models = [1,2,4]; and you want to fit all models to each other, you need: 
    %       fitting_models_for_each_generative_model = {[1,2,4]; [1,2,4]; [1,2,4]};
    fitting_models_for_each_generative_model = {[1,2,4]; [1,2,4]; [1,2,4]};

    % check that there is one array of fitting models per generative model
    assert(size(generative_models,2) == size(fitting_models_for_each_generative_model,1), 'Problem: must be as many rows in fitting_models_for_each_generative_model as there are generative models');
    
    % Number of agents to simulate
    n_agents = 100; % reflects real number of participants in data  
    
    % Number of repetitions of parameter estimation in case fmincon gets stuck in local minimum
    n_repetition_of_parameter_estimation = 3;
    
    % set options for fmincon function
    fmincon_options = optimset('Algorithm', 'interior-point', 'Display', 'off', 'MaxIter', 10000);

    % settings for recovery
    reward_schedule_generation_method = "real"; % use real participants' reward schedules (available option outcomes on each trial)
    parameter_generation_method = "real"; % use real participants' parameters to generate new agents' parameters 
    confidence_generation_method = "real"; % use real participants' confidence to generate new agents' confidence
    fixed_reversal_schedule = 0; % 0: keep reversal schedule from real participants; 1: only relevant when generating new reward schedules
    
    
    %% set specific directory
    
    generative_models_string = sprintf('%d', vertcat(generative_models));
    % Convert each cell to a string, Join the strings with underscores
    fitting_models_string = cellfun(@(x) sprintf('%d', x(:)'), fitting_models_for_each_generative_model, 'UniformOutput', false);
    fitting_models_string = strjoin(fitting_models_string, '_');
    % set directories for saving outputs and figures
    special_folder_path = fullfile(recovery_dir,sprintf('generativemodels_%s_fittingmodels_%s_version_%s%s',generative_models_string,fitting_models_string,version_name)); 
    if ~exist(special_folder_path, 'dir')
        % Folder doesn't exist, so create it
        mkdir(special_folder_path);
    end
    % Display confirmation
    disp(['Folder "' special_folder_path '" created in the current directory.']);
    % add new folder to path
    addpath(genpath('Functions'), genpath('Data'), genpath('Outputs'));  % add folder and contained folders
    
    % replace both directories used for export by this dated directory
    output_export_dir  = special_folder_path;
    figures_export_dir = special_folder_path;
    
    % record current date/time -> use this to save files in folder
    formatted_datetime = datestr(now, 'ddmmmyyyyHHMM');
    
    %% save settings
    % store settings in a variable, to be saved alongside the data
    settings = {};
    settings.max_number_of_models = max_number_of_models;
    settings.version_name = version_name;
    settings.reward_structure_dataset_name = reward_structure_dataset_name;
    settings.outcome_encoding_for_fitting = outcome_encoding_for_fitting;
    settings.generative_models = generative_models;
    settings.fitting_models_for_each_generative_model = fitting_models_for_each_generative_model;
    settings.parameter_generation_method = parameter_generation_method;
    settings.confidence_generation_method = confidence_generation_method;
    settings.reward_schedule_generation_method = reward_schedule_generation_method;
    settings.fixed_reversal_schedule = fixed_reversal_schedule;
    settings.n_agents = n_agents;
    settings.n_repetition_of_parameter_estimation = n_repetition_of_parameter_estimation;
    settings.seed = seed; 
    
    % SAVE SETTINGS
    base_path = special_folder_path;
    base_filename = sprintf('settings_%s',formatted_datetime);
    extension = ".mat";
    %svnm = save_file_with_increment(base_path,base_filename,extension);
    svnm = strcat(base_path,'/',base_filename,extension);
    save(svnm,'settings');
    fprintf('\n -------- saved file: %s -------- \n',svnm)
    clear settings
    
    %% load real participant data 
    % load behavioural datasets from real participants
    % depending on settings, may be used to create task schedules and confidence for simulated agents  
    real_behaviour = load_behaviour_datasets(version_name,  "matrix", data_dir); 

    % create list of participants in the order in which they appear in behavioural dataset to load modelling outputs in the same order
    ordered_participant_list = unique(real_behaviour.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));
    % load model-fit and timeseries outputs from real participants
    % real parameters are used directly or indirectly to generate new agents
    real_participants_modelling_outputs = load_modelling_outputs(version_name, outcome_encoding_for_fitting, output_dir, ordered_participant_list);

    %% standardise real participant behavioural datasets [NEW STEP] 
    %{
    GPT:
    - MLNSG variants are trimmed so every participant contributes the same number of trials
    - impute_missing_confidence_and_choice removes any NaNs in confidence, choices, and outcomes.
        Those NaNs used to propagate into the simulated datasets, which silently zeroed gradients in fmincon; with the cleaned matrices the likelihood surface is much smoother
    %}
    
    % trim datasets with unequal numbers of trials (MLNSG_0_reversals and MLNSG_1_reversal) - to avoid dealing with NaN values linked to different lengths of blocks 
    if (strcmp(reward_structure_dataset_name, "MLNSG_0reversals" ) || strcmp(reward_structure_dataset_name, "MLNSG_1reversal"))
        if strcmp(reward_structure_dataset_name, "MLNSG_0reversals" )
            min_n_trials = 20;
        elseif strcmp(reward_structure_dataset_name, "MLNSG_1reversal")
            min_n_trials = 28;
        end
        % loop through all fields and cut them to the minimal number of trials
        field_names = fieldnames(real_behaviour);
        for f = 1:length(field_names)
            field_name = field_names{f};
            if isfield(real_behaviour, field_name)
                current_data = real_behaviour.(field_name);
                if ndims(current_data) == 4
                    real_behaviour.(field_name) = current_data(:,:,:,1:min_n_trials);
                end
            end
        end
    end

    % impute missing values to avoid dealing with missing values in simulated data
    real_behaviour = impute_missing_confidence_and_choice(real_behaviour);
    % sanity check    
    assert(sum( isnan(real_behaviour.confidence_rating ), "all") == 0, "There are still NaN confidence values in data.")
    assert(sum( isnan(real_behaviour.chose_symbol_1 ), "all") == 0, "There are still NaN chose_symbol_1 values in data.")
    assert(sum( isnan(real_behaviour.symbol_chosen_actual_payoff ), "all") == 0, "There are still NaN symbol_chosen_actual_payoff values in data.")
    assert(sum( isnan(real_behaviour.symbol_unchosen_actual_payoff(real_behaviour.full_feedback == 1) ), "all") == 0, "There are still NaN symbol_unchosen_actual_payoff values for complete fdb data.")

    % get sizing variables from real data --> to simulate same structure of data
    [n_subjects, n_sessions, n_conditions, n_trials_by_cond] = size(real_behaviour.confidence_rating);
    
    %% loop over generative models: generate & fit data
    % prepare list of fields for variable "d" which contains simulated data
    fields_to_simulate = ["generative_parameters", ...
                    "exp_ID", ...
                    "participant_ID",...
                    "full_feedback", ...
                    "session", ...
                    "condition", ...
                    "trial_by_condition", ...
                    "reversal",...
                    "symbol_1_actual_payoff", ...
                    "symbol_2_actual_payoff", ...
                    "correct_schedule", ...
                    "symbol_chosen_id_relative", ...
                    "symbol_chosen_actual_payoff", ...
                    "symbol_unchosen_actual_payoff", ...
                    "chose_highest", ...
                    "confidence_rating", ...
                    "switched_choice", ...
                    "chose_symbol_1"];

    for gm = 1:numel(generative_models)
        generative_model = generative_models(gm);
    
        %% -------- DATA GENERATION -------- 
        %{
        - variables needed for simulation: params,reward_schedule,correct_schedule,condition,full_feedback
        - variables needed for model-fitting: params,action,outcome,cf_outcome,correct,full_feedback,condition,confidence
        %}
    
        % initialise variable which stores data simulated by this generative model
        d = {};
        for i = 1:numel(fields_to_simulate)
            fieldname = fields_to_simulate(i);
            d.(fieldname) = cell(1,max_number_of_models);
        end
    
        % create list of generative parameters to choose from - can be real parameters or parameters sampled from real distribution of paramaeters 
        real_participants_parameters_current_model = real_participants_modelling_outputs.parameters{generative_model};

        % estimate distribution of real parameters' parameters, then sample from each parameters' distribution to create new agents
        generative_parameters_current_model = generate_parameters_using_distribution_of_real_parameters( generative_model, real_participants_parameters_current_model, n_agents );

        clear real_participants_parameters_current_model

        % sanity checks
        has_duplicates = size(unique(generative_parameters_current_model, 'rows'), 1) < size(generative_parameters_current_model, 1);
        assert(~has_duplicates, 'Duplicate parameter sets detected among subjects');
        clear has_duplicates
        % sanity check    
        assert( sum(isnan(generative_parameters_current_model),"all")==0, 'Problem: parameter values cannot be NaN values');
        assert(sum( isnan(real_behaviour.confidence_rating ), "all") == 0, "There are still NaN confidence values in data.")
        assert(sum( isnan(real_behaviour.chose_symbol_1 ), "all") == 0, "There are still NaN chose_symbol_1 values in data.")
        assert(sum( isnan(real_behaviour.symbol_chosen_actual_payoff ), "all") == 0, "There are still NaN symbol_chosen_actual_payoff values in data.")
        assert(sum( isnan(real_behaviour.symbol_unchosen_actual_payoff(real_behaviour.full_feedback == 1) ), "all") == 0, "There are still NaN symbol_unchosen_actual_payoff values for complete fdb data.")

        % generate task schedule for multiple agents
        task_schedule = simulate_task_schedule(n_agents, ...
                                                generative_parameters_current_model, ...
                                                generative_model, ...
                                                real_behaviour, ...
                                                n_sessions, ...
                                                n_conditions, ...
                                                n_trials_by_cond, ...
                                                fixed_reversal_schedule, ...
                                                reward_schedule_generation_method, ...
                                                outcome_encoding_for_fitting,...
                                                models_info,...
                                                version_name);
  
        % generate behaviour for multiple agents - using task_schedule as input (which determines the number of participants, etc.)
        simulated_behaviour = simulate_dataset(generative_model, task_schedule, confidence_generation_method);
    
        % sanity check
        assert(sum( isnan(simulated_behaviour.confidence_rating ), "all") == 0, "There are still NaN confidence values in data.")
    
        %% combine information from task_schedule and simulated_behaviour into variable d
    
        % add info from simulated_behaviour
        combined_datasets = simulated_behaviour;
        % add info from task_schedule (only if it is not already present in the simulated_behaviour)
        task_schedule_fieldnames = fieldnames(task_schedule);
        % add fieldnames and variable content from task_schedule in combined_datasets
        for i = 1:length(task_schedule_fieldnames)
            if ~(ismember(task_schedule_fieldnames{i},fieldnames(combined_datasets)))
                combined_datasets.(task_schedule_fieldnames{i}) = task_schedule.(task_schedule_fieldnames{i});
                a=1;
            end
        end

        fprintf(' -------- simulated behavioural data for all agents using generative model %i --------\n',generative_model);   
        
        %% SAVE GENERATED DATA AND PARAMETERS FOR A GIVEN GENERATIVE MODEL
        d = combined_datasets;
        base_path = special_folder_path;
        base_filename = sprintf('simulated_data_generativemodel%i_%s',generative_model,formatted_datetime);
        extension = ".mat";
        %svnm = save_file_with_increment(base_path,base_filename,extension);
        svnm = strcat(base_path,'/',base_filename,extension);
        save(svnm,'d');
        fprintf('\n -------- saved file: %s --------\n',svnm)
    
        %% sanity check on simulated data 
        assert( isequal(generative_parameters_current_model, d.generative_parameters) , "Problem: the generated parameters in the d variable don't match those in the generative_parameters_current_model variable");
        clear generative_parameters_current_model 
        assert( isequal(size(d.reversal),      [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.reversal should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.session),       [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.session should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.full_feedback), [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.full_feedback should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.condition),     [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.condition should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.symbol_chosen_id_relative),     [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.symbol_chosen_id_relative should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.symbol_chosen_actual_payoff),   [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.symbol_chosen_actual_payoff should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.symbol_unchosen_actual_payoff), [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.symbol_unchosen_actual_payoff should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.chose_highest),   [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.chose_highest should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
        assert( isequal(size(d.switched_choice), [n_agents,n_sessions,n_conditions, n_trials_by_cond]) , 'Problem: the dimensions of d.switched_choice should be: n_sessions,n_conditions, n_trials_by_cond' ) ;
    
        %% -------- FIT THE SIMULATED DATA IN ORDER TO BE ABLE TO PLOT MODELFITS --------
        % for the current generative model, fit the data with a bunch of different models
    
        % define which models we are fitting with
        generative_model = generative_models(gm);
        fitting_models = fitting_models_for_each_generative_model{gm};

        % sanity checks 
        assert(sum( isnan(d.confidence_rating ), "all") == 0, "There are still NaN confidence values in data.")
        assert(sum( isnan(d.chose_highest ), "all") == 0, "There are still NaN chose_symbol_1 values in data.")
        assert(sum( isnan(d.symbol_chosen_actual_payoff ), "all") == 0, "There are still NaN symbol_chosen_actual_payoff values in data.")
        assert(sum( isnan(d.symbol_unchosen_actual_payoff(d.full_feedback == 1) ), "all") == 0, "There are still NaN symbol_unchosen_actual_payoff values for complete fdb data.")

        % prepare data d for fitting
        % rename some fields
        d.correct = d.chose_highest;
        d = rmfield(d,'chose_highest');
        d.confidence = d.confidence_rating;
        d = rmfield(d,'confidence_rating');
        d.chosen = d.symbol_chosen_id_relative;
        d = rmfield(d,'symbol_chosen_id_relative');
        % change outcome encoding if needed ("actua" will keep same values, just rename columns)
        d = change_outcome_encoding(d,outcome_encoding_for_fitting);
        % only keep fields needed for fitting
        required_fields = ["participant_ID",...
                           "exp_ID",...
                           "condition",...
                           "chosen",...
                           "outcome",...
                           "cf_outcome",...
                           "correct",...
                           "confidence",...
                           "full_feedback"];
        d = rmfield(d,setdiff(fieldnames(d),required_fields));

        % IMPORTANT set use of parallel computing
        use_parallel = 1; 
        % fit models
        modelling_outputs = fit_several_models(d, fitting_models, fmincon_options, n_repetition_of_parameter_estimation, use_parallel, models_info, version_name );

        %% SAVE DATA (at the level of each generative model)
        % save seed for reproducibility
        modelling_outputs.seed = seed;

        base_path = special_folder_path;
        base_filename = sprintf('modelling_outputs_generativemodel%i_%s',generative_model,formatted_datetime);
        extension = ".mat";
        %svnm = save_file_with_increment(base_path,base_filename,extension);
        svnm = strcat(base_path,'/',base_filename,extension);
        save(svnm,'modelling_outputs');
        fprintf('\n -------- saved file: %s --------\n',svnm)
    
        %% clear both main variables defined at the level of one generative model (simulated behaviour and modelling outputs)
        clear modelling_outputs d
    
    end % for generative_model = generative_models

end

toc
