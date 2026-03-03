function [Q_next,action,outcome,cf_outcome,is_correct,confidence] = generate_model_1(inputs)
% Model 1: asymmetric Q-learning
%{
 Inputs: 
    - parameters for model, 
    - latest Q_values (array of 2 for the the 2 stim), 
    - reward_schedule (array of 2 for the the 2 stim), 
    - correct_schedule (one value)
    - full feedback (one value, = 0 or 1)
 Output: 
    - Q_next (array of 2 for the the 2 stim), 
    - action (one value, = 1 or 2)
    - outcome (one value)
    - cf_outcome (one value)
    - correct (one value, = 0 or 1)
%}

    % rename inputs
    params              = inputs.params;
    Q                   = inputs.Q;
    reward_schedule     = inputs.reward_schedule;
    correct_schedule    = inputs.correct_schedule;
    full_feedback       = inputs.full_feedback_schedule;
    previous_confidence = inputs.previous_confidence;
    real_confidence     = inputs.real_confidence;
    confidence_generation_method = inputs.confidence_generation_method;

    % set parameters
    beta1      = params(1);   % choice temperature
    alphaCON   = params(2);   % confirmatory learning rate
    alphaDIS   = params(3);   % disconfirmatory learning rate

    % sanity check 
    assert(~any(isnan(reward_schedule)),'Problem: there should not be any NaN outcomes when simulating data.')

    % -------------------------- CHOICE -------------------------- %
    % apply choice policy
    pChooseStim1 = get_pChooseA(Q(1),Q(2),beta1);

    % get binary action based probability
    [action, chosen, cf] = get_binary_action_based_on_pChooseA(pChooseStim1);

    % -------------------------- CONFIDENCE [temporary] -------------------------- %
    is_correct = (action == correct_schedule);     % check if chosen symbol == correct symbol
    Q_chosen = Q(chosen);
    Q_unchosen = Q(cf);
    if is_correct == 1
        Q_correct = Q_chosen;
        Q_incorrect = Q_unchosen;
    else
        Q_correct = Q_unchosen;
        Q_incorrect = Q_chosen;
    end

    confidence = generate_confidence(Q_chosen,Q_unchosen,Q_correct,Q_incorrect,beta1,real_confidence,confidence_generation_method);
    assert(~isnan(confidence),'Problem: in the simulations, confidence must never be equal to NaN otherwise it sets Q values to NaN and they cannot recover ')

    % -------------------------- LEARNING -------------------------- %
    % identify outcomes 
    outcome      = reward_schedule(action);   % record outcome
    cf_outcome   = reward_schedule(cf);      % record cf outcome

    % update Q-values using helper functions (delta rule update with confirmatory/disconfirmatory learning rates)
    Q_next = NaN(1,2); 
    Q_next(chosen) = update_Q_value_chosen_option(Q(chosen), outcome, alphaCON, alphaDIS);
    Q_next(cf) = update_Q_value_counterfactual_option(Q(cf), cf_outcome, alphaCON, alphaDIS, full_feedback);

    % sanity check
    assert(sum(isnan(Q_next))==0,'Problem: in the simulations, Q-values must never be equal to NaN, because they will be stuck at NaN values from then on')

end



%% older version
%{
function [Q_next,action,outcome,cf_outcome,is_correct,confidence] = generate_model_1(inputs)
% Model 1: asymmetric Q-learning
%{
 Inputs: 
    - parameters for model, 
    - latest Q_values (array of 2 for the the 2 stim), 
    - reward_schedule (array of 2 for the the 2 stim), 
    - correct_schedule (one value)
    - full feedback (one value, = 0 or 1)
 Output: 
    - Q_next (array of 2 for the the 2 stim), 
    - action (one value, = 1 or 2)
    - outcome (one value)
    - cf_outcome (one value)
    - correct (one value, = 0 or 1)
%}

    % rename inputs
    params              = inputs.params;
    Q                   = inputs.Q;
    reward_schedule     = inputs.reward_schedule;
    correct_schedule    = inputs.correct_schedule;
    full_feedback       = inputs.full_feedback_schedule;
    previous_confidence = inputs.previous_confidence;
    real_confidence     = inputs.real_confidence;
    confidence_generation_method = inputs.confidence_generation_method;

    % set parameters
    beta1      = params(1);   % choice temperature
    alphaCON   = params(2);   % confirmatory learning rate
    alphaDIS   = params(3);   % disconfirmatory learning rate

    % sanity check 
    assert(~any(isnan(reward_schedule)),'Problem: there should not be any NaN outcomes when simulating data.')

    % -------------------------- CHOICE -------------------------- %

    % simulate choice 
    Q_next       = NaN(1,2);
    diffQ        = Q(2)-Q(1);
    % apply choice policy
    pChooseStim1 = 1./(1+exp(diffQ.*beta1));
    r            = rand();
    action       = ((r<pChooseStim1)*(-1))+2; % if r<pChooseStim1, choose stim 1, else choose stim 2
    is_correct   = (action == correct_schedule);     % check if chosen symbol == correct symbol
    chosen       = action;  % find index of chosen stimuli in Q value matrix (= 1 or 2)
    cf           = 3-action; 
    
    % -------------------------- CONFIDENCE [temporary] -------------------------- %

    Q_chosen = Q(chosen);
    Q_unchosen = Q(cf);
    if is_correct == 1
        Q_correct = Q_chosen;
        Q_incorrect = Q_unchosen;
    else
        Q_correct = Q_unchosen;
        Q_incorrect = Q_chosen;
    end

    confidence = generate_confidence(Q_chosen,Q_unchosen,Q_correct,Q_incorrect,beta1,real_confidence,confidence_generation_method);
    assert(~isnan(confidence),'Problem: in the simulations, confidence must never be equal to NaN otherwise it sets Q values to NaN and they cannot recover ')

    % -------------------------- LEARNING -------------------------- %

    % Q value chosen option: compute prediction error (delta rule) and update Q value of chosen option based on feedback
    outcome = reward_schedule(action);   % record outcome
    delta_chosen = outcome - Q(chosen);
    if delta_chosen >= 0   % learning rate depends on prediction error sign
        alpha_chosen = alphaCON;
    else
        alpha_chosen = alphaDIS;
    end
    Q_next(chosen) = Q(chosen) + alpha_chosen * delta_chosen; % update Q value of chosen option

    % Q value unchosen option: if have complete/full feedback also update Q value of unchosen option
    if (full_feedback == 1)
        cf_outcome = reward_schedule(cf);  % record cf outcome
        delta_unchosen = cf_outcome - Q(cf);   % update cf Q value 
        if delta_unchosen <= 0  % learning rate depends on prediction error sign
            alpha_unchosen = alphaCON;
        else
            alpha_unchosen = alphaDIS;
        end
        Q_next(cf) = Q(cf) + alpha_unchosen * delta_unchosen;
    else   % partial info condition: Q_unchosen keeps its previous value 
        cf_outcome = reward_schedule(cf);          % record cf outcome
        Q_next(cf) = Q(cf);        % update cf Q value
    end
    
    assert(sum(isnan(Q_next))==0,'Problem: in the simulations, Q-values must never be equal to NaN, because they will be stuck at NaN values from then on')

end
%}









