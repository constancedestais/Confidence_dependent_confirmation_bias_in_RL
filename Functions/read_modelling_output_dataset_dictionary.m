function corresponding_smallest_dataset_units = read_modelling_output_dataset_dictionary(requested_output_dataset_name)

%{
% function 
    - creates a dictionary of task versions that can ve requested (the keys) and the smallest dataset units (values) that must be combined in order to get these task versions
    - returns the smallest_dataset_units corresponding to the requested_output_dataset_name 
% NB: can also consult dictionary like this: dataset_dictionary{"RL3_partialfeedback"} 
%}


% --- define key↔value pairs clearly, one per row ---
pairs = {
    % -------- RL3 datasets --------
    "RL3_vA",                               "RL3_vA";
    "RL3_vB",                               "RL3_vB";
    "RL3_vC",                               "RL3_vC";
    "RL3_vD",                               "RL3_vD";
    "RL3_partialfeedback",                  ["RL3_vA","RL3_vC"];
    "RL3_completefeedback",                 ["RL3_vB","RL3_vD"];
    "RL3_all",                              ["RL3_vA","RL3_vB","RL3_vC","RL3_vD"];

    % -------- RL1 reversal datasets --------
    "RL1_exp1",                  "RL1_exp1";
    "RL1_exp2",                  "RL1_exp2";
    "RL1_exp3",                  "RL1_exp3";
    "RL1_completefeedback",      "RL1_exp1";
    "RL1_partialfeedback",       ["RL1_exp2","RL1_exp3"];
    "RL1_all",                   ["RL1_exp1","RL1_exp2","RL1_exp3"];

    % -------- RL0 reversals datasets --------
    "RL0_exp1",                 "RL0_exp1";
    "RL0_exp2",                 "RL0_exp2";
    "RL0_exp3",                 "RL0_exp3";
    "RL0_exp4",                 "RL0_exp4";
    "RL0_exp5",                 "RL0_exp5";
    "RL0_exp6",                 "RL0_exp6";
    "RL0_exp7",                 "RL0_exp7";
    "RL0_all",                  ["RL0_exp1", ... 
                                                "RL0_exp2",...
                                                "RL0_exp3",...
                                                "RL0_exp4",...
                                                "RL0_exp5",...
                                                "RL0_exp6",...
                                                "RL0_exp7"];

    % -------- RL0 reversals datasets - with partial feedback --------
    "RL0_exp1_partialfeedbacktrials", "RL0_exp1_partialfeedbacktrials";
    "RL0_exp2_partialfeedbacktrials", "RL0_exp2_partialfeedbacktrials";
    "RL0_exp3_partialfeedbacktrials", "RL0_exp3_partialfeedbacktrials";
    "RL0_exp4_partialfeedbacktrials", "RL0_exp4_partialfeedbacktrials";
    "RL0_exp5_partialfeedbacktrials", "RL0_exp5_partialfeedbacktrials";
    "RL0_exp6_partialfeedbacktrials", "RL0_exp6_partialfeedbacktrials";
    "RL0_exp7_partialfeedbacktrials", "RL0_exp7_partialfeedbacktrials";
    "RL0_partialfeedbacktrials",      ["RL0_exp1_partialfeedbacktrials",...
                                                    "RL0_exp2_partialfeedbacktrials",...
                                                    "RL0_exp3_partialfeedbacktrials",...
                                                    "RL0_exp4_partialfeedbacktrials",...
                                                    "RL0_exp5_partialfeedbacktrials",...
                                                    "RL0_exp6_partialfeedbacktrials",...
                                                    "RL0_exp7_partialfeedbacktrials"];

    % -------- RL0 reversals datasets - with complete feedback --------
    "RL0_exp1_completefeedbacktrials", "RL0_exp1_completefeedbacktrials";
    "RL0_exp2_completefeedbacktrials", "RL0_exp2_completefeedbacktrials";
    "RL0_exp3_completefeedbacktrials", "RL0_exp3_completefeedbacktrials";
    "RL0_exp4_completefeedbacktrials", "RL0_exp4_completefeedbacktrials";
    "RL0_exp5_completefeedbacktrials", "RL0_exp5_completefeedbacktrials";
    "RL0_exp6_completefeedbacktrials", "RL0_exp6_completefeedbacktrials";
    "RL0_exp7_completefeedbacktrials", "RL0_exp7_completefeedbacktrials";
    "RL0_completefeedbacktrials",      ["RL0_exp1_completefeedbacktrials",...
                                                    "RL0_exp2_completefeedbacktrials",...
                                                    "RL0_exp3_completefeedbacktrials",...
                                                    "RL0_exp4_completefeedbacktrials",...
                                                    "RL0_exp5_completefeedbacktrials",...
                                                    "RL0_exp6_completefeedbacktrials",...
                                                    "RL0_exp7_completefeedbacktrials"];

    % -------- RL1 reversal datasets - blocks 1&3 --------
    "RL1_exp1_blocks13",             "RL1_exp1_blocks13";
    "RL1_exp2_blocks13",             "RL1_exp2_blocks13";
    "RL1_exp3_blocks13",             "RL1_exp3_blocks13";
    "RL1_partialfeedback_blocks13",  ["RL1_exp2_blocks13","RL1_exp3_blocks13"];
    "RL1_completefeedback_blocks13", "RL1_exp1_blocks13";
    "RL1_all_blocks13",              ["RL1_exp1_blocks13","RL1_exp2_blocks13","RL1_exp3_blocks13"];

    % -------- RL1 reversal datasets - blocks 2&4 --------
    "RL1_exp1_blocks24",              "RL1_exp1_blocks24";
    "RL1_exp2_blocks24",              "RL1_exp2_blocks24";
    "RL1_exp3_blocks24",              "RL1_exp3_blocks24";
    "RL1_partialfeedback_blocks24",   ["RL1_exp2_blocks24","RL1_exp3_blocks24"];
    "RL1_completefeedback_blocks24",  "RL1_exp1_blocks24";
    "RL1_all_blocks24",               ["RL1_exp1_blocks24","RL1_exp2_blocks24","RL1_exp3_blocks24"];

    % -------- RL3 1 reversal datasets - blocks 1&3 --------
    "RL3_vA_blocks13",                      "RL3_vA_blocks13";
    "RL3_vB_blocks13",                      "RL3_vB_blocks13";
    "RL3_vC_blocks13",                      "RL3_vC_blocks13";
    "RL3_vD_blocks13",                      "RL3_vD_blocks13";
    "RL3_partialfeedback_blocks13",         ["RL3_vA_blocks13", "RL3_vC_blocks13"];
    "RL3_completefeedback_blocks13",        ["RL3_vB_blocks13", "RL3_vD_blocks13"];
    "RL3_all_blocks13",                     ["RL3_vA_blocks13","RL3_vB_blocks13","RL3_vC_blocks13","RL3_vD_blocks13"];

    % -------- RL3 1 reversal datasets - blocks 2&4 --------
    "RL3_vA_blocks24",                      "RL3_vA_blocks24";
    "RL3_vB_blocks24",                      "RL3_vB_blocks24";
    "RL3_vC_blocks24",                      "RL3_vC_blocks24";
    "RL3_vD_blocks24",                      "RL3_vD_blocks24";
    "RL3_all_blocks24",                     ["RL3_vA_blocks24","RL3_vB_blocks24","RL3_vC_blocks24","RL3_vD_blocks24"];
};

% Keys and values (values remain string arrays; singletons are 1x1 string arrays)
output_datasets        = string(pairs(:,1));
smallest_dataset_units = pairs(:,2);  % cell array of string arrays

% sanity check (unchanged)
assert(ismember(requested_output_dataset_name, output_datasets), 'Problem: the dataset name you request is not available (check the spelling)');

% Create the dictionary with keys and values
dataset_dictionary = dictionary(output_datasets, smallest_dataset_units);

% Get values in dictionary corresponding to requested key
corresponding_smallest_dataset_units = dataset_dictionary{requested_output_dataset_name};

end