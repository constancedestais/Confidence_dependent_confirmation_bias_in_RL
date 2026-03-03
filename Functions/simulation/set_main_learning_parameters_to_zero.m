function [generated_parameters] = set_main_learning_parameters_to_zero(generated_parameters, generative_model)

assert( ismember(generative_model, [1,2,3,4,10,11]), 'Problem: The model you have requested is not dealt with in the following function: set_main_learning_parameters_to_zero.m ' )

% Load information about model parameters 
[~,models_info_extra] = load_models_info_constance(); 


% set parameters of distribution from which parameters will be drawn
% in this case, very small distribution around zero

n_agents = size(generated_parameters,1);
%{
% replace parameters controlling learning learning rate with values very close to zero
mu = 0.001;
sigma = 0.000001;
column_index_CON = models_info_extra.indices_learning_parameters_CON_DIS(generative_model, 1);
generated_parameters(:, column_index_CON) = normrnd(mu, sigma, n_agents, 1);
column_index_DIS = models_info_extra.indices_learning_parameters_CON_DIS(generative_model, 2);
generated_parameters(:, column_index_DIS) = normrnd(mu, sigma, n_agents, 1);
%}

% replace parameters controlling learning learning rate with zero
column_index_CON = models_info_extra.indices_learning_parameters_CON_DIS(generative_model, 1);
generated_parameters(:, column_index_CON) = zeros(n_agents, 1);
column_index_DIS = models_info_extra.indices_learning_parameters_CON_DIS(generative_model, 2);
generated_parameters(:, column_index_DIS) = zeros(n_agents, 1);

%{
    if generative_model == 1
            params_SUBJ(2) = parameter_learning_CON;
            params_SUBJ(3) = parameter_learning_DIS;
        elseif generative_model == 2
            params_SUBJ(3) = parameter_learning_CON;
            params_SUBJ(5) = parameter_learning_DIS;
        elseif generative_model == 3
            params_SUBJ(3) = parameter_learning_CON;
            params_SUBJ(4) = parameter_learning_DIS;
        elseif generative_model == 4
            params_SUBJ(4) = parameter_learning_CON;
            params_SUBJ(6) = parameter_learning_DIS;
        elseif generative_model == 10
            params_SUBJ(3) = parameter_learning_CON;
            params_SUBJ(4) = parameter_learning_DIS;
        elseif generative_model == 11
            params_SUBJ(4) = parameter_learning_CON;
            params_SUBJ(5) = parameter_learning_DIS;
            % if want to look specifically at a parameter == 0
            % params_SUBJ(3) = normrnd(0,2); % mean at zero, mostly between -5 and 5
    end
%}

end