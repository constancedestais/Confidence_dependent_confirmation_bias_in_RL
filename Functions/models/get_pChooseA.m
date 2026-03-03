function [pChooseA] = get_pChooseA(Q_A,Q_B,beta1)

    delta_Q        = Q_B - Q_A;
    pChooseA = 1./(1+exp(delta_Q.*beta1));

end