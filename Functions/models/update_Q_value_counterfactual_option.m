function [Q_next_cf] = update_Q_value_counterfactual_option(Q_cf,cf_outcome,lrCON,lrDIS,full_feedback)
    %{
        GOAL
        update Q-values using delta rule, with confirmatory/disconfirmatory learning rates based on sign of prediction error

        INPUTS
        - Q_cf: Q value of counterfactual (unchosen) option
        - cf_outcome: outcome of counterfactual (unchosen) option
        - lrCON: confirmatory learning rate (same as for chosen option)
        - lrDIS: disconfirmatory learning rate (same as for chosen option)
        - full_feedback: indicator if have complete feedback (1) or partial feedback (0)
    %}
    
    if (full_feedback == 1) % if have complete feedback (aka full information), also update Q value of unchosen option
        % compute prediction error (delta rule) and update Q value of unchosen option 
        delta_unchosen = cf_outcome - Q_cf;
        is_confirmatory_unchosen = delta_unchosen <= 0;
        if is_confirmatory_unchosen
            learning_rate_unchosen = lrCON;
        else
            learning_rate_unchosen = lrDIS;
        end
        Q_next_cf = Q_cf + learning_rate_unchosen * delta_unchosen;     
    else % if partial feedback, no update of unchosen Q value
        Q_next_cf = Q_cf;
    end

end