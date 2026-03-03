function [d] = load_modelling_outputs_info()
    %{ 
    dimensions of data
    temp = {};
    temp.parameters      = {n_models} (1 x n_parameters in this model)
    temp.PChosen         = {n_model}(n_participants x n_conditions x n_trials)
    temp.PCorrect        = {n_model}(n_participants x n_conditions x n_trials)
    temp.PSwitch         = {n_model}(n_participants x n_conditions x n_trials)
    temp.Q               = {n_model}(n_participants x n_conditions x n_trials x 2)
    temp.BIC             = size (n_participants x n_models) --> needed for BMC model comparison function in VBA toolbox
    temp.LAME            = (n_participants x n_models) --> needed for BMC model comparison function in VBA toolbox
    temp.nLL             = (n_participants x n_models) 
    temp.nLPP            = (n_participants x n_models) 
    temp.gradient_nLPP   = {n_participants x n_models}
    temp.hessian_nLPP    = {n_participants x n_models}
    %} 


    d.fields_matrices_of_n_agents_by_fitting_models = ["LAME","nLPP","nLL","BIC"];      %"date","generative_model"
    d.fields_cell_array_of_n_agents_by_fitting_models = ["gradient_nLPP", "hessian_nLPP"];
    d.fields_cell_array_with_one_cell_per_fitting_model = ["parameters", "Q", "PChosen", "PCorrect", "PSwitch"];
    d.fields_matrices_of_n_agents = ["seed", "participant_ID_modelfit", "seed_partial", "seed_complete"];

    % remaining fields are: seed (1x1 at the beginning), and participant_ID_modelfit (n_agents x 1)

end