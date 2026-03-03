function modelling_outcomes_combined = concatenate_modelling_outcomes(modelling_outcomes_by_repetition, target_generative_models)
%CONCATENATE_MODELLING_OUTCOMES Combine modelling outputs across repetitions.
%
%   modelling_outcomes_combined = concatenate_modelling_outcomes(data_by_rep)
%   modelling_outcomes_combined = concatenate_modelling_outcomes(data_by_rep, gm_list)
%
% Inputs
%   modelling_outcomes_by_repetition : cell {repetition}{generative_model}
%   target_generative_models         : optional vector of GM indices to combine
%
% Output
%   modelling_outcomes_combined{gm}  : cell where entry {gm} is a struct whose
%                                 fields have been concatenated along the
%                                 agent dimension across all repetitions.
%

    arguments
        modelling_outcomes_by_repetition (1,:) cell
        target_generative_models double = []
    end

    % Determine which generative models actually exist in the repetitions.
    gm_present = infer_available_models(modelling_outcomes_by_repetition);

    % If no explicit target list is provided, combine everything we found.
    if isempty(target_generative_models)
        target_generative_models = gm_present;
    end

    if isempty(target_generative_models)
        modelling_outcomes_combined = {};
        warning('concatenate_modelling_outcomes:noData', ...
                'No modelling outcomes available to concatenate.');
        return;
    end

    % Preallocate the output cell so caller can index by GM directly.
    max_gm = max([gm_present(:); target_generative_models(:)]);
    modelling_outcomes_combined = cell(1, max_gm);

    % Process each requested generative model independently.
    for model_idx = 1:numel(target_generative_models)
        gm = target_generative_models(model_idx);

        % gm_slices stores, for every repetition, the struct corresponding
        % to this generative model. Having all slices in one cell array
        % makes the subsequent per-field concatenations straightforward.
        [gm_slices, n_agents_per_rep] = collect_repetitions(modelling_outcomes_by_repetition, gm);
        if isempty(gm_slices)
            warning('concatenate_modelling_outcomes:noGM', ...
                    'No data found for generative model %d.', gm);
            continue;
        end

        % Use the first repetition as a template for available fields.
        fields = fieldnames(gm_slices{1});
        % only keep fields that are also in list
        useful_fiels = ["LAME","nLPP","nLL","BIC","gradient_nLPP", "hessian_nLPP", "parameters", "Q", "PChosen", "PCorrect", "PSwitch", "seed", "participant_ID_modelfit"];
        fields = intersect(fields,useful_fiels);

        % initialize combined struct for this GM
        combined_struct = struct();

        % Concatenate each field with a helper that knows how to handle the different types (for different variables)
        for f = 1:numel(fields)
            field_name   = fields{f};
            field_chunks = cellfun(@(s) s.(field_name), gm_slices, 'UniformOutput', false);
            combined_struct.(field_name) = concatenate_field(field_chunks, n_agents_per_rep, field_name, gm);
        end

        modelling_outcomes_combined{gm} = combined_struct;
    end
end

%% ------------------------------------------------------------------------
function gm_present = infer_available_models(data_by_rep)
% Return a sorted list of generative-model indices that appear anywhere in
% the repetitions. This prevents loops over models that were never run.

    gm_present = [];
    for rep = 1:numel(data_by_rep)
        current = data_by_rep{rep};
        if isempty(current), continue; end
        for gm = 1:numel(current)
            if ~isempty(current{gm})
                gm_present(end+1) = gm; %#ok<AGROW>
            end
        end
    end
    gm_present = unique(gm_present);
end

function [gm_slices, n_agents_per_rep] = collect_repetitions(data_by_rep, gm)
% Gather every repetition that contains the requested GM. gm_slices keeps the
% per-repetition structs, while n_agents_per_rep tracks how many agents each
% repetition contributed (used for sanity checks later on).

    gm_slices = {};
    n_agents_per_rep = [];
    for rep = 1:numel(data_by_rep)
        current = data_by_rep{rep};
        if isempty(current) || numel(current) < gm || isempty(current{gm})
            continue;
        end
        slice = current{gm};
        gm_slices{end+1}      = slice; %#ok<AGROW>
        n_agents_per_rep(end+1) = size(slice.participant_ID_modelfit, 1); %#ok<AGROW>
    end
