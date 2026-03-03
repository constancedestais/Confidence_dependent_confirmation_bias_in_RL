%% Runner script to fit parameters to models and compute model evidence
% Fit different models to each participant (like adding fixed effects for participants in a regression)
% Model parameters are estimated by maximising the log posterior probability (via functions including fmincon, Model_Priors.m, Model_Param.m)
% Using these estimated parameters, we obtain variables useful for computing model evidence (nLL, BIC, nLPP, LAME) for each participant (via function Model_Timeseries.m)

% Details about data that is needed to perform model fitting 
%{
INPUT
  Dataset contains one matrix per variable, each matrix is of size: n_subjects x n_conditions x n_trials
  Variables that are needed are: 
    - condition: 1=stable_gain; 2=volatile_gain ; 3=stable_loss; 4=volatile_loss 
    - chosen: which stimulus was chosen on each trial (option 1 or 2))
    - confidence: re-scaled (0.5 to 1)
    - correct: whether or not the choice was correct on each trial (1 or 0)
    - outcome: outcome (sometimes transformed into relative outcome)
    - cf_outcome: unchosen/counterfactual outcome (sometimes transformed into relative outcome)
    - full_feedback: 0 (partial feedback) or 1 (full_feedback)

OUTPUT 
    - LAME: matrix (k_subj x n_fitting_models)
    - gradient_nLPP: cell array (k_subj x n_fitting_models)
    - hessian_nLPP: cell array (k_subj x n_fitting_models)
    - nLPP: (k_subj x n_fitting_models)
    - nLL: (k_subj x n_fitting_models)
    - BIC: (k_subj x n_fitting_models)
    - parameters: cell array {n_fitting_models} with matrices (n_subj x n_params)
    - Q: cell array {n_fitting_models} with matrices (n_subj x n_conditions x n_trials_max+1?? x 2 for the two presented options)
    - PChosen: cell array {n_fitting_models} with matrices (n_subj x  n_conditions x n_trials)
    - PCorrect: cell array {n_fitting_models} with matrices (n_subj x  n_conditions x n_trials)
    - PSwitch: cell array {n_fitting_models} with matrices (n_subj x  n_conditions x n_trials)
%}

%% Setup workspace/directories/paths 

% load_working_environment; 
clear 
close all
clc
format longg

dbstop if error 

fprintf(' -------- have started running script simulation_ENS_server.m --------\n')

% set whether this is running on DEC server or not
run_on_DEC_server = 1;

% set reference directory
if (run_on_DEC_server == 1)
    filePath = mfilename('fullpath') % mfilename('fullpath') ; % matlab.desktop.editor.getActiveFilename;
else
    filePath = matlab.desktop.editor.getActiveFilename;
end
cwd = fileparts(filePath);
    fprintf('cwd = %s\n',cwd);
cd(cwd);
data_dir         = fullfile(cwd,'Data');
output_dir       = fullfile(cwd,'Outputs');  
figures_dir      = fullfile(output_dir,'Figures');  

% set path
restoredefaultpath
addpath(genpath('Functions'), genpath('Data'), genpath('Outputs'))  % add folder and contained folders
addpath(genpath('../MBB-team_VBA-toolbox')); % add folder and contained folders

% set directories for saving outputs and figures
if (run_on_DEC_server == 1)
    % create figure output directory with current date and time
    currentDateTime = datestr(now, 'yyyy_mm_dd__HH_MM_SS'); % Format: Year-Month-Day_Hour-Minute-Second
    DEC_server_outputs_dir = fullfile(output_dir,sprintf('server_outputs_%s',currentDateTime));  
    % Create the folder in the current working directory
    mkdir(DEC_server_outputs_dir);
    % Display confirmation
    disp(['Folder "' DEC_server_outputs_dir '" created in the current directory.']);
    % add new folder to path
    addpath(genpath('Functions'), genpath('Data'), genpath('Outputs'));  % add folder and contained folders

    % replace both directories used for export by this dated directory
    output_export_dir  = DEC_server_outputs_dir;
    figures_export_dir = DEC_server_outputs_dir;
else 
   output_export_dir  = output_dir ;
   figures_export_dir = figures_dir ;
end

