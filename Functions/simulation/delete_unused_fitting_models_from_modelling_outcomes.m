function [output] = delete_unused_fitting_models_from_modelling_outcomes(modelling_outputs_for_one_generative_model, fitting_models_for_this_generative_model)
    
    fieldnames_in_modelling_outputs = fieldnames(modelling_outputs_for_one_generative_model);

    for f = 1:length(fieldnames_in_modelling_outputs)
        fieldname = fieldnames_in_modelling_outputs{f};
        modelling_outputs_for_one_generative_model.(fieldname) = delete_unused_fitting_models_from_modelling_outcome_field(fieldname, modelling_outputs_for_one_generative_model.(fieldname), fitting_models_for_this_generative_model);
    end

    output = modelling_outputs_for_one_generative_model;

end


function [field_value] = delete_unused_fitting_models_from_modelling_outcome_field(fieldname, field_value, fitting_models_for_this_generative_model)

    % load info about field types
    field_info = load_modelling_outputs_info();

    max_fitting_model = max(fitting_models_for_this_generative_model);
    %n_fitting_models = numel(fitting_models_for_this_generative_model);


    % (1) replace unused models by empty elements (do so differently based on data type)
    % (2) remove the slots for models higher than the highest model number required so that all data has same size (do so differently based on data type)
    if ismember(fieldname, field_info.fields_matrices_of_n_agents_by_fitting_models) % matrices ( {'nLPP', 'LAME', 'nLL', 'BIC', 'date'} )
        fitting_model_indices_to_empty = ~ismember(1:size(field_value,2), fitting_models_for_this_generative_model);
        field_value(:,fitting_model_indices_to_empty) = NaN;
        fitting_model_indices_to_delete = [1:size(field_value,2)] > max_fitting_model;
        field_value(:,fitting_model_indices_to_delete) = [];
        assert(size(field_value,2) == max_fitting_model, 'Size mismatch while deleting unused fitting models in field "%s"', fieldname);
    elseif ismember(fieldname, field_info.fields_cell_array_of_n_agents_by_fitting_models) % Cell array whose rows correspond to agents ({'gradient_nLPP', 'hessian_nLPP'})
        fitting_model_indices_to_empty = ~ismember(1:size(field_value,2), fitting_models_for_this_generative_model);
        field_value(:,fitting_model_indices_to_empty) = {[]};
        fitting_model_indices_to_delete = [1:size(field_value,2)] > max_fitting_model;
        field_value(:,fitting_model_indices_to_delete) = [];
        assert(size(field_value,2) == max_fitting_model, 'Size mismatch while deleting unused fitting models in field "%s"', fieldname);
    elseif ismember(fieldname, field_info.fields_cell_array_with_one_cell_per_fitting_model) % Cell array containing one matrix per fitting model ({'parameters', 'Q', 'PChosen', 'PCorrect', 'PSwitch'})
        fitting_model_indices_to_empty = ~ismember(1:numel(field_value), fitting_models_for_this_generative_model);
        field_value(fitting_model_indices_to_empty) = {[]};
        fitting_model_indices_to_delete = [1:numel(field_value)] > max_fitting_model;
        field_value(:,fitting_model_indices_to_delete) = [];
        assert(numel(field_value) == max_fitting_model, 'Size mismatch while deleting unused fitting models in field "%s"', fieldname);
    elseif ismember(fieldname, field_info.fields_matrices_of_n_agents) % matrices of n_agents ( {'seed', 'participant_ID_modelfit'} )
        % do nothing
    else
        error('Unsupported data type in field "%s" for generative model %d.', fieldname, gm);
    end
   
end