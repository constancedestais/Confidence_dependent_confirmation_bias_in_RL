%% Setup workspace/directories/paths 
% among other things, loads the folowing directories: output_dir, data_dir, figures_dir
load_working_environment; 

color_dict = load_my_colors;


%% plot a_DIS vs. a_CON (resp. b_DIS vs b_CON) on the same figure for RL0, RL1, and RL3 - model with confidence-dependent learning

% Versions to loop over
version_names = ["MLNSG_0reversals_all",...
                "MLNSG_1reversal_all",...
                "CDAG_all"];
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
version_names = ["MLNSG_0reversals_all",...
                "MLNSG_1reversal_all",...
                "CDAG_all"];
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
version_names = ["MLNSG_0reversals_partialfeedbacktrials",...
                "MLNSG_0reversals_completefeedbacktrials",...
                "MLNSG_1reversal_partialfeedback",...  
                "MLNSG_1reversal_completefeedback",...
                "CDAG_partialfeedback",...
                "CDAG_completefeedback"];
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




