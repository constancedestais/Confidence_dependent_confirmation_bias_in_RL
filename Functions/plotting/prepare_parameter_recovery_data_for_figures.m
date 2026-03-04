
function [outputs] = prepare_parameter_recovery_data_for_figures( generative_models, ...
                                                                    recovery_dir, ...
                                                                    folder, ...
                                                                    fitting_models_for_each_generative_model, ...
                                                                    data_dir, ...
                                                                    output_dir, ...
                                                                    color_dict, ...
                                                                    desired_n_repetitions)


%% load data

% specify fields to delete from loaded data to save memory
fields_to_delete = {
    "date",... % from modelling outcomes
    "seed",... 
    "gradient_nLPP",...
    "hessian_nLPP",...
    "Q",... 
    "PChosen",...
    "PSwitch",...
    "PCorrect",...
    "symbol_chosen_id_relative",... % from simulated data
    "symbol_chosen_actual_payoff",...
    "symbol_unchosen_actual_payoff",...
    "chose_highest",...
    "confidence_rating",...
    "switched_choice",...
    "chose_symbol_1",...
    "exp_ID",...
    "full_feedback",...
    "valence",...
    "session",...
    "condition",... 
    "condition_name",...
    "trial_by_condition",...
    "correct_schedule",...
    "reversal",...
    "symbol_1_actual_payoff",...
    "symbol_2_actual_payoff",...
    "reward_schedule",...
    "real_confidence",...
    "n_reversals_per_block",...
    };

% load data
[settings_by_repetition, simulated_data_by_repetition_original, modelling_outcomes_by_repetition_original, simulated_data, modelling_outcomes] = load_simulation_recovery_data( generative_models, ...
                                                                                                                                                                                recovery_dir, ...
                                                                                                                                                                                folder, ...
                                                                                                                                                                                fields_to_delete, ...
                                                                                                                                                                                fitting_models_for_each_generative_model);

                                                                                                                                                                        
% %% remove data for models not amoung those requested for fitting/generating
a=1; 

% define version name based on settings
version_name = settings_by_repetition{1}.version_name ;


% save settings info in easy-to-access variables
reward_structure_dataset_name = settings_by_repetition{1}.reward_structure_dataset_name ;

colors = {color_dict.green,color_dict.red,color_dict.blue,color_dict.grey,color_dict.black,color_dict.light_green,color_dict.light_grey,color_dict.light_red,color_dict.dark_blue,color_dict.dark_green,color_dict.dark_red,color_dict.dark_purple,color_dict.dark_grey,color_dict.orange,color_dict.yellow};


%% -------- CREATE SUBSET OF DATA WITH SAME NUMBER OF AGENTS AS IN REAL DATASETS, e.g. simulated 100 agents in each repetition but real data has 21 participants only --------
% generic version name
if contains(version_name, "RL0")
    n_agents_in_real_data = 148;
elseif contains(version_name, "RL1_partialfeedback")
    n_agents_in_real_data = 18;  
elseif contains(version_name, "RL1_completefeedback")
    n_agents_in_real_data = 48;  
elseif contains(version_name, "RL1_partial_complete")
    n_agents_in_real_data = 66;
elseif (contains(version_name, "RL3_partialfeedback") || contains(version_name, "RL3_completefeedback"))
    n_agents_in_real_data = 50;
elseif contains(version_name, "RL3_partial_complete")
    n_agents_in_real_data = 100;
end

% remove seed from modelling_outcomes to avoid dealing with it because of size issues
for gm = generative_models
    if isfield(modelling_outcomes{gm}, 'seed')
        modelling_outcomes{gm} = rmfield(modelling_outcomes{gm}, 'seed');
    end
end

% remove unsued fields to lighten the data

% can now subdivide repetitions into only n_agents_in_real_data agents - first combine all repetitions, then divide in groups of n_agents_in_real_data agents
% this should not affect combined data, only data by repetition
[simulated_data_by_repetition, modelling_outcomes_by_repetition] = regroup_simulation_repetitions( simulated_data,modelling_outcomes, generative_models, n_agents_in_real_data );


% recompute number of repetitions
n_repetitions = numel(simulated_data_by_repetition);
%% -------- ONLY KEEP DESIRED NUMBER OF REPETITIONS --------

if n_repetitions < desired_n_repetitions
    fprintf('\nNot enough repetitions to keep 50 only')
end
final_n_repetitions = min(n_repetitions, desired_n_repetitions);
simulated_data_by_repetition = simulated_data_by_repetition(1:final_n_repetitions);
modelling_outcomes_by_repetition = modelling_outcomes_by_repetition(1:final_n_repetitions);

%% -------- also load empirical parameters for same datasets --------

% generic version name
if contains(version_name, "RL0_partialfeedbacktrials")
    empirical_version_name = "RL0_partialfeedbacktrials";

elseif contains(version_name, "RL0_completefeedbacktrials")
    empirical_version_name = "RL0_completefeedbacktrials";

elseif contains(version_name, "RL0_all")
    empirical_version_name = "RL0_all";

elseif contains(version_name, "RL1_partialfeedback")
    empirical_version_name = "RL1_partialfeedback";

elseif contains(version_name, "RL1_completefeedback")
    empirical_version_name = "RL1_completefeedback";

elseif contains(version_name, "RL1_partial_complete")
    empirical_version_name = "RL1_all";

elseif (contains(version_name, "RL3_partialfeedback"))
    empirical_version_name = "RL3_partialfeedback";
    
elseif (contains(version_name, "RL3_completefeedback"))
    empirical_version_name = "RL3_completefeedback";
    
elseif contains(version_name, "RL3_partial_complete")
    empirical_version_name = "RL3_all";
end

% load behaviour to get list of participants in order
dataset_type = "matrix"; 
d = load_behaviour_datasets(empirical_version_name,  dataset_type, data_dir);    
% create list of p articipants in the order in which they appear in behavioural dataset
ordered_participant_list = unique(d.participant_ID,"stable");
ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));

outcome_encoding_for_fitting = "actual";
empirical_modelling_outputs  = load_modelling_outputs(empirical_version_name, outcome_encoding_for_fitting, output_dir, ordered_participant_list);
clear d ordered_participant_list


%% prepare output structure
outputs = struct();
outputs.simulated_data = simulated_data;
outputs.modelling_outcomes = modelling_outcomes;
outputs.simulated_data_by_repetition = simulated_data_by_repetition;
outputs.modelling_outcomes_by_repetition = modelling_outcomes_by_repetition;
outputs.reward_structure_dataset_name = reward_structure_dataset_name;
outputs.empirical_modelling_outputs = empirical_modelling_outputs;
outputs.colors = colors;
outputs.models_info = load_models_info();
