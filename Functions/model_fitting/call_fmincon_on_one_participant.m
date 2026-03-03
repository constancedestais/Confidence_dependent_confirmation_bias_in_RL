function output = call_fmincon_on_one_participant(data,model,fmincon_options,n_repetition_of_parameter_estimation,models_info,param_starts_by_repetition)

%{

GOAL
call model-fitting function for one participant

INPUTS
- Behaviour data from current participant
    data.participant_ID - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.exp_ID - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.condition - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.full_feedback - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.correct - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.confidence - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.chosen - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.outcome - matrix of dimensions: n_sessions x n_conditions x n_trials
    data.cf_outcome - matrix of dimensions: n_sessions x n_conditions x n_trials
- model - int
- fmincon_options - array of strings
- n_repetition_of_parameter_estimation - int
- models_info - struct
- param_starts_by_repetition - matrix of size: [n_repetition_of_parameter_estimation x n_params]
    !!! COMPUTED OUTSIDE OF PARFOR LOOP TO ALLOW DETERMINISTIC SETTING OF START POINTS WITH SEED

OUTPUTS
For current subject and current model:
    output.parameters{model} = parameters_for_current_model;
    output.Q{model}          = Q_for_current_model ;
    output.PChosen{model}    = PChosen_for_current_model;
    output.PCorrect{model}   = PCorrect_for_current_model;
    output.PSwitch{model}    = PSwitch_for_current_model;  
    output.nLPP,
    output.gradient_nLPP,
    output.hessian_nLPP,
    output.LAME,
    output.nLL,
    output.BIC,
    output.participant_ID_modelfit

%}

% check param_starts_by_repetition
if ~isempty(param_starts_by_repetition)
    assert(size(param_starts_by_repetition,1) == n_repetition_of_parameter_estimation, ...
        'Wrong number of precomputed repetitions');
    assert(size(param_starts_by_repetition,2) == models_info{model}.param_num, ...
        'Wrong number of parameters in precomputed starts');
end


% find current exp_ID
current_exp_ID = unique(data.exp_ID);
current_exp_ID = current_exp_ID(current_exp_ID~="");

% initialise variables
parameters_BY_REPETITION = [];  %n_repetition_of_parameter_estimation x n_param
nLPP_BY_REPETITION = [];
gradient_nLPP_BY_REPETITION = {};
hessian_nLPP_BY_REPETITION = {};

% repeat parameter estimation n_repetition_of_parameter_estimation times to avoid local minima
for k_rep = 1:n_repetition_of_parameter_estimation             
    param_start = param_starts_by_repetition(k_rep,:); % VERY IMPORTANT: this must be prepared outside of the parfor loop to allow seed to create a deterministic start value
    param_lowerbound = models_info{model}.param_lowerbound;
    param_upperbound = models_info{model}.param_upperbound;

    % fmincon: will find the three parameters that minimise the NEGATIVE log posterior probability (="LPP")
    %{
    INPUTS: 
    - variable by which you minimise (x)  REVIEW - HOW DOES IT LINK THIS TO PARAMS?
    - function to minimise: Computational_Model_m1
        INPUTS: 
        - data: conditions, choice, outcomes, counterfactual outcomes ; each time, reshape to just get one participant's values across all sessions, conditions and trials: dimensions = n_sess x n_cond x n_trials_per_cond (must use reshape rather than squeeze to preserve the singleton sessions dimension in data with only 1 session)
        - model number
    - starting points for each parameters
    - upper and lower bounds for each parameter REVIEW / CHECK IF CORRECT
    OUTPUTS: 
    - parameters = parameters that minimise the posterior
    - LPP = NEGATIVE log posterior probability
    - gradient = first-order partial derivation of the LPP function at the returned minimised LPP value 
    - hessian = same as gradient but second-order partial derivation); in the LAME, the HESSIAN rewards models with better parameter precision
    %}  
    try 
        record_timeseries=false;
        [parameters_BY_REPETITION(k_rep,:), nLPP_BY_REPETITION(k_rep), ~, ~, ~, gradient_nLPP_BY_REPETITION{k_rep}, hessian_nLPP_BY_REPETITION{k_rep}] =  fmincon( @(x) Modelling_compute_posterior( x, ...
                                                                                                                                                                            data.condition,...
                                                                                                                                                                            data.chosen ,...
                                                                                                                                                                            data.outcome ,...
                                                                                                                                                                            data.cf_outcome,...
                                                                                                                                                                            data.correct,...
                                                                                                                                                                            data.confidence,...
                                                                                                                                                                            data.full_feedback,...
                                                                                                                                                                            current_exp_ID,...
                                                                                                                                                                            model,...
                                                                                                                                                                            models_info,...
                                                                                                                                                                            record_timeseries ), ... 
                                                                                                                         param_start, [], [], [], [], param_lowerbound, param_upperbound, [], fmincon_options);
    catch terrible_error
        warning(sprintf("Problem running fmincon function / function provided to fmincon. Error: %s",terrible_error.message))
    end
end

% find repetition with best fit / lowest negative log posterior probability) - Salem-Garcia et al. (2021): "find params that minimise the negative log posterior probability)
[~,pos] = min(nLPP_BY_REPETITION);
% in case several repetitions yield the same LPP, only keep the first 
best_rep = pos(1);

% store data in model-specific variables to facilitate paraellelisation
output.parameters    = parameters_BY_REPETITION(best_rep,:);
% Save participant results of model fitting for best repetition
output.nLPP          = nLPP_BY_REPETITION(best_rep);
output.gradient_nLPP = gradient_nLPP_BY_REPETITION{best_rep}; 
output.hessian_nLPP  = hessian_nLPP_BY_REPETITION{best_rep};

% Compute and save Laplace-approximation of model evidence
output.LAME          = compute_LAME(  numel(output.parameters), output.nLPP, output.hessian_nLPP ) ; 

% Save prolific ID to avoid mixing up participant order
current_ID  = unique(data.participant_ID);
output.current_ID    = current_ID(current_ID ~= "");
%% -------------- compute timeseries --------------
% Once the best repetition is known, rerun the model to get timeseries of latent variables (Q-values, pChosen, pCorrect, pSwitch) and nLL/BIC
% Call Modelling_fit_models_all directly, without going through fmincon and Modelling_compute_posterior
% This avoids calling Modelling_timeseries
record_timeseries=true;
[final_nLL,timeseries] = Modelling_fit_models_all( ...
                output.parameters, ...
                data.condition,...
                data.chosen, ...
                data.outcome,...
                data.cf_outcome, ...
                data.correct, ...
                data.confidence, ...
                data.full_feedback, ...
                current_exp_ID, ...
                model, ...
                record_timeseries );
output.timeseries = timeseries;
output.nLL = final_nLL;
[n_sess,n_cond,n_trial] = size(data.correct);
output.BIC = compute_BIC(models_info{model}.param_num, n_sess*n_cond*n_trial, final_nLL);


end


