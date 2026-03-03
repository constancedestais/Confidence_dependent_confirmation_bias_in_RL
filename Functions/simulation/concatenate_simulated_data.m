function simulated_data_combined = concatenate_simulated_data(simulated_data_by_repetition, target_generative_models)
%concatenateSimulatedData Concatenate simulated data across repetitions for a specific generative model
%   simulated_data_combined = concatenateSimulatedData(simulated_data_by_repetition, target_generative_model)
%   concatenates data from all repetitions for the specified generative model along the first dimension (subjects)

%   Syntax:
%       combined_data = concatenateSimulatedData(data_by_repetition, generative_model)
%
%   Inputs:
%       simulated_data_by_repetition - Cell array {repetition}{generative_model}
%                                      containing simulated data for each
%                                      repetition and generative model
%       target_generative_model - Integer specifying which generative model
%                                 to combine data for
%
%   Output:
%       simulated_data_combined - Structure containing combined simulated data
%                                 where all repetitions have been concatenated
%                                 along the subject dimension
%
%   What gets combined:
%       - All structure fields are combined by stacking data vertically
%       - Dimensions: [subjects × sessions × conditions × trials]
%       - Works with both numeric arrays and string arrays
%       - Each repetition can have different numbers of subjects
%
%   Example:
%       % Combine data for generative model 2 across all repetitions
%       combined = concatenateSimulatedData(my_data, 2);
%       
%       % If repetition 1 had 2 subjects and repetition 2 had 5 subjects:
%       % Input:  rep1: exp_ID [2×1×4×30], rep2: exp_ID [5×1×4×30]
%       % Output: combined: exp_ID [7×1×4×30]
%
%   See also concatenate_modelling_outcomes

    for gm_idx = 1:numel(target_generative_models)
        gm = target_generative_models(gm_idx);
        simulated_data_combined{gm} = concatenate_for_single_generative_model(simulated_data_by_repetition, gm);
    end
   
end

function simulated_data_combined_for_single_generative_model= concatenate_for_single_generative_model(simulated_data_by_repetition, target_generative_model)

 % Get the number of repetitions
    n_repetitions = length(simulated_data_by_repetition);
    
    % Initialize the combined structure
    simulated_data_combined_for_single_generative_model = struct();
    
    % Find the first non-empty repetition for this generative model to get field names
    first_valid_rep = [];
    for rep = 1:n_repetitions
        if ~isempty(simulated_data_by_repetition{rep}) && ...
           length(simulated_data_by_repetition{rep}) >= target_generative_model && ...
           ~isempty(simulated_data_by_repetition{rep}{target_generative_model})
            first_valid_rep = rep;
            break;
        end
    end
    
    if isempty(first_valid_rep)
        warning('No data found for generative model %d', target_generative_model);
        return;
    end
    
    % Get field names from the first valid repetition
    field_names = fieldnames(simulated_data_by_repetition{first_valid_rep}{target_generative_model});
    
    % Loop through each field
    for f = 1:length(field_names)
        field_name = field_names{f};
        %fprintf('Processing field: %s\n', field_name);
        
        % Collect all data for this field across repetitions
        data_to_concatenate = {};
        valid_data_count = 0;
        
        for rep = 1:n_repetitions
            % Check if this repetition and generative model exists
            if ~isempty(simulated_data_by_repetition{rep}) && ...
               length(simulated_data_by_repetition{rep}) >= target_generative_model && ...
               ~isempty(simulated_data_by_repetition{rep}{target_generative_model}) && ...
               isfield(simulated_data_by_repetition{rep}{target_generative_model}, field_name)
                
                current_data = simulated_data_by_repetition{rep}{target_generative_model}.(field_name);
                
                if ~isempty(current_data)
                    valid_data_count = valid_data_count + 1;
                    data_to_concatenate{valid_data_count} = current_data;
                end
            end
        end
        
        % Concatenate along the first dimension (subjects)
        if valid_data_count > 0
            if valid_data_count == 1
                % Only one repetition has data
                simulated_data_combined_for_single_generative_model.(field_name) = data_to_concatenate{1};
            else
                % Multiple repetitions - concatenate along first dimension
                if isstring(data_to_concatenate{1}) || ischar(data_to_concatenate{1})
                    % Handle string/char arrays
                    simulated_data_combined_for_single_generative_model.(field_name) = vertcat(data_to_concatenate{:});
                else
                    % Handle numeric arrays
                    simulated_data_combined_for_single_generative_model.(field_name) = cat(1, data_to_concatenate{:});
                end
            end
            
            %fprintf('  Concatenated %d repetitions, final size: %s\n', valid_data_count, mat2str(size(simulated_data_combined_for_single_generative_model.(field_name))));
        else
            warning('No valid data found for field %s in generative model %d', field_name, target_generative_model);
        end
    end
    
    fprintf('Concatenation complete for simulated data for generative model %d\n', target_generative_model);

end