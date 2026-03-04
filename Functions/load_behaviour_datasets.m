function new_data = load_behaviour_datasets(requested_output_dataset_name, requested_type, data_dir) 

%{
function new_data = filter_behaviour_datasets(data, sorting_variable, dataset_name) 
this function allows to only select one version of the task - as defined by the variable "exp_ID" in the data (e.g. pilot called RL0_v8)

INPUTS
 1. requested_output_dataset_name: should be a string that matches entry of sorting variable (exp_id/task_versions) that you want to keep e.g."RL0_v8", OR "all" to mean no filter
        Names you can request can be found in the list of "requested_output_dataset_name" in the read_behaviour_dataset_dictionary.m function
 2. requested_type: accepts data in a "table", in a structure ("matrix") of matrices of dimensions: n_participants x n_conditions x n_trials

OUTPUTS
matrix or table (depending on the requested type) with the participants (and sometimes specific conditions) corresponding to the requested dataset 
%}

%% code section that adapts to the different datasets
% find smallest dataset units (aka initial_dataset_names) that must be combined to get the requested_output_dataset_name
initial_dataset_names = read_behaviour_dataset_dictionary(requested_output_dataset_name);

% set variables specific to each requested dataset
if contains(requested_output_dataset_name, "RL3")
    all_versions_name     = "RL3_all"; % will be compared to requested_output_dataset_name to check if the latter includes ALL or a SUBSET of participants in this dataset
    matrix_file_name      = "data_RL3_LearningTask_matrix.mat";
    table_file_name       = "data_RL3_LearningTask_table.csv";

elseif contains(requested_output_dataset_name, "RL1")
    all_versions_name     = "RL1_all"; % will be compared to requested_output_dataset_name to check if the latter includes ALL or a SUBSET of participants in this dataset
    matrix_file_name      = "data_RL1_matrix.mat";
    table_file_name       = "data_RL1_table.csv";

elseif contains(requested_output_dataset_name, "RL0") 
    all_versions_name     = "RL0_all"; % will be compared to requested_output_dataset_name to check if the latter includes ALL or a SUBSET of participants in this dataset
    matrix_file_name      = "data_RL0_matrix.mat";
    table_file_name       = "data_RL0_table.csv";

else 
    warning('The requested_output_dataset_name you have requested are not coded in the filter_parameter_datasets.m function')
    return
end


%% code that works for all datasets

% ------ if requested data type = table ------ %

if (requested_type == "table")

    % load the data file
    full_file_path  = fullfile(data_dir,table_file_name);
    % options to read table
    opts = detectImportOptions(full_file_path); % options to read table
    opts = setvartype(opts, {'exp_ID' 'participant_ID' 'condition_name' }, {'string' 'string' 'string' }); % by default readtable converts strings to cells so specify not to
    opts.VariableNames;  % specify to use variable names found in first row
    data = readtable(full_file_path, opts);    

    if requested_output_dataset_name == all_versions_name % if don't need to retrieve a specific version, return full dataset

        new_data = data;

        % print the number of participants
        unique_participants = unique(new_data.participant_ID);
        unique_participants = unique_participants(~ismissing(unique_participants) & unique_participants~="");
        n_participants_here = numel(unique_participants);
        fprintf('\n Loaded data contains %i participants \n',n_participants_here)

        return

    else % otherwise create specific subset of dataset  

        % filter version using logical indexing (this works even for multiple dataset names in the initial_dataset_names)
        logical_mask = ismember(data.exp_ID, initial_dataset_names);
        new_data     = data(logical_mask,:);

    end

% ------ if requested data type = structure of matrices ------ %

elseif (requested_type == "matrix")

    % load the data file
    file        = fullfile(data_dir,matrix_file_name);
    temp_struct = load(file);
    % rename contents to "data"
    temp_name = fieldnames(temp_struct);
    data = temp_struct.(temp_name{1});

    if requested_output_dataset_name == all_versions_name % if don't need to retrieve a specific version, return full dataset
        
        new_data = data;

        % print number of participants
        unique_participants = unique(new_data.participant_ID);
        unique_participants = unique_participants(~ismissing(unique_participants) & unique_participants~="");
        n_participants_here = numel(unique_participants);
        fprintf('\n Loaded data contains %i participants \n',n_participants_here)

        return        

    else % otherwise create specific subset of dataset  

        % get subset of each matrix inside the structure 
        fields = fieldnames(data);
        for i = 1:length(fields)
            field_name = fields{i};
            current_variable = data.(field_name);
            % check that matrix has correct size
            if ( size(size(current_variable))~=4  )    
                warning("\nWarning from filter_version.m: this script only accepts data in a table, in a structure of matrices or a matrix of dimensions: n_participants x n_conditions x n_trials\n")
                return
            end
            % find rows corresponding to participants in filtered task version
            logical_mask       = ismember(data.exp_ID, initial_dataset_names);
            logical_mask       = logical_mask(:,1,1,1); % get one value per participant/row
            participant_index  = find(logical_mask);  % get indices of the rows/participants to be kept
            % only keep rows corresponding to participants in filtered task version
            new_data.(field_name)   =  current_variable(participant_index,:,:,:);
        end

    end  
end

%% deal with partialfeedbacktrials and completefeedbacktrials in RL0, which require subsetting trials within each participant  
% specifically, these versions require filtering out trials with partial/complete feedback within each participant in RL0

if contains(requested_output_dataset_name, "completefeedbacktrials") || contains(requested_output_dataset_name, "partialfeedbacktrials") 
    % set filtering variables according to requested type of feedback
    if contains(requested_output_dataset_name, "partialfeedbacktrials") 
        % condition_names = ["partial_info_gain" ; "full_info_gain" ; "partial_info_loss" ; "full_info_loss"];
        conditions_to_keep = [1,3];
        conditions_to_remove = [2,4];
    elseif contains(requested_output_dataset_name, "completefeedbacktrials")
        % condition_names = ["partial_info_gain" ; "full_info_gain" ; "partial_info_loss" ; "full_info_loss"];
        conditions_to_keep = [2,4];
        conditions_to_remove = [1,3];
    end
    % filter the relevant data - do so differently 
    if (requested_type == "table")
        % create logical mask
        logical_mask  = ismember(new_data.condition,conditions_to_keep);
        % sanity check
        assert( sum(new_data.full_feedback == 0,"all") == sum(ismember(new_data.condition,conditions_to_keep),"all") );
        % filter using logical indexing
        new_data = data(logical_mask,:);
    elseif (requested_type == "matrix")
        % loop over variables in matrix
        all_fields = string( fieldnames(new_data) );
        fields_to_keep = ["exp_ID","participant_ID","session","block","condition","trial_by_condition","full_feedback","valence","condition_name","interleaved_valence","interleaved_volatility" ];
        fields_to_filter =  setdiff(all_fields,fields_to_keep);
        % fill non-filtered variables with NaNs to preserve condition indexing
        for i = 1:length(fields_to_filter)
            field_name = fields_to_filter{i};
            new_data.(field_name)(:,:,conditions_to_remove,:) = NaN;           
        end
    end
end

% print the number of participants
unique_participants = unique(new_data.participant_ID);
unique_participants = unique_participants(~ismissing(unique_participants) & unique_participants~="");
n_participants_here = numel(unique_participants);
fprintf('\n Loaded data contains %i participants \n',n_participants_here)
a=1;

end
