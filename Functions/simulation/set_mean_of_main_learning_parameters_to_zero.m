function [generated_parameters] = set_mean_of_main_learning_parameters_to_zero(generated_parameters, generative_model)

assert( ismember(generative_model, [2,4,10,11]), 'Problem: The model you have requested is not dealt with in the following function: set_mean_of_main_learning_parameters_to_zero.m ' )

% Load information about model parameters 
[~,models_info_extra] = load_models_info_constance(); 

n_agents = size(generated_parameters,1);

% sSt high significance threshold to make sure that the resulting parameter distribution is clearly centered at zero, even if only have a few agents
significance_level = 0.01;
% Calculate the critical t-value for the significance level
t_critical = tinv(1 - significance_level / 2, n_agents - 1);          
% Desired SEM to make mean not significantly different from zero
desired_sem = 1 / t_critical; 

% Generates a normal distribution centered around zero, with a mean not significantly different from zero

% Calculate the standard deviation
sigma = desired_sem * sqrt(n_agents);
% set mean of distribution 
mu = 0;
% ARBITRARY, get smaller std around zero
sigma = sigma*0.80;

% replace parameters controlling learning rate with values close to zero
% IF the resulting distribution is significantly different from zero, repeat the process
p_value_CON = 0;
p_value_DIS = 0;
while p_value_CON <= 0.05 && p_value_DIS <= 0.05
    column_index_CON = models_info_extra.indices_learning_parameters_CON_DIS(generative_model, 1);
    generated_parameters(:, column_index_CON ) = normrnd(mu, sigma, n_agents, 1); 
    [~,p_value_CON] = ttest(generated_parameters(:, column_index_CON ));
    
    column_index_DIS = models_info_extra.indices_learning_parameters_CON_DIS(generative_model, 2);
    generated_parameters(:, column_index_DIS ) = normrnd(mu, sigma, n_agents, 1);
    [~,p_value_DIS] = ttest(generated_parameters(:, column_index_DIS ));
end
assert( sum(isnan(generated_parameters),"all")==0, 'Problem: parameter values cannot be NaN values');

end