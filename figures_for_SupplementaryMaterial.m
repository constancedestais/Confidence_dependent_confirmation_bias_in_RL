%% Setup workspace/directories/paths 
% among other things, loads the folowing directories: output_dir, data_dir, figures_dir
load_working_environment; 

color_dict = load_my_colors;

%% plot a_DIS vs. a_CON (resp. b_DIS vs b_CON) on the same figure for RL0, RL1, and RL3 - model with confidence-dependent learning

% Versions to loop over
version_names = ["RL0_all",...
                "RL1_all",...
                "RL3_all"];
% Model (c.f. README)
model = 2; 

% initialize cell array to store parameters for each dataset
parameters_multiple_datasets = {};

for v = 1:numel(version_names) 

    % load behaviour to get list of participants in order
    dataset_type = "matrix"; 
    d = load_behaviour_datasets(version_names{v},  dataset_type, data_dir);    
    % create list of p articipants in the order in which they appear in behavioural dataset
    ordered_participant_list = unique(d.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));

    % load modelling outputs
    outcome_encoding = "actual";
    modelling_outputs  = load_modelling_outputs(version_names(v), outcome_encoding, output_dir, ordered_participant_list);
    
    % store in cell array with one cell array per database, each cell contains parameter matrix of size n_participant x n_params
    parameters_multiple_datasets{v} = modelling_outputs.parameters{model};
end

% plot how learning rate changes with confidence for multiple datasets on the same figure
version_name = join(version_names,"_");
plot_parameters_against_each_other(parameters_multiple_datasets, version_name, model, outcome_encoding, figures_dir);



%% plot on the same figure the confirmation bias ratio as a function of confidence for RL0, RL1, and RL3 - model with confidence-dependent learning 
% Versions to loop over
version_names = ["RL0_all",...
                "RL1_all",...
                "RL3_all"];
% Model (c.f. README)
model = 2; 

% need mean_LR_bias_ratio, CI_lower_bias_ratio and CI_upper_bias_ratio for each dataset
mean_LR_bias_ratio = {};
CI_lower_bias_ratio = {};
CI_upper_bias_ratio = {};

% compute learning rate for each confidence value for each participant + average over all participants + compute stats for plot
for v = 1:numel(version_names)
    % load behaviour to get list of participants in order
    dataset_type = "matrix"; 
    d = load_behaviour_datasets(version_names{v},  dataset_type, data_dir);  
    % create list of p articipants in the order in which they appear in behavioural dataset
    ordered_participant_list = unique(d.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));
    % load modelling outputs
    modelling_outputs  = load_modelling_outputs(version_names{v}, "actual", output_dir, ordered_participant_list);
    params = modelling_outputs.parameters{model};    
    % compute learning rate for each confidence value for each participant + average over all participants
    stats = stats_learning_rate_by_confidence_averaged_across_participants(params,model);
    % create variables specifically for plotting function
    mean_LR_bias_ratio{v} = stats.mean_LR_bias_ratio;
    CI_lower_bias_ratio{v} = stats.CI_lower_bias_ratio;
    CI_upper_bias_ratio{v} = stats.CI_upper_bias_ratio;
    % use last version (could be any) just to get confidence_rescaled variable
    confidence_rescaled = stats.confidence_rescaled;
end

% call plotting function
file_version_name = "RL0_RL1_RL3" ;
outcome_encoding = "actual";
plot_confirmation_bias_ratio_by_confidence_for_several_datasets(confidence_rescaled, mean_LR_bias_ratio, CI_lower_bias_ratio, CI_upper_bias_ratio, file_version_name, model, outcome_encoding, figures_dir);
a=1;

%% plot estimated parameters and learning rate as a function of confidence for RL0, RL1, and RL3 (Partial info condition / Complete info condition) using models 2 and 4 (c.f. README)

% Versions to loop over
version_names = ["RL0_partialfeedbacktrials",...
                "RL0_completefeedbacktrials",...
                "RL1_partialfeedback",...  
                "RL1_completefeedback",...
                "RL3_partialfeedback",...
                "RL3_completefeedback"];
% Models to loop over
models = [2,4]; 