%% reproducibility: seed
% check that there are no calls to rng/seed 
%{
dbclear all
dbstop in rng
%}
% IF SCRIPT DOES STOP, run "dbstack -completenames" in the command line to get history of function calls, then check the n-1 function/script to see where the seed is being set

% set seed myself -> save seed in output
seed = 1; %randi(100000);
rng(seed)

%% Choose data versions/models/outcome encoding and more

% available datasets, in smallest subdivisions, you can recombine them later
version_names_CD2   = ["CD2_v8","CD2_v9","CD2_v10","CD2_v11", "CD2_v12","CD2_v13","CD2_v14","CD2_v15"];
version_names_CDAG  = ["CDAG_vA", "CDAG_vB", "CDAG_vC", "CDAG_vD"];
version_names_MLNSG_1reversal  = ["MLNSG_1reversal_exp1", "MLNSG_1reversal_exp2", "MLNSG_1reversal_exp3"]; 
version_names_MLNSG_0reversals = ["MLNSG_0reversals_exp1","MLNSG_0reversals_exp2","MLNSG_0reversals_exp3","MLNSG_0reversals_exp4","MLNSG_0reversals_exp5","MLNSG_0reversals_exp6","MLNSG_0reversals_exp7"]; 
version_names_MLNSG_0reversals_partialfeedbacktrials = ["MLNSG_0reversals_exp1_partialfeedbacktrials","MLNSG_0reversals_exp2_partialfeedbacktrials","MLNSG_0reversals_exp3_partialfeedbacktrials","MLNSG_0reversals_exp4_partialfeedbacktrials","MLNSG_0reversals_exp5_partialfeedbacktrials","MLNSG_0reversals_exp6_partialfeedbacktrials","MLNSG_0reversals_exp7_partialfeedbacktrials"]; 
version_names_MLNSG_0reversals_completefeedbacktrials = ["MLNSG_0reversals_exp1_completefeedbacktrials","MLNSG_0reversals_exp2_completefeedbacktrials","MLNSG_0reversals_exp3_completefeedbacktrials","MLNSG_0reversals_exp4_completefeedbacktrials","MLNSG_0reversals_exp5_completefeedbacktrials","MLNSG_0reversals_exp6_completefeedbacktrials","MLNSG_0reversals_exp7_completefeedbacktrials"]; 

% Set datasets (task versions) to use 
version_names = [version_names_MLNSG_0reversals, ...
                version_names_MLNSG_1reversal, ...
                version_names_CDAG, ...
                version_names_MLNSG_0reversals_partialfeedbacktrials, ...
                version_names_MLNSG_0reversals_completefeedbacktrials ];
%{
[version_names_MLNSG_0reversals, ...
                version_names_MLNSG_1reversal, ...
                version_names_CDAG, ...
                version_names_MLNSG_0reversals_partialfeedbacktrials, ...
                version_names_MLNSG_0reversals_completefeedbacktrials ];

%}

% Models that I want to fit - exclude models that depend on volatility conditions for tasks with no volatility manipulation
    % available_models = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];  
models = [1,2,4]; %[1,2,4]; 

% Use "relative" vs "semirelative" vs "actual" outcomes ; relative: -1 vs 1 for best and worst outcomes in a trial; semi-relative: rescale two outcomes compared to their mean; 
outcome_encoding = "actual";

% Set options for fmincon function
 % "MaxIter" increases the number of iterations to ensure the convergence
% options = optimset('Algorithm', 'interior-point', 'Display', 'iter-detailed', 'MaxIter', 10000);
fmincon_options = optimset('Algorithm', 'interior-point', 'Display', 'off', 'MaxIter', 10000);

% Repeat parameter estimation several times in case fmincon gets stuck in local minimum
n_repetition_of_parameter_estimation   = 3;

%% Set useful variables 

% Load information about model parameters and priors
models_info = load_models_info_constance(); 

