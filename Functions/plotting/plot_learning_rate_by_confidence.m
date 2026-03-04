function [] = plot_learning_rate_by_confidence(modelling_outputs, version_name, model, outcome_encoding, add_inset_m1_confirmation_bias, figures_dir)

% goal: plot how learning rate changes as a function of confidence, do so by computing this for each participant using their parameters, and then averaging these traces - so for each point, this is the average LR for this level of confidence

assert(  ismember(model,[2,4,10,11]), 'Only models with confidence-dependent learning rates for confirmatory and disconfirmatory evidence can be plotted')

%% set useful variables

% load colour 
color_dict = load_my_colors();
%% compute learning rate for each confidence value for each participant + average over all participants + compute stats for plot
params = modelling_outputs.parameters{model};    
d = stats_learning_rate_by_confidence_averaged_across_participants(params,model);

%% plot learning rate by confidence, averaged across all participants

% figure settings
position_units = "centimeters";
%outer_position_size = [1, 1, 19, 15];
inner_position_size = [1, 1, 6.895 , 5.4125]; % [1, 1, 7, 5.5]; 
figure_background_color = 'none';
axes_background_color = 'none';
font_size = 8*1.33333368888898; % to get fontsize 8 in Inkscape
my_fontweight = 'bold';
my_line_width = 1.8;
x_interval = [0.5:0.1:1];
y_interval = [0:0.2:1];

% plot
f = figure;
fill([d.confidence_rescaled fliplr(d.confidence_rescaled)],[d.CI_lower_confirmatory    fliplr(d.CI_upper_confirmatory)],  [color_dict.blue_autumn_palette] ,'EdgeColor','none','FaceAlpha',0.2) 
hold on 
fill([d.confidence_rescaled fliplr(d.confidence_rescaled)],[d.CI_lower_disconfirmatory fliplr(d.CI_upper_disconfirmatory)], [color_dict.red_autumn_palette] ,'EdgeColor','none','FaceAlpha',0.2)
hold on 
l1 = plot(d.confidence_rescaled, d.mean_LR_confirmatory, 'Color',[color_dict.blue_autumn_palette], 'LineWidth',my_line_width) ;
hold on
l2 = plot(d.confidence_rescaled, d.mean_LR_disconfirmatory, 'Color',[color_dict.red_autumn_palette], 'LineWidth',my_line_width);
yline(0.5,":");

% overlay m1 learning rates on top
if add_inset_m1_confirmation_bias
    % setup
    params_m1 = modelling_outputs.parameters{1}; 
    LR_CON = params_m1(:,2);
    LR_DIS = params_m1(:,3);
    alpha = 0.05;

    % --- x location
    x = 0.75;
    
    % --- summary stats
    mean_CON = mean(LR_CON);
    n_CON    = numel(LR_CON);
    se_CON   = std(LR_CON,0) / sqrt(n_CON);
    t_CON    = tinv(1-alpha/2, n_CON-1);           % 95% t critical
    ci_CON   = t_CON * se_CON;                 % CI half-width
    
    mean_DIS = mean(LR_DIS);
    n_DIS    = numel(LR_DIS);
    se_DIS   = std(LR_DIS,0) / sqrt(n_DIS);
    t_DIS    = tinv(1-alpha/2, n_DIS-1);
    ci_DIS   = t_DIS * se_DIS;
    
    % --- plot 
    % Mean ± CI (outer, no marker)
    hCI_CON = errorbar(x, mean_CON, ci_CON, 'o', "MarkerSize",6, 'LineWidth',1.5, 'CapSize',15, "MarkerFaceColor",color_dict.very_dark_blue_autumn_palette, "MarkerEdgeColor",color_dict.very_dark_blue_autumn_palette, "Color",color_dict.very_dark_blue_autumn_palette);
    hCI_DIS = errorbar(x, mean_DIS, ci_DIS, 'o', "MarkerSize",6, 'LineWidth',1.5, 'CapSize',15, "MarkerFaceColor",color_dict.very_dark_red_autumn_palette, "MarkerEdgeColor",color_dict.very_dark_red_autumn_palette, "Color",color_dict.very_dark_red_autumn_palette);
    
    % optional: ensure these are on top
    uistack([hCI_CON hCI_DIS ],'top') 
end



% xlabel('confidence')
% ylabel('{\alpha}')
xlim([min(x_interval), max(x_interval)])
xticks(x_interval)
xticklabels(string(x_interval*100))
ylim([min(y_interval), max(y_interval)])
yticks(y_interval)
yticklabels(string(y_interval))
% yticklabels(string(y_interval*100))
% legend([l1, l2],'confirmatory','disconfirmatory')
hold off 
% figure settings
set(gca,'FontSize',font_size,'box','off','FontName','Arial','units',position_units,'position',inner_position_size,'color',figure_background_color); % set size of inner plot & set color of background behind plots
set(gcf,'units',position_units,'position',inner_position_size+1.5); % set size of inner plot & set color of background behind plots
% save figure
name = sprintf('Learning_rate_by_confidence_model%i_%s_outcomes_%s',model,outcome_encoding,version_name);
svnm = fullfile(figures_dir,name);
print(gcf,[svnm,'.svg'],'-dsvg')
%saveas(gcf, [svnm,'.fig']);
clear subject_mean name svnm f1 pvalue1 pvalue2 pvalue3 pvalue4 pvalue5 pvalue6

clear a_confirmatory  b_confirmatory  a_disconfirmatory b_disconfirmatory ...
      SEM_confirmatory SEM_disconfirmatory CI_upper_confirmatory CI_lower_confirmatory CI_upper_disconfirmatory CI_lower_disconfirmatory...
      LR_confirmatory LR_disconfirmatory mean_LR_confirmatory mean_LR_disconfirmatory CI_boundary CI_temp LR SEM CI_lower CI_upper        


end
