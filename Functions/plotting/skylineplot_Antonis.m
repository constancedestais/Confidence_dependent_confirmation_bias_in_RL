function skylineplot_Antonis(type, InputCell, opts)

% Based on Sophie Bavard's script - December 2018
% Modified by Antonis Nasioulas to create different types of graphs 
% (number of factors (types of grouping), lines connecting individuals' values, reference point)
% Modifications by Constance Destais
% (including adding inputs for indvidual dot_size and sem_bar_width)

% INPUTS
% type = (type of the group)
%   1: one-sided violins 
%   2: one-sided violins / connect participants 
%   3: two-sided violins
%   4: two-sided violins/ connect participants 
%   5: one factor / only boxes (mean,sem,CI)
%   6: two factors / only boxes (mean, sem, CI)
% InputCell - can be  
% - a matrix with data to be plotted (levels/conditions in rows)
% - a cell with one entry 
%       InputCell{1} which contains the data, with one cell per level/condition
% - a cell with two entries: 
%       InputCell{1} matrix of data as above
%       InputCell{2} array with grouping variables of the data (one for each column)


% Example calls to this function, once with type 2, once with type 4 :

%{

% create fake data - input data must be matrix where rows are conditions
d1 = normrnd(0.5,0.2,[1,20])*0.5;
d2 = normrnd(0.5,0.2,[1,20])*0.7;
d3 = normrnd(0.5,0.2,[1,20])*0.8;
d4 = normrnd(0.5,0.2,[1,20]);

% function/figure settings
ymin = 0;
ymax = 1;
font_size = 20;
title = 'Testing title';
x_label = 'testing x';
y_label = 'testing y';
x_ref_input = NaN;

% call plotting function to plot first 2 conditions
data = [d1; d2];
type = 2;
violin_colors_in_order = [red ; green];

figure;
skylineplot_Antonis(type,data,violin_colors_in_order,ymin,ymax,x_ref_input,font_size,title,x_label,y_label)
hold off

% call plotting function to plot all 4 conditions
data = [d1; d2; d3; d4];
type = 4;
violin_colors_in_order = [red ; green ; red ; green];

figure;
skylineplot_Antonis(type,data,violin_colors_in_order,ymin,ymax,x_ref_input,font_size,title,x_label,y_label)
hold off

% call plotting function to plot all 4 conditions with EXTRA INPUTS (via varargin)
x_tick_label = ['L' ; 'G' ; 'L' ; 'G']; % input as varargin, as a row vector
dot_size = 130;
sem_bar_size = 20; 
line_width = 2;
highlight_connected_lines_in_dominant_direction  = 0;

figure;
skylineplot_Antonis(type,data,violin_colors_in_order,ymin,ymax,x_ref_input,font_size,title,x_label,y_label,x_tick_label,dot_size,sem_bar_size,line_width,highlight_connected_lines_in_dominant_direction);
hold off

% ----- 

% suppose have data of different sizes, store it as cell arrays inside single cell

% create fake data - input data must be matrix where rows are conditions
d1 = normrnd(0.5,0.2,[1,20])*0.5;
d2 = normrnd(0.5,0.2,[1,20])*0.7;
d3 = normrnd(0.5,0.2,[1,50])*0.8;
d4 = normrnd(0.5,0.2,[1,50]);

% function/figure settings
ymin = 0;
ymax = 1;
font_size = 20;
title = 'Testing title';
x_label = 'testing x';
y_label = 'testing y';
x_ref_input = NaN;

% call plotting function to plot all 4 conditions
data = {};
data(1} = {d1; d2; d3; d4};
type = 4;
violin_colors_in_order = [red ; green ; red ; green];

figure;
skylineplot_Antonis(type,data,violin_colors_in_order,ymin,ymax,x_ref_input,font_size,title,x_label,y_label)
hold off


%}

%========================================================================%

% Creates a violin plot with mean, error bars, confidence interval, kernel density.

arguments
    type (1,1) double {mustBeMember(type,[1 2 3 4])}
    InputCell

    opts.Colors double = []
    opts.YLim (1,2) double = [NaN NaN]     % replaces Yinf,Ysup
    opts.xRefInput = []                    % provides a refence point on the x-axis for all the prints (it is useful when we use skylinplot to plot something on an existing figure (so we want to position it in a specific place). Can take value "NaN".
    opts.Title (1,1) string = ""
    opts.LabelX (1,1) string = ""
    opts.LabelY (1,1) string = ""
    opts.x_tick_labels = ""
    opts.dot_size (1,1) double {mustBePositive} = 30
    opts.sem_bar_width (1,1) double {mustBeNonnegative} = 10
    opts.line_width (1,1) double {mustBePositive} = 1
    opts.highlight_connected_lines_in_dominant_direction (1,1) logical = true
    opts.font (1,1) string = "Arial"
    opts.font_size (1,1) double = 10
    opts.star_font_size (1,1) double = 13
    opts.violin_width (1,1) double {mustBePositive} = 0.75
end

% ---- use named args everywhere ----
Colors   = opts.Colors;
Yinf     = opts.YLim(1);
Ysup     = opts.YLim(2);
xRefInput= opts.xRefInput;
Title    = opts.Title;
LabelX   = opts.LabelX;
LabelY   = opts.LabelY;
x_tick_labels = opts.x_tick_labels;
dot_size      = opts.dot_size;
sem_bar_width = opts.sem_bar_width;
line_width    = opts.line_width;
highlight_connected_lines_in_dominant_direction = opts.highlight_connected_lines_in_dominant_direction;
font          = opts.font;
font_size     = opts.font_size;
star_font_size = opts.star_font_size;
violin_width  = opts.violin_width;


% ---- parse InputCell variants safely ----

DataCell = {};
dataCat = 0;
dataCatSampleSizes = [];

% extract DataCell, dataCat, dataCatSampleSizes from InputCell
if iscell(InputCell)
    
    raw = InputCell;
    
    % first cell of raw inputcontains data itself - format of data passed on 
    if type > 1 % more than one condition   
        data = raw{1}; 
    else 
        data = raw;
    end
    % second cell of raw input, if exists, contains dataCat 
    if numel(raw) >= 2
        dataCat = raw{2}; 
    end
    % third cell of raw input, if exists, contains dataCatSampleSizes
    if numel(raw) >= 3, 
        dataCatSampleSizes = raw{3}; 
    end
    DataCell = data;

else
    DataCell = num2cell(InputCell,2);
end


% parse DataCell
%{
if iscell(DataCell)
    if numel(DataCell) == 1
       DataCell = DataCell{1}; % DataCell from this point contains only the data
       dataCat=0;
    elseif numel(DataCell) >= 2 
        DataCell = DataCell{1}; %DataCell from this point contains only the data, in any case  
        dataCat = DataCell{2};
    end

    if numel(DataCell) == 3
        dataCatSampleSizes = DataCell{3}; % not sure what this does
    end
else % if matrix
    dataCat=0;
    % data = DataCell; %keep version of the data in matrix format -> Antonis used this for plotting lines between points but I changed it to allow the use of DataCell in that part of the script too
    % transforms the Data matrix into cell format if needed
    DataCell = num2cell(DataCell,2);
end

% ---- type-specific checks ----
% if plot lines between the dots, the two plots that are next to each other must have the same number of data points
if type == 2
    assert(isequal(size(DataCell{1}), size(DataCell{2})), ...
        "If type=2, connected conditions must match number of points.");
elseif type == 4
    assert(isequal(size(DataCell{1}), size(DataCell{2})) && ...
           isequal(size(DataCell{3}), size(DataCell{4})), ...
        "If type=4, connected conditions must match number of points.");
end

%}

% if nnz(isnan(DataCell))       
%    DataCell = DataCell(:,all((~isnan(DataCell)),1));
%    dataCat = dataCat(all((~isnan(DataCell)),1));
%    fprintf('Warning: nan values detected. Plots without these entries.\n')    
% end


% number of factors/groups/conditions
Nbar = size(DataCell,1);

% confidence interval
ConfInter = 0.95;

% color of the box + error bar
trace = [0.5 0.5 0.5];

% color of the dominant and non-dominant lines (connecting different levels of the same participant
alpha = 0.7;
ColDom    = [1.0000, 0.5529, 0.3608, alpha]; % orange 
ColNonDom = [0.4,0.4,0.4, alpha]; % black
ColAll    = [0.6 0.6 0.6, alpha]; % grey
% ColNonDom = [0.5020,0.5020,0.5020,0.5]; ColDom = [0,0,0,.5];
% ColNonDom = [Colors(1,:),0.5]; ColDom = [Colors(2,:),0.5]

if isempty(Colors)
    Colors = repmat(zeros(1,3),Nbar,1);
end

% initialise variable to store all the xRef variables used
xRefs_log = [];

% keep all the elements in the current axis
hold on 

% set font_size BEFORE plotting so that it applies to all elements
set(gca,'FontSize',font_size,'FontName',font)

for n = 1:Nbar
    
    clear DataMatrix
    clear jitter jitterstrength
    DataMatrix = DataCell{n,:}';   
    
    % number of subjects
    Nsub = length(DataMatrix(~isnan(DataMatrix)));
    
    curve = mean((DataMatrix),"omitnan");
    sem   = std(DataMatrix,1, "omitnan")/sqrt(Nsub);
    conf  = tinv(1 - 0.5*(1-ConfInter),Nsub);   
    keepI = ~isnan(DataMatrix);
    DataMatrix = DataMatrix(keepI);
    if dataCat ~= 0
        dataCatKeep = dataCat(keepI);
    end

    %-------- preparation for the violin---------
    
    % calculate kernel density estimation for the violin
    % if all data is identical, fix the density and value 
    if min(DataMatrix) == max(DataMatrix)
        density = 1; value = 1;
    else  % if the data is normal, calculate the real kernal density
    [density, value] = ksdensity(DataMatrix, 'Bandwidth', 0.9 * min(std(DataMatrix), iqr(DataMatrix)/1.34) * Nsub^(-1/5)); % change Bandwidth for violin shape. Default MATLAB: std(DataMatrix)*(4/(3*Nsub))^(1/5)
    density = density(value >= min(DataMatrix) & value <= max(DataMatrix));
    value = value(value >= min(DataMatrix) & value <= max(DataMatrix));
    value(1) = min(DataMatrix);
    value(end) = max(DataMatrix);
    end

    % scaling of violin_width controlling the width of the violin plot
    if type==4 
        scale_violin_width = 2.5;
    else
        scale_violin_width = 1.6; %2; %1.5; 
    end
    widthV = violin_width/scale_violin_width/max(density);  

    % set variables for positioning on x axis
        % xRef (position on x axis of the main axis for the first skyline plot)
        % xPos (position on x axis of other side of the first skyline plot - used to draw Confidence Interval box)
        % c1 and c2:
        % coeff
    if type == 1
        coeff = 1;
        c1=1; 
        c2=1;
        if ~isnan(xRefInput)
            xRef = xRefInput;
        else
            xRef = n;
        end
        xPos = xRef;
    elseif type == 2                
        c1=1; 
        c2=-10; %c2 is irrelevant because jitter==0 when type==2
        xRef = n;
    
        %if we have two levels, the violin face each other
        %if more than two levels, all the violins in the same direction
        if Nbar==2
            coeff = 1-2*rem(n,2);
            xPos= xRef - (rem(n,2)==1)*violin_width/scale_violin_width;
        else
           coeff = 1;
           xPos= xRef; 
        end
    elseif type == 3 || type == 6
        coeff = 1-2*rem(n,2);
        c1 = -1; 
        c2 = -1;
        pair_dist=0.05;
    
        if ~isnan(xRefInput)
            xRefTemp = xRefInput + n - 1; 
        else
            xRefTemp = n;
        end
        xRef= ceil(xRefTemp/2)+(-2*rem(xRefTemp,2)+1)*pair_dist; %n for odd, n+0.1 for even; to bring closer the pairs {1,2}, {3,4} etc
        xPos= xRef - (rem(n,2)==1)*violin_width/scale_violin_width;
    elseif type == 4 
        coeff = 1-2*rem(n,2);
        c1 = 1/3; co
        c2 = -1;
        pair_dist=0.15;
    
        %c1 = 0.5; % CONSTANCE ARTIFICALLY INCREASED DISTANCE BETWEEN VIOLIN AND DOTS
        %pair_dist=0.2; % CONSTANCE ARTIFICALLY INCREASED DISTANCE BETWEEN VIOLIN AND DOTS SO HAD TO MANUALLY DECREASE THIS
    
        if ~isnan(xRefInput)
            xRefTemp = xRefInput + n - 1; 
        else
            xRefTemp = n;
        end
        xRef= ceil(xRefTemp/2)+(-2*rem(xRefTemp,2)+1)*pair_dist; %n-pair_dist for odd, n+pair_dist for even; to bring closer the pairs {1,2}, {3,4} etc
        xPos=xRef-(rem(n,2)==1)*violin_width/scale_violin_width;
    
    elseif type == 5
        coeff = 1;
        
        if ~isnan(xRefInput)
            xRef = xRefInput;
        else
            xRef = n ;
        end
        xRef = xRef-violin_width/(2*scale_violin_width);
        xPos = xRef;
    end

    if type ~= 6 && type ~= 5
        %-------plot the violin-------
        fill([xRef, xRef+coeff*density*widthV, xRef],...
            [value(1), value, value(end)],...
            Colors(n,:),...
            'EdgeColor', 'none',...%trace,...
            'FaceAlpha',0.2);
        %-----------------------------            
        
        %-------INDIVIDUAL DOTS-------
        if length(density) > 1
            jitterstrength = interp1(value, density*widthV, DataMatrix);
        else % all data is identical
            jitterstrength = density*widthV;
        end
    
        if type==1 || type==3 
            %individual dots not on the same vertical line
            jitter=abs(zscore(1:length(DataMatrix))'/max(zscore(1:length(DataMatrix))')); 
        elseif type==2 || type==4
            jitter=zeros(Nsub,1); %all dots on the same vertical line
        end
        % TESTING CONSTANCE
        scatter(xRef-c1*coeff*violin_width/10 - c2*coeff*jitter.*(violin_width/2- violin_width/10), DataMatrix, dot_size,...
            Colors(n,:),'filled',...
            'marker','o',...
            'MarkerFaceAlpha',0.4);  
        
        %-----------------------------
    
        %if I want to plot the bold region of the violin plot for the box plots as well
        %to make the discrimination easier between conditions, I should put
        %it outside this if 
        %-------CONFIDENCE INTERVAL------- (bold region of the violin plot)   
        if length(density) > 1
            d = interp1(value, density*widthV, curve-sem*conf:0.0001:curve+sem*conf);
        fill([xRef xRef+coeff*d xRef],...
            [curve-sem*conf curve-sem*conf:0.0001:curve+sem*conf curve+sem*conf],...
            Colors(n,:),...
            'EdgeColor', 'none',...%trace,...
            'FaceAlpha',0.4);
        end
        %-----------------------------
    end


    
    
    if dataCat == 0
        %-------MEAN HORIZONTAL BAR------- (inside rectangle)
        xMean = [xRef ; xRef + coeff*violin_width/scale_violin_width];
        yMean = [curve; curve];
        plot(xMean,yMean,'-','LineWidth',line_width,'Color',[0 0 0 1]);        
        %-------ERROR BARS------- (inside rectangle)
        errorbar(xRef+coeff*violin_width/(2*scale_violin_width),curve,sem,...
            'Color',[0 0 0 1],...Colors(n,:),...
            'LineStyle','-',...  
            'CapSize',sem_bar_width,... 
            'LineWidth',line_width);
        %-------CONFIDENCE INTERVAL RECTANGLE-------    
        rectangle('Position',[xPos, curve - sem*conf, violin_width/scale_violin_width, sem*conf*2],... % [lower_left_corner_x, lower_left_corner_right, wdith, heigh]
            'EdgeColor',Colors(n,:),...
            'LineWidth',line_width);

    else
        u = unique(dataCatKeep,'stable');
        w = violin_width/scale_violin_width/numel(u);
        for  i = 1:numel(u) 
            dataDC = DataMatrix(dataCatKeep == u(i));
            nDC = height(dataDC);
            curveDC = mean(dataDC); %the curve value for each of the categories          
            semDC   = std(dataDC)/sqrt(numel(dataDC));

            %-------MEAN HORIZONTAL BAR------- (inside rectangle)
            xRefCat = choose( [xRef, repmat(xRef-rem(n,2)*violin_width/scale_violin_width,1,3)] ,type);
            xMean = [xRefCat + w*(i-1) ; xRefCat + w*i];
            yMean = [curveDC; curveDC];
            plot(xMean,yMean,'-','LineWidth',line_width,'Color',[0 0 0 1]);
            %-------ERROR BARS------- (inside rectangle)
            errorbar(xRefCat + w*(i-1)+w/2,curveDC,semDC,...
                'Color',[0 0 0 1],...Colors(n,:),...
                'LineStyle','-',...  'CapSize',3,...
                'LineWidth',line_width);
            %-------Experiments' labels above error bars ------%
            myColor=[0,0,0]; %black
            opacityStep=-.12; opacity= 1:opacityStep:(1+5*opacityStep);
            text(mean(xMean),yMean(1)+semDC+choose([.01,.01],ismac+1),num2str(u(i)),'FontSize', choose([10,17],ismac+1),'Color',(1 - opacity(u(i)) * (1 - myColor)), 'HorizontalAlignment', 'center', 'VerticalAlignment','baseline')

            if exist('dataCatSampleSizes','var') && dataCatSampleSizes
                yText = min(DataMatrix) - .05;
                FS = 7;
                if i == 1
                    text(mean(xMean), yText, 'N =   ','HorizontalAlignment','right')
                end
                text(mean(xMean), yText, num2str(nDC), 'HorizontalAlignment','center', 'FontSize', FS)
            end
        end
    end
    %-------PARTICIPANTS' LINES BETWEEN DOTS (type=4) ------
    if type==4 
        if rem(n,2)==1     
            xRef1= xRef;
            % xRef1 = xRef-c1*coeff*violin_width/10 - c2*coeff*jitter(1)*(violin_width/2- violin_width/10); % ATTEMPTED CHANGE BY CONSTANCE
            xRef2= xRef+2*pair_dist;
            x1 = xRef1 + (2*rem(n,2)-1)* violin_width/20;
            x2 = xRef2 + (2*rem(n+1,2)-1)* violin_width/20;

              
            %designed to give different colors in dominant and non-dominant
            %directions. Note, that when we have two factors, all the code
            %(not just this part) is coded with the assumption that the
            %second factor has two levels
            % ORIGINAL ANTONIS VERSION
            % means = mean(data,2,'omitnan'); 
            % CONSTANCE: try to use cell version (DataCell) for everything that requires looking at all the provided datasets
                % NB: cellfun applies function to each cell in cell array
            means =  cellfun(@(x) mean(x, 2, 'omitnan'), DataCell, 'UniformOutput', false); 
            means = cell2mat(means);
            % ColNonDom = [Colors(1,:),0.5]; ColDom = [Colors(2,:),0.5];

            % ORIGINAL ANTONIS VERSION
                % data2 = data([n n+1],:); %keep the two relevant rows
                % data2 = data2(:,~any(isnan(data2), 1)); %omit columns with at least one nan entry;
            % CONSTANCE: try to use cell version (DataCell) for everything that requires looking at all the provided datasets
                % NB: cellfun applies function to each cell in cell array
            two_connected_datasets = DataCell([n n+1],:); %keep the two relevant rows
            nanIndices = isnan(two_connected_datasets{1}) | isnan(two_connected_datasets{2}); % identify pairs of values in which there is at least one NaN value
            two_connected_datasets = cellfun(@(x) x(:,~nanIndices), two_connected_datasets, 'UniformOutput', false);  % remove pairs of values containing NaNs
            % assert(size(DataCell{n}),size(DataCell{n+1}), "Need same numbers of data points in each violin to perform basic t-tests")    
            
            for datapoint = 1:width(two_connected_datasets{1})
                % get color of line between dots for this participant
                if highlight_connected_lines_in_dominant_direction
                    % in this case dominant lines can be defined and we can color differently the dominant direction lines
                    col=choose({ColNonDom, ColDom}, (sign(two_connected_datasets(1,datapoint)-two_connected_datasets(2,datapoint)) == sign(means(n)-means(n+1)))+1); % here, compare sign of difference for one datapoint to sign of difference for overall population
                else
                    col = ColAll;
                end                
                plot([x1 x2], [two_connected_datasets{1}(datapoint) two_connected_datasets{2}(datapoint)],'Color',col,'LineWidth',line_width/3)
            end
            
        end
    end 
    % store for memory
    xRefs_log = [xRefs_log; xRef];
end

%-------PARTICIPANTS' LINES BETWEEN DOTS  (type=2) ------
if type == 2   

    %if we have two levels, the violins face each other
    %if more than two levels, all the violins in the same direction
    if Nbar==2
        xx = arrayfun(@(n) n+(2*rem(n,2)-1)*violin_width/8,1:Nbar); % "/8" is for leaving some space between dots and lines
        
        % ORIGINAL ANTONIS VERSION WITH MATRIX
        % means = mean(data,2,'omitnan');   
        % CONSTANCE: try to use cell version (DataCell) for everything that requires looking at all the provided datasets
            % NB: cellfun applies function to each cell in cell array
        means = cellfun(@(x) mean(x, 2, 'omitnan'), DataCell, 'UniformOutput', false); 
        means = cell2mat(means);

        for datapoint = 1:Nsub 
            % get color of line between dots for this participant
            if highlight_connected_lines_in_dominant_direction
                % in this case dominant lines can be defined and we can color differently the dominant direction lines
                col=choose({ColNonDom, ColDom}, ( sign(DataCell{1}(datapoint)-DataCell{2}(datapoint)) == sign(means(1)-means(2)) )+1 ); % here, compare sign of difference for one datapoint to sign of difference for overall population
            else
                col = ColAll; 
            end
            yy = [ DataCell{1}(datapoint) , DataCell{2}(datapoint) ] ;
            plot(xx,yy,'Color',col,'LineWidth',line_width/3)
        end
    else
        xx = arrayfun(@(n) n-violin_width/8,1:Nbar);
        for datapoint = 1:Nsub
            plot(xx, data(:,datapoint),'Color',[0,0,0,0.5])
        end
    end
end
%--------


%------- PLOT SIGNIFICANCE STARS -------- %
if type == 4 || type == 2
    
    if type == 4
        data_index = [1,2 ; 3,4];
    elseif type == 2
        data_index = [1,2];
    end

    for i = 1:size(data_index,1)
        data_index_here =  data_index(i,:);
        a = data_index_here(1);
        b = data_index_here(2);

        % plot bars
        % x position: use xRefs_log as reference for star and end points of bars
        % y position: 
        x_bar = [xRefs_log(a), xRefs_log(b)];
        y_bar = [Yinf+(Ysup-Yinf)*0.90, Yinf+(Ysup-Yinf)*0.90];
        line(x_bar,y_bar,'Color', [0 0 0 1], 'LineWidth', line_width)
        
        % compare the data to get pvalue
        [~,pvalue] = ttest(DataCell{a}-DataCell{b}) ;
        
        % translate the pvalue in a number of stars using function (input = pvalue, output = string of stars)
        stars = significance_stars(pvalue);
        
        % plot stars
        % x position: get middle of x coordinates for lines above
        % y position: add a little space above the previous y position
        x_stars = mean(x_bar);
        % adapt size and position if need to write "n.a" as opposed to stars
        if stars == "n.a" % if plot "n.a"
            Font_size_here = star_font_size*0.7; % font_size*0.80;
            y_stars = y_bar(1)+ ((Ysup-Yinf)*0.06);
        else % if plot stars
            Font_size_here = star_font_size;
            y_stars = y_bar(1)+ ((Ysup-Yinf)*0.02);
        end
        % plot the stars
        text(x_stars,y_stars,stars, 'FontSize', Font_size_here, 'HorizontalAlignment', 'center');

    end
end
% ----------



% axes and stuff
x_spacing_factor = 0.7; % change this value to make the x axis tighter around the violins
ylim([Yinf Ysup]);
set(gca, ...
    'XLim',[0+(1-x_spacing_factor) Nbar+x_spacing_factor],... %'XLim',[0 Nbar+1],...
    'XTick',1:Nbar,...
    'XTickLabel',x_tick_labels);
% yline(0);

if type==4 | type == 3
    xlim([0 Nbar/2]+.5)
end
title(Title);
xlabel(LabelX);
ylabel(LabelY);
