%% [AVERAGE OVER REPETITIONS] plot recovered bCON and bDIS of models 2 and 4, when generative model is 1 (so no true b parameters)

function [] = plot_recovered_bCON_bDIS_for_generativemodel1(generative_model,...
                                        fitting_models,...
                                        generated_parameters_combined_repetitions,...
                                        recovered_parameters_combined_repetitions,...
                                        simulated_data_by_repetition,...
                                        modelling_outcomes_by_repetition,...
                                        models_info,...
                                        figures_export_dir,...
                                        reward_structure_dataset_name, ...
                                        simulated_data, ...
                                        colors, ...
                                        empirical_parameters)
%% sanity check
assert( ~isempty( simulated_data ) , 'plot_parameter_recovery(): simulated_data input is empty')
assert( ~isempty( generated_parameters_combined_repetitions ) , 'plot_parameter_recovery(): generated_parameters_combined_repetitions input is empty')
assert( ~isempty( recovered_parameters_combined_repetitions ) , 'plot_parameter_recovery(): recovered_parameters_combined_repetitions input is empty')

color_dict = load_my_colors();

[models_info, models_info_extra] = load_models_info_constance();

% set figure settings 

font_size = 11;
star_font_size = 15;
my_linewidth = 1; %0.65;
position_units = "centimeters";
figure_background_color = 'none';
x_ref_input = NaN;
dot_size = 6;
sem_bar_width = 8;
highlight_connected_lines_in_dominant_direction = 0;
x_label = ''; 
font = "Arial";
font_size = 11;
star_font_size = 15;
%figure_position = [0, 0, 6, 6]; 
%axis_inner_position = [1.3, 1.3, 3, 4]; % order: left, bottom, width, height
axis_inner_position = [1.3, 1.3, 4, 6]; 

