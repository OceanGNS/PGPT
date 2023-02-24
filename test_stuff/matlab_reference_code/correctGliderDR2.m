
%% Compute the corrected gps locations
%inputs is an already formated glider struct according to 
% 
% glider.time=datag(:,sensor_lookupg.m_present_time);
% glider.lat=datag(:,sensor_lookupg.m_lat);
% glider.lon=datag(:,sensor_lookupg.m_lon);
% glider.dr_state=datag(:,sensor_lookupg.x_dr_state);
% glider.gps_lat=datag(:,sensor_lookupg.m_gps_lat);
% glider.gps_lon=datag(:,sensor_lookupg.m_gps_lon);

%this code cannot have any dbd files where the mission aborted or the
%indexing will get messed up

% dr_state
% out, mission_start=0, underwater=1,awaiting_fix=2,
%      awaiting_postfix=3, awaiting_dive=4
%i_search = find(~isnan(dr_state));

function [glider ap] = correctGliderDR2(glider)




%dr dive location
%lat/lon index for transition from 4->1
index.i_si=find(diff(glider.dr_state.^2)~=0);
index.i_start= index.i_si(find(diff(diff(glider.dr_state(index.i_si).^2))==18));


for ki = 1:length(index.i_start)
     while(isnan(glider.lon(index.i_start(ki))))
         index.i_start(ki) = index.i_start(ki) +1;
     end
end

%gps location at surface
%transition from 2->3
index.i_end = find(diff(glider.dr_state.^2)==5);
for ki = 1:length(index.i_end)
     while(isnan(glider.lon(index.i_end(ki))) && isnan(glider.gps_lon(index.i_end(ki))))
         index.i_end(ki) = index.i_end(ki) +1;
     end
end

%DR location after surfacing
%transition from 1->2
index.i_mid = find(diff(glider.dr_state.^2)==3);
for ki = 1:length(index.i_mid)
     while(isnan(toDD(glider.lon(index.i_mid(ki)))))
         index.i_mid(ki) = index.i_mid(ki) -1;
     end
end  


glider.t_start= glider.time(index.i_start);
    
glider.lon_dif = toDD(glider.lon(index.i_end))-toDD(glider.lon(index.i_mid));
glider.lat_dif = toDD(glider.lat(index.i_end))-toDD(glider.lat(index.i_mid));
glider.t_dif = glider.time(index.i_mid)-glider.time(index.i_start);

glider.vlonDD=glider.lon_dif./glider.t_dif;
glider.vlatDD=glider.lat_dif./glider.t_dif;
glider.loncDD=toDD(glider.lon(1));
glider.latcDD=toDD(glider.lat(1));
index.ap=1;

for i=1:length(index.i_start)
    a = index.i_start(i)+(find(~isnan(glider.lon(index.i_start(i):index.i_mid(i)))))-1;
    index.ap = [index.ap;a];
    ti = glider.time(a) - glider.time(a(1));
    glider.loncDD = [glider.loncDD; (toDD(glider.lon(a)) + ti.*glider.vlonDD(i))];
    glider.latcDD = [glider.latcDD; (toDD(glider.lat(a)) + ti.*glider.vlatDD(i))];
end

ap = index.ap;
glider.lonDD = toDD(glider.lon(index.ap));
glider.latDD = toDD(glider.lat(index.ap));
glider.gps_lonDD = toDD(glider.gps_lon(2:end));
glider.gps_latDD = toDD(glider.gps_lat(2:end));

end

function [dd] = toDD (x)

dd = sign(x).*(floor(abs(x)./100)+ mod(abs(x),100)./60);

end
