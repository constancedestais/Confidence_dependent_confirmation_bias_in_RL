function  stars_string = significance_stars(p_value)

    if p_value > 0.05
        stars_string = "ns";
    elseif p_value <= 0.05 & p_value > 0.01
        stars_string = "*";
    elseif p_value <= 0.01 & p_value > 0.001
        stars_string = "**";
    elseif p_value <= 0.001 
        stars_string = "***";
    end

end