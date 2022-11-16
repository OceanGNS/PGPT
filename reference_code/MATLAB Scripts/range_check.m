function var_check=range_check(var,var_min,var_max)
    var_check = var;
    
    % get rid of outliers above var_max
    id = var>var_max;
    var_check(id)=NaN;
    
    % get rid of outliers below var_min
    id = var<var_min;
    var_check(id)=NaN;
    
end

