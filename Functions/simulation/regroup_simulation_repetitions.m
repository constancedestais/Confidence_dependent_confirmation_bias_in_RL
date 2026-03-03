function [simulated_data_by_repetition,modelling_outcomes_by_repetition] = regroup_simulation_repetitions( simulated_data_combined,modelling_outcomes_combined, generative_models, agents_per_repetition )

% regroup_simulation_repetitions  Re-slice combined simulation/modelling data into new repetitions
%
%   [sim_by_rep, mod_by_rep] = regroup_simulation_repetitions(sim_data, mod_outcomes, ...
%                               generative_models, agents_per_repetition)
%   splits the already-concatenated results (across all original repetitions) into
%   repetitions of size agents_per_repetition, so downstream code that expects
%   {repetition}{generative_model} inputs can be run with any target sample size.
%
%   Inputs:
%       simulated_data_combined     cell array indexed by generative model id
%       modelling_outcomes_combined cell array indexed by generative model id
%       generative_models           vector of generative model ids to reshape
%       agents_per_repetition       desired number of agents in each new repetition
%
%   Outputs:
%       simulated_data_by_repetition    {n_new_reps}{max(generative_models)} cell array
%       modelling_outcomes_by_repetition same shape as above

% regroup_simulation_repetitions  Re-slice combined simulation/modelling data into fixed-size repetitions.
%
% Workflow:
%   1. Slice the fully combined structs into repetitions of size `agents_per_repetition`
%      (the final repetition may be smaller).
%   2. Double-check that concatenating those repetitions exactly rebuilds the original data.
%   3. Drop the last repetition if it is smaller than requested so downstream analyses
%      only receive full-size repetitions.

    arguments
        simulated_data_combined (1,:) cell
        modelling_outcomes_combined (1,:) cell
        generative_models (1,:) double
        agents_per_repetition (1,1) double {mustBePositive, mustBeInteger}
    end

    % ----- Preparation & sanity checks -----
    max_gm = max(generative_models);
    ref_gm = generative_models(1);
    total_agents = size(simulated_data_combined{ref_gm}.generative_parameters, 1);

    % Every generative model should contain the same number of agents before reshaping.
    for gm = generative_models
        assert(size(simulated_data_combined{gm}.generative_parameters, 1) == total_agents, ...
            'Generative model %d has %d agents, expected %d', gm, ...
            size(simulated_data_combined{gm}.generative_parameters, 1), total_agents);
    end

    % Number of repetitions needed so the last one can be shorter if needed.
    n_new_reps = ceil(total_agents / agents_per_repetition);
    simulated_data_by_repetition = cell(1, n_new_reps);
    modelling_outcomes_by_repetition = cell(1, n_new_reps);

    % ----- Slice each repetition -----
    for new_rep_idx = 1:n_new_reps
        start_agent = (new_rep_idx - 1) * agents_per_repetition + 1;
        stop_agent = min(new_rep_idx * agents_per_repetition, total_agents);
        agent_indices = start_agent:stop_agent;      % Agents to include in this repetition

        simulated_data_by_repetition{new_rep_idx} = cell(1, max_gm);
        modelling_outcomes_by_repetition{new_rep_idx} = cell(1, max_gm);

        for gm = generative_models
            % Slice the simulated data and modelling outcomes along the agent dimension.
            simulated_data_by_repetition{new_rep_idx}{gm} = slice_simulated_struct(simulated_data_combined{gm}, agent_indices);
            modelling_outcomes_by_repetition{new_rep_idx}{gm} = slice_modelling_struct(modelling_outcomes_combined{gm}, agent_indices);
        end
    end

    fprintf('Regrouped %d agents into %d repetition(s) of up to %d agents.\n', total_agents, n_new_reps, agents_per_repetition);

    % ----- Integrity check: regrouping must be lossless -----
    sim_rebuilt = concatenate_simulated_data(simulated_data_by_repetition, generative_models);
    mod_rebuilt = concatenate_modelling_outcomes(modelling_outcomes_by_repetition, generative_models);

    for gm_idx = 1:numel(generative_models)
        gm = generative_models(gm_idx);
        if ~isequaln(sim_rebuilt{gm}, simulated_data_combined{gm})
            assert(isequaln(sim_rebuilt{gm}, simulated_data_combined{gm}), 'Simulation mismatch for GM (%d) after regrouping', gm);
        end
        if ~isequaln(mod_rebuilt{gm}, modelling_outcomes_combined{gm})
            assert(isequaln(mod_rebuilt{gm}, modelling_outcomes_combined{gm}), 'Modelling mismatch for GM (%d) after regrouping', gm);
        end
    end

    % ----- Drop final repetition if it is shorter than requested -----
    final_rep_size = size(simulated_data_by_repetition{end}{generative_models(1)}.generative_parameters, 1);
    if final_rep_size < agents_per_repetition
        fprintf('Dropping final repetition with %d agents (< %d requested).\n', final_rep_size, agents_per_repetition);
        simulated_data_by_repetition(end) = [];
        modelling_outcomes_by_repetition(end) = [];
        n_dropped = final_rep_size;
    else
        n_dropped = 0;
    end

    % ----- Alignment check: simulated vs modelled participant IDs -----
    for rep = 1:numel(simulated_data_by_repetition)
        for gm = generative_models
            sim_ids = simulated_data_by_repetition{rep}{gm}.participant_ID;
            % sim_ids is of dimensions n_agents x n_sessions x n_conditions x n_trials (with the same ID repeated within all trials of one agent)
            % I want vector of dimensions n_agents x 1, containing the ID for each agent
            % so take the ID from the first trial of the first condition of the first session
            sim_ids_formatted = squeeze(sim_ids(:,1,1,1));

            mod_ids = modelling_outcomes_by_repetition{rep}{gm}.participant_ID_modelfit;
            assert(isequaln(sim_ids_formatted, mod_ids), 'Participant IDs misaligned for rep %d GM %d', rep, gm);
        end
    end
