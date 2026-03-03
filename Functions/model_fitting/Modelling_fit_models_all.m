function [nll,timeseries] = Modelling_fit_models_all(params,condition,action,outcome,cf_outcome,correct,confidence,full_feedback,current_exp_ID,model,record_timeseries)
%% This function computes the negative log likelihood of data given parameters and model
% It also computes trial-by-trial latent variables (Q-values, pChosen, pCorrect, pSwitch) if a timeseries struct is provided
% If no timeseries struct is provided, only the negative log likelihood is computed. 
% when functionsing with fmincon
%   - timeseries is not provided as input, and only nll is computed
%   - fmincon will only retrieve first output of fucntion anyway - nll must be first output

if record_timeseries
    timeseries = struct('Q', [], 'pChosen', [], 'pCorrect', [], 'pSwitch', []);
else 
    %timeseries = [];
end 

% Choose model function
switch model
    case 1, fitfun = @fit_model_1;
    case 2, fitfun = @fit_model_2;
    case 3, fitfun = @fit_model_3;
    case 4, fitfun = @fit_model_4;
    case 15, fitfun = @fit_model_15;
    otherwise 
        warning('Model %i does not exist', model)
    return
end

% checks for specific models
if ismember(model,[12 13 14])
    % warning('Functions models 12-14 assumes that conditions = (1) low_volatility_gain  ; (2) high_volatility_gain ; (3) low_volatility_loss ; (4) high_volatility_loss')
    assert(~any(contains(current_exp_ID, "MLNSG_0reversals")),"Problem: can only fit model 12-14 on datasets with within-participant volatility conditions (e.g. not MLNSG_0_reversals)");
end

% Create input struct
input = struct( ...
    'params', params, ... # stays the same
    'nll_previous', 0, ...
    'Q', NaN, ...
    'action', NaN, ...
    'previous_action', NaN, ...
    'outcome', NaN, ...
    'cf_outcome', NaN, ...
    'correct', NaN, ...
    'full_feedback', NaN, ...
    'condition', NaN, ...
    'confidence', NaN );


% set variables that are fixed across all pilot versions, subjects and conditions
n_sess   = size(condition,1);
n_cond   = size(condition,2); % this condition variable is for one subject
n_trial  = size(condition,3);
nll      = 0;  % negative log likelihood

if ~record_timeseries
    % loop over sessions
    for s = 1:n_sess
        % loop over conditions
        for c = 1:n_cond
            % Initial Q variable
            Q = [0,0]; 
            % loop over trials
            for t = 1:n_trial
                % check for NaN values, if NaN, move on to next trial - NaN values reflects either a missed trial OR that experiments of different sizes are combined in a matrix
                if isnan(action(s,c,t)) || isnan(confidence(s,c,t)) 
                    % warning('Modelling_fit_models_all.m : NaN confidence values in some trials, check that this if for the right reasons');
                    
                    % if called from fmincon, do nothing, just skip to next trial, since nll and Q are here single values, updated on each trial but not stored at each trial 
                    continue
                else 
                    % set input variables that change on each trial
                    if t==1
                        previous_action = action(s,c,t); 
                    else
                        previous_action = action(s,c,t-1);
                    end
                    input.nll_previous    = nll;
                    input.Q               = Q;
                    input.action          = action(s,c,t);
                    input.previous_action = previous_action;
                    input.outcome         = outcome(s,c,t);
                    input.cf_outcome      = cf_outcome(s,c,t);
                    input.correct         = correct(s,c,t);
                    input.full_feedback   = full_feedback(s,c,t);
                    input.condition       = condition(s,c,t);
                    input.confidence      = confidence(s,c,t);
                    
                    % call fitting function for specific model (specified by fitfun)
                    % and retrieve outputs differently depending on whether timeseries are recorded or not
                    % if called from fmincon, only output nll and Q
                    [nll,Q,~,~,~] = fitfun(input);

                    % sanity checks
                    %{
                    assert(~isnan(nll),'\n Problem: nll is NaN')
                    assert(~(isnan(Q(1)) | isnan(Q(2))),'\n Problem: a Q value is NaN')
                    %}
        
                end
            end
        end
    end

