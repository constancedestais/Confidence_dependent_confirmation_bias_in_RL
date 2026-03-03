function [nll,Q_next,pChosen,pCorrect,pSwitch] = fit_model_4(data)
% Model 4: Q-learning + confidence-dependent learning + confidence-dependent choice temperature
    % Note: output current nll and current action which become the next trial's "previous" nll and previous action
    
    params          = data.params;
    nll_previous    = data.nll_previous;    
    Q               = data.Q;
    action          = data.action;
    action_previous = data.previous_action;
    outcome         = data.outcome;
    cf_outcome      = data.cf_outcome;
    correct         = data.correct;
    full_feedback   = data.full_feedback;
    %condition       = data.condition;
    confidence      = data.confidence;

    % sanity check
    if isnan(confidence) || confidence == 88888888
        warning('missing confidence information, cannot fit this model')
        return
    end

    % set parameters
    beta0 = params(1);   % fixed, confidence-independent term in choice temperature
    w     = params(2);   % weights confidence term in choice temperature
    aCON  = params(3);   % confirmatory lr
    bCON  = params(4);   % confirmatory lr
    aDIS  = params(5);   % disconfirmatory lr
    bDIS  = params(6);   % disconfirmatory lr
    
    % -------------------------- CHOICE -------------------------- %
    % find indices of chosen/unchosen stimuli, to find position in Q value matrix (= 1 or 2)
    chosen = action;
    cf = 3-action; 

    % inverse temperature parameter depends on confidence
    beta1 = get_confidence_dependent_inverse_temperature(beta0, w, confidence, NaN); % temperature depends on reported confidence on this trial

    % compute p(choose chosen option) & p(choose correct option) 
    pChosen = get_pChooseA(Q(chosen),Q(cf),beta1);

    % compute likelihood using p(choose chosen)
    nll = nll_previous - log(pChosen);   % IN CASE: nll = nll - (beta1 * Q(action(k_cond,i)) - log(sum(exp(beta1 * Q(:)))));   % This is the softmax, the likelihood of the choice
    
    % get p(chose correct)
    if correct==1
        pCorrect = pChosen;
    else
        pCorrect = 1 - pChosen;
    end
    
    % get p(switched choice) (need to compare current choice to previous choice)
    if (action ~= action_previous)
        pSwitch = pChosen;
    else % if action == action_previous
        pSwitch = 1 - pChosen;
    end

    % -------------------------- LEARNING -------------------------- %
    % set confidence-dependent learning rates
    lrCON = get_confidence_dependent_learning_rate(bCON, confidence, aCON);  % confirmatory
    lrDIS = get_confidence_dependent_learning_rate(bDIS, confidence, aDIS); % disconfirmatory

    % update Q-values using helper functions (delta rule update with confirmatory/disconfirmatory learning rates)
    Q_next = NaN(1,2); 
    Q_next(chosen) = update_Q_value_chosen_option(Q(chosen), outcome, lrCON, lrDIS);
    Q_next(cf) = update_Q_value_counterfactual_option(Q(cf), cf_outcome, lrCON, lrDIS, full_feedback);

end








