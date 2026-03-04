function modelling_outputs = load_modelling_outputs(requested_output_dataset_name, outcome_encoding, data_dir, participant_ordered_list) 

% this function returns modelling_outputs based on the requested dataset version
%{
 INPUTS: 
  - requested_output_dataset_name: stores the names of the desired output version - which is a combination of some of the original datasets or the original datasets themselves
        Names you can request can be found in the list of "requested_output_dataset_name" in the read_behaviour_dataset_dictionary.m function
  - outcome_encoding: models are run for different outcome encodings (actual, relative, and sometimes semirelative), so this is necessary to load the desired parameters 

OUTPUTS: 
  - modelling_outputs: a structure containing the variables in Parameters and Timeseries files (parameters BIC LAME PChosen PCorrect PSwitch Q), which are concatenated across the original datasets that make up the desired output version

VARIABLES IN FUNCTION
  - most output variables are of size {n_models}(n_participants,:)
  - corresponding_initial_dataset_names: on row i, stores the names of all the initial datasets (exp_ID) that make up the output dataset on row i in output_dataset_names
    e.g. 
      - requested_output_dataset_name = "RL1_partialfeedback"
      - corresponds to row 13 in output_dataset_names_RL1
      - so need to combine all datasets mentioned on row 13 of corresponding_initial_dataset_names_RL1 (so "RL1_v9","RL1_v11","RL1_v13","RL1_v15")
      - at the end, to see parameters for model 4 in the RL1_partialfeedback dataset, write: modelling_outputs.parameters{4}
%}

% sanity check
assert(numel(participant_ordered_list) > 1 , 'Problem: load_modelling_outputs function requires a list of the participants in the required order');
assert(sum(participant_ordered_list ~= "") , 'Problem: load_modelling_outputs function requires a list of the participants without empty ("") values');

%% code section that adapts to the different datasets

% find smallest dataset units (aka initial_dataset_names) that must be combined to get the requested_output_dataset_name
initial_dataset_names = read_modelling_output_dataset_dictionary(requested_output_dataset_name);

%% iterate over datasets to create list of all participants that should appear in the final dataset and to get useful variables for size (n_models and n_participants)
 
% initialise
participant_ID_modelfit_all_versions = strings(0);

