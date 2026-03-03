%% [AVERAGE ACROSS REPETITIONS]  plot correlation matrix
%{
 1. compute correlation matrix BY repetition, store in matrix n_rep x n_params x n_params
 2. average over n_rep to get average correlation, plot heatmap of averaged correlation coefficients
%}

function [] = plot_parameter_recovery_correlation_matrix(generative_model,...
                                                        fitting_models,...
                                                        generated_parameters_combined_repetitions,...
                                                        recovered_parameters_combined_repetitions,...
                                                        simulated_data_by_repetition,...
                                                        modelling_outcomes_by_repetition,...
                                                        models_info,...
                                                        figures_export_dir,...
                                                        reward_structure_dataset_name, ...
                                                        simulated_data, ...
                                                        colors, ...
                                                        empirical_parameters)



% check if have a combination with the same fitting and generative model
if ismember(generative_model, fitting_models)

    n_repetitions_of_generation = numel(modelling_outcomes_by_repetition);
    fitting_model = generative_model;

    % initialise
    n_parameters = size(generated_parameters_combined_repetitions,2);
    correlation_matrix_by_repetition_rho = NaN(n_repetitions_of_generation,n_parameters,n_parameters);
    correlation_matrix_by_repetition_pval = NaN(n_repetitions_of_generation,n_parameters,n_parameters);
    clear n_parameters

    % only average across repetitions if there are more than 1 repetitions
    if n_repetitions_of_generation >= 2
        % loop over repetitions
        for repetition = 1:n_repetitions_of_generation
            generated_parameters_this_repetition = simulated_data_by_repetition{repetition}{generative_model}.generative_parameters;
            recovered_parameters_this_repetition = modelling_outcomes_by_repetition{repetition}{generative_model}.parameters{fitting_model};
            % correlation matrix for this repetitions
            [rho,pval] = corr(generated_parameters_this_repetition,recovered_parameters_this_repetition);
            % store in matrix n_rep x n_params x n_params
            correlation_matrix_by_repetition_rho(repetition,:,:) = rho;
            correlation_matrix_by_repetition_pval(repetition,:,:) = pval;
            clear rho pval
        end
    end

    % average correlation values over repetitions
    correlation_matrix_averaged_over_repetitions_rho = squeeze(mean(correlation_matrix_by_repetition_rho,1));
    correlation_matrix_averaged_over_repetitions_pval = squeeze(mean(correlation_matrix_by_repetition_pval,1));

    % create my own color gradient
    [my_colormap, lims] = custom_colormap_for_heatmap(correlation_matrix_averaged_over_repetitions_rho);

    % plot heatmap
    f = figure;
    h = heatmap(correlation_matrix_averaged_over_repetitions_rho);
    h.Colormap = my_colormap;
    h.ColorLimits = lims;
    h.CellLabelFormat = '%.2f';
    h.Title = sprintf( 'Parameter recovery m%i, averaged over %i repetitions',generative_model,n_repetitions_of_generation);
    h.XLabel = 'simulated parameters'; 
    h.YLabel = 'fitted parameters';
    labels = models_info{fitting_model}.param_names;
    h.XDisplayLabels = labels;
    h.YDisplayLabels = labels;
    set(gca, 'FontSize', 18);
    % save figure
    generative_models_name = sprintf('simulated_generativemodel%i',generative_model);
    name = sprintf('Parameter_recovery_Pearson_model%s_%s_averaged_over_repetitions_%s.svg',string(fitting_model),generative_models_name,reward_structure_dataset_name);
    svnm = fullfile(figures_export_dir,name);
    set(f, 'Renderer', 'painters');
    print(f, svnm, '-dsvg'); 

    
    clear fitting_model f name svnm x y rho pval fitting_model n_repetitions_of_generation

end