desired_models = [2,4];
% if generative model is 1
if generative_model == 1

    for fitting_model_idx = 1:numel(desired_models)
        
        fitting_model = desired_models(fitting_model_idx);

        % check if have a combination with the same fitting and generative model
        if ismember(fitting_model, fitting_models)

            % loop over repetitions - get mean across repetitions
            n_repetitions_of_generation = numel(modelling_outcomes_by_repetition);
            % initialise
            n_parameters = size(modelling_outcomes_by_repetition{1}{generative_model}.parameters{fitting_model},2);
            mean_recovered_parameters = NaN(n_repetitions_of_generation,n_parameters);
            clear n_parameters
            % loop over repetitions
            for repetition = 1:n_repetitions_of_generation
            % get mean of parameters
                mean_recovered_parameters(repetition,:) = mean(modelling_outcomes_by_repetition{repetition}{generative_model}.parameters{fitting_model},1);
            end

            % -------- plot bCON next to bDIS w/ p value --------

            bCON_idx = models_info_extra.indices_b_CON_DIS(fitting_model,1) ;
            bDIS_idx = models_info_extra.indices_b_CON_DIS(fitting_model,2) ;

            % input data must be matrix where rows are conditions
            data = {};
            data{1} = {mean_recovered_parameters(:,bCON_idx);...
                       mean_recovered_parameters(:,bDIS_idx) }; 

            % violin figure settings
            ymin = -25 ;
            ymax = 25 ;
            my_title = sprintf("m%i fitted on m%i \nbCON vs bDIS \n(mean by repetitions)",fitting_model,generative_model);
            type = 2;
            x_tick_label = [''; ''];%['bCON';'bDIS']; 
            violin_colors_in_order = [color_dict.very_dark_blue_autumn_palette ; color_dict.very_dark_red_autumn_palette];

            f = figure ;

            % IF empirical parameters are provided, superimpose parameters from corresponding data set and fitting model
            if ~isempty(empirical_parameters{fitting_model})
                % get empirical parameters
                empirical_bCON = empirical_parameters{fitting_model}(:,bCON_idx);
                empirical_bDIS = empirical_parameters{fitting_model}(:,bDIS_idx);

                % --- summary stats
                alpha = 0.05;
                mean_CON = mean(empirical_bCON);
                n_CON    = numel(empirical_bCON);
                se_CON   = std(empirical_bCON,0) / sqrt(n_CON);
                t_CON    = tinv(1-alpha/2, n_CON-1);           % 95% t critical
                ci_CON   = t_CON * se_CON;                 % CI half-width
                
                mean_DIS = mean(empirical_bDIS);
                n_DIS    = numel(empirical_bDIS);
                se_DIS   = std(empirical_bDIS,0) / sqrt(n_DIS);
                t_DIS    = tinv(1-alpha/2, n_DIS-1);
                ci_DIS   = t_DIS * se_DIS;
                % --- plot mean ± CI 
                x_CON = 1;
                x_DIS = 2;
                hCI_CON = errorbar(x_CON, mean_CON, ci_CON, 'o', "MarkerSize",4, 'LineWidth',1.5, 'CapSize',15, "MarkerFaceColor",color_dict.blue_autumn_palette, "MarkerEdgeColor",color_dict.blue_autumn_palette, "Color",color_dict.blue_autumn_palette);
                hold on
                hCI_DIS = errorbar(x_DIS, mean_DIS, ci_DIS, 'o', "MarkerSize",4, 'LineWidth',1.5, 'CapSize',15, "MarkerFaceColor",color_dict.red_autumn_palette, "MarkerEdgeColor",color_dict.red_autumn_palette, "Color",color_dict.red_autumn_palette);  
                hold on
            end

            % call plotting function
            skylineplot_Antonis(type, data, ...
                    Colors=violin_colors_in_order, ...
                    YLim=[ymin ymax], ...
                    xRefInput=x_ref_input, ...
                    font_size=font_size, ...
                    Title=my_title, ...
                    LabelX=x_label, ...
                    x_tick_labels=x_tick_label, ...
                    dot_size=dot_size, ...
                    sem_bar_width=sem_bar_width, ...
                    line_width=my_linewidth, ...
                    highlight_connected_lines_in_dominant_direction=highlight_connected_lines_in_dominant_direction, ...
                    font=font, ...
                    star_font_size=star_font_size);
            hold on
            % add stars for data{1}{1} and data{1}{2} compared to zero
            [~,p_diff_1] = ttest(data{1}{1});
            stars_p_diff_1 = significance_stars(p_diff_1);
            [~,p_diff_2] = ttest(data{1}{2});
            stars_p_diff_2 = significance_stars(p_diff_2);
            text(x_CON,ymax-0.2*(abs(ymax-ymin)),stars_p_diff_1, 'Color','black','FontSize', star_font_size); 
            text(x_DIS,ymax-0.2*(abs(ymax-ymin)),stars_p_diff_2, 'Color','black','FontSize', star_font_size); 
            hold on

            % add y line at 0
            yline(0,":")
            hold on
            % remove top and right box lines
            set(gca,'box','off')
            % remove x axis line
            set(gca,'XColor','none')
            % remove bottom box ticks
            set(gca,'XTick',[])
            % figure settings
            set(f,'units',position_units,'position',axis_inner_position,'color',figure_background_color); % set size of inner plot & set color of background behind plots
            % save figure
            name = sprintf('Parameter_recovery_generativemodel1_fittingmodel%i_mean_across_repetitions_bCON_bDIS_%s.svg' ,fitting_model, reward_structure_dataset_name);
            svnm = fullfile(figures_export_dir,name);
            set(f, 'Renderer', 'painters');
            print(f, svnm, '-dsvg'); 
            hold off

            % --------- also print statistics for paper: bCON vs 0, bDIS vs 0, bCON vs bDIS
            fprintf("\n--------- Stats for paper: generativemodel1_fittingmodel%i_mean_across_repetitions_bCON_bDIS_%s \n",fitting_model, reward_structure_dataset_name);
            recovered_bCON = data{1}{1};
            recovered_bDIS = data{1}{2};
            [h,p,ci,stats] = ttest(recovered_bCON,0,'Tail','right');
            p = text_p_value(p);
            mu = mean(recovered_bCON);
            fprintf("\nbCON in model %i is ABOVE zero (ttest): mean = %.2f, t(%i) = %.2f, %s\n",fitting_model,mu,stats.df,round(stats.tstat,2),p);
            clear h p ci stats mean

            [h,p,ci,stats] = ttest(recovered_bDIS,0,'Tail','left');
            p = text_p_value(p);
            mu = mean(recovered_bDIS);
            fprintf("\nbDIS in model %i is BELOW zero (ttest): mean = %.2f, t(%i) = %.2f, %s\n",fitting_model,mu,stats.df,round(stats.tstat,2),p);
            clear h p ci stats mean

            [h,p,ci,stats] = ttest(recovered_bCON-recovered_bDIS,0);
            p = text_p_value(p);
            fprintf("\nbCON is different from bDIS in model %i (paired-ttest): t(%i) = %.2f, %s\n",fitting_model,stats.df,round(stats.tstat,2),p);
            clear h p ci stats 
            clear recovered_bCON recovered_bDIS

         end
    end
end
clear fitting_model mean_recovered_parameters n_repetitions_of_generation n_parameters parameter_index data ymin ymax my_title
