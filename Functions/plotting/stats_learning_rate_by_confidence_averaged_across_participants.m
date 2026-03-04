function [variables_for_plot] = stats_learning_rate_by_confidence_averaged_across_participants(params,model)

%{
Goal
    Put into a block the different steps involved in preparing data for plotting learning rate by confidence (averaged across all participants' traces 
Steps
    1. compute learning rate for each confidence value for each participant
    2. average individuals values/traces over all participants
    3. compute stats for plot

INPUTS 
- params variable from modelling_outputs variable, dimensions n_participants x n_parameters 
- model number 

OUTPUTS
structure (variables_for_plot{}) with the following variables
    - confidence_rescaled
    - mean_LR_confirmatory
    - mean_LR_disconfirmatory
    - CI_lower_confirmatory
    - CI_upper_confirmatory
    - CI_lower_disconfirmatory
    - CI_upper_disconfirmatory
%}

%% set useful variables
n_participants = numel(params(:,3)); 
confidence_rescaled = linspace(0.5,1,11); 

[models_info,extra_models_info] = load_models_info;


%% compute learning rate for each confidence value for each participant, then average individuals values/traces over all participants

% identify confirmatory and disconfirmatory parameters in different models
a_confirmatory     = params(:,extra_models_info.indices_a_CON_DIS(model,1));
b_confirmatory     = params(:,extra_models_info.indices_b_CON_DIS(model,1));
a_disconfirmatory  = params(:,extra_models_info.indices_a_CON_DIS(model,2));
b_disconfirmatory  = params(:,extra_models_info.indices_b_CON_DIS(model,2));

% initialise
LR_confirmatory    = NaN(n_participants,numel(confidence_rescaled));
LR_disconfirmatory = NaN(n_participants,numel(confidence_rescaled));
% compute learning rate for all possible values of confidence, given each participants' parameters in model XX
% each matrix is of size n_participants x n_confidence_values
for p = 1:n_participants
    for c = 1:length(confidence_rescaled) 
        LR_confirmatory(p,c)    = get_confidence_dependent_learning_rate(b_confirmatory(p),    confidence_rescaled(c), a_confirmatory(p)); 
        LR_disconfirmatory(p,c) = get_confidence_dependent_learning_rate(b_disconfirmatory(p), confidence_rescaled(c), a_disconfirmatory(p));
    end
end
% sanity checks
assert(all(size(LR_confirmatory)==[n_participants,numel(confidence_rescaled)]), "stats_learning_rate_by_confidence_averaged_across_participants(): Problem, LR_confirmatory should be of dimensions: n_participants x numel(confidence_rescaled)")
assert(all(size(LR_disconfirmatory)==[n_participants,numel(confidence_rescaled)]), "stats_learning_rate_by_confidence_averaged_across_participants(): Problem, LR_disconfirmatory should be of dimensions: n_participants x numel(confidence_rescaled)")


% add a variable with the bias_ratio between CON and DIS 
% careful, here i am rescaling each participant's confirmation bias by the amplitude of the learning rates
LR_bias_ratio = (LR_confirmatory-LR_disconfirmatory)./(LR_confirmatory+LR_disconfirmatory);


%% compute stats for plot

% averages over first dimension (participants), to get average LR for each value of the confidence
mean_LR_confirmatory    = mean(LR_confirmatory,1); 
mean_LR_disconfirmatory = mean(LR_disconfirmatory,1); 
mean_LR_bias_ratio      = mean(LR_bias_ratio,1); 

% get SEM then get confidence interval (CI) to plot - UNSURE HOW TO COMPUTE SEM HERE
% here, want to capture variability across subjects, NOT variability of the pop average across the confidence values
% so need to compute std for each value of y

% initialise
SEM       = NaN(2,numel(confidence_rescaled)); 
CI_lower  = NaN(2,numel(confidence_rescaled)); 
CI_upper  = NaN(2,numel(confidence_rescaled)); 

CI_boundary = 0.95;
CI_temp = tinv(1 - 0.5*(1-CI_boundary),n_participants);

LR(1,:,:) = LR_confirmatory;
LR(2,:,:) = LR_disconfirmatory;
LR(3,:,:) = LR_bias_ratio;

for k = 1:3 % once for confirmatory, once for disconfirmatory, once for the bias_ratio
    for c = 1:numel(confidence_rescaled)
        SEM(k,c)       = std(LR(k,:,c),'omitnan') / sqrt(n_participants); % get std of learning rates across participants for a given confidence value
        CI_upper(k,c)  = mean(LR(k,:,c),'omitnan') + SEM(k,c)*CI_temp;
        CI_lower(k,c)  = mean(LR(k,:,c),'omitnan') - SEM(k,c)*CI_temp;
    end
end
SEM_confirmatory         = SEM(1,:);
SEM_disconfirmatory      = SEM(2,:);
SEM_bias_ratio           = SEM(3,:);
CI_upper_confirmatory    = CI_upper(1,:);
CI_lower_confirmatory    = CI_lower(1,:);
CI_upper_disconfirmatory = CI_upper(2,:);
CI_lower_disconfirmatory = CI_lower(2,:);
CI_upper_bias_ratio      = CI_upper(3,:);
CI_lower_bias_ratio      = CI_lower(3,:);

%% save variables in a structure
variables_for_plot = {};
variables_for_plot.confidence_rescaled      = confidence_rescaled;
variables_for_plot.mean_LR_confirmatory     = mean_LR_confirmatory;
variables_for_plot.mean_LR_disconfirmatory  = mean_LR_disconfirmatory;
variables_for_plot.mean_LR_bias_ratio       = mean_LR_bias_ratio;
variables_for_plot.CI_lower_confirmatory    = CI_lower_confirmatory;
variables_for_plot.CI_upper_confirmatory    = CI_upper_confirmatory;
variables_for_plot.CI_lower_disconfirmatory = CI_lower_disconfirmatory;
variables_for_plot.CI_upper_disconfirmatory = CI_upper_disconfirmatory;
variables_for_plot.CI_lower_bias_ratio      = CI_lower_bias_ratio;
variables_for_plot.CI_upper_bias_ratio      = CI_upper_bias_ratio;

% sanity checks
fields = fieldnames(variables_for_plot);
for f = 1:numel(fields)
    assert( isequal(size(variables_for_plot.(fields{f})),size(confidence_rescaled)), "Problem, output variables should be of size 1 x n_possible_confidence_values")
end
