%% This function  probability to parameters
% it is used to calculate the negative log posterior, using priors on the parameters, and the negative log likelihood 
    % if provide this function to fmincon, fmincon will find parameters that maximise likelihood AND probability density fucntion
    % the priors are taken from Daw et al. Neuron 2011
% this function calls the function Models_Params which runs the different models individually

function [negative_log_posterior] = Modelling_compute_posterior(params,condition,action,outcome,cf_outcome,correct,confidence,full_feedback,current_exp_ID,model,modelsInfo,record_timeseries)
    
    log_prior = get_priors_helper(params,model,modelsInfo); % NB: prior distributions are already logged in modelsInfo
    
    negative_log_prior = -sum(log_prior); 
    
    try 
        negative_log_likelihood = Modelling_fit_models_all(params,condition,action,outcome,cf_outcome,correct,confidence,full_feedback,current_exp_ID,model,record_timeseries); % compute classic likelihood  
    catch
        warning("Problem running Modelling_compute_posterior function")
    end

    negative_log_posterior = negative_log_prior + negative_log_likelihood; 
    
   
end



