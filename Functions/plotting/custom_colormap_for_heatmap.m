function [colormap, lims] = custom_colormap_for_heatmap(correlation_matrix)
    %{
    custom_colormap_for_heatmap  Return a heatmap colormap and color limits.

    Builds a purple→white→orange diverging colormap and chooses an appropriate
    half/full map plus ColorLimits based on the sign of the data:
      • all >= 0  → white→orange, lims = [0, max]
      • all <= 0  → purple→white, lims = [min, 0]
      • mixed     → full map,    lims = [-m, m] (symmetric about 0)

    INPUT
      correlation_matrix : numeric matrix of values to plot

    OUTPUT
      colormap : N×3 RGB colormap (N=128 or 256)
      lims     : 1×2 vector for heatmap ColorLimits
    %}

    % Data matrix for the heatmap
    M = correlation_matrix;

    % Define negative-side color 
    neg = [170 84 134] / 255; % (purple) 
    % Define positive-side color % 
    pos = [255 213 36] / 255; % (orange) 

    % Build full diverging colormap: purple -> white -> orange (256 colors)
    base = interp1([1 2 3], [neg; 1 1 1; pos], linspace(1, 3, 256), 'linear');

    % Compute data minimum
    data_min = min(M(:));

    % Compute data maximum
    data_max = max(M(:));

    colormap = [];
    lims = [];
    % If data are nonnegative, use white->orange half and limits [0, max]
    if data_min >= 0 && data_max > 0
        colormap = base(129:end, :);
        lims = [0 data_max];
    % If data are nonpositive, use purple->white half and limits [min, 0]
    elseif data_max <= 0 && data_min < 0
        colormap = base(1:128, :);
        lims = [data_min 0];
    % If data span both signs, use full map with symmetric limits about zero
    else
        m = max(abs([data_min data_max]));
        colormap = base;
        lims = [-m m];
    end

end