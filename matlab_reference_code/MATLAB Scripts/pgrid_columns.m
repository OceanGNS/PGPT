function [temp_sort_var2,xu2,temp_sort_var,xu] = pgrid_columns(x,y2,var,yq)
    % x  - profile index, removes stalled segments
    temp_t = 1:length(var);
    id = ~isnan(var);
    y = interp1(temp_t(id),y2(id),temp_t);
    y = y(:);
    
    

    xu = unique(x(~isnan(x)));
    xu(rem(xu,1)~=0)=[];
    
    
    temp_sort_var = NaN(length(yq),length(xu));
    for i = 1:length(xu)
        xidx = find(x == xu(i));

        temp_var  = var(xidx);
        temp_y    = y(xidx);
        idnan = find(~isnan(temp_var) & ~isnan(temp_y));
        if length(idnan)>3
            temp_var = temp_var(idnan);
            temp_y = temp_y(idnan);

            [~,~,loc]=histcounts(temp_y,yq);
            temp_y(loc==0)=[];
            temp_var(loc==0)=[];
            loc(loc==0)=[];

            y_mean = accumarray(loc(:),temp_y(:))./accumarray(loc(:),1);
            var_mean = accumarray(loc(:),temp_var(:))./accumarray(loc(:),1);

            id = find(~isnan(var_mean));
            if length(id)>2
%                 iy1 = loc(1);
%                 iy2 = loc(end);
                [~,iy1]=nanmin(abs(yq-nanmin(y_mean(id))));
                [~,iy2]=nanmin(abs(yq-nanmax(y_mean(id))));
                temp_sort_var(iy1:iy2,i)=interp1(y_mean(id),var_mean(id),yq(iy1:iy2),...
                    'linear');
            else 
                temp_sort_var(:,i) = NaN*yq;
            end
        end
    end
    temp_sort_var2 = temp_sort_var;  % for nan - columns
    xu = xu';
    xu2 = xu;
    temp_sort_var2(:, all(isnan(temp_sort_var),1)) = [];
    xu2(:, all(isnan(temp_sort_var),1)) = [];
    xu2 = xu2(:);
end


%             if iy1>1
%                 iy1=1;
%             end

%             iy2=iy2+round((length(yq)-iy2)/100,-1);