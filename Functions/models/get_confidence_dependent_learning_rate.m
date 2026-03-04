function [lr] = get_confidence_dependent_learning_rate(b,confidence,a) %(b, confidence, a, confidence_subject_mean, confidence_subject_sd)

    lr = 1/(1 + exp(-(b * (confidence-0.50) + a))); 
end
