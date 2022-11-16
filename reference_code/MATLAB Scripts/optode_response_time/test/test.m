% add functions in parent folder
addpath(genpath('../'))

% load example pressure, time, and oxygen data
% data are real profiling float data from the GOMRI deployment in the
% northern Gulf of Mexico in
load('example_data.mat','P','T','DO')

% population of tau values
tau = calculate_tau(T, P, DO, 'tres', 5);

% display results
fprintf('Number of profiles analyzed: %d\n', size(T, 1))
fprintf('Number of time constants found: %d\n', numel(tau))
fprintf('Median response time: %3.1f, standard deviation %3.3f\n', median(tau), std(tau))
