function [var_ds,dflag] = spike_test(var,max_dV1,smoothing_factor,plot_fac)

    if nargin<4
        smoothing_factor = 3;
        plot_fac =0;
    end
    if nargin<2
        max_dV1 = 3;

    end
    
    dflag = 0*var;
    var_ds = var;
    for i = 1:length(var(1,:))
        v = var(:,i);
        vs = medfilt1(v,smoothing_factor); % smoothed timeseries
        pg = 1:length(v);
    
    
        res_vs = abs(v-vs);
        thrsh = max_dV1*std(res_vs,'omitnan');
        id = res_vs>thrsh;
        var_ds(id,i)=NaN;
        idn = ~isnan(var_ds(:,i));
        max_gap = mean(diff(pg(idn)));
%         var_ds(:,i)=interp1gap(pg(idn),var_ds(idn,i),pg,max_gap*10);

%         nanid = isnan(v);
        dflag(id)=4;
        dflag(~id)=1;

        
        if plot_fac==1
            figure(1);hold on
            plot(v,-pg,':k')
            plot(var_ds(:,i),-pg,'-r')
            plot(vs,-pg,'-b');
            plot(v(id),-pg(id),'*m')
            if ~exist('spike_plot', 'dir')
                mkdir('spike_plot')
            end
            save_figure(gcf,['./spike_plot/spike_test_',num2str(i)],[7.5 5],'.png','100')
            close all
        end

    end
end



%% Spike test
% dflag = NaN*v;
%     for i = 1:length(v(1,:))
%         temp = v(:,i);
%         id = find(~isnan(temp));
%         if length(id)>10
%             temp2 = temp(id);
%             for j = 2:length(id)-4
%             % ARGO Spike test  | V2 − (V3 + V1)/2 | − | (V3 − V1) / 2 |
%             dV = abs(temp2(j)-(temp2(j+1)+temp2(j-1))/2)...
%                 -abs((temp2(j+1)-temp2(j-1))/2);
%                 if dV>max_dV1
%                     dflag(j-1:j+4,i)=4;
% %                     dflag(j,i)=4;
% %                     dflag(j+1,i)=4;
%                 end
%             end
% %             temp(id) = temp2;
%         end
% %         v(:,i) = temp;
%     end
% end