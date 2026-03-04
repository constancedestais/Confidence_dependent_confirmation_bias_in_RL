
%% Setup workspace/directories/paths 
% among other things, loads the folowing directories: output_dir, data_dir, figures_dir
load_working_environment; 

color_dict = load_my_colors;


%% plot estimated parameters and learning rate as a function of confidence for RL0, RL1, and RL3 (full dataset) for models 2 and 4 (c.f. README)

% all requested versions to loop over
version_names = ["RL0_all",...
                "RL1_all",...
                "RL3_all"];
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
    outcome_encoding = "actual";
    % load modelling outputs
    modelling_outputs  = load_modelling_outputs(version_names(v), outcome_encoding, output_dir, ordered_participant_list);

    % loop over requested models 
    for m = 1:numel(models)
        model = models(m);
        % plot parameter values
        plot_parameters_skyline(modelling_outputs.parameters{model}, version_names(v), model, outcome_encoding, figures_dir);      
        % plot learning rate as a function of confidence
        plot_learning_rate_by_confidence(modelling_outputs, version_names(v), model, outcome_encoding, 1, figures_dir);
    end
    clear d modelling_outputs ordered_participant_list
end



%% plot estimated parameters and learning rate as a function of confidence in RL0, RL1, and RL3 (Complete info condition), using model 2 (c.f. README)

% all requested versions to loop over
version_names = ["RL0_completefeedbacktrials",...
                "RL1_completefeedback",...
                "RL3_completefeedback"];
% Models to loop over
models = [2]; 

for v = 1:numel(version_names) 

    % load behaviour to get list of participants in order
    dataset_type = "matrix"; 
    d = load_behaviour_datasets(version_names{v},  dataset_type, data_dir);    
    % create list of p articipants in the order in which they appear in behavioural dataset
    ordered_participant_list = unique(d.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));

    % load modelling outputs
    modelling_outputs  = load_modelling_outputs(version_names(v), outcome_encoding, output_dir, ordered_participant_list);

    % loop over requested models 
    for m = 1:numel(models)
        model = models(m);
        % plot parameter values
        plot_parameters_skyline(modelling_outputs.parameters{model}, version_names(v), model, outcome_encoding, figures_dir);      
        % plot learning rate as a function of confidence
        plot_learning_rate_by_confidence(modelling_outputs, version_names(v), model, outcome_encoding, 1, figures_dir);
    end
    clear d modelling_outputs ordered_participant_list
end




%% plot choice accuracy and confidence by trial in RL0 - across all conditions
version_name = "RL0_all"; 

% load matrix-form data
dataset_type = "matrix";
data_mat = load_behaviour_datasets(version_name, dataset_type, data_dir);

% prepare stats once
prepared_data = prepare_behaviour_over_block_data(data_mat, version_name);

% plot data averaged across all conditions
plot_behaviour_over_block_average(prepared_data, version_name, figures_dir);


%% plot choice accuracy and confidence by trial in RL1 and RL3 - across high vs low volatility

version_names = {"RL1_all", "RL3_all"}; 

for version_index = 1:numel(version_names)
    version_name = version_names{version_index};

    % load matrix-form data
    dataset_type = "matrix";
    data_mat = load_behaviour_datasets(version_name, dataset_type, data_dir);

    % prepare stats once
    prepared_data = prepare_behaviour_over_block_data(data_mat, version_name);

    % plot data averaged across low vs high volatility (overlaid)
    plot_behaviour_over_block_volatility_overlay(prepared_data, version_name, figures_dir);
end


%% plot choice accuracy and confidence around the reversal for RL1 - in the high volatility condition (only condition with a reversal)

pre  = 5;
post = 5;

version_name = [ "RL1_all"] ; 
condition_idx = [2 4];  % only these conditions have a reversal

% load behavioural data - load data in both table and matrix forms
dataset_type = "matrix"; 
d = load_behaviour_datasets(version_name,  dataset_type, data_dir);   

% plot choice accuracy
out_correct = extract_event_locked_participant_traces(d, 'chose_highest', condition_idx, pre, post);
plot_behaviour_around_reversal_one_var(out_correct, pre, version_name, figures_dir, ...
    'pcorrect', '', [0 100], 0:50:100, color_dict.black);

% plot confidence
out_conf = extract_event_locked_participant_traces(d, 'confidence_rating', condition_idx, pre, post);
plot_behaviour_around_reversal_one_var(out_conf, pre, version_name, figures_dir, ...
    'confidence', '', [65 85], 65:10:85, color_dict.black);


%% plot choice accuracy and confidence around the reversal for RL3 - across all conditions (since both have a reversal)

pre  = 5;
post = 5;

version_name = [ "RL3_all"] ; 
condition_idx = [1 2 3 4]; 

% load behavioural data - load data in both table and matrix forms
dataset_type = "matrix"; 
d = load_behaviour_datasets(version_name,  dataset_type, data_dir);   

% plot choice accuracy
out_correct = extract_event_locked_participant_traces(d, 'chose_highest', condition_idx, pre, post);
plot_behaviour_around_reversal_one_var(out_correct, pre, version_name, figures_dir, ...
    'pcorrect', '', [0 100], 0:50:100, color_dict.black);

% plot confidence
out_conf = extract_event_locked_participant_traces(d, 'confidence_rating', condition_idx, pre, post);
plot_behaviour_around_reversal_one_var(out_conf, pre, version_name, figures_dir, ...
    'confidence', '', [65 85], 65:10:85, color_dict.black);

