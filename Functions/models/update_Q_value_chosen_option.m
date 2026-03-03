    function [Q_next_chosen] = update_Q_value_chosen_option(Q_chosen,outcome,lrCON,lrDIS)
    
    %{
        GOAL
        update Q-values using delta rule, with confirmatory/disconfirmatory learning rates based on sign of prediction error

        INPUTS
        - Q_chosen: Q value of chosen option
        - outcome: outcome of chosen option
        - lrCON: confirmatory learning rate 
        - lrDIS: disconfirmatory learning rate 
    %}
    
        % learning: compute prediction error (delta rule) and update Q value of chosen option based on feedback
        delta_chosen = outcome - Q_chosen;
        is_confirmatory_chosen = delta_chosen >= 0;  
        if is_confirmatory_chosen
            learning_rate_chosen = lrCON;
        else
            learning_rate_chosen = lrDIS;
        end
        Q_next_chosen = Q_chosen + learning_rate_chosen * delta_chosen; 

    end