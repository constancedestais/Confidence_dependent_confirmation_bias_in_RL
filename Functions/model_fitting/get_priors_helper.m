function [prior] = get_priors_helper(params,model,modelsinfo) 

% fprintf('/n get_priors function: model = %d /n',model)
% goal is to parse the different parameters stored in params into the specific parameters needed to call on the functions to get priors defined in modelsinfo 
switch model
    case 1 % model 1: Q-learning
        beta1 = params(1);   % choice temperature
        lr1   = params(2);   % policy or factual learning rate
        lr2   = params(3);   % fictif or counterfactual learning rate 
        prior = modelsinfo{model}.get_priors(beta1, lr1, lr2);         % vector of priors
    case 2 % model 2: confidence-dependent learning
        beta1 = params(1);   % choice temperature
        a1    = params(2);    % confirmatory lr 
        b1    = params(3);    % confirmatory lr
        a2    = params(4);    % disconfirmatory lr
        b2    = params(5);    % disconfirmatory lr
        prior = modelsinfo{model}.get_priors(beta1, a1, b1, a2, b2);   % vector of priors
    
    case 4 % model 4: confidence-dependent learning + conf-dependent choice temperature
        beta0 = params(1);   % fixed, confidence-independent term in choice temperature
        w     = params(2);   % weights confidence term in choice temperature
        a1    = params(3);   % confirmatory lr
        b1    = params(4);   % confirmatory lr
        a2    = params(5);   % disconfirmatory lr
        b2    = params(6);   % disconfirmatory lr 
        prior = modelsinfo{model}.get_priors(beta0, w, a1, b1, a2, b2);   % vector of priors
        
    otherwise 
        warning('Model %i does not exist in get_priors_helper.m', model)
        return
end

end