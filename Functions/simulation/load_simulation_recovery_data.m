function [settings_by_repetition, simulated_data_by_repetition, modelling_outcomes_by_repetition, simulated_data_combined, modelling_outcomes_combined] = load_simulation_recovery_data(generative_models, recovery_dir, folder, fields_to_delete, fitting_models_for_each_generative_model)

%{
INPUTS
- generative_models
- fitting_models_for_each_generative_model: cell array containing line vectors (one line vector per generative model)
- version_name

Note the structure of the loaded variables: 
- settings: 
    max_number_of_models            (int) 
    version_name                    (str) 
    reward_structure_dataset_name   (str) 
    outcome_encoding_for_fitting    (sltr) 
    generative_models               (vector) 
    fitting_models_for_each_generative_model (cell array of vectors of size {n_generative_models}(n_fitting_models) ) 
    parameter_generation_method         (str) 
    confidence_generation_method        (str)
    reward_schedule_generation_method   (str) 
    fixed_reversal_schedule             (int) 
    n_agents                            (int) 
    n_sessions                          (int) 
    n_repetition_of_parameter_estimation (int) 
    seed                                (int)
- d (simulated data)
    generative_parameters
    exp_ID                      (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    participant_ID              (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    full_feedback               (matrix: n_agents  x n_sessions x n_conditions x n_trials_by_cond)
    session                     (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    condition                   (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    trial_by_condition          (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    reversal                    (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    symbol_1_actual_payoff      (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    symbol_2_actual_payoff      (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    correct_schedule            (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond) 
    symbol_chosen_id_relative   (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    symbol_chosen_actual_payoff (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    symbol_unchosen_actual_payoff (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    chose_highest               (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    confidence_rating           (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    switched_choice             (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
    chose_symbol_1              (matrix: n_agents x n_sessions x n_conditions x n_trials_by_cond)
- modelling_outputs
    parameters    (cell array : {n_models} (n_agents x n_params) )
    gradient_nLPP (cell array : {n_agents, numel(models_info)} )
    hessian_nLPP  (cell array : {n_agents, numel(models_info)} )
    nLPP          (matrix : n_agents, numel(models_info)) 
    LAME          (matrix : n_agents, numel(models_info)) 
    nLL           (matrix : n_agents, numel(models_info)) 
    BIC           (matrix : n_agents, numel(models_info)) 
    Q             (cell array : {n_models} (n_agents x  n_conditions x n_trials))
    PChosen       (cell array : {n_models} (n_agents x  n_conditions x n_trials))
    PCorrect      (cell array : {n_models} (n_agents x  n_conditions x n_trials))
    PSwitch       (cell array : {n_models} (n_agents x  n_conditions x n_trials))
    participant_ID_modelfit (n_agents x 1) 

OUTPUTS
- settings_by_repetition - cell array {n_repetitions}
- simulated_data_by_repetition - cell array  {n_repetitions}{n_generative_models}
- modelling_outcomes_by_repetition - cell array  {n_repetitions}{n_generative_models}
- simulated_data_combined - cell array {n_generative_models} 
    Each cell is a structure with the following fields
        generative_parameters: [n_agents × n_parameters_in_generative_model] double
        real_confidence: [n_agents x n_sessions x n_conditions x n_trials] double
        exp_ID: [n_agents x n_sessions x n_conditions x n_trials] string
        participant_ID: [n_agents x n_sessions x n_conditions x n_trials] string
        full_feedback: [n_agents x n_sessions x n_conditions x n_trials] double
        valence: [n_agents x n_sessions x n_conditions x n_trials] double
        session: [n_agents x n_sessions x n_conditions x n_trials] double
        condition: [n_agents x n_sessions x n_conditions x n_trials] double
        condition_name: [n_agents x n_sessions x n_conditions x n_trials] string]
        trial_by_condition: [n_agents x n_sessions x n_conditions x n_trials] double
        correct_schedule: [n_agents x n_sessions x n_conditions x n_trials] double
        reversal: [n_agents x n_sessions x n_conditions x n_trials] double
        symbol_1_actual_payoff: [n_agents x n_sessions x n_conditions x n_trials] double
        symbol_2_actual_payoff: [n_agents x n_sessions x n_conditions x n_trials] double
        reward_schedule: [n_agents x n_sessions x n_conditions x n_trials x 2] double
        symbol_chosen_id_relative: [n_agents x n_sessions x n_conditions x n_trials] double
        symbol_chosen_actual_payoff: [n_agents x n_sessions x n_conditions x n_trials] double
        symbol_unchosen_actual_payoff: [n_agents x n_sessions x n_conditions x n_trials] double
        chose_highest: [n_agents x n_sessions x n_conditions x n_trials] double
        confidence_rating: [n_agents x n_sessions x n_conditions x n_trials] double
        switched_choice: [n_agents x n_sessions x n_conditions x n_trials] double
        chose_symbol_1: [n_agents x n_sessions x n_conditions x n_trials] double
        date: ??
        generative_model: ??
- modelling_outcomes_combined - cell array {n_generative_models}
    Each cell is a structure with the following fields:
        participant_ID_modelfit: [n_agents × 1] string
        LAME: [n_agents × n_available_fitting_models] double
        gradient_nLPP: [n_agents × n_available_fitting_models] cell
        hessian_nLPP: [n_agents × n_available_fitting_models] cell
        nLPP: [n_agents × n_available_fitting_models] cell
        nLL: n_agents × n_available_fitting_models] double
        BIC: n_agents × n_available_fitting_models] double
        parameters: [n_available_fitting_models] cell --> where each cell contains a matrix of dimensions [n_agents x n_parameters_in_this_fitting_model], for example: {[200×3 double]  [200×5 double]  [200×4 double]  [200×6 double]  []  []  []  []  []  []  []  []  []  []  []  []  []}
        Q: [n_available_fitting_models] cell --> where each cell contains a matrix of dimensions [n_agents x n_sessions x n_conditions x n_trials x 2], for example: {[5-D double]  [5-D double]  [5-D double]  [5-D double]  []  []  []  []  []  []  []  []  []  []  []  []  []}
        PChosen: [n_available_fitting_models] cell --> where each cell contains a matrix of dimensions [n_agents x n_sessions x n_conditions x n_trials], for example: {[200×3×4×30 double]  [200×3×4×30 double]  [200×3×4×30 double]  [200×3×4×30 double]  []  []  []  []  []  []  []  []  []  []  []  []  []}
        PCorrect: [n_available_fitting_models] cell --> where each cell contains a matrix of dimensions [n_agents x n_sessions x n_conditions x n_trials], {[200×3×4×30 double]  [200×3×4×30 double]  [200×3×4×30 double]  [200×3×4×30 double]  []  []  []  []  []  []  []  []  []  []  []  []  []}
        PSwitch: [n_available_fitting_models] cell --> where each cell contains a matrix of dimensions [n_agents x n_sessions x n_conditions x n_trials], {[200×3×4×30 double]  [200×3×4×30 double]  [200×3×4×30 double]  [200×3×4×30 double]  []  []  []  []  []  []  []  []  []  []  []  []  []}
        date: ??
        generative_model: [2×1 double]
    E.g., if want to get the parameters obtained when data generated with model G was fitted with model F, you need to call: modelling_outcomes_combined{G}.parameters{F}
          if want to get the first parameter here, then: modelling_outcomes_combined{G}.parameters{F}(:,1)
%}


    %% get specific folder name from inputs

    % set directory
    special_folder_path = fullfile(recovery_dir,folder);

    % check if folder exists
    if ~exist(special_folder_path, 'dir')
        error('Folder does not exist: %s \nYou probably did not run this exact parameter recovery yet.',special_folder_path)
    else
        % Display confirmation
        fprintf('\nFolder %s exists in the current directory.\n',special_folder_path);
    end
    % add new folder to path
    addpath(genpath('Functions'), genpath('Data'), genpath('Outputs'));  % add folder and contained folders



   %% check that folder contains each type of file in the correct number
    
    % list files
    settingsFiles         = dir(fullfile(special_folder_path, 'settings_*.mat'));
    simulatedDataFiles    = dir(fullfile(special_folder_path, 'simulated_data_generativemodel*_*.mat'));
    modellingOutputsFiles = dir(fullfile(special_folder_path, 'modelling_outputs_generativemodel*_*.mat'));
    
    % extract dates from settings
    dateExpr_settings = 'settings_(.+)\.mat';
    dates_settings = cellfun(@(f) regexp(f,dateExpr_settings,'tokens','once'), ...
                             {settingsFiles.name}, 'UniformOutput', false);
    dates_settings = cellfun(@(t) t{1}, dates_settings, 'UniformOutput', false);
    unique_dates = unique(dates_settings);
    
    % build expected filenames
    expected_files = {};
    
    for d = 1:numel(unique_dates)
        this_date = unique_dates{d};
    
        % settings
        expected_files{end+1} = sprintf('settings_%s.mat', this_date);
    
        % sim + mod per generative model
        for generative_model_index = 1:numel(generative_models)
            generative_model = generative_models(generative_model_index);
            expected_files{end+1} = sprintf('simulated_data_generativemodel%d_%s.mat', generative_model, this_date);
            expected_files{end+1} = sprintf('modelling_outputs_generativemodel%d_%s.mat', generative_model, this_date);
        end
    end
    
    % flatten to set
    expected_files = unique(expected_files);
    
    % collect actual files
    actual_files = unique([ {settingsFiles.name}, {simulatedDataFiles.name}, {modellingOutputsFiles.name} ]);
    
    % check for missing files
    missing_files = setdiff(expected_files, actual_files);
    if ~isempty(missing_files)
        error('Missing expected file(s): \n%s', strjoin(missing_files, '\n'));
    end
    
    % check for extra files
    extra_files = setdiff(actual_files, expected_files);
    if ~isempty(extra_files)
        warning('Extra file(s) found that were not expected:\n%s', strjoin(extra_files, '\n'));
    end
    
    fprintf('\nFile check passed: all expected files are present for each date × generative model.\n');




    %% load settings file and store settings variable
    % Create dictionary to map dates → repetition indices
    unique_dates = string(unique(dates_settings));   % ensure string array
    repetition_dictionary = dictionary(unique_dates, 1:numel(unique_dates));
    n_repetitions = numel(unique_dates);
    settings_by_repetition = cell(1, n_repetitions);

    % Load each settings file into the corresponding repetition cell
    for i = 1:numel(settingsFiles)
        filePath = fullfile(special_folder_path, settingsFiles(i).name);
        %fprintf('Loading settings file: %s\n', settingsFiles(i).name);
        try
            temp = load(filePath);
            if isfield(temp, 'settings')
                date_token = regexp(settingsFiles(i).name, dateExpr_settings, 'tokens', 'once');
                rep = repetition_dictionary(string(date_token{1}));  % cast to string for lookup
                settings_by_repetition{rep} = temp.settings;
                % Add meta info
                settings_by_repetition{rep}.date = string(date_token{1});
                settings_by_repetition{rep}.repetition = rep;
            else
                warning('Settings file %s does not contain "settings"', settingsFiles(i).name);
            end
        catch e
            warning('Error loading %s: %s', settingsFiles(i).name, e.message);
        end
    end

    %% load simulated_data and modelling_outputs into by-repetition arrays
    simulated_data_by_repetition = cell(1, n_repetitions);
    modelling_outcomes_by_repetition = cell(1, n_repetitions);

    for d = 1:numel(unique_dates)
        this_date = string(unique_dates{d});
        
        rep = repetition_dictionary(this_date);

        for generative_model_index = 1:numel(generative_models)
            generative_model = generative_models(generative_model_index);

            % Construct expected filenames
            filename_simulated_data   = fullfile(special_folder_path, sprintf('simulated_data_generativemodel%d_%s.mat', generative_model, this_date));
            filename_modelling_outputs = fullfile(special_folder_path, sprintf('modelling_outputs_generativemodel%d_%s.mat', generative_model, this_date));

            %fprintf('\nLoading %s\n', filename_simulated_data);
            %fprintf('Loading %s\n', filename_modelling_outputs);

            % Load both files
            try
                temp_simulated_data = load(filename_simulated_data);
            catch ME
                error('Failed to load %s: %s', filename_simulated_data, ME.message);
            end
            try
                temp_modelling_outcomes = load(filename_modelling_outputs);
            catch ME
                error('Failed to load %s: %s', filename_modelling_outputs, ME.message);
            end


            % delete unused fields to lighten the data
            if ~isempty(fields_to_delete)
                for field = fields_to_delete
                    if isfield(temp_simulated_data.d, field{1})
                        temp_simulated_data.d = rmfield(temp_simulated_data.d, field{1});
                    end
                    if isfield(temp_modelling_outcomes.modelling_outputs, field{1})
                        temp_modelling_outcomes.modelling_outputs = rmfield(temp_modelling_outcomes.modelling_outputs, field{1});
                    end
                end
            end

            % delete unused models to lighten the data/to help with compatibility across data sets simulated with a different number of models
            temp_modelling_outcomes.modelling_outputs  = delete_unused_fitting_models_from_modelling_outcomes( temp_modelling_outcomes.modelling_outputs, fitting_models_for_each_generative_model{generative_model_index} );

            % is seed still exists, reshape it to size: n_agents x 1 (for consistency with other fields, and consistency with regroup_simulation_repetitions)
            if isfield(temp_modelling_outcomes.modelling_outputs, 'seed')
                n_agents = size(temp_modelling_outcomes.modelling_outputs.participant_ID_modelfit, 1);
                temp_modelling_outcomes.modelling_outputs.seed = repmat(temp_modelling_outcomes.modelling_outputs.seed, n_agents, 1);
            end

            % Store into cell arrays
            simulated_data_by_repetition{rep}{generative_model} = temp_simulated_data.d;
            modelling_outcomes_by_repetition{rep}{generative_model} = temp_modelling_outcomes.modelling_outputs;

            % Add other meta info - size: n_agents x 1
            n_agents = size(modelling_outcomes_by_repetition{rep}{generative_model}.participant_ID_modelfit, 1);
            simulated_data_by_repetition{rep}{generative_model}.date = repmat(this_date, n_agents, 1);
            simulated_data_by_repetition{rep}{generative_model}.generative_model = repmat(generative_model, n_agents, 1);
            modelling_outcomes_by_repetition{rep}{generative_model}.date = repmat(this_date, n_agents, 1);
            modelling_outcomes_by_repetition{rep}{generative_model}.generative_model = repmat(generative_model, n_agents, 1);
        end
    end

    %% combine data across repetitions
    %{
    what we have
        - modelling_outcomes_by_repetition{repetitionIndices}{generativeModelIndices}
        - simulated_data_by_repetition{repetitionIndices}{generativeModelIndices}
    what we create
        - simulated_data_combined{generativeModelIndices}
        - modelling_outcomes_combined{generativeModelIndices}
    %}

    % Allocate containers for combined data
    simulated_data_combined     = cell(1, settings_by_repetition{1}.max_number_of_models);
    modelling_outcomes_combined = cell(1, settings_by_repetition{1}.max_number_of_models);

    assert(numel(modelling_outcomes_combined) == numel(simulated_data_combined), ...
           'Mismatch in combined container sizes');

    modelling_outcomes_combined = concatenate_modelling_outcomes(modelling_outcomes_by_repetition, generative_models);

    simulated_data_combined = concatenate_simulated_data(simulated_data_by_repetition, generative_models);

    % check that the number of participants is the same in both sources, for each generative model
    for generative_models_idx = 1:numel(generative_models)
        generative_model = generative_models(generative_models_idx);
        assert(size(simulated_data_combined{generative_model}.participant_ID,1) == size(modelling_outcomes_combined{generative_model}.participant_ID_modelfit,1), ...
            'Mismatch in number of participants for generative model %d: simulated data has %d, modelling outcomes has %d, in participant variable', ...
            generative_model, size(simulated_data_combined{generative_model}.participant_ID,1), size(modelling_outcomes_combined{generative_model}.participant_ID_modelfit,1));
        
        fitting_models_for_this_generative_model = fitting_models_for_each_generative_model{generative_models_idx};
        for fitting_model_idx = 1:numel(fitting_models_for_this_generative_model)
            fitting_model = fitting_models_for_this_generative_model(fitting_model_idx);
            assert(size(simulated_data_combined{generative_model}.generative_parameters,1) == size(modelling_outcomes_combined{generative_model}.parameters{fitting_model},1), ...
            'Mismatch in number of participants for generative model %d: simulated data has %d, modelling outcomes has %d, in parameters variable', ...
            generative_model, size(simulated_data_combined{generative_model}.participant_ID,1), size(modelling_outcomes_combined{generative_model}.parameters{fitting_model},1));
        end
    end

    %% check that the different repetitions do not all contain exactly the same agents
    
    example_model = generative_models(1);
    example_combined_data = simulated_data_combined{example_model}.generative_parameters;
    % how many agents
    n_rows = size(example_combined_data,1);
    % how many unique values
    n_unique_rows = size(unique(example_combined_data, 'rows'),1); % size(unique(modelling_outcomes_combined{1}.parameters{1}(:,1)))
    % check that there are not more than 5% of repeated agents
    assert(n_unique_rows >= n_rows*0.95, 'Problem in the parameter simulation process, there are more than 5% of the agents which are exactly the same')

end

