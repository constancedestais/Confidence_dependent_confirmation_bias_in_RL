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
    case 3 % model 3: conf-dependent choice temperature
        beta0 = params(1);   % fixed, confidence-independent term in choice function
        w     = params(2);    % controls impact of confidence on choice temperature
        lr1   = params(3);
        lr2   = params(4);
        prior = modelsinfo{model}.get_priors(beta0, w, lr1, lr2);      % vector of priors
    case 4 % model 4: confidence-dependent learning + conf-dependent choice temperature
        beta0 = params(1);   % fixed, confidence-independent term in choice temperature
        w     = params(2);   % weights confidence term in choice temperature
        a1    = params(3);   % confirmatory lr
        b1    = params(4);   % confirmatory lr
        a2    = params(5);   % disconfirmatory lr
        b2    = params(6);   % disconfirmatory lr 
        prior = modelsinfo{model}.get_priors(beta0, w, a1, b1, a2, b2);   % vector of priors
    case 5 % model 5: conf-dependent confirmatory learning
        beta1 = params(1);   % choice temperature
        a1    = params(2);   % confirmatory lr
        b1    = params(3);   % confirmatory lr
        lr2   = params(4);   % disconfirmatory lr
        prior = modelsinfo{model}.get_priors(beta1, a1, b1, lr2);      % vector of prior
    case 6 % model 6: conf-dependent disconfirmatory learning
        beta1 = params(1);   % choice temperature
        lr1   = params(2);   % disconfirmatory lr 
        a2    = params(3);   % confirmatory lr
        b2    = params(4);   % confirmatory lr
        prior = modelsinfo{model}.get_priors(beta1, lr1, a2, b2);      % vector of prior
    case 7   % model 7:  1 learning rate
        beta1 = params(1);   % choice temperature
        lr    = params(2);   % single lr
        prior = modelsinfo{model}.get_priors(beta1, lr);         % vector of priors
    case 8   % model 8: 4 learning rates: confirmatory/disconfirmatory x chosen/unchosen 
        beta1 = params(1);   % choice temperature
        lr1   = params(2);   % confirmatory x chosen lr
        lr2   = params(3);   % confirmatory x unchosen lr
        lr3   = params(4);   % disconfirmatory x chosen lr
        lr4   = params(5);   % disconfirmatory x unchosen lr
        prior = modelsinfo{model}.get_priors(beta1, lr1, lr2, lr3, lr4);         % vector of priors
    case 9 
        beta1 = params(1);   % choice temperature
        a     = params(2);   % policy or factual learning rate
        b     = params(3);   % fictif or counterfactual learning rate 
        prior = modelsinfo{model}.get_priors(beta1, a, b);         % vector of priors
    case 10
        beta1 = params(1);   % choice temperature
        a     = params(2);   
        b1    = params(3);    % confirmatory lr
        b2    = params(4);    % disconfirmatory lr
        prior = modelsinfo{model}.get_priors(beta1, a, b1, b2);   % vector of priors
    case 11 % model 11: confidence-dependent learning (1 intercept) + conf-dependent choice temperature
        beta0 = params(1);   % fixed, confidence-independent term in choice temperature
        w     = params(2);   % weights confidence term in choice temperature
        a     = params(3);   % confirmatory lr
        b1    = params(4);   % confirmatory lr
        b2    = params(5);   % disconfirmatory lr 
        prior = modelsinfo{model}.get_priors(beta0, w, a, b1, b2);   % vector of priors
    case 12 % model 12: Q learning with 4 LR for valence x volatility - but not confirmatory/disconfirmatory difference
        beta1 = params(1);   % fixed, confidence-independent term in choice temperature
        lr1   = params(2);   % low volatility - gain 
        lr2   = params(3);   % high volatility - gain
        lr3   = params(4);   % low volatility - loss
        lr4   = params(5);   % high volatility - loss
        prior = modelsinfo{model}.get_priors(beta1, lr1, lr2, lr3, lr4);         % vector of priors

    case 13 % model 13: Q learning with 8 LR for valence x volatility x confirmatory/disconfirmatory 
        beta1  = params(1);   % choice temperature
        lr1    = params(2);   % low volatility - gain - confirmatory
        lr2    = params(3);   % high volatility - gain - confirmatory
        lr3    = params(4);   % low volatility - loss - confirmatory
        lr4    = params(5);   % high volatility - loss - confirmatory
        lr5    = params(6);   % low volatility - gain - disconfirmatory
        lr6    = params(7);   % high volatility - gain - disconfirmatory
        lr7    = params(8);   % low volatility - loss - disconfirmatory
        lr8    = params(9);   % high volatility - loss - disconfirmatory
        prior = modelsinfo{model}.get_priors(beta1, lr1, lr2, lr3, lr4, lr5, lr6, lr7, lr8);         % vector of priors
    
    case 14 % model 14: Q learning with 4 LR for volatility x confirmatory/disconfirmatory 
        beta1  = params(1);   % choice temperature
        lr1    = params(2);   % low volatility - confirmatory
        lr2    = params(3);   % high volatility - confirmatory
        lr3    = params(4);   % low volatility - disconfirmatory
        lr4    = params(5);   % high volatility - disconfirmatory
        prior = modelsinfo{model}.get_priors(beta1, lr1, lr2, lr3, lr4);         % vector of priors

    case 15 % model 15: Q learning with 4 LR for valence x confirmatory/disconfirmatory 
        beta1  = params(1);   % choice temperature
        lr1    = params(2);   % gain - confirmatory
        lr2    = params(3);   % loss - confirmatory
        lr3    = params(4);   % gain - disconfirmatory
        lr4    = params(5);   % loss - disconfirmatory
        prior = modelsinfo{model}.get_priors(beta1, lr1, lr2, lr3, lr4);         % vector of priors
        
    otherwise 
        warning('Model %i does not exist in get_priors_helper.m', model)
        return
end

end