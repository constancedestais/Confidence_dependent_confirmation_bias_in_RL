function BIC = compute_BIC( number_of_parameters, n_data_points, negative_log_likelihood )

% classic equation: BIC = (n_parameters)*ln(n data points) - 2*LL
% but we invert signs, since we use "nLL" instead of "LL"   
BIC = number_of_parameters.*log(n_data_points) + 2*negative_log_likelihood;


end