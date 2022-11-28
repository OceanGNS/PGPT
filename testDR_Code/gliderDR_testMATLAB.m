
opts = delimitedTextImportOptions("NumVariables", 6);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["time", "lat", "lon", "dr_state", "gps_lat", "gps_lon"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double"];

% Specify file level properties
% opts.ExtraColumnsRule = "ignore";
% opts.EmptyLineRule = "read";

% Import the data
dat = readtable("glider_processing_scripts/glider_334_data.csv", opts);

glider.time=dat.time;
glider.lat=dat.lat;
glider.lon=dat.lon;
glider.dr_state=dat.dr_state;
glider.gps_lat=dat.gps_lat;
glider.gps_lon=dat.gps_lon;

clear dat opts
[glider , ap] = correctGliderDR2(glider);

figure; hold on
plot(glider.loncDD,glider.latcDD,'.') % corrected glider DR positions
plot(glider.lonDD,glider.latDD,'.')   % original glider DR positions
legend('corrected','original')
title('Unit\_334 Nov 1 - 7, Deploymnent Placentia Bay')
save_figure(gcf,'DRTestMatlab',[7.5 5],'.png','300')

