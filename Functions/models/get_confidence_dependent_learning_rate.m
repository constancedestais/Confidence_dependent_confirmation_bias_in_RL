function [lr] = get_confidence_dependent_learning_rate(b,confidence,a) %(b, confidence, a, confidence_subject_mean, confidence_subject_sd)

    lr = 1/(1 + exp(-(b * (confidence-0.50) + a))); % initially I used this
    % lr = 1/(1 + exp(-(b * (confidence-0.75) + a))); % new attempts, hopefully centering confidence by subtracting mean can help with collinearity
    % lr = 1/(1 + exp( -(b * (confidence-confidence_subject_mean) + a) ) ); % new attempts, hopefully centering confidence by subtracting mean can help with collinearity

end
