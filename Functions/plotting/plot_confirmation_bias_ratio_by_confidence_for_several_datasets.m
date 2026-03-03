function [] = plot_confirmation_bias_by_confidence_for_several_datasets(confidence_rescaled,mean_LR_bias_ratio, CI_lower_bias_ratio, CI_upper_bias_ratio, version_name, model, outcome_encoding, figures_dir)

% goal: plot how learning rate changes as a function of confidence, do so by computing this for each participant using their parameters, and then averaging these traces - so for each point, this is the average LR for this level of confidence
%{
    need mean_LR_bias_ratio, CI_lower_bias_ratio and CI_upper_bias_ratio for each dataset
    INPUT
        confidence_rescaled, array 1x11 between 0.5 and 1
        mean_LR_bias_ratio, cell array with one cell per dataset
        CI_lower_bias_ratio,  cell array with one cell per dataset
        CI_upper_bias_ratio,  cell array with one cell per dataset

%}


assert(  ismember(model,[2,4,10,11]), 'Only models with confidence-dependent learning rates for confirmatory and disconfirmatory evidence can be plotted')

%% set useful variables

% load colour 
color_dict = load_my_colors();




%% plot learning rate by confidence, averaged across all participants

% figure settings
position_units = "centimeters";
%outer_position_size = [1, 1, 19, 15];
inner_position_size = [1, 1, 6, 4.8];
figure_background_color = 'none';
axes_background_color = 'none';
font_size = 10;
my_fontweight = 'bold';
my_line_width = 1.8;
x_interval = [0.5:0.1:1];
y_interval = [-0.6:0.2:1.2];

colors = {color_dict.grey; color_dict.green; color_dict.dark_orange}; % {color_dict.black; color_dict.dark_grey; color_dict.middle_grey};

f = figure;
for i = 1:numel(mean_LR_bias_ratio)
    % plot
    fill([confidence_rescaled fliplr(confidence_rescaled)],[CI_lower_bias_ratio{i}    fliplr(CI_upper_bias_ratio{i})],  [colors{i}] ,'EdgeColor','none','FaceAlpha',0.2) 
    hold on 
    plot(confidence_rescaled, mean_LR_bias_ratio{i}, 'Color',[colors{i}], 'LineWidth',my_line_width) ;
    hold on
end

yline(0,"--")
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