%% fit models for each dataset/pilot version
for v = 1:numel(version_names)

    % load behavioural data
    dataset_type = "matrix"; %  need matrices for model fitting functions
    d = load_behaviour_datasets(version_names{v},  dataset_type, data_dir); 

    % select necessary variables 
    data.participant_ID        =  d.participant_ID;
    data.exp_ID                =  d.exp_ID; 
    data.condition             =  d.condition;
    data.chosen                =  d.symbol_chosen_id_relative;
    data.confidence            =  d.confidence_rating;
    data.correct               =  d.chose_highest;
    data.full_feedback         =  d.full_feedback;
    switch outcome_encoding
        case "relative"
            data.outcome       =  d.symbol_chosen_actual_payoff_relative;
            data.cf_outcome    =  d.symbol_unchosen_actual_payoff_relative; 
        case "semirelative"
            data.outcome       =  d.symbol_chosen_actual_payoff_semirelative;
            data.cf_outcome    =  d.symbol_unchosen_actual_payoff_semirelative;
        case "actual"
            data.outcome       =  d.symbol_chosen_actual_payoff;
            data.cf_outcome    =  d.symbol_unchosen_actual_payoff; 
    end 

    % call function which handles model fitting
    use_parallel = 1; % !! needs to be accompanied by change to loop call (parfor vs normal for loop) in fit_several_models.m
    modelling_outputs = fit_several_models(data, models, fmincon_options, n_repetition_of_parameter_estimation, use_parallel, models_info, version_names(v) );

    %% deal with MLNSG_0reversals with partial/complete feedback trials
    %{
    % set which conditions should be empty 
    conditions_to_remove = [];
    if contains(version_names(v), "partialfeedbacktrials")
        % condition_names = ["partial_info_gain" ; "full_info_gain" ; "partial_info_loss" ; "full_info_loss"];
        conditions_to_remove = [2,4];
    elseif contains(version_names(v), "completefeedbacktrials")
        % condition_names = ["partial_info_gain" ; "full_info_gain" ; "partial_info_loss" ; "full_info_loss"];
        conditions_to_remove = [1,3];
    end
    % SANITY CHECKS to deal with MLNSG_0reversals with partial/complete feedback trials only : check that values in absent conditions are NaNs
    if contains(version_names(v), "partialfeedbacktrials") || contains(version_names(v), "completefeedbacktrials")
        % check in variables that all values in "absent" conditions are filled with NaNs
        assert(sum(isnan(correct(   :,:,conditions_to_remove,:)),"all") == numel(correct(   :,:,conditions_to_remove,:)), "Problem, in sub-task with partial/complete feedback, values in conditions with opposite type of feedback should be NaNs")
        assert(sum(isnan(confidence(:,:,conditions_to_remove,:)),"all") == numel(confidence(:,:,conditions_to_remove,:)), "Problem, in sub-task with partial/complete feedback, values in conditions with opposite type of feedback should be NaNs")
        assert(sum(isnan(chosen(    :,:,conditions_to_remove,:)),"all") == numel(chosen(    :,:,conditions_to_remove,:)), "Problem, in sub-task with partial/complete feedback, values in conditions with opposite type of feedback should be NaNs")
    end
    %}
 
    %% save
    
    %{
    % FOR DEBUGGING: PLOT MODEL FIT VARIABLES AROUND REVERSAL
    % call function that plots variables around reversals (including model fits)
    data.fitted_pCorrect = PCorrect{14};
    data.fitted_pSwitch = PSwitch{14};

    plot_modelfit_around_reversal(     data, 2,   14, outcome_encoding, version_names(v), fullfile(output_dir,'Figures'));      
    TEMP_plot_modelfit_around_reversal(data, 2,   14 , outcome_encoding,   version_names(v), fullfile(output_dir,'Figures'));

    % plot variables around the reversal
    plot_behaviour_around_reversal(data, 2, "simulated", fullfile(output_dir,'Figures'))
  
    % plot variables across all trials in a block
    plot_behaviour_over_block(data, "simulated", fullfile(output_dir,'Figures'))
    %}
   
    % save seed for reproducibility
    modelling_outputs.seed = seed;

    % create output file
    name = sprintf('modelling_outputs_%s_outcomes_%s.mat',outcome_encoding,version_names{v});
    svnm = fullfile(output_export_dir,name);
    save(svnm,'modelling_outputs');    % for each: n_subjects x n_conditions x n_trials_max 
    fprintf('modelling_outputs for participant data in file: %s \n',svnm)
    
end
