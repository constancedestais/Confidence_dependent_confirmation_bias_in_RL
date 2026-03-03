function confidence = generate_confidence(Q_chosen,Q_unchosen,Q_correct,Q_incorrect,slope_coefficient,real_confidence,confidence_generation_method)
					

    if confidence_generation_method == "fake"
        % ---- generate confidence artificially ---- %
        %{
        Simulate confidence on a given trial
            confidence = 1./(1+exp(diff_Q.*slope_coefficient));
        Possible computations of diff_Q: 
            diff_Q = Q_chosen - Q_unchosen;
            diff_Q = Q_max - Q_min;
            diff_Q = Q_correct - Q_incorrect;     
        Or
            confidence = rand;
        %}
        diff_Q = abs(Q_chosen - Q_unchosen);
        confidence = 1./(1+exp(diff_Q.*slope_coefficient)); 

    elseif confidence_generation_method == "real"
        % ---- use real participants' confidence ---- %
     
        if ~isnan(real_confidence)
            confidence = real_confidence;
        else
            confidence = (rand/2)+0.5;
        end
    else
        error('Problem: currently, confidence_generation_method = %s, but it can only be equal to "fake" or "real".',confidence_generation_method)
    end

end

% If this function is called after choice, can use Qchosen and Qunchosen 
% but this creates a recursiveness in the choice-dependent confidence model
%{
pChosen       = 1./(1+exp((Q(cf)-Q(chosen)).*beta1));
pchoseCorrect = is_correct*pChosen + (-1*is_correct+1)*(1-pChosen);
confidence    =  pchoseCorrect; % pchoseCorrect % 0.5+abs(pChosen-0.5);  % 0.4+pchoseCorrect*0.5;
%}
