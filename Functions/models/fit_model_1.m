function [nll,Q_next,pChosen,pCorrect,pSwitch] = fit_model_1(data)
% Model 1: asymmetric Q learning    
    % Note: output current nll and current action which become the next trial's "previous" nll and previous action
    %{%}
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
    %confidence      = data.confidence;

    % set parameters
    beta1      = params(1);   % choice temperature
    alphaCON   = params(2);   % confirmatory lr
    alphaDIS   = params(3);   % disconfirmatory lr

    % -------------------------- CHOICE -------------------------- %
    % find indices of chosen/unchosen stimuli, to find position in Q value matrix (= 1 or 2)
    chosen = action;
    cf = 3-action; 

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
    % update Q-values using helper functions (delta rule update with confirmatory/disconfirmatory learning rates)
    Q_next = NaN(1,2); 
    Q_next(chosen) = update_Q_value_chosen_option(Q(chosen), outcome, alphaCON, alphaDIS);
    Q_next(cf) = update_Q_value_counterfactual_option(Q(cf), cf_outcome, alphaCON, alphaDIS, full_feedback);

end


%% older version
%{
function [nll,Q_next,pChosen,pCorrect,pSwitch] = fit_model_1(data)
% Model 1: asymmetric Q learning    
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
    %confidence      = data.confidence;

    % set parameters
    beta1      = params(1);   % choice temperature
    alphaCON   = params(2);   % confirmatory lr
    alphaDIS   = params(3);   % disconfirmatory lr

    % -------------------------- CHOICE -------------------------- %
    % find indices of chosen/unchosen stimuli, to find position in Q value matrix (= 1 or 2)
    chosen     = action;
    cf         = 3-action; 

    % compute p(choose chosen option) & p(choose correct option)
    diffQ      = Q(cf)-Q(chosen);
    pChosen    = 1./(1+exp(diffQ.*beta1));  
    is_correct = (correct==1);
    pCorrect   = is_correct*pChosen + (-1*is_correct+1)*(1-pChosen); 

    % compute pSwitch (compare current choice to previous choice to do so)
    if (action ~= action_previous)
        pSwitch = pChosen;
    else % if action == action_previous
        pSwitch = 1 - pChosen;
    end

    % compute likelihood using p(choose chosen)
    nll = nll_previous - log(pChosen);   % IN CASE: nll = nll - (beta1 * Q(action(k_cond,i)) - log(sum(exp(beta1 * Q(:)))));   % This is the softmax, the likelihood of the choice
    
    % -------------------------- LEARNING -------------------------- %

    % Q value chosen option: compute prediction error (delta rule) and update Q value of chosen option based on feedback
    delta_chosen = outcome - Q(chosen);    
    is_confirmatory = delta_chosen >= 0;
    Q_next(chosen) = Q(chosen) + ( is_confirmatory*alphaCON + (is_confirmatory*(-1)+1)*alphaDIS ) * delta_chosen;
    
    % Q value unchosen option: if have complete/full feedback also update Q value of unchosen option
    if (full_feedback == 1)
        delta_unchosen = cf_outcome - Q(cf);   % update cf Q value 
        is_confirmatory = delta_unchosen <= 0;
        Q_next(cf) = Q(cf) + ( is_confirmatory*alphaCON + (is_confirmatory*(-1)+1)*alphaDIS ) * delta_unchosen;      
    else
        Q_next(cf) = Q(cf);
    end


end
%}



