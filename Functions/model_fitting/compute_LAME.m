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

%{
--- WORRY ---
Here i'm taking the hessian of the nLPP, but original formula says hessian of LPP
--- ANSWER ---
According to chatGPT, in original formula:
LAME = LPP + (n/2)*log(2*pi) - (1/2)*log(det(H)) 
where H actually corresponds to MINUS the second-order partial derivative of LPP, so H = -nabla^2(LPP). 
    NB: What you get with the hessian command in MATLAB is the second-order partial derivative of x, or nabla^2(x)
    NB: General property of the second-order partial derivative: nabla^2(x) = -nabla^2(x).
So if I have nLPP instead of LPP and similarly the second-order partial derivative of the nLPP (nabla^2(nLPP)), 
then I can directly use it because: H = -nabla^2(LPP) = nabla^2(nLPP)
%}

end