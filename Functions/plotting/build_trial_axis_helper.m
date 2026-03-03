function [trial_indices, x_limits, x_tick_values] = build_trial_axis_helper(number_of_trials, tick_step)
% Create x-axis values for trial-based plots:
% - trial_indices: full trial vector (1:number_of_trials)
% - x_limits: axis limits spanning first to last trial
% - x_tick_values: regularly spaced tick positions, always including last trial

% Build trial axis with ticks at 1, then multiples of tick_step, and always last trial.

trial_indices = 1:number_of_trials;
x_limits = [1, number_of_trials];

% Multiples of tick_step (10,20,30,...) plus first and last trial.
x_tick_values = unique([1, tick_step:tick_step:number_of_trials, number_of_trials], "stable");


end