end

%% Helper functions -------------------------------------------------------

function sliced_struct = slice_simulated_struct(sim_struct, idx)
    % Slice every field in the simulated-data struct along the agent dimension.
    sliced_struct = struct();
    fields = fieldnames(sim_struct);
    for f = 1:numel(fields)
        sliced_struct.(fields{f}) = slice_first_dimension(sim_struct.(fields{f}), idx);
    end
end

function sliced_struct = slice_modelling_struct(mod_struct, idx)
    % load info about field types
    field_info = load_modelling_outputs_info();
    
    % initialize output struct
    sliced_struct = struct();
    fields = fieldnames(mod_struct);

    % loop over fields
    for f = 1:numel(fields)
        field_name = fields{f};
        field_value = mod_struct.(field_name);

        % handle different field types: matrices, cell arrays with n_agent rows, cell arrays of matrices 
        if ismember(field_name, field_info.fields_matrices_of_n_agents_by_fitting_models)  || ismember(field_name, field_info.fields_matrices_of_n_agents) % matrices ( {'nLPP', 'LAME', 'nLL', 'BIC', 'date', 'seed', 'participant_ID_modelfit'} )
            sliced_struct.(field_name) = slice_first_dimension(field_value, idx);
        elseif ismember(field_name, field_info.fields_cell_array_of_n_agents_by_fitting_models) % Cell array whose rows correspond to agents ({'gradient_nLPP', 'hessian_nLPP'})
            sliced_struct.(field_name) = field_value(idx, :);
        elseif ismember(field_name, field_info.fields_cell_array_with_one_cell_per_fitting_model) % Cell array containing one matrix per fitting model ({'parameters', 'Q', 'PChosen', 'PCorrect', 'PSwitch'})
            % loop over each cell entry
            for i = 1:numel(field_value)
                sliced_struct.(field_name){i} = slice_cell_of_matrices(field_value{i}, idx);
            end
        else
            error('Unknown field type in modelling outcomes struct: %s', field_name);
        end

    end
end

function sliced_cell = slice_cell_of_matrices(cell_array, idx)
    % Slice each matrix stored in a cell array along the first dimension.
    if ~iscell(cell_array)
        sliced_cell = slice_first_dimension(cell_array, idx);
        return;
    end
    sliced_cell = cell(size(cell_array));
    for c = 1:numel(cell_array)
        entry = cell_array{c};
        sliced_cell{c} = slice_first_dimension(entry, idx);
    end
end

function out = slice_first_dimension(value, idx)
    % Generic slicing helper that keeps non-agent metadata untouched.
    if isempty(value) || isscalar(value)
        out = value;
        return;
    end
    if size(value, 1) < idx(end)
        out = value;
        return;
    end
    subs = repmat({':'}, 1, ndims(value) - 1);
    out = value(idx, subs{:});
end
