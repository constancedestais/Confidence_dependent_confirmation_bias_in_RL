function [d] = impute_missing_confidence_and_choice(d)

    [n_subjects, n_sessions, n_conditions, n_trials_by_cond] = size(d.confidence_rating);
    % relies on the fact that there are no missing values in symbol_1_actual_payoff and symbol_2_actual_payoff
    assert( sum( isnan(d.symbol_1_actual_payoff), "all") == 0, "There are NaN values in symbol_1_actual_payoff - cannot proceed with imputation." )
    assert( sum( isnan(d.symbol_2_actual_payoff), "all") == 0, "There are NaN values in symbol_2_actual_payoff - cannot proceed with imputation." )
    
    for i = 1:n_subjects
        for j = 1:n_sessions
            for k = 1:n_conditions

                %% impute confidence to avoid dealing with missing values
                if any(isnan(d.confidence_rating(i,j,k,:))) && ~all(isnan(d.confidence_rating(i,j,k,:)))
                    d.confidence_rating(i,j,k,:) = impute_nan_with_surrounding_mean(d.confidence_rating(i,j,k,:));
                elseif all(isnan(d.confidence_rating(i,j,k,:)))
                    warning("A participant did not report any confidence ratings for a whole block - current code cannot handle this")
                end
                
                %% impute choice and choice-related variables to avoid dealing with missing values
                if any(isnan(d.chose_highest(i,j,k,:))) || any(isnan(d.symbol_chosen_actual_payoff(i,j,k,:))) && any(isnan(d.symbol_unchosen_actual_payoff(i,j,k,:)))
                    
                    %% repeat choice on previous trial, except if NaN is first in array
                    
                    x = squeeze(d.chose_highest(i,j,k,:));   
                    x = fillmissing(x,'previous');                        % forward-fill
                    x = fillmissing(x,'next');                            % fix NaN if in first position
                    d.chose_highest(i,j,k,:) = reshape(x,1,1,1,[]);

                    x = squeeze(d.symbol_chosen_id_relative(i,j,k,:));
                    x = fillmissing(x,'previous');                        % forward-fill
                    x = fillmissing(x,'next');                            % fix NaN if in first position
                    d.symbol_chosen_id_relative(i,j,k,:) = reshape(x,1,1,1,[]);

                    x = squeeze(d.symbol_unchosen_id_relative(i,j,k,:));
                    x = fillmissing(x,'previous');                        % forward-fill
                    x = fillmissing(x,'next');                            % fix NaN if in first position
                    d.symbol_unchosen_id_relative(i,j,k,:) = reshape(x,1,1,1,[]);

                    x = squeeze(d.switched_choice(i,j,k,:));
                    x = fillmissing(x,'previous');                        % forward-fill
                    x = fillmissing(x,'next');                            % fix NaN if in first position
                    d.switched_choice(i,j,k,:) = reshape(x,1,1,1,[]);

                    x = squeeze(d.rt_choice(i,j,k,:));
                    x = fillmissing(x,'previous');                        % forward-fill
                    x = fillmissing(x,'next');                            % fix NaN if in first position
                    d.rt_choice(i,j,k,:) = reshape(x,1,1,1,[]);

                    x = squeeze(d.chose_symbol_1(i,j,k,:));
                    x = fillmissing(x,'previous');                        % forward-fill
                    x = fillmissing(x,'next');                            % fix NaN if in first position
                    d.chose_symbol_1(i,j,k,:) = reshape(x,1,1,1,[]);

                    % IMPORTANT: variables I am not bothering to change for the moment: 
                    % symbol_chosen_actual_payoff_relative, symbol_unchosen_actual_payoff_relative

                    %% fill in NaN values in symbol_chosen_actual_payoff/symbol_unchosen_actual_payoff
                    % rely on symbol_1_actual_payoff and symbol_2_actual_payoff which do not contain NaNs

                    % Pull trial vectors (as columns)
                    symbol_chosen_actual_payoff     = squeeze(d.symbol_chosen_actual_payoff(i,j,k,:));
                    symbol_unchosen_actual_payoff   = squeeze(d.symbol_unchosen_actual_payoff(i,j,k,:));
                    symbol_chosen_id_relative    = squeeze(d.symbol_chosen_id_relative(i,j,k,:));   % 1 or 2
                    symbol_unchosen_id_relative  = squeeze(d.symbol_unchosen_id_relative(i,j,k,:));  % 1 or 2
                    symbol_1_actual_payoff  = squeeze(d.symbol_1_actual_payoff(i,j,k,:));
                    symbol_2_actual_payoff  = squeeze(d.symbol_2_actual_payoff(i,j,k,:));
                    
                    nanMask = isnan(symbol_chosen_actual_payoff);
                    % Replace NaNs depending on chosen id
                    symbol_chosen_actual_payoff(nanMask & symbol_chosen_id_relative==1) = symbol_1_actual_payoff(nanMask & symbol_chosen_id_relative==1);
                    symbol_chosen_actual_payoff(nanMask & symbol_chosen_id_relative==2) = symbol_2_actual_payoff(nanMask & symbol_chosen_id_relative==2);
                    % Write back
                    d.symbol_chosen_actual_payoff(i,j,k,:) = reshape(symbol_chosen_actual_payoff,1,1,1,[]);
                    
                    nanMask = isnan(symbol_unchosen_actual_payoff);
                    % Replace NaNs depending on unchosen id
                    symbol_unchosen_actual_payoff(nanMask & symbol_unchosen_id_relative==1) = symbol_1_actual_payoff(nanMask & symbol_unchosen_id_relative==1);
                    symbol_unchosen_actual_payoff(nanMask & symbol_unchosen_id_relative==2) = symbol_2_actual_payoff(nanMask & symbol_unchosen_id_relative==2);
                    % Write back
                    d.symbol_unchosen_actual_payoff(i,j,k,:) = reshape(symbol_unchosen_actual_payoff,1,1,1,[]);

                    %% same for relative values
                    % Pull trial vectors (as columns)
                    symbol_chosen_actual_payoff_relative     = squeeze(d.symbol_chosen_actual_payoff_relative(i,j,k,:));
                    symbol_unchosen_actual_payoff_relative   = squeeze(d.symbol_unchosen_actual_payoff_relative(i,j,k,:));
                    symbol_chosen_id_relative    = squeeze(d.symbol_chosen_id_relative(i,j,k,:));   % 1 or 2
                    symbol_unchosen_id_relative  = squeeze(d.symbol_unchosen_id_relative(i,j,k,:));  % 1 or 2
                    symbol_1_actual_payoff  = squeeze(d.symbol_1_actual_payoff(i,j,k,:));
                    symbol_2_actual_payoff  = squeeze(d.symbol_2_actual_payoff(i,j,k,:));
                    
                    nanMask = isnan(symbol_chosen_actual_payoff_relative);
                    % Replace NaNs depending on chosen id
                    symbol_chosen_actual_payoff_relative(nanMask & symbol_chosen_id_relative==1) = symbol_1_actual_payoff(nanMask & symbol_chosen_id_relative==1);
                    symbol_chosen_actual_payoff_relative(nanMask & symbol_chosen_id_relative==2) = symbol_2_actual_payoff(nanMask & symbol_chosen_id_relative==2);
                    % Write back
                    d.symbol_chosen_actual_payoff_relative(i,j,k,:) = reshape(symbol_chosen_actual_payoff_relative,1,1,1,[]);
                    
                    nanMask = isnan(symbol_unchosen_actual_payoff_relative);
                    % Replace NaNs depending on unchosen id
                    symbol_unchosen_actual_payoff_relative(nanMask & symbol_unchosen_id_relative==1) = symbol_1_actual_payoff(nanMask & symbol_unchosen_id_relative==1);
                    symbol_unchosen_actual_payoff_relative(nanMask & symbol_unchosen_id_relative==2) = symbol_2_actual_payoff(nanMask & symbol_unchosen_id_relative==2);
                    % Write back
                    d.symbol_unchosen_actual_payoff_relative(i,j,k,:) = reshape(symbol_unchosen_actual_payoff_relative,1,1,1,[]);

                end

            end
        end
    end
    clear i j k

    % sanity check
    assert(sum( isnan(d.confidence_rating ), "all") == 0, "There are still NaN confidence values in data.")
    assert(sum( isnan(d.chose_highest ), "all") == 0, "There are still NaN chose_highest values in data.")
    assert(sum( isnan(d.symbol_chosen_id_relative ), "all") == 0, "There are still NaN symbol_chosen_id_relative values in data.")
    assert(sum( isnan(d.symbol_unchosen_id_relative ), "all") == 0, "There are still NaN symbol_unchosen_id_relative values in data.")
    assert(sum( isnan(d.symbol_chosen_actual_payoff ), "all") == 0, "There are still NaN symbol_chosen_actual_payoff values in data.")
    assert(sum( isnan(d.symbol_unchosen_actual_payoff ), "all") == 0, "There are still NaN symbol_unchosen_actual_payoff values in data.")
    assert(sum( isnan(d.symbol_chosen_actual_payoff_relative ), "all") == 0, "There are still NaN symbol_chosen_actual_payoff values in data.")
    assert(sum( isnan(d.symbol_unchosen_actual_payoff_relative ), "all") == 0, "There are still NaN symbol_unchosen_actual_payoff values in data.")

end