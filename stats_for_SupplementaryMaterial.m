%% Setup workspace/directories/paths 
% among other things, loads the folowing directories: output_dir, data_dir, figures_dir
load_working_environment; 

[models_info,models_info_extra] = load_models_info();


%% Effect of reversal on confidence and accuracy for for RL1
% average confidence/accuracy for trial around reversal (t-1 to t+5) 
% with a t-test comparing confidence on trial t_x vs. t (or t-1 for accuracy) to see if there is a significant drop in confidence/accuracy after the reversal

fprintf("======== MLNSG_1reversal_all ========")

pre  = 1;
post = 5;

version_name = [ "MLNSG_1reversal_all"] ; %+ version_names_CD2 ; %version_names_MLNSG + version_names_CDAG; 
cond_idx = [2 4]; % only these conditions have a reversal

% load behavioural data - load data in both table and matrix forms
dataset_type = "matrix"; 
d = load_behaviour_datasets(version_name,  dataset_type, data_dir);  

% scale to 0-100
d.confidence_rating = d.confidence_rating *100;
d.chose_highest = d.chose_highest *100;

variables = ["confidence_rating","chose_highest"];  % add more as needed
reference_lags = [0, -1]; % compare confidence to reversal trial and correct to previous trials
results = event_locked_participant_pipeline(d, variables, cond_idx, pre, post, reference_lags);
% Table with mean ± 95% CI and 1-sided tests vs t (lag 0)
fprintf("\nconfidence_rating: compare to trial %d\n",reference_lags(1))
tbl = results.confidence_rating.summaryTable;
disp(tbl)
fprintf("\nchose_highest: compare to trial %d\n",reference_lags(2))
tbl = results.chose_highest.summaryTable;
disp(tbl)
a=1;

clear d 

%% Effect of reversal on confidence and accuracy for for RL3
% average confidence/accuracy for trial around reversal (t-1 to t+5) 
% with a t-test comparing confidence on trial t_x vs. t (or t-1 for accuracy) to see if there is a significant drop in confidence/accuracy after the reversal

fprintf("======== CDAG_all ========")

pre  = 1;
post = 5;

version_name = [ "CDAG_all"] ; %+ version_names_CD2 ; %version_names_MLNSG + version_names_CDAG; 
cond_idx = [1 2 3 4]; 

% load behavioural data - load data in both table and matrix forms
dataset_type = "matrix"; 
d = load_behaviour_datasets(version_name,  dataset_type, data_dir);   

% scale to 0-100
d.confidence_rating = d.confidence_rating *100;
d.chose_highest = d.chose_highest *100;

variables = ["confidence_rating","chose_highest"];  % add more as needed
reference_lags = [0, -1]; % compare confidence to reversal trial and correct to previous trials
results = event_locked_participant_pipeline(d, variables, cond_idx, pre, post, reference_lags);
% Table with mean ± 95% CI and 1-sided tests vs t (lag 0)
fprintf("\nconfidence_rating: compare to trial %d\n",reference_lags(1))
tbl = results.confidence_rating.summaryTable;
disp(tbl)
fprintf("\nchose_highest: compare to trial %d\n",reference_lags(2))
tbl = results.chose_highest.summaryTable;
disp(tbl)
a=1;



%% Beta distributions fitted to empirical parameter distributions 
% do this for RL0, RL1, and RL3 (full dataset / Partial info condition / Complete info condition) 
% do this for models 1, 2 and 4 (c.f. README)

% Datasets (task versions) to loop over 
version_names = ["MLNSG_0reversals_all", ...
                 "MLNSG_1reversal_all", ...
                 "CDAG_all", ...
                 "MLNSG_0reversals_partialfeedbacktrials", ...
                 "MLNSG_0reversals_completefeedbacktrials", ...
                 "MLNSG_1reversal_partialfeedback", ... 
                 "MLNSG_1reversal_completefeedback", ...
                 "CDAG_partialfeedback", ...
                 "CDAG_completefeedback"
                 ];

% Models to loop over
models = [2,4];

% combine data from each version into a cell array
n_versions = numel(version_names);

% load behaviour from all versions of interest - because in order to look at the effect of versions on behaviour, the script itself loops over versions
for v = 1:n_versions
    version_names{v}
    % load data 
    dataset_type = "table"; 
    behaviour_array_by_version{v} = load_behaviour_datasets(version_names{v},  dataset_type, data_dir); 
    dataset_type = "matrix"; 
    behaviour_matrix_by_version{v} = load_behaviour_datasets(version_names{v},  dataset_type, data_dir); 
end

% prepare data  
[my_table,my_vectors] = group_data_by_valence_and_volatility(behaviour_array_by_version, version_names);

% compute stats for each version
for v = 1:n_versions
    fprintf("\n \n================== version: %s =================== \n",version_names{v})

    % load behaviour to get list of participants in order
    data = behaviour_matrix_by_version{v};    
    % create list of p articipants in the order in which they appear in behavioural dataset
    ordered_participant_list = unique(data.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));
    % load modelling outputs
    outcome_encoding = "actual";
    modelling_outputs  = load_modelling_outputs(version_names(v), outcome_encoding, output_dir, ordered_participant_list);

    for m = 1:numel(models)
        fprintf("\n\n-------- model: %i -------- \n",models(m))
        model = models(m);

        % loop over parameters and print fitted Beta function parameters
        for i_param=1:size(modelling_outputs.parameters{model},2)

            min_parameter = models_info{model}.param_lowerbound(i_param);
            max_parameter = models_info{model}.param_upperbound(i_param);
        
            [~, ~, alpha, beta] = fit_and_generate_beta_parameter( ...
                                        modelling_outputs.parameters{model}(:, i_param), ...
                                        min_parameter, ...
                                        max_parameter, ...
                                        1, ...
                                        i_param ...
                                    );
            fprintf("\n Beta distribution fitted to parameter #%i: alpha,beta: (%.2f, %.2f)", i_param, alpha, beta);
        end
    end
    clear d modelling_outputs ordered_participant_list
 

end

