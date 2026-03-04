function LAME = compute_LAME( number_of_parameters, negative_log_posterior_probability, hessian_of_negative_log_posterior_probability )

%{
Laplace-approximation of model evidence, as shown in Daw 2009 (eq. 17), Lebreton 2019 and Salem-Garcia 2023 (eq.20) correcting here for our estimation of nLPP instead of LPP
    Salem-Garcia 2023 (eq.20): LAME = nLPP + (n/2)*log(2*pi) - (1/2)*log(det(H))
        where n is the number of parameters and H is hessian of nLPP
        NB: equation in paper says "LPP" but in the text he says LPP actually refers to nLPP
    Lebreton 2019 (p.22): LAME = -nLPP + (n/2)*log(2*pi) - (1/2)*log(det(H)) 
        where n is the number of parameters BUT UNCLEAR WHETHER H IS HESSIAN OF LPP OR nLPP
%}

LAME = -negative_log_posterior_probability + (number_of_parameters/2)*log(2*pi) - real(log(det(hessian_of_negative_log_posterior_probability))/2);

if ~isreal(det(hessian_of_negative_log_posterior_probability))
    error('compute_LAME(): current determinant of the Hessian has an imaginary part.')
end


end