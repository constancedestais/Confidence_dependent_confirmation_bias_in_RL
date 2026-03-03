function [action, chosen, cf] = get_binary_action_based_on_pChooseA(pChooseStim1)
    %{
    INPUT: p(chose option 1)

    OUTPUT: 
    - binary action (1 or 2)
    - index of chosen option in Q values (1 or 2), 
    - index of counterfactual option in Q values (1 or 2)
    %} 
    r = rand();
    if r<pChooseStim1
        action = 1; % choose stim 1
        chosen = 1; % index of chosen stimuli in Q value matrix (= 1 or 2)
        cf = 2; % index of counterfactual stimuli in Q value matrix (= 1 or 2)
    else
        action = 2; % choose stim 2
        chosen = 2; % index of chosen stimuli in Q value matrix (= 1 or 2)
        cf = 1; % index of counterfactual stimuli in Q value matrix (= 1 or 2)
    end
end