end

function combined_value = concatenate_field(field_chunks, n_agents_per_rep, field_name, gm)
% Concatenate one field across repetitions, branching on the data type.

    % load info about field types
    field_info = load_modelling_outputs_info();

    % find first non-empty chunk to infer data type
    nonempty_idx = find(~cellfun(@isempty, field_chunks), 1, 'first');
    if isempty(nonempty_idx)
        combined_value = [];
        return;
    end

    %sample_value = field_chunks{nonempty_idx};
    total_agents = sum(n_agents_per_rep);

    % concatenate based on data type
    if ismember(field_name, field_info.fields_matrices_of_n_agents_by_fitting_models) % matrices ( {'nLPP', 'LAME', 'nLL', 'BIC', 'date'} )
        try
            combined_value = cat(1, field_chunks{:});
        catch
            error('Error concatenating numeric field "%s" for generative model %d.', field_name, gm);
        end 
        assert(size(combined_value,1) == total_agents, 'Size mismatch while concatenating field "%s" for GM %d.', field_name, gm);
    elseif ismember(field_name, field_info.fields_cell_array_of_n_agents_by_fitting_models) % Cell array whose rows correspond to agents ({'gradient_nLPP', 'hessian_nLPP'})
        %n_agents_sample = n_agents_per_rep(nonempty_idx);
        combined_value = vertcat(field_chunks{:});
        assert(size(combined_value,1) == total_agents, 'Size mismatch while concatenating field "%s" for GM %d.', field_name, gm);
    elseif ismember(field_name, field_info.fields_cell_array_with_one_cell_per_fitting_model) % Cell array containing one matrix per fitting model ({'parameters', 'Q', 'PChosen', 'PCorrect', 'PSwitch'})
        combined_value = concatenate_per_fitted_model_cells(field_chunks, n_agents_per_rep, field_name, gm);
    elseif ismember(field_name, field_info.fields_matrices_of_n_agents) % matrices of n_agents ( {'seed', 'participant_ID_modelfit'} )
        combined_value = cat(1, field_chunks{:});
        assert(size(combined_value,1) == total_agents, 'Size mismatch while concatenating field "%s" for GM %d.', field_name, gm);
    else
        error('Unsupported data type in field "%s" for generative model %d.', field_name, gm);
    end
end

function combined_cell = concatenate_per_fitted_model_cells(field_chunks, n_agents_per_rep, field_name, gm)
% Handle fields that are {n_fitted_models} cells where each entry is an
% [n_agents × J] matrix (parameters, Q, etc.). We concatenate the matrices
% model by model to keep dimensions consistent.

    template_idx = find(~cellfun(@isempty, field_chunks), 1, 'first');
    template = field_chunks{template_idx};
    combined_cell = cell(size(template));

    n_fitted_models = numel(template);
    for m = 1:n_fitted_models
        
        % ----- create model_blocks{r} which only contains data from repetitions in which model m exists -----

        model_blocks = cell(1, numel(field_chunks));
        keep_mask = false(1, numel(field_chunks)); % keep_mask will track which repetitions actually have data for model m

        % walks through every repetition (field_chunks{r}) 
        % if that repetition contains the m‑th model (current{m}), stores that matrix in model_blocks{r} and marks keep_mask(r) true
        for rep = 1:numel(field_chunks)
            current = field_chunks{rep};
            % if current is empty or does not have m-th model, skip
            if numel(current) < m || isempty(current{m})
                continue;
            end
            % otherwise, store the matrix for model m from repetition rep
            model_blocks{rep} = current{m};
            keep_mask(rep) = true;
        end

        % keep only the repetitions that had data for model m
        model_blocks = model_blocks(keep_mask);
        if isempty(model_blocks)
            combined_cell{m} = [];
            continue;
        end

        % ----- Concatenate the collected matrices along the agent dimension -----
        
        % concatenate along first dimension (agents)
        combined_cell{m} = cat(1, model_blocks{:});

        % sanity check 
        expected_rows = sum(n_agents_per_rep(keep_mask));
        assert(size(combined_cell{m},1) == expected_rows, 'Size mismatch in field "%s" for GM %d, model %d.', field_name, gm, m);
    end
end

