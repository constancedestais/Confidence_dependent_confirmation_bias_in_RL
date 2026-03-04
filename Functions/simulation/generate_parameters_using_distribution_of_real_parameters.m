function [generated_parameters] = generate_parameters_using_distribution_of_real_parameters(model, real_parameters, n_new_agents)
%{
INPUT
    model = model number
    real_parameters = matrix of size n_participants x n_parameters
    n_new_agents = number of agents you want to create
OUTPUT
    parameters = matrix of size n_new_agents x n_parameters
Goal
    - Fit beta distribution to parameter data
    - Generate new parameters using this distribution
%}

% example
%{
% Example data between -40 and 40
data = -40 + 80 * rand(1000, 1); % Random data for demonstration

% Transform data to [0, 1] for Beta fitting
data_normalized = (data + 40) / 80;

% Fit Beta distribution
beta_params = mle(data_normalized, 'distribution', 'beta');

% Extract fitted parameters
alpha = beta_params(1);
beta  = beta_params(2);

% Generate random samples from the Beta distribution
num_samples = 1000;
generated_data_normalized = betarnd(alpha, beta, num_samples, 1);

% Transform generated samples back to [-40, 40]
generated_data = generated_data_normalized * 80 - 40;

% Plot original and generated data
figure;
subplot(2, 1, 1);
histogram(data, 'Normalization', 'pdf');
title('Original Data Histogram');
xlabel('Value');
ylabel('Probability Density');

subplot(2, 1, 2);
histogram(generated_data, 'Normalization', 'pdf');
title('Generated Data Histogram (Beta)');
xlabel('Value');
ylabel('Probability Density');
%}


% sanity check: check that real parameters in a two dimensional matrix (not a cell array containing multiple matrices)
assert(ismatrix(real_parameters), 'generate_parameters_using_distribution_of_real_parameters(): real_parameters must be a matrix');
assert(ndims(real_parameters) == 2, 'generate_parameters_using_distribution_of_real_parameters(): real_parameters must be a 2D matrix');

% Load information about model parameters and priors
models_info = load_models_info(); 

% fit beta distribution to real parameters
n_params = size(real_parameters,2);
% initialise
generated_parameters_normalized = NaN(n_new_agents,n_params);
generated_parameters            = NaN(n_new_agents,n_params);

% loop over each parameter
for i_param = 1:n_params
    %% Fit beta distribution to parameter data

    %{
    % Transform data to [0, 1] for Beta fitting
    min_parameter = models_info{model}.param_lowerbound(i_param);
    max_parameter = models_info{model}.param_upperbound(i_param);
    range_parameter = max_parameter - min_parameter;
    real_parameter_normalized = (real_parameters(:,i_param) + abs(min_parameter)) / range_parameter;

    assert( max(real_parameter_normalized) <= 1 && min(real_parameter_normalized) > 0 , 'Problem: normalised parameter values should be between 0 (excluded) and 1 (included)')
    
    % Fit Beta distribution
    beta_params = mle(real_parameter_normalized, 'distribution', 'beta');
    % Extract fitted parameters
    alpha = beta_params(1);
    beta  = beta_params(2);

    fprintf("==== param #%i ==== \n",i_param)
    fprintf("alpha,beta: (%.2f, %.2f)\n",alpha,beta)
    %}

    min_parameter = models_info{model}.param_lowerbound(i_param);
    max_parameter = models_info{model}.param_upperbound(i_param);

    [generated_parameters(:, i_param), generated_parameters_normalized(:, i_param), ~, ~] = fit_and_generate_beta_parameter( ...
                                                                                            real_parameters(:, i_param), ...
                                                                                            min_parameter, ...
                                                                                            max_parameter, ...
                                                                                            n_new_agents, ...
                                                                                            i_param ...
                                                                                        );

    
end




end