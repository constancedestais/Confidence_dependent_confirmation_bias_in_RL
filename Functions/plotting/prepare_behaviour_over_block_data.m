function prepared_data = prepare_behaviour_over_block_data(data_matrix, version_name)
% Prepare participant-level summaries and statistics for behaviour-over-block plots.
% This function is intentionally self-contained (no project-specific dependencies).
%
% INPUTS
% - data_matrix  : struct with 4D behavioural matrices (participants x sessions x conditions x trials)
%                  Required fields:
%                  chose_highest, confidence_rating, switched_choice,
%                  n_reversals_per_block, reversal, trial_by_condition
% - version_name : dataset/version label (used for optional hard-coded reversal windows)
%
% OUTPUT
% - prepared_data : struct used directly by plotting functions
%   - stats.all.correct/confidence/switches
%   - stats.stable.* and stats.volatile.* (if volatility groups exist)
%   - conditions.all/stable/volatile
%   - windows.stable/volatile
%   - flags.plot_by_volatility_conditions

% ---------- Validate required inputs ----------
required_field_names = { ...
    "chose_highest", "confidence_rating", "switched_choice", ...
    "n_reversals_per_block", "reversal", "trial_by_condition" ...
};
assert_required_fields(data_matrix, required_field_names);
% each field should be 4D: participants x sessions x conditions x trials
for field_index = 1:numel(required_field_names)
    field_name = required_field_names{field_index};
    field_value = data_matrix.(field_name);
    assert(ndims(field_value) == 4, ...
        "Expected data_matrix.%s to be a 4D array.", field_name);
end

% ---------- Determine usable trial count ----------
all_trial_numbers = data_matrix.trial_by_condition(~isnan(data_matrix.trial_by_condition));
assert(~isempty(all_trial_numbers), "trial_by_condition contains no valid trial numbers.");
number_of_trials = max(all_trial_numbers);

% Trim every 4D field to the detected trial count (prevents trailing NaN columns).
data_matrix = trim_all_four_dimensional_fields(data_matrix, number_of_trials);

% ---------- Basic dimensions and condition indexing ----------
number_of_participants = size(data_matrix.chose_highest, 1);
number_of_conditions = size(data_matrix.chose_highest, 3);
all_condition_indices = 1:number_of_conditions;

% ---------- Prepare output container ----------
prepared_data = struct();
prepared_data.metadata.version_name = string(version_name);
prepared_data.metadata.number_of_participants = number_of_participants;
prepared_data.metadata.number_of_conditions = number_of_conditions;
prepared_data.metadata.number_of_trials = number_of_trials;

prepared_data.conditions.all = all_condition_indices;
prepared_data.conditions.stable = [];
prepared_data.conditions.volatile = [];

prepared_data.windows.stable = [];
prepared_data.windows.volatile = [];

prepared_data.flags.plot_by_volatility_conditions = false;

% ---------- Compute per-participant traces for all conditions ----------
% 1) Average across sessions -> participants x conditions x trials
% 2) Average across all conditions -> participants x trials
variable_labels = {"correct", "confidence", "switches"};
source_field_names = {"chose_highest", "confidence_rating", "switched_choice"};

for variable_index = 1:numel(variable_labels)
    variable_label = variable_labels{variable_index};
    source_field_name = source_field_names{variable_index};

    raw_variable = data_matrix.(source_field_name);
    participant_condition_trial_values = average_across_sessions(raw_variable);
    participant_trial_values_all_conditions = average_across_conditions( ...
        participant_condition_trial_values, all_condition_indices);

    prepared_data.by_condition.(variable_label) = participant_condition_trial_values;
    prepared_data.by_participant.all.(variable_label) = participant_trial_values_all_conditions;
    prepared_data.stats.all.(variable_label) = average_across_participants( ...
        participant_trial_values_all_conditions, 0.95);
end

% ---------- Detect stable vs volatile condition groups ----------
% We infer one reversal-count value per condition index.
reversal_count_by_condition = infer_reversal_count_per_condition(data_matrix.n_reversals_per_block);
valid_reversal_counts = reversal_count_by_condition(~isnan(reversal_count_by_condition));
unique_reversal_counts = unique(valid_reversal_counts);

has_distinct_volatility_groups = numel(unique_reversal_counts) > 1 && max(unique_reversal_counts) > 0;

if has_distinct_volatility_groups
    prepared_data.flags.plot_by_volatility_conditions = true;

    minimum_reversal_count = min(unique_reversal_counts);
    maximum_reversal_count = max(unique_reversal_counts);

    stable_condition_indices = find(reversal_count_by_condition == minimum_reversal_count);
    volatile_condition_indices = find(reversal_count_by_condition == maximum_reversal_count);

    prepared_data.conditions.stable = stable_condition_indices;
    prepared_data.conditions.volatile = volatile_condition_indices;

    % Compute stable/volatile participant-level traces and statistics
    for variable_index = 1:numel(variable_labels)
        variable_label = variable_labels{variable_index};
        participant_condition_trial_values = prepared_data.by_condition.(variable_label);

        stable_participant_trial_values = average_across_conditions( ...
            participant_condition_trial_values, stable_condition_indices);
        volatile_participant_trial_values = average_across_conditions( ...
            participant_condition_trial_values, volatile_condition_indices);

        prepared_data.by_participant.stable.(variable_label) = stable_participant_trial_values;
        prepared_data.by_participant.volatile.(variable_label) = volatile_participant_trial_values;

        prepared_data.stats.stable.(variable_label) = average_across_participants( ...
            stable_participant_trial_values, 0.95);
        prepared_data.stats.volatile.(variable_label) = average_across_participants( ...
            volatile_participant_trial_values, 0.95);
    end

