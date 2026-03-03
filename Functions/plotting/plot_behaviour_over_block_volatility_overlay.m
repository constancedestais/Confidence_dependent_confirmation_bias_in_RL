function plot_behaviour_over_block_volatility_overlay(prepared_data, file_name, figures_dir)
% Plot 5: overlay low-volatility and high-volatility trajectories across trials.
% Plot stable vs volatile behaviour traces over trials for one dataset.
% Uses precomputed participant-level summary statistics (means + CIs) and
% highlights reversal windows with distinct line colors.
%
% Inputs:
% - prepared_data : struct from prepare_behaviour_over_block_data()
% - file_name     : dataset label used in output file names
% - figures_dir   : directory where figures are saved
%
% Output:
% - Saves one figure per variable (pcorrect, confidence).

% ---- check that the input data contains expected variables -----
assert(isfield(prepared_data.stats, "stable"), "prepared_data must contain 'stable' field");
assert(isfield(prepared_data.stats, "volatile"), "prepared_data must contain 'volatile' field");
assert(isfield(prepared_data.stats.stable, "correct"), "prepared_data.stats.stable must contain 'correct' field");
assert(isfield(prepared_data.stats.volatile, "correct"), "prepared_data.stats.volatile must contain 'correct' field");
assert(isfield(prepared_data.stats.stable, "confidence"), "prepared_data.stats.stable must contain 'confidence' field");
assert(isfield(prepared_data.stats.volatile, "confidence"), "prepared_data.stats.volatile must contain 'confidence' field");

% ---------- Style and layout ----------
color_dictionary = load_my_colors();

font_size = 10;
line_width = 1;
reference_line_color = color_dictionary.grey;

position_units = "centimeters";
figure_position = [3, 3, 5, 4];
inner_axes_position = [1, 1, 3, 2.25];

line_alpha = 0.9;
confidence_band_alpha = 0.4;

% Volatile traces and confidence interval colors
volatile_reversal_line_color = [color_dictionary.very_dark_blue, line_alpha];
volatile_nonreversal_line_color = [color_dictionary.light_blue, line_alpha];
volatile_confidence_interval_color = color_dictionary.very_light_blue;

% Stable traces and confidence interval colors
stable_reversal_line_color = [color_dictionary.very_dark_orange, line_alpha];
stable_nonreversal_line_color = [color_dictionary.light_orange, line_alpha];
stable_confidence_interval_color = color_dictionary.very_light_orange;

% ---------- Variables to plot ----------
plot_specifications = struct( ...
    "variable_name", {"pcorrect", "confidence"}, ...
    "stable_statistics", { ...
        prepared_data.stats.stable.correct, ...
        prepared_data.stats.stable.confidence}, ...
    "volatile_statistics", { ...
        prepared_data.stats.volatile.correct, ...
        prepared_data.stats.volatile.confidence}, ...
    "y_limits", {[0, 100], [50, 100] }, ...
    "y_ticks", {0:25:100, 50:25:100 } ...
);

% Build trial axis based on the number of trials of one condition, since in some datasets there are different numbers of trials (due to between-participant experiment design differences)
number_of_trials = numel(prepared_data.stats.volatile.correct.sample_mean);
[trial_indices, x_limits, x_tick_values] = build_trial_axis_helper(number_of_trials, 10);


