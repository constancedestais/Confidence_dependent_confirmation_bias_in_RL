function [d] = change_outcome_encoding(d,outcome_encoding_for_fitting)
    
    % check required variables are present
    required = {'symbol_chosen_actual_payoff', 'symbol_unchosen_actual_payoff', 'condition'};   % required field names
    missing = setdiff(required, fieldnames(d));
    assert(isempty(missing), "Missing required fields: %s", strjoin(missing, ", "))
    

    switch outcome_encoding_for_fitting
        case "actual"
            d.outcome       =  d.symbol_chosen_actual_payoff;
            d.cf_outcome    =  d.symbol_unchosen_actual_payoff;
    end
end