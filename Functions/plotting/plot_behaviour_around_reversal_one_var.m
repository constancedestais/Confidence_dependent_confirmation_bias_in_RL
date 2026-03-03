function plot_behaviour_around_reversal_one_var(data, n_trials_before_reversal, version_name, figures_dir, ...
                                                variable_name_for_file, y_label, y_limits, y_ticks, line_color_rgb)
% plot_behaviour_around_reversal_one_var
%
% Single-variable version of your legacy plotting code, compatible with new event-locked outputs.
%
% Inputs
%   data : struct -> obtained from extract_event_locked_participant_traces(), must contain:
%       data.lags            (1 x nLags)  e.g. -n:n
%       data.mean            (1 x nLags)  participant-locked mean (0-1 scale)
%       data.per_participant  (P x nLags)  participant traces (0-1 scale), used to compute 95% CI
%
%   n_trials_before_reversal : scalar n, used to set x = -n:n (must match data.lags)
%   version_name             : char/string for saving
%   figures_dir              : output folder
%
% Variable-specific plot settings (passed in):
%   variable_name_for_file   : char/string, used in filename (e.g. 'pcorrect' or 'confidence')
%   y_label                  : char/string
%   y_limits                 : 1x2 numeric (in the ×100 scale)
%   y_ticks                  : numeric vector (in the ×100 scale)
%   line_color_rgb           : 1x3 numeric RGB (e.g. color_dict.black)
%
% Behaviour
%   - Plots mean and 95% CI band (computed across participants).
%   - Scales values by ×100 explicitly 
%   - Keeps your figure settings and SVG + FIG saving.

%% check 
% data contains expected fields
required = ["lags","mean","per_participant"];
assert(all(isfield(data, required)), "data must contain lags, mean, per_participant.");

% shape
assert(isvector(data.lags), "data.lags must be a vector.");
assert(isvector(data.mean), "data.mean must be a vector.");
assert(size(data.per_participant,2) == numel(data.lags), ...
    "data.per_participant columns must match number of lags.");
assert(numel(data.mean) == numel(data.lags), ...
    "data.mean length must match data.lags.");

% variable range
all_values = [data.mean(:); data.per_participant(:)];
all_values = all_values(~isnan(all_values));
assert(all(all_values >= 0 & all_values <= 1), ...
    "Expected behavioural values in [0,1] before x100 scaling.");

% have minimum data for CIs
n_by_lag = sum(~isnan(data.per_participant),1);
assert(any(n_by_lag >= 2), "Need at least one lag with >=2 participants for CI.");


%% set useful variables used for plots
% Visual style parameters reused across all variables/versions
color_dict = load_my_colors();
CI_alpha = 0.15;
line_alpha = 0.7;
font_size = 10;
my_linewidth = 1;
my_linecolor = color_dict.grey;
position_units = "centimeters";
figure_position = [3, 3, 5, 6];
inner_position_size = [1, 1, 2.35, 3.3]; 
figure_background_color = 'none';
axes_background_color = 'none';
my_xlabel = ""; % my_xlabel = "Trials around reversal";
reversal_color  = {color_dict.grey};
reversal_linestyle = "--";
reversal_linewidth = 0.75;

% Build symmetric trial axis around reversal (0 = reversal trial)
my_x = -n_trials_before_reversal:n_trials_before_reversal;
my_xticks = [min(my_x): abs(max(my_x)-min(my_x))/2 :max(my_x)];

% Check that provided data.lags match the intended x-axis
if ~isequal(data.lags(:)', my_x(:)')
    error('data.lags does not match -n_trials_before_reversal:n_trials_before_reversal. Check pre/post used in extraction.');
end

% Compute 95% CI across participants (t-based) from data.per_participant
% CI is computed per trial relative to reversal (so it accounts for varying participant contributions at each lag due to edge effects and missing data)
[ci_low, ci_high] = ci95_from_participants(data.per_participant);

% Create a stats struct
variable_stats.sample_mean = data.mean;   % 0-1 scale
variable_stats.CI_lower    = ci_low;     % 0-1 scale
variable_stats.CI_upper    = ci_high;    % 0-1 scale

%% plot 
f = figure;

% Mean trace (converted to percentage scale)
plot(my_x, variable_stats.sample_mean*100, ...
    'Color', [line_color_rgb, line_alpha], 'LineWidth', my_linewidth);
hold on

% Shaded confidence interval band (also converted to percentage scale)
fill([my_x fliplr(my_x)], ...
     [variable_stats.CI_lower*100, fliplr(variable_stats.CI_upper*100)], ...
     line_color_rgb, 'EdgeColor', 'none', 'FaceAlpha', CI_alpha);
hold on

% Axis limits/ticks provided by caller for variable-specific scaling
ylim(y_limits)
xticks(my_xticks)
yticks(y_ticks)
ylabel(y_label)

% Vertical line marks reversal (x=0), horizontal line marks 50%
xline(0, "LineWidth", reversal_linewidth, "LineStyle", reversal_linestyle, "Color", reversal_color{1});
yline(50, ":", "LineWidth", my_linewidth, "Color", my_linecolor);

hold off

% figure settings
set(gca, 'FontSize', font_size, 'box', 'off', 'FontName', 'Arial', ...
    'color', figure_background_color, 'units', position_units, 'position', inner_position_size);

set(gcf, 'Units', position_units, 'Position', figure_position);

xlabel(my_xlabel)

% save figure
name = sprintf('%s_over_trials_around_reversal_%s.svg', char(variable_name_for_file), char(version_name));
svnm = fullfile(figures_dir, name);
print(f, svnm, '-dsvg'); 
fprintf('\n Saved figure: %s  \n', svnm)
close(f);
end

% ===== helper: 95% CI from participant traces =====
function [ci_low, ci_high] = ci95_from_participants(per_participant)
X = per_participant;

% Per-lag sample size after excluding NaNs
n  = sum(~isnan(X), 1);

% Per-lag mean, SD, and SEM across participants
mu = mean(X, 1, 'omitnan');
sd = std(X, 0, 1, 'omitnan');
sem = sd ./ sqrt(n);

% t critical value per lag (only defined when n>=2)
tcrit = nan(size(n));
for k = 1:numel(n)
    if n(k) >= 2
        tcrit(k) = tinv(0.975, n(k)-1);
    end
end

% 95% CI: mean ± tcrit*SEM
half = tcrit .* sem;
ci_low  = mu - half;
ci_high = mu + half;
end
