function plot_behaviour_over_block_average(prepared_data, file_name, figures_dir)
% Plot block-wise average pCorrect and confidence (with 95% CI) across all conditions.
% Inputs: prepared_data (from prepare_behaviour_over_block_data), file_name, figures_dir.
% Output: saves one PNG per variable.

% ---------- Basic input checks ----------
assert(isfield(prepared_data, "stats"), "prepared_data must contain a 'stats' field.");
assert(isfield(prepared_data.stats, "all"), "prepared_data.stats must contain an 'all' field.");
assert(isfield(prepared_data.stats.all, "correct"), "prepared_data.stats.all must contain a 'correct' field.");
assert(isfield(prepared_data.stats.all, "confidence"), "prepared_data.stats.all must contain a 'confidence' field.");

% ---------- Plot style ----------
color_dictionary = load_my_colors();
line_alpha = 0.7;
confidence_interval_alpha = 0.15;
line_width = 1;
font_size = 10;

reference_line_color = color_dictionary.grey;
font_name = "Arial";
position_units = "centimeters";
figure_position = [3, 3, 5, 4];
axes_inner_position = [1, 1, 3, 2.25];

number_of_trials = numel(prepared_data.stats.all.correct.sample_mean);
[trial_indices, x_limits, x_tick_values] = build_trial_axis_helper(number_of_trials, 10);

% ---------- Variables to plot ----------
plot_specifications = struct( ...
    "variable_name", {"pcorrect", "confidence"}, ...
    "statistics", {prepared_data.stats.all.correct, prepared_data.stats.all.confidence}, ...
    "y_limits", {[0, 100], [50, 100]}, ...
    "y_ticks", {0:25:100, 50:25:100} ...
);

% ---------- Create one figure per variable ----------
for specification_index = 1:numel(plot_specifications)
    current_specification = plot_specifications(specification_index);
    current_statistics = current_specification.statistics;

    figure_handle = figure;

    % Confidence band (convert from proportion to percentage)
    fill([trial_indices fliplr(trial_indices)], ...
         [current_statistics.CI_lower*100, fliplr(current_statistics.CI_upper)*100], ...
         color_dictionary.black, ...
         "EdgeColor", "none", ...
         "FaceAlpha", confidence_interval_alpha);
    hold on

    % Sample mean trace
    plot(trial_indices, current_statistics.sample_mean*100, ...
         "Color", [color_dictionary.black, line_alpha], ...
         "LineWidth", line_width);

    % Reference line at chance/confidence midpoint
    yline(50, ":", "LineWidth", line_width/3, "Color", reference_line_color);

    % Axes formatting
    xticks(x_tick_values);
    xlim(x_limits);
    ylim(current_specification.y_limits);
    yticks(current_specification.y_ticks);

    set(gca, ...
        "FontSize", font_size, ...
        "box", "off", ...
        "FontName", font_name, ...
        "units", position_units, ...
        "position", axes_inner_position);

    set(gcf, ...
        "Units", position_units, ...
        "Position", figure_position);

    % Save figure
    output_file_name = sprintf("%s_over_block_%s.svg", current_specification.variable_name, file_name);
    output_full_path = fullfile(figures_dir, output_file_name);
    print(figure_handle, output_full_path, '-dsvg');   
    fprintf("\n Saved figure: %s\n", output_full_path);
    
    close(figure_handle);
end

end