elseif record_timeseries

    % initialise timeseries recording trial-level variables
    Q_record       = NaN(n_sess,n_cond,n_trial,2);
    pChosen_record = NaN(n_sess,n_cond,n_trial);
    pCorrect_record= NaN(n_sess,n_cond,n_trial);
    pSwitch_record = NaN(n_sess,n_cond,n_trial);

    % loop over sessions
    for s = 1:n_sess
        % loop over conditions
        for c = 1:n_cond
            % Initial Q variable
            Q = [0,0]; 
            % also set initial value of Q_record variable if recording timeseries
            Q_record(s,c,1,:) = [0,0]; 

            % loop over trials
            for t = 1:n_trial
                % check for NaN values, if NaN, move on to next trial - NaN values reflects either a missed trial OR that experiments of different sizes are combined in a matrix
                if isnan(action(s,c,t)) || isnan(confidence(s,c,t)) 
                    % warning('Modelling_fit_models_all.m : NaN confidence values in some trials, check that this if for the right reasons');
                    % if called from outside of fmincon, record NaN values for latent variables, since we are need one value per trial here             
                    pChosen_record(s,c,t)  = NaN;       
                    pCorrect_record(s,c,t) = NaN;
                    pSwitch_record(s,c,t)  = NaN;
                    if t < n_trial
                        Q_record(s,c,t+1,:) = Q; 
                    else
                        % do nothing, since Q values computed on trial t are those used to make decision on trial t+1, so no need to record Q at last trial
                    end
                    continue
                else 
                    % set input variables that change on each trial
                    if t==1
                        previous_action = action(s,c,t); 
                    else
                        previous_action = action(s,c,t-1);
                    end
                    input.nll_previous    = nll;
                    input.Q               = Q;
                    input.action          = action(s,c,t);
                    input.previous_action = previous_action;
                    input.outcome         = outcome(s,c,t);
                    input.cf_outcome      = cf_outcome(s,c,t);
                    input.correct         = correct(s,c,t);
                    input.full_feedback   = full_feedback(s,c,t);
                    input.condition       = condition(s,c,t);
                    input.confidence      = confidence(s,c,t);
                    
                    % call fitting function for specific model (specified by fitfun)
                    % if called from outside of fmincon, output all latent variables for timeseries
                    [nll,Q,pChosen,pCorrect,pSwitch] = fitfun(input);
                    pChosen_record(s,c,t)  = pChosen;
                    pCorrect_record(s,c,t) = pCorrect;
                    pSwitch_record(s,c,t)  = pSwitch;
                    % Q values computed on trial t are those used to make decision on trial t+1, so store in t+1 slice
                    % - we have manually set the initial Q values at t=1 set to 0,0
                    % - don't record Q at last trial since it won't fit in matrix of dimensions n_sess x n_cond x n_trial
                    if t < n_trial
                        Q_record(s,c,t+1,:) = Q;
                    end
                    
                    % sanity checks
                    %{
                    assert(~isnan(nll),'\n Problem: nll is NaN')
                    assert(~(isnan(Q(1)) | isnan(Q(2))),'\n Problem: a Q value is NaN')
                    %}
        
                end
            end
        end
    end

    % store timeseries data in one struct
    timeseries = struct('Q', [], 'pChosen', [], 'pCorrect', [], 'pSwitch', []);
    timeseries.Q       = Q_record;  
    timeseries.pChosen = pChosen_record;
    timeseries.pCorrect= pCorrect_record;
    timeseries.pSwitch = pSwitch_record;
    % there should be no NaN values in Q_record at this stage
    %{ 
    assert(sum(isnan(timeseries.Q), 'all') == 0, "There are NaN values in timeseries.Q after record_timeseries.")
    %}

end




end







