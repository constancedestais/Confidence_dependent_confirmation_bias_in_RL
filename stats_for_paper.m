%% Setup workspace/directories/paths 
% among other things, loads the folowing directories: output_dir, data_dir, figures_dir
load_working_environment; 

[models_info,models_info_extra] = load_models_info();

%% Choose data versions

% Datasets (task versions) to loop over 
version_names = ["MLNSG_0reversals_all", ...
                 "MLNSG_1reversal_all", ...
                 "CDAG_all", ...
                 "MLNSG_0reversals_partialfeedbacktrials", ...
                 "MLNSG_0reversals_completefeedbacktrials", ...
                 "MLNSG_1reversal_partialfeedback", ... 
                 "MLNSG_1reversal_completefeedback", ...
                 "CDAG_partialfeedback", ...
                 "CDAG_completefeedback"
                 ];

% Models to loop over
%   - model 1: no confidence-dependent learning rates, no confidence modulation of choice (fixed learning rates for confirmatory and disconfirmatory evidence)
%   - model 2: confidence-dependent learning rates, no confidence modulation of choice
%   - model 4: confidence-dependent learning rates, AND confidence modulation of choice
models = [2,4];

% combine data from each version into a cell array
n_versions = numel(version_names);

% load behaviour from all versions of interest - because in order to look at the effect of versions on behaviour, the script itself loops over versions
for v = 1:n_versions
    version_names{v}
    % load data 
    dataset_type = "table"; 
    behaviour_array_by_version{v} = load_behaviour_datasets(version_names{v},  dataset_type, data_dir); 
    dataset_type = "matrix"; 
    behaviour_matrix_by_version{v} = load_behaviour_datasets(version_names{v},  dataset_type, data_dir); 
end

%% prepare data  
[my_table,my_vectors] = group_data_by_valence_and_volatility(behaviour_array_by_version, version_names);

%% loop over versions and compute stats for each version
for v = 1:n_versions
    fprintf("\n \n================== version: %s =================== \n",version_names{v})

    %% compare p_correct options to chance 
    data = my_vectors.mean_correct{v};
    [h,p,ci,stats] = ttest(data,0.5);
    p = text_p_value(p);
    fprintf("\nPcorrect different from 0.5 (ttest): t(%i)=%.2f, %s\n",stats.df,round(stats.tstat,2),p);
    clear data h p ci stats

    %% compare confidence ratings on correct trials vs. incorrect trials
    
    data = groupsummary(behaviour_array_by_version{v}, {'participant_ID','chose_highest'}, @(x) mean(x,'omitnan'), 'confidence_rating');
    % Clean column name
    data.Properties.VariableNames{'fun1_confidence_rating'} = 'mean_confidence_rating';
    data.GroupCount = [];
    % Make unstack column names valid and meaningful
    data.chose_highest = categorical(data.chose_highest, [0 1], {'incorrect','correct'});    
    data = unstack(data, 'mean_confidence_rating', 'chose_highest');    
    % Rename (optional, but nice)
    data = renamevars(data, ["incorrect","correct"], ["conf_incorrect","conf_correct"]);

    % paired t-test
    [h,p,ci,stats] = ttest(data.conf_correct-data.conf_incorrect,0,'Tail','right');
    p = text_p_value(p);
    fprintf("\nConfidence HIGHER in correct than incorrect trials (paired-ttest): t(%i)=%.2f, %s\n",stats.df,round(stats.tstat,2),p);
    clear data h p ci stats

    %% difference between bCON and bDIS parameters

    % load behaviour to get list of participants in order
    data = behaviour_matrix_by_version{v};    
    % create list of p articipants in the order in which they appear in behavioural dataset
    ordered_participant_list = unique(data.participant_ID,"stable");
    ordered_participant_list = ordered_participant_list(ordered_participant_list ~= "");
    ordered_participant_list = ordered_participant_list(~ismissing(ordered_participant_list));
    % load modelling outputs
    outcome_encoding = "actual";
    modelling_outputs  = load_modelling_outputs(version_names(v), outcome_encoding, output_dir, ordered_participant_list);

    for m = 1:numel(models)
        fprintf("\n\n-------- model: %i -------- \n",models(m))
        model = models(m);

        if model == 2 || model == 4

            bCON_index = models_info_extra.indices_b_CON_DIS(model,1);
            bDIS_index = models_info_extra.indices_b_CON_DIS(model,2);
            aCON_index = models_info_extra.indices_a_CON_DIS(model,1);
            aDIS_index = models_info_extra.indices_a_CON_DIS(model,2);
            
            [h,p,ci,stats] = ttest(modelling_outputs.parameters{model}(:,bCON_index),0);
            p = text_p_value(p);
            my_mean = mean(modelling_outputs.parameters{model}(:,bCON_index));
            fprintf("\nbCON in model %i is different from zero (ttest): mean=%.2f, t(%i)=%.2f, %s\n",model,my_mean,stats.df,round(stats.tstat,2),p);
            clear h p ci stats my_mean
            
            [h,p,ci,stats] = ttest(modelling_outputs.parameters{model}(:,bDIS_index),0);
            p = text_p_value(p);
            my_mean = mean(modelling_outputs.parameters{model}(:,bDIS_index));
            fprintf("\nbDIS in model %i is different from zero (ttest): mean=%.2f, t(%i)=%.2f, %s\n",model,my_mean,stats.df,round(stats.tstat,2),p);
            clear h p ci stats my_mean

            [h,p,ci,stats] = ttest(modelling_outputs.parameters{model}(:,bCON_index)-modelling_outputs.parameters{model}(:,bDIS_index),0);
            p = text_p_value(p);
            my_mean = mean(modelling_outputs.parameters{model}(:,bCON_index)-modelling_outputs.parameters{model}(:,bDIS_index));
            fprintf("\nbCON is different from bDIS in model %i (paired-ttest): mean=%.2f, t(%i)=%.2f, %s\n",model,my_mean,stats.df,round(stats.tstat,2),p);
            clear h p ci stats my_mean
            
            [h,p,ci,stats] = ttest(modelling_outputs.parameters{model}(:,aCON_index)-modelling_outputs.parameters{model}(:,aDIS_index),0);
            my_mean = mean(modelling_outputs.parameters{model}(:,aCON_index)-modelling_outputs.parameters{model}(:,aDIS_index));
            p = text_p_value(p);
            fprintf("\naCON is different from aDIS in model %i (paired-ttest):  mean=%.2f, t(%i)=%.2f, %s\n",model,my_mean,stats.df,round(stats.tstat,2),p);
            clear h p ci stats 
            
            clear bCON_index bDIS_index

            fprintf("\n");

        end
    end
    clear d modelling_outputs ordered_participant_list
end

