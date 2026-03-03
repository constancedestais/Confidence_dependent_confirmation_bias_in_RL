%% set colors
    function [c] = load_my_colors()
    % return a struct with my preferred colors for plotting
    c = struct();

    c.white       = [1 1 1];
    c.black       = [0 0 0];


    c.grey         = [.35 .35 .35];
    c.light_grey   = [0.9 0.9 0.9];
    c.middle_grey  = [0.5 0.5 0.5];
    c.dark_grey    = [0.1 0.1 0.1]; % [0.2 0.2 0.2];

    %{
    red          = [255, 0, 0]/256; % https://www.w3schools.com/colors/colors_picker.asp 
    very_light_red = [255, 179, 179]/256; % https://www.w3schools.com/colors/colors_picker.asp
    light_red    = [255, 102, 102]/256; % https://www.w3schools.com/colors/colors_picker.asp
    dark_red     = [204, 0, 0]/256;  % https://www.w3schools.com/colors/colors_picker.asp
    %}
    %{
    % https://www.w3schools.com/colors/colors_picker.asp?colorhex=f21414 
    red          = [242, 13, 13]/256; 
    very_light_red = [250, 158, 158]/256; 
    light_red    = [247, 110, 110]/256; 
    dark_red     = [194, 10, 10]/256;  
    %}
    % https://www.w3schools.com/colors/colors_picker.asp?colorhex=ff0000
    c.red          = [255, 0, 0]/256; 
    c.very_light_red = [255, 179, 179]/256; 
    c.light_red    = [255, 128, 128]/256; 
    c.dark_red     = [204, 0, 0]/256;  
    c.baby_red     = [217, 182, 182]/256;

    %{
    blue         = [0, 0, 255]/256 ; % https://www.w3schools.com/colors/colors_picker.asp / https://www.w3schools.com/colors/colors_rgb.asp
    dark_blue    = [0, 0, 179]/256; % https://www.w3schools.com/colors/colors_picker.asp?colorhex=79b0e7        
    light_blue   =  [121, 176, 255]/256 % [121, 176, 231]/256; % https://www.w3schools.com/colors/colors_picker.asp?colorhex=79b0e7 
    very_light_blue  = [179, 209, 255]/256; % https://www.w3schools.com/colors/colors_picker.asp
    %}
    % https://www.w3schools.com/colors/colors_picker.asp?colorhex=1a75ff
    %{
    blue         = [26, 117, 255]/256 ; % OR [0, 102, 255]/256 
    dark_blue    = [0, 71, 179]/256;  
    light_blue   =  [102, 163, 255]/256 % OR [121, 176, 231]/256;
    very_light_blue  = [179, 209, 255]/256; 
    %}
    % https://www.w3schools.com/colors/colors_picker.asp?colorhex=0066ff
    c.blue         = [0, 110, 255]/256; %[26, 71, 255]/256; 
    c.light_blue   =  [77, 148, 255]/256; 
    c.very_light_blue  = [153, 194, 255]/256; 
    c.dark_blue    = [0, 41, 204]/256;  
    c.very_dark_blue    = [0, 31, 153]/256; 
    c.baby_blue = [170, 187, 204]/256;
    c.cyan_blue    = [0,128,128]/256; 

    c.bright_blue = [0, 21, 255	]/256;
    c.bright_red = [255, 0, 13]/256;

    % https://colordrop.io/palette/25675
    c.blue_autumn_palette         = [0, 115, 168]/256; 
    c.light_blue_autumn_palette   =  [153, 210, 231]/256; % or maybe [51, 153, 204]/256
    c.very_light_blue_autumn_palette  = [204, 238, 255]/256; 
    c.dark_blue_autumn_palette = [0,79,115]/256; %[0, 90, 140]/256;
    c.very_dark_blue_autumn_palette = [0, 63, 102]/256;

    c.red_autumn_palette = [204, 51, 51]/256;
    c.light_red_autumn_palette = [255, 102, 102]/256;
    c.very_light_red_autumn_palette = [255, 179, 179]/256;
    c.dark_red_autumn_palette = [163,41,41]/256; %[163, 41, 41]/256;
    c.very_dark_red_autumn_palette = [143, 36, 36]/256;
    
    %----
    c.green        = [0.4660, 0.6740, 0.1880]; 
    c.dark_green   = [0, 57, 0]/256;            
    c.light_green  = [0, 0.5, 0];  

    c.light_purple = [159, 109, 191]/256; % [194, 151, 222]/256; % [224, 176, 255]/256; 
    c.purple       = [157, 0, 255]/256; 
    c.dark_purple  = [0.4, 0, 0.5];
    c.very_light_orange = [255, 194, 153]/256;
    c.light_orange = [255, 163, 101]/256; % https://www.w3schools.com/colors/colors_picker.asp?colorhex=ffa366
    c.orange       = [255, 117, 24]/256 ;
    c.poppy_orange = [227, 83, 53]/256;
    % https://www.w3schools.com/colors/colors_picker.asp?colorhex=cc5500
    c.dark_orange = [204, 85, 0]/256; 
    c.burnt_orange = c.dark_orange;
    c.very_dark_orange = [179, 74, 0]/256;



    c.very_light_yellow = [255, 248, 214]/256;
    c.light_yellow      = [255, 243, 183]/256;
    c.yellow            = [251, 226, 98]/256;
    c.dark_yellow       = [218, 165, 32]/256;