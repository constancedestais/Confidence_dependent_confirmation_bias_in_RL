function string_p = text_p_value(number_p)
%{
    if number_p < 0.0001
        string_p = "p < 0.0001";
    else
        number_p = round(number_p,4);
        string_p = sprintf("p = %.4f",number_p);
    end
%}
  if number_p < 0.001
    string_p = "P<0.001";
  else
    number_p = round(number_p,3);
    string_p = sprintf("p = %.3f",number_p);
  end
end