end

end

% =====================================================================
% Local helper functions
% =====================================================================

function assert_required_fields(data_structure, required_field_names)
% Ensure all required fields exist in input struct.
for field_index = 1:numel(required_field_names)
    field_name = required_field_names{field_index};
    assert(isfield(data_structure, field_name), ...
        "Missing required field: %s", field_name);
end
end

function trimmed_data_structure = trim_all_four_dimensional_fields(data_structure, target_trial_count)
% Trim each 4D field to target trial count on dimension 4.
trimmed_data_structure = data_structure;
field_names = fieldnames(data_structure);

for field_index = 1:numel(field_names)
    current_field_name = field_names{field_index};
    current_value = data_structure.(current_field_name);

    if ndims(current_value) == 4 && size(current_value, 4) >= target_trial_count
        trimmed_data_structure.(current_field_name) = current_value(:, :, :, 1:target_trial_count);
    end
end
end




function participant_condition_trial_values = average_across_sessions(variable_values)
% Average a 4D variable across sessions (dimension 2).
% Input:  participants x sessions x conditions x trials
% Output: participants x conditions x trials

assert(ndims(variable_values) == 4, "Expected a 4D variable.");

number_of_participants = size(variable_values, 1);
number_of_conditions = size(variable_values, 3);
number_of_trials = size(variable_values, 4);

session_averaged_values = mean(variable_values, 2, "omitnan");
participant_condition_trial_values = reshape( ...
    session_averaged_values, number_of_participants, number_of_conditions, number_of_trials);
end




function participant_trial_values = average_across_conditions(participant_condition_trial_values, selected_condition_indices)
% Average participant-condition-trial values across selected conditions.
% Input:  participants x conditions x trials
% Output: participants x trials

assert(ndims(participant_condition_trial_values) == 3, ...
    "Expected participant_condition_trial_values to be 3D.");

number_of_participants = size(participant_condition_trial_values, 1);
number_of_trials = size(participant_condition_trial_values, 3);

if isempty(selected_condition_indices)
    participant_trial_values = NaN(number_of_participants, number_of_trials);
    return;
end

condition_averaged_values = mean( ...
    participant_condition_trial_values(:, selected_condition_indices, :), 2, "omitnan");
participant_trial_values = reshape(condition_averaged_values, number_of_participants, number_of_trials);
end




function statistics = average_across_participants(participant_trial_values, confidence_interval_boundary)
% Compute mean, SEM, and CI per trial.
% Unit of inference: participant.
%
% Input: participants x trials

trial_mean = mean(participant_trial_values, 1, "omitnan");
trial_sample_size = sum(~isnan(participant_trial_values), 1);
trial_standard_deviation = std(participant_trial_values, 0, 1, "omitnan");
trial_standard_error = trial_standard_deviation ./ sqrt(trial_sample_size);

alpha = 1 - confidence_interval_boundary;
degrees_of_freedom = trial_sample_size - 1;

% Use t critical value if available; otherwise fallback to normal approximation.
if exist("tinv", "file") == 2
    trial_t_critical = tinv(1 - alpha/2, degrees_of_freedom);
else
    % z critical via inverse complementary error function.
    z_critical = -sqrt(2) * erfcinv(2 * (1 - alpha/2));
    trial_t_critical = z_critical * ones(size(degrees_of_freedom));
end

trial_t_critical(degrees_of_freedom <= 0) = NaN;

trial_ci_upper = trial_mean + trial_t_critical .* trial_standard_error;
trial_ci_lower = trial_mean - trial_t_critical .* trial_standard_error;

statistics = struct();
statistics.sample_mean = trial_mean;
statistics.sample_sem = trial_standard_error;
statistics.CI_upper = trial_ci_upper;
statistics.CI_lower = trial_ci_lower;
statistics.sample_size = trial_sample_size;
end

function reversal_count_by_condition = infer_reversal_count_per_condition(n_reversals_per_block)
% Infer one reversal-count value per condition index by taking mode over
% participants/sessions/trials within each condition.
assert(ndims(n_reversals_per_block) == 4, "Expected n_reversals_per_block to be 4D.");

number_of_conditions = size(n_reversals_per_block, 3);
reversal_count_by_condition = NaN(1, number_of_conditions);

for condition_index = 1:number_of_conditions
    condition_values = n_reversals_per_block(:, :, condition_index, :);
    condition_values = condition_values(~isnan(condition_values));

    if ~isempty(condition_values)
        reversal_count_by_condition(condition_index) = mode(condition_values);
    end
end
end