% ---------- One figure per variable ----------
for specification_index = 1:numel(plot_specifications)
    current_specification = plot_specifications(specification_index);

    figure_handle = figure;

    statistics_volatile = current_specification.volatile_statistics;
    statistics_stable = current_specification.stable_statistics;

    % Draw volatile confidence band behind the lines.
    fill([trial_indices fliplr(trial_indices)], ...
         [statistics_volatile.CI_lower*100, fliplr(statistics_volatile.CI_upper)*100], ...
         volatile_confidence_interval_color, ...
         "EdgeColor", "none", "FaceAlpha", confidence_band_alpha);
    hold on

    % Draw volatile mean line with darker color during reversal windows.
    plot_segmented_trace( ...
        trial_indices, ...
        statistics_volatile.sample_mean*100, ...
        prepared_data.windows.volatile, ...
        1, ... % keep legacy shift for volatile windows
        volatile_nonreversal_line_color, ...
        volatile_reversal_line_color, ...
        line_width);

    % Draw stable confidence band.
    stable_band_handle = fill([trial_indices fliplr(trial_indices)], ...
                              [statistics_stable.CI_lower*100, fliplr(statistics_stable.CI_upper)*100], ...
                              stable_confidence_interval_color, ...
                              "EdgeColor", "none", "FaceAlpha", confidence_band_alpha);
    uistack(stable_band_handle, "top");

    % Draw stable mean line with darker color during reversal windows.
    plot_segmented_trace( ...
        trial_indices, ...
        statistics_stable.sample_mean*100, ...
        prepared_data.windows.stable, ...
        0, ...
        stable_nonreversal_line_color, ...
        stable_reversal_line_color, ...
        line_width);

    % ---------- Axes formatting ----------
    ylim(current_specification.y_limits);
    yticks(current_specification.y_ticks);
    xticks(x_tick_values);
    xlim(x_limits);

    % Chance/reference line
    yline(50, ":", "LineWidth", line_width/3, "Color", reference_line_color);

    set(gca, ...
        "FontSize", font_size, ...
        "box", "off", ...
        "FontName", "Arial", ...
        "units", position_units, ...
        "position", inner_axes_position);

    set(gcf, ...
        "Units", position_units, ...
        "Position", figure_position);

    % ---------- Save ----------
    output_name = sprintf("%s_over_block_high_AND_low_volatility_%s.svg", ...
                          current_specification.variable_name, file_name);
    output_full_path = fullfile(figures_dir, output_name);
    print(figure_handle, output_full_path, '-dsvg');   
    fprintf("\n Saved figure: %s\n", output_full_path);

    close(figure_handle);
end

end






function plot_segmented_trace(x, y, windows, shift, color_no_reversal, color_reversal, line_width)
% Plot one trajectory in segments:
% - outside reversal windows: color_no_reversal
% - inside reversal windows:  color_reversal
%
% INPUTS
% x, y               : 1 x n vectors (trial index and value)
% windows            : m x 2 matrix [startTrial endTrial] for reversal windows
% shift              : scalar offset applied to each window start (legacy alignment)
% color_no_reversal  : RGB or RGBA for non-reversal segments
% color_reversal     : RGB or RGBA for reversal segments
% line_width         : line width for all plotted segments

n = numel(x);

% If there are no reversal windows, plot the full trace in one color.
if isempty(windows)
    plot(x, y, "Color", color_no_reversal, "LineWidth", line_width);
    return;
end

% Ensure windows are ordered by start trial.
windows = sortrows(windows, 1);

% Apply start-shift and keep bounds inside [1, n].
starts = max(1, windows(:,1) - shift);
stops  = min(n, windows(:,2));

% Cursor tracks where the next unplotted non-reversal segment begins.
cursor = 1;

for k = 1:numel(starts)
    % 1) Plot non-reversal segment from cursor up to current window start.
    if cursor <= starts(k)
        seg = cursor:starts(k);
        plot(x(seg), y(seg), "Color", color_no_reversal, "LineWidth", line_width);
        hold on
    end

    % 2) Plot reversal segment for the current window.
    seg = starts(k):stops(k);
    plot(x(seg), y(seg), "Color", color_reversal, "LineWidth", line_width);
    hold on

    % Move cursor to end of current window.
    cursor = stops(k);
end

% Plot trailing non-reversal segment after the last reversal window.
if cursor <= n
    seg = cursor:n;
    plot(x(seg), y(seg), "Color", color_no_reversal, "LineWidth", line_width);
end
end

