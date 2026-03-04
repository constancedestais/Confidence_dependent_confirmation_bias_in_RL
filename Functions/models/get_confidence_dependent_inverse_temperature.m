function [beta1] = get_confidence_dependent_inverse_temperature(beta0, w, confidence, previous_confidence) % (beta0, w, confidence, previous_confidence, confidence_subject_mean, confidence_subject_sd)

    beta1 = beta0 + w*(confidence-0.50); 
    
end