for v = 1:numel(version_names) 

    % load behaviour to get list of participants in order
    dataset_type = "matrix"; 
    d = load_behaviour_datasets(version_names{v},  dataset_type, data_dir);    
    % create list of p articipants in the order in which they appear in behavioural dataset
    ordered_participant_list = unique(d.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));

    % load modelling outputs
    modelling_outputs  = load_modelling_outputs(version_names(v), "actual", output_dir, ordered_participant_list);

    % loop over requested models 
    for m = 1:numel(models)
        model = models(m);
        % plot parameter values
        plot_parameters_skyline(modelling_outputs.parameters{model}, version_names(v), model, "actual", figures_dir);      
        % plot learning rate as a function of confidence
        plot_learning_rate_by_confidence(modelling_outputs, version_names(v), model, "actual", 1, figures_dir);
    end
    clear d modelling_outputs ordered_participant_list
end




%% plot parameters for parameter recovery

% AFTER HAVING SIMULATED AND FITTED DATA USING parameter_recovery.m

desired_n_repetitions = 50;

% Models used for generating data
generative_models = [1,2,4];  

% Models used for fitting 
% models on n-th line correspond to models to the n-th model listed in generative_models
fitting_models_for_each_generative_model =  { [2,4]; [2]; [4]; };
assert(size(generative_models,2) == size(fitting_models_for_each_generative_model,1), 'Problem: must be as many rows in fitting_models_for_each_generative_model as there are generative models');

% instead of version names, specify folder name in which required data version is stored (c.f. Simulations_recovery folder)
folders = [ "generativemodels_1234_fittingmodels_1234_1234_1234_1234_version_RL1_partial_complete_concat";
            "generativemodels_1234_fittingmodels_1234_1234_1234_1234_version_RL0_all";
            "generativemodels_1234_fittingmodels_1234_1234_1234_1234_version_RL3_partial_complete_concat"];

recovery_dir     = fullfile(output_dir,'Simulations_recovery');  

for f = 1:numel(folders)
    folder = folders(f);

    % prep structure containing all variables needed for plotting functions
    [s] = prepare_parameter_recovery_data_for_figures( generative_models, ...
                                                        recovery_dir, ...
                                                        folder, ...
                                                        fitting_models_for_each_generative_model, ...
                                                        data_dir, ...
                                                        output_dir, ...
                                                        color_dict, ...
                                                        desired_n_repetitions);

    % plot parameter recovery correlation matrix for models 2 and 4                                                  
    models = [2,4];
    for m = 1:numel(models)
        generative_model = models(m); 
        fitting_model = models(m); 
        % prepare variables with parameters for this generative model
        generated_parameters_combined_repetitions = s.simulated_data{generative_model}.generative_parameters;
        recovered_parameters_combined_repetitions = s.modelling_outcomes{generative_model}.parameters;

        plot_parameter_recovery_correlation_matrix(generative_model,...
                                            fitting_model,...
                                            generated_parameters_combined_repetitions,...
                                            recovered_parameters_combined_repetitions,...
                                            s.simulated_data_by_repetition,...
                                            s.modelling_outcomes_by_repetition,...
                                            s.models_info,...
                                            figures_dir,...
                                            s.reward_structure_dataset_name, ...
                                            s.simulated_data{generative_model}, ...
                                            s.colors, ...
                                            s.empirical_modelling_outputs.parameters);


    end

    % plot parameters for data simulated with model 1 (classic) and fitted with models 2 and 4                                                  
    generative_model = 1; 
    fitting_models = [2,4];
    for m = 1:numel(fitting_models)
        fitting_model = fitting_models(m);

        % prepare variables with parameters for this generative model
        generated_parameters_combined_repetitions = s.simulated_data{generative_model}.generative_parameters;
        recovered_parameters_combined_repetitions = s.modelling_outcomes{generative_model}.parameters;

        % call function which creates a bunch of plots showing parameter recovery   
        plot_recovered_bCON_bDIS_for_generativemodel1(generative_model,...
                                                fitting_model,...
                                                generated_parameters_combined_repetitions,...
                                                recovered_parameters_combined_repetitions,...
                                                s.simulated_data_by_repetition,...
                                                s.modelling_outcomes_by_repetition,...
                                                s.models_info,...
                                                figures_dir,...
                                                s.reward_structure_dataset_name, ...
                                                s.simulated_data{generative_model}, ...
                                                s.colors, ...
                                                s.empirical_modelling_outputs.parameters);
                            
    end
end