% loop over datasets
for j = 1:size(initial_dataset_names,2)
    % load Parameter data for a given dataset
    name = sprintf('modelling_outputs_%s_outcomes_%s.mat',outcome_encoding,initial_dataset_names(j));
    file = fullfile(data_dir,name); % output from model fitting 
    vars = {"modelling_outputs"};
    load(file,vars{:}); % --> loads parameters, BIC, LAME; of size n_participants x n_models  

    % concatenate participant IDs from one dataset after the other
    participant_ID_modelfit_all_versions = cat(1, participant_ID_modelfit_all_versions, modelling_outputs.participant_ID_modelfit); % [participant_ID_modelfit_all_versions; participant_ID_modelfit];

    % get number of models (it's fine if this variable just stored the value from the last dataset)
    n_models = size(modelling_outputs.parameters,2);

    clear modelling_outputs vars
end

n_participants = numel(participant_ID_modelfit_all_versions);

% sanity check: compare number and IDs of participants resulting from combination of different datasets to number of participants in similarly filtered behavioural data (d_mat)
assert( numel(participant_ID_modelfit_all_versions) == numel(participant_ordered_list) , 'Problem: there should be same number of participants in loaded modelling output data as in the participant_ordered_list provided as input');
assert( isempty(setxor(participant_ID_modelfit_all_versions, participant_ordered_list)) ,"Problem: the same participant IDs should be present in the loaded modelling output data as in the participant_ordered_list provided as input");

%% iterate once over initial_dataset_names corresponding to one final dataset (for a given model, concatenate data from all these datasets) 

% initialise larger arrays, within which data from each input file will be added one by one
temp = {};
temp.parameters      = cell(n_models,1);  % size {n_models} (1 x n_parameters in this model)
temp.PChosen         = cell(n_models,1);  % size {n_model}(n_participants x n_conditions x n_trials)
temp.PCorrect        = cell(n_models,1);  % size {n_model}(n_participants x n_conditions x n_trials)
temp.PSwitch         = cell(n_models,1);  % size {n_model}(n_participants x n_conditions x n_trials)
temp.Q               = cell(n_models,1);  % size {n_model}(n_participants x n_conditions x n_trials x 2)
temp.BIC             = NaN(n_participants,n_models);  % size (n_participants x n_models) --> needed for BMC model comparison function in VBA toolbox
temp.LAME            = NaN(n_participants,n_models);  % size (n_participants x n_models) --> needed for BMC model comparison function in VBA toolbox
temp.nLL             = NaN(n_participants,n_models);  % size (n_participants x n_models) 
temp.nLPP            = NaN(n_participants,n_models);  % size (n_participants x n_models) 
temp.gradient_nLPP   = NaN(n_participants,n_models);  % size {n_participants x n_models}
temp.hessian_nLPP    = NaN(n_participants,n_models);  % size {n_participants x n_models}

n_participants_seen_here = 0;

for j = 1:size(initial_dataset_names,2)
    % load Parameter data for a given dataset
    % --> loads parameters, BIC, LAME; of size n_participants x n_models  
    name = sprintf('modelling_outputs_%s_outcomes_%s.mat',outcome_encoding,initial_dataset_names(j));
    file  = fullfile(data_dir,name); % output from model fitting 
    load(file,"modelling_outputs"); 

    % get number of participants in the loaded dataset
    n_participants_current_dataset = numel(modelling_outputs.participant_ID_modelfit);

    % update cell arrays with values for each model by iterating over models : for a given model, concatenate matrices from several datasets
    for model = 1:n_models       
        % concatenate parameter matrices
        temp.parameters{model} = [temp.parameters{model}; modelling_outputs.parameters{model}];
        % concatenate PChosen, PCorrect, PSwitch, and Q-value matrices of current version with previous versions 
        temp.PChosen{   model} = cat(1, temp.PChosen{   model}, modelling_outputs.PChosen{model} ); 
        temp.PCorrect{  model} = cat(1, temp.PCorrect{  model}, modelling_outputs.PCorrect{model}); 
        temp.PSwitch{   model} = cat(1, temp.PSwitch{   model}, modelling_outputs.PSwitch{model});  
        temp.Q{         model} = cat(1, temp.Q{         model}, modelling_outputs.Q{model});        
        % create indices for BIC and LAME variables
        first_participant = n_participants_seen_here+1;
        last_participant  = n_participants_seen_here + n_participants_current_dataset;
        % fill in variables for model evidence
        try
            temp.BIC( first_participant:last_participant,          model)  = modelling_outputs.BIC(            :,model);      
            temp.LAME(first_participant:last_participant,          model)  = modelling_outputs.LAME(           :,model); 
            temp.nLL( first_participant:last_participant,          model)  = modelling_outputs.nLL(            :,model); 
            temp.nLPP(first_participant:last_participant,          model)  = modelling_outputs.nLPP(           :,model); 
            temp.gradient_nLPP(first_participant:last_participant, model)  = modelling_outputs.gradient_nLPP(  :,model);       
            temp.hessian_nLPP(first_participant:last_participant,  model)  = modelling_outputs.hessian_nLPP(   :,model); 
        catch
            warning("")
        end
    end
    % update the total number of participants that have been processed so far
    n_participants_seen_here = n_participants_seen_here + n_participants_current_dataset ; 
    clear file modelling_outputs
end

% check dimensions of variables
assert(size(temp.BIC,1)          == n_participants,"Problem, BIC and parameters should have same number of participants");
assert(size(temp.nLL,1)          == n_participants,"Problem, BIC and parameters should have same number of participants");
assert(size(temp.PChosen{1},1)   == n_participants,"Problem, BIC and parameters should have same number of participants");
assert(size(temp.parameters{1},1)== n_participants,"Problem, BIC and parameters should have same number of participants");
assert(size(temp.BIC,2)       == n_models,"Problem, BIC and parameters should have same number of models");
assert(size(temp.nLL,2)       == n_models,"Problem, BIC and parameters should have same number of models");
assert(size(temp.PChosen,1)   == n_models,"Problem, BIC and parameters should have same number of models");
assert(size(temp.parameters,1)== n_models,"Problem, BIC and parameters should have same number of models");


%% fix order of participants in model fit dataset to match that in behavioural dataset

% set useful variables
n_participants = numel(participant_ordered_list);

% initialise matrix variables with dimensions: n_participants x model
temp_ordered.BIC            = NaN(n_participants,n_models); 
temp_ordered.LAME           = NaN(n_participants,n_models);  
temp_ordered.nLL            = NaN(n_participants,n_models);  
temp_ordered.nLPP           = NaN(n_participants,n_models);  
temp_ordered.gradient_nLPP  = NaN(n_participants,n_models);  
temp_ordered.hessian_nLPP   = NaN(n_participants,n_models);  

% initialise cell array variables with dimensions: {model}(n_participants,:)
temp_ordered.participant_ID_modelfit = strings(0); % size {n_models}(n_participants);
temp_ordered.parameters = cell(n_models,1);  % size {n_models}(1 x n_parameters in this model)
temp_ordered.PChosen    = cell(n_models,1);  % size {n_models}(n_participants x n_conditions x n_trials)
temp_ordered.PCorrect   = cell(n_models,1);  % size {n_models}(n_participants x n_conditions x n_trials)
temp_ordered.PSwitch    = cell(n_models,1);  % size {n_models}(n_participants x n_conditions x n_trials)
temp_ordered.Q          = cell(n_models,1);  % size {n_models}(n_participants x n_conditions x n_trials X 2)

% "i_participant" will be used as the index for the new datasets
for i_participant = 1:n_participants

    % get current participant ID from the input: participant_ordered_list
    current_participant_ID = participant_ordered_list(i_participant);
    % fill in variables with this participant's data
    participant_ID_modelfit(i_participant,:) = current_participant_ID;

    % get index for the participant with this ID in the modelling outputs 
    current_participant_index_in_modelling_outputs = find( participant_ID_modelfit_all_versions == current_participant_ID );

    % loop over models since most variables have a dimension that stores data for each model
    % and for each variable, store the current participant's data in the index corresponding to this participant's position in the behavioural data
    for model = 1:n_models 
        % fill variables with dimensions: n_participants x model (if model was not fitted, fills with NaNs)
        temp_ordered.BIC(          i_participant, model) = temp.BIC(          current_participant_index_in_modelling_outputs, model) ; 
        temp_ordered.LAME(         i_participant, model) = temp.LAME(         current_participant_index_in_modelling_outputs, model) ; 
        temp_ordered.nLL(          i_participant, model) = temp.nLL(          current_participant_index_in_modelling_outputs, model) ; 
        temp_ordered.nLPP(         i_participant, model) = temp.nLPP(         current_participant_index_in_modelling_outputs, model) ; 
        temp_ordered.gradient_nLPP(i_participant, model) = temp.gradient_nLPP(current_participant_index_in_modelling_outputs, model) ; 
        temp_ordered.hessian_nLPP( i_participant, model) = temp.hessian_nLPP( current_participant_index_in_modelling_outputs, model) ; 
        % prevent crashing when model was not fitted, 
        if ~isempty(temp.parameters{model})   
            % fill structure variables with dimensions: {model}(n_participants,:)
            try 
            temp_ordered.parameters{model} = [temp_ordered.parameters{model} ; temp.parameters{model}(current_participant_index_in_modelling_outputs,:)       ] ; 
            temp_ordered.PChosen{   model} = [temp_ordered.PChosen{   model} ; temp.PChosen{   model}(current_participant_index_in_modelling_outputs,:,:,:)   ] ; 
            temp_ordered.PCorrect{  model} = [temp_ordered.PCorrect{  model} ; temp.PCorrect{  model}(current_participant_index_in_modelling_outputs,:,:,:)   ] ; 
            temp_ordered.PSwitch{   model} = [temp_ordered.PSwitch{   model} ; temp.PSwitch{   model}(current_participant_index_in_modelling_outputs,:,:,:)   ] ; 
            temp_ordered.Q{         model} = [temp_ordered.Q{         model} ; temp.Q{         model}(current_participant_index_in_modelling_outputs,:,:,:,:) ] ;
            catch
            a=1;
            end
        else
            % fill structure variables with empty arrays 
            temp_ordered.parameters{model} = [] ; 
            temp_ordered.PChosen{   model} = [] ;
            temp_ordered.PCorrect{  model} = [] ;
            temp_ordered.PSwitch{   model} = [] ;
            temp_ordered.Q{         model} = [] ;
            %fprintf(sprintf("\n NB: Modelling output data does not contain fitted parameters for model %i, for dataset %s \n",model,requested_output_dataset_name))
        end
    end
end

% sanity check : check that ordering participants in the variables has not altered the dimensions of variables
assert(isequal( size(temp.BIC,1),           size(temp_ordered.BIC,1) )  , "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.LAME,1),          size(temp_ordered.LAME,1) ) , "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.nLL,1),           size(temp_ordered.nLL,1) ) , "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.nLPP,1),          size(temp_ordered.nLPP,1) ) , "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.gradient_nLPP,1), size(temp_ordered.gradient_nLPP,1) ) , "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.hessian_nLPP,1),  size(temp_ordered.hessian_nLPP,1) ) , "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.parameters{1},1), size(temp_ordered.parameters{1},1) ) ,"Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.PChosen{1},1),    size(temp_ordered.PChosen{1},1) )  ,  "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.PCorrect{1},1),   size(temp_ordered.PCorrect{1},1) ) ,  "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.PSwitch{1},1),    size(temp_ordered.PSwitch{1},1) ) ,   "Problem, variable should be of same size before and after re-ordering the participants");
assert(isequal( size(temp.Q{1},1),          size(temp_ordered.Q{1},1) ) ,         "Problem, variable should be of same size before and after re-ordering the participants");

% sanity check: check that recovering a random participant works 
r = 7;
current_participant_ID = participant_ordered_list(r);
current_participant_index_in_modelling_outputs = find( participant_ID_modelfit_all_versions == current_participant_ID );
% for BIC variable
assert( isequaln( temp_ordered.BIC(r,1),             temp.BIC(current_participant_index_in_modelling_outputs,1)            ) ,"Problem, value of a random participant should be the same before and after re-ordering the participants");
% for PCorrect variable
assert( isequaln( temp_ordered.PCorrect{1}(r,1,2,1), temp.PCorrect{1}(current_participant_index_in_modelling_outputs,1,2,1)) ,"Problem, value of a random participant should be the same before and after re-ordering the participants");
% for params
assert( isequaln( temp_ordered.parameters{1}(r,1),   temp.parameters{1}(current_participant_index_in_modelling_outputs,1)  ) ,"Problem, value of a random participant should be the same before and after re-ordering the participants");

%% store variables in a structure

modelling_outputs = {};
modelling_outputs.BIC           = temp_ordered.BIC;               % size (n_models, n_participants);
modelling_outputs.LAME          = temp_ordered.LAME;              % size (n_models, n_participants);
modelling_outputs.nLL           = temp_ordered.nLL;               % size (n_models, n_participants);
modelling_outputs.nLPP          = temp_ordered.nLPP;              % size (n_models, n_participants);
modelling_outputs.gradient_nLPP = temp_ordered.gradient_nLPP;     % size {n_models, n_participants};
modelling_outputs.hessian_nLPP  = temp_ordered.hessian_nLPP;      % size {n_models, n_participants};
modelling_outputs.participant_ID_modelfit = participant_ID_modelfit_all_versions; % size {n_models}(n_participants);
modelling_outputs.parameters    = temp_ordered.parameters;        % size {n_models}(1 x n_parameters in this model)
modelling_outputs.PChosen       = temp_ordered.PChosen;           % size {n_models}(n_participants x sessions x n_conditions x n_trials)
modelling_outputs.PCorrect      = temp_ordered.PCorrect;          % size {n_models}(n_participants x sessions x n_conditions x n_trials)
modelling_outputs.PSwitch       = temp_ordered.PSwitch;           % size {n_models}(n_participants x sessions x n_conditions x n_trials)
modelling_outputs.Q             = temp_ordered.Q;                 % size {n_models}(n_participants x sessions x n_conditions x n_trials X 2)
    
end