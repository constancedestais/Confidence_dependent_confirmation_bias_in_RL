function [models_info,models_info_extra] = load_models_info()
% Function returns useful, hard-coded information about each model 


%% predefine values that will be used in several models

% upper and lower bounds for parameter estimation
lowerbound_beta1 = 0;
upperbound_beta1 = 40;

lowerbound_beta0 = 0;
upperbound_beta0 = 40;

lowerbound_w     = 0;
upperbound_w     = 40;

lowerbound_lr    = 0; 
upperbound_lr    = 1;

lowerbound_a     = -10;
upperbound_a     = 10;

lowerbound_b     = -40;
upperbound_b     = 40;

a_amplitude = abs(upperbound_a-lowerbound_a);
b_amplitude = abs(upperbound_b-lowerbound_b);

% functions for generating priors
priorfunction_beta1 = @(x) log(gampdf(x, 1.2, 5));
priorfunction_beta0 = @(x) log(gampdf(x, 1.2, 5)); 
priorfunction_w     = @(x) log(gampdf(x, 1.2, 5)); % @(x) log(betapdf(x, 1.1, 1.1)); 
priorfunction_lr    = @(x) log(betapdf(x, 1.1, 1.1));
priorfunction_a     = @(x) log(betapdf((x+(a_amplitude/2))/a_amplitude, 1.1, 1.1)); % log(betapdf((x+10)/20, 1.1, 1.1));
priorfunction_b     = @(x) log(betapdf((x+(b_amplitude/2))/b_amplitude, 1.1, 1.1)); % log(betapdf((x+40)/80, 1.1, 1.1)); 

% functions for generating starting point
startfunction_beta1 = @() 5*rand();
startfunction_beta0 = @() 5*rand(); % CHECK WITH MAEL
startfunction_w     = @() 10*rand();
startfunction_lr    = @() rand();
startfunction_a     = @() a_amplitude*rand()-(a_amplitude/2); %(logit(0.7)-logit(0.3))*rand()+logit(0.3);  % a_amplitude*rand()-(a_amplitude/2); % 10*rand()-5; % a_amplitude*rand()-(a_amplitude/2) % (logit(0.7)-logit(0.3))*rand()+logit(0.3);  
startfunction_b     = @() b_amplitude*rand()-(b_amplitude/2); % 80*rand()-40;

%% create model-specific variables
   
% model 1: asymmetric Q learning
models_info{1}.model_name       = "1. Classic_asymmetric";
models_info{1}.param_names      = ["beta1", "alpha_confirmatory", "alpha_disconfirmatory"]; 
models_info{1}.param_num        = length(models_info{1}.param_names);
models_info{1}.get_param_start  = @() [startfunction_beta1(), startfunction_lr(), startfunction_lr()]; 
models_info{1}.param_lowerbound = [lowerbound_beta1, lowerbound_lr, lowerbound_lr];
models_info{1}.param_upperbound = [upperbound_beta1, upperbound_lr, upperbound_lr];
models_info{1}.get_priors      = @(beta1,lr1,lr2) [priorfunction_beta1(beta1), priorfunction_lr(lr1), priorfunction_lr(lr2)];

% model 2: confidence-dependent learning
models_info{2}.model_name       = "2. Confidence-dependent learning";
models_info{2}.param_names      = ["beta1" "a_confirmatory" "b_confirmatory" "a_disconfirmatory" "b_disconfirmatory"] ;
models_info{2}.param_num        = length(models_info{2}.param_names);
models_info{2}.get_param_start  = @() [startfunction_beta1(), startfunction_a(), startfunction_b(), startfunction_a(), startfunction_b()]; 
models_info{2}.param_lowerbound = [lowerbound_beta1, lowerbound_a, lowerbound_b, lowerbound_a, lowerbound_b]; 
models_info{2}.param_upperbound = [upperbound_beta1, upperbound_a, upperbound_b, upperbound_a, upperbound_b];
models_info{2}.get_priors      = @(beta1,a1,b1,a2,b2) [priorfunction_beta1(beta1), priorfunction_a(a1), priorfunction_b(b1), priorfunction_a(a2), priorfunction_b(b2)];

% model 4: confidence-dependent learning + conf-dependent choice temperature
models_info{4}.model_name       = "4. Confidence-dependent learning & choice";
models_info{4}.param_names      = ["beta0" "w" "a_confirmatory" "b_confirmatory" "a_disconfirmatory" "b_disconfirmatory" ]; 
models_info{4}.param_num        = length(models_info{4}.param_names);
models_info{4}.get_param_start  = @() [startfunction_beta0(), startfunction_w(), startfunction_a(), startfunction_b(), startfunction_a(), startfunction_b()]; 
models_info{4}.param_lowerbound = [lowerbound_beta0, lowerbound_w, lowerbound_a, lowerbound_b, lowerbound_a, lowerbound_b];
models_info{4}.param_upperbound = [upperbound_beta0, upperbound_w, upperbound_a, upperbound_b, upperbound_a, upperbound_b];
models_info{4}.get_priors      = @(beta0,w,a1,b1,a2,b2) [priorfunction_beta0(beta0), priorfunction_w(w), priorfunction_a(a1), priorfunction_b(b1), priorfunction_a(a2), priorfunction_b(b2)];

%% sanity checks 
% check that all fields are not empty for each model
required_fields = fieldnames(models_info{1});
for m = 1:numel(models_info)
    % if there is a model for that model number, check its fields
    if ~isempty(models_info{m})
        for f = 1:numel(required_fields)
            field = required_fields{f};
            field_exist_and_is_not_empty = isfield(models_info{m}, field) && ~isempty(models_info{m}.(field));
            fieldname = string(field);
            if field_exist_and_is_not_empty == 0
                assert(field_exist_and_is_not_empty,sprintf('Problem, in load_models_info, model %i info is missing field: %s (or else field is empty) ',m,fieldname));
            end
        end
    end
end


% check consistency across param definitions
for m = 1:numel(models_info)
    mi = models_info{m};
    % if there is a model for that model number, check its fields
    if ~isempty(models_info{m})
            
        % Basic type checks
        assert(isfield(mi,'param_names') && (isstring(mi.param_names) || iscellstr(mi.param_names)) , ...
            'Model %d: param_names must be a string array or cellstr.', m);
        assert(isfield(mi,'param_num') && isnumeric(mi.param_num) && isscalar(mi.param_num), ...
            'Model %d: param_num must be a numeric scalar.', m);
        assert(isfield(mi,'get_param_start') && isa(mi.get_param_start,'function_handle'), ...
            'Model %d: get_param_start must be a function handle.', m);
        assert(isfield(mi,'param_lowerbound') && isnumeric(mi.param_lowerbound), ...
            'Model %d: param_lowerbound must be numeric.', m);
        assert(isfield(mi,'param_upperbound') && isnumeric(mi.param_upperbound), ...
            'Model %d: param_upperbound must be numeric.', m);
        assert(isfield(mi,'get_priors') && isa(mi.get_priors,'function_handle'), ...
            'Model %d: get_priors must be a function handle.', m);

        % Ensure param_num matches param_names length
        nNames = numel(mi.param_names);
        assert(mi.param_num == nNames, ...
            'Model %d: param_num (%d) does not match numel(param_names) (%d).', m, mi.param_num, nNames);

        % Ensure bounds lengths match param_num
        nLB = numel(mi.param_lowerbound);
        nUB = numel(mi.param_upperbound);
        assert(nLB == mi.param_num, ...
            'Model %d: numel(param_lowerbound) (%d) does not match param_num (%d).', m, nLB, mi.param_num);
        assert(nUB == mi.param_num, ...
            'Model %d: numel(param_upperbound) (%d) does not match param_num (%d).', m, nUB, mi.param_num);

        % Ensure bounds are finite and ordered
        assert(all(isfinite(mi.param_lowerbound)) && all(isfinite(mi.param_upperbound)), ...
            'Model %d: bounds contain non-finite values.', m);
        assert(all(mi.param_lowerbound(:) <= mi.param_upperbound(:)), ...
            'Model %d: some lowerbounds exceed upperbounds.', m);

        % Check starting point dimensionality and that it lies within bounds
        x0 = mi.get_param_start();
        assert(isnumeric(x0) && isvector(x0), 'Model %d: get_param_start must return a numeric vector.', m);
        assert(numel(x0) == mi.param_num, ...
            'Model %d: get_param_start returned %d values, expected %d.', m, numel(x0), mi.param_num);

        x0 = x0(:)'; % row
        lb = mi.param_lowerbound(:)'; 
        ub = mi.param_upperbound(:)';

        if any(x0 < lb) || any(x0 > ub)
            badIdx = find(x0 < lb | x0 > ub);
            badNames = string(mi.param_names(badIdx));
            assert(false, ...
                'Model %d: start point out of bounds for params: %s', m, strjoin(badNames, ", "));
        end

        % Check priors: accept the right number of inputs and return correct length

        try
            args = num2cell(x0);
            pri = mi.get_priors(args{:});
        catch ME
            error('Model %d: get_priors call failed (%s).', m, ME.message);
        end

        assert(isnumeric(pri) && isvector(pri), ...
            'Model %d: get_priors must return a numeric vector.', m);
        assert(numel(pri) == mi.param_num, ...
            'Model %d: get_priors returned %d values, expected %d.', m, numel(pri), mi.param_num);

        % Warn if priors produce NaN/Inf at the start point (often indicates domain issues)
        if any(~isfinite(pri))
            warning('Model %d: get_priors returned non-finite values at start point (NaN/Inf).', m);
        end
    end
end



%% extra variables for my conveniance, that are deduced from the above information -> useful for certain plots

% initialise with empty cells

models_info_extra.indices_learning_parameters_CON = cell(numel(models_info),1);
models_info_extra.names_learning_parameters_CON = cell(numel(models_info),1);
models_info_extra.indices_learning_parameters_DIS = cell(numel(models_info),1);
models_info_extra.names_learning_parameters_DIS = cell(numel(models_info),1);
models_info_extra.indices_learning_parameters = cell(numel(models_info),1);
models_info_extra.names_learning_parameters = cell(numel(models_info),1);


models_info_extra.indices_b_CON_DIS = NaN(numel(models_info),2);
models_info_extra.indices_a_CON_DIS = NaN(numel(models_info),2);


% NOTE: DOES NOT WORK FOR MODELS WITH MORE THAN ONE CONFIRMATORY/DISCONFIRMATORY LEARNING PARAMETER E.G. MODEL 15, BECAUSE indices_learning_parameters_CON_DIS ONLY HAS 2 SPOTS
for m = 1:numel(models_info)
    if ~isempty(models_info{m})
        % look at alpha or b parameters in my main models, split by confirmatory/disconfirmatory
        index_learning_parameters_CON = find( contains(models_info{m}.param_names,["b_confirmatory","alpha_confirmatory"]));
        index_learning_parameters_DIS = find( contains(models_info{m}.param_names,["b_disconfirmatory","alpha_disconfirmatory"]));
        if ~isempty(index_learning_parameters_CON)
            % fill in indices_learning_parameters_CON_DIS
            models_info_extra.indices_learning_parameters_CON{m} = index_learning_parameters_CON;
            % fill in names_learning_parameters_CON
            models_info_extra.names_learning_parameters_CON{m} = models_info{m}.param_names(index_learning_parameters_CON);
            % change name from confirmatory to CON
            models_info_extra.names_learning_parameters_CON{m} = regexprep(models_info_extra.names_learning_parameters_CON{m}, 'confirmatory', 'CON', 'ignorecase');
        end
        if ~isempty(index_learning_parameters_DIS)
            % fill in indices_learning_parameters_DIS
            models_info_extra.indices_learning_parameters_DIS{m} = index_learning_parameters_DIS;
            % fill in names_learning_parameters_DIS
            models_info_extra.names_learning_parameters_DIS{m} = models_info{m}.param_names(index_learning_parameters_DIS);
            % change name from disconfirmatory to DIS
            models_info_extra.names_learning_parameters_DIS{m} = regexprep(models_info_extra.names_learning_parameters_DIS{m}, 'disconfirmatory', 'DIS', 'ignorecase');
        end
        clear index_learning_parameters_CON index_learning_parameters_DIS

        % look at alpha or b parameters in my main models, NOT split by confirmatory/disconfirmatory
        index_learning_parameters = find( contains(models_info{m}.param_names,["b_","alpha_"]));
        if ~isempty(index_learning_parameters) 
            % fill in indices_learning_parameters
            models_info_extra.indices_learning_parameters{m} = index_learning_parameters;
            % fill in names_learning_parameters
            models_info_extra.names_learning_parameters{m} = models_info{m}.param_names(index_learning_parameters);
            % change name from confirmatory to CON
            models_info_extra.names_learning_parameters{m} = regexprep(models_info_extra.names_learning_parameters{m}, 'confirmatory', 'CON', 'ignorecase');
            % change name from disconfirmatory to DIS
            models_info_extra.names_learning_parameters{m} = regexprep(models_info_extra.names_learning_parameters{m}, 'disconfirmatory', 'DIS', 'ignorecase');
        end


        % look at b parameters in my main models
        index_b_CON = find( ismember(models_info{m}.param_names,["b_confirmatory"]));
        index_b_DIS = find( ismember(models_info{m}.param_names,["b_disconfirmatory"]));
        if ~isempty(index_b_CON)
            % fill in indices_b_CON_DIS
            models_info_extra.indices_b_CON_DIS(m,1) = index_b_CON;
        end
        if ~isempty(index_b_DIS)
            % fill in indices_b_CON_DIS
            models_info_extra.indices_b_CON_DIS(m,2) = index_b_DIS;
        end
        clear index_b_CON index_b_DIS

        % look at a parameters in my main models
        index_a_CON = find( ismember(models_info{m}.param_names,["a_confirmatory","a"]));
        index_a_DIS = find( ismember(models_info{m}.param_names,["a_disconfirmatory","a"]));
        if ~isempty(index_a_CON)
            % fill in indices_b_CON_DIS
            models_info_extra.indices_a_CON_DIS(m,1) = index_a_CON;
        end
        if ~isempty(index_a_DIS)
            % fill in indices_b_CON_DIS
            models_info_extra.indices_a_CON_DIS(m,2) = index_a_DIS;
        end
        clear index_a_CON index_a_DIS
    end
end

end