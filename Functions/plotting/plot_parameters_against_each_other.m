function [] = plot_parameters_against_each_other(parameters_multiple_datasets, version_name, model, outcome_encoding, figures_dir)

%PLOT_PARAMETERS_AGAINST_EACH_OTHER_FOR_SEVERAL_DATASETS
% Plot pairwise relationships between fitted model parameters, overlaid across datasets.
%
% This function creates 2 figures (one per parameter pairing/contrast). In each figure, it overlays:
%   - a scatter plot for each dataset (unique color per dataset)
%   - a least-squares best-fit line for each dataset (same color as its scatter)
%
% -------------------------
% Input format / arguments
% -------------------------
% parameters_multiple_datasets (cell array)
%   A cell array with one cell per dataset
%   Each dataset contains matrix of fitted parameters of size: n_participants x n_params
%   The mapping from parameter columns to a_CON/a_DIS/b_CON/b_DIS is obtained via:
%     load_models_info() -> models_info_extra.indices_a_CON_DIS / indices_b_CON_DIS
%
% version_name (char/string)
%   Label used in saved filenames (e.g., "v1", "replication").
%
% model (scalar integer)
%   Model index. Must be one of [2, 4] (enforced by assert), because the function expects
%   confidence-dependent learning-rate parameters a_CON/a_DIS and b_CON/b_DIS to exist in that model.
%
% outcome_encoding (char/string)
%   Label used in saved filenames to identify outcome encoding (e.g., "signed", "binary").
%
% figures_dir (char/string)

% modelling_outputs_many_datasets: cell array, each cell is a modelling_outputs struct for one dataset

    assert(ismember(model,[2,4]), ...
        'Only models with confidence-dependent learning rates for confirmatory and disconfirmatory evidence can be plotted');

    assert(iscell(parameters_multiple_datasets) && ~isempty(parameters_multiple_datasets), ...
        'modelling_outputs_many_datasets must be a non-empty cell array');

    color_dict = load_my_colors();

    % Load model info (for parameter indices)
    [models_info, models_info_extra] = load_models_info();

    % Names for plots
    variable_names = ["aCON","aDIS";
                      "bCON","bDIS";];
    % Axis intervals
    x_intervals = { -10:5:10;
                    -40:10:40;};

    y_intervals = { -10:5:10;
                    -40:10:40;};

    % Figure settings
    position_units = "centimeters";
    inner_position_size = [1, 1, 6, 4.8];
    figure_background_color = 'none';
    font_size = 10;

    % Colors: MATLAB default axes color order, repeated if needed
    baseColors = [color_dict.grey;
                  color_dict.green;
                  color_dict.dark_orange;
                  color_dict.dark_yellow ];
    nDatasets = numel(parameters_multiple_datasets);

    % Precompute x/y pairs for each dataset once (clean + efficient)
    x_y_all = cell(nDatasets,1);
    for database_index = 1:nDatasets
        x_y_all{database_index} = make_xy_pairs(parameters_multiple_datasets{database_index}, model, models_info_extra);
    end

    for variable_index = 1:size(variable_names,1)

        x_interval = x_intervals{variable_index};
        y_interval = y_intervals{variable_index};

        figure; hold on;

        % grey dotted diagonal line
        horizontal_line = plot(xlim, xlim, ':', 'Color', color_dict.grey, 'LineWidth', 1);

        % ======== Plot each dataset: scatter plot ========
        for database_index = 1:nDatasets

            my_color = baseColors(mod(database_index-1, size(baseColors,1)) + 1, :);

            x = x_y_all{database_index}{variable_index}(:,1);
            y = x_y_all{database_index}{variable_index}(:,2);

            s = scatter(x, y, 20, 'o', ...
                'MarkerEdgeColor', my_color, ...
                'MarkerFaceColor', my_color);
            s.MarkerFaceAlpha = 0.2;

            size(x,1)
            size(y,1)
        end


        % ======== Plot each dataset: Mean +/- 95% CI cross (no caps) ========
        % NB: do this in seperate loop so that appears on top
        for database_index = 1:nDatasets

            my_color = baseColors(mod(database_index-1, size(baseColors,1)) + 1, :);

            x = x_y_all{database_index}{variable_index}(:,1);
            y = x_y_all{database_index}{variable_index}(:,2);

            % plot mean in terms of x and y 
            % so basically a cross as error bars (no caps) for x (mean+/-95%CI) and y (mean+/-95%CI)

            errorbar_linewidth = 4;

            xMean = mean(x, 'omitnan');
            yMean = mean(y, 'omitnan');

            nX = sum(~isnan(x));
            nY = sum(~isnan(y));

            % 95% CI using t critical value (works for finite sample sizes)
            if nX > 1
                tX  = tinv(0.975, nX-1);
                ciX = tX * std(x, 'omitnan') / sqrt(nX);
            else
                ciX = 0;
            end

            if nY > 1
                tY  = tinv(0.975, nY-1);
                ciY = tY * std(y, 'omitnan') / sqrt(nY);
            else
                ciY = 0;
            end

            % get darker color for errorbars
            rgb_dark = my_color * 0.7;   % 30% darker
            rgb_dark = max(0, min(1, rgb_dark));

            % Horizontal bar: xMean +/- ciX at yMean
            hx = plot([xMean-ciX, xMean+ciX], [yMean, yMean], '-', ...
                'Color', rgb_dark, 'LineWidth', errorbar_linewidth);

            % Vertical bar: yMean +/- ciY at xMean
            hy = plot([xMean, xMean], [yMean-ciY, yMean+ciY], '-', ...
                'Color', rgb_dark, 'LineWidth', errorbar_linewidth);

            % Keep the mean/CI cross on top of the scatter cloud
            uistack([hx hy], 'top');

        end

        % Labels and axes
        xlabel(variable_names(variable_index,1));
        ylabel(variable_names(variable_index,2));

        xlim([min(x_interval), max(x_interval)]);
        xticks(x_interval);
        xticklabels(string(x_interval));

        ylim([min(y_interval), max(y_interval)]);
        yticks(y_interval);
        yticklabels(string(y_interval));

        hold off;

        % Styling
        set(gca,'FontSize',font_size,'box','off','FontName','Arial','units',position_units,'position',inner_position_size,'color',figure_background_color);
        set(gcf,'units',position_units,'position',inner_position_size+1.5);

        % Save figure (include plot name so we don't overwrite)
        plotTag = sprintf('%s_vs_%s', variable_names(variable_index,1), variable_names(variable_index,2));
        name = sprintf('Params_%s_model%i_%s_outcomes_%s', plotTag, model, outcome_encoding, version_name);
        svnm = fullfile(figures_dir, name);
        print(gcf,[svnm,'.svg'],'-dsvg');

    end
end

function x_y = make_xy_pairs(params, model, models_info_extra)
% Returns a 2x1 cell, each cell is Nx2 [x y] for one plot.

    % get indices of parameters in this model
    index_a_CON = models_info_extra.indices_a_CON_DIS(model,1);
    index_a_DIS = models_info_extra.indices_a_CON_DIS(model,2);
    index_b_CON = models_info_extra.indices_b_CON_DIS(model,1);
    index_b_DIS = models_info_extra.indices_b_CON_DIS(model,2);

    % extract parameters
    a_CON = params(:,index_a_CON);
    a_DIS = params(:,index_a_DIS);
    b_CON = params(:,index_b_CON);
    b_DIS = params(:,index_b_DIS);

    x_y = { [a_CON, a_DIS];
            [b_CON, b_DIS];};


end
