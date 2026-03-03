function [generated_parameter, generated_parameter_normalized, alpha, beta] = fit_and_generate_beta_parameter(real_parameter, min_parameter, max_parameter, n_new_agents, i_param)
% Fit a beta distribution to one parameter column and generate new samples.

    % Transform data to [0, 1] for Beta fitting
    range_parameter = max_parameter - min_parameter;
    real_parameter_normalized = (real_parameter - min_parameter) / range_parameter;

    assert( max(real_parameter_normalized) <= 1 && min(real_parameter_normalized) > 0, ...
        'Problem: normalised parameter values should be between 0 (excluded) and 1 (included)' );

    % Fit Beta distribution
    beta_params = mle(real_parameter_normalized, 'distribution', 'beta');

    % Extract fitted parameters
    alpha = beta_params(1);
    beta  = beta_params(2);

    % Generate new parameters using this distribution
    generated_parameter_normalized = betarnd(alpha, beta, n_new_agents, 1);

    % Transform generated samples back to original range
    generated_parameter = (generated_parameter_normalized * range_parameter) + min_parameter;
end