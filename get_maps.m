%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course :  Multimedia Data Security                 %
% Project:  Second competition - get_maps script     %
% Group name: beermark                               %
% Group members: Stefano Branchi; Federico Brugiolo; %
%                Matteo Malacarne; Asia Salvaterra   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear all;
start_time = cputime;

%% Set the forged image folder
fdsPath = uigetdir();
fdsInfo = dir(fdsPath);
tifFiles = dir([fdsPath filesep '*.tif']);
jpgFiles = dir([fdsPath filesep '*.jpg']);
files = [tifFiles; jpgFiles];
len = length(files);

%% Run get_map function
for i = 1:len
    get_map(strcat(fdsPath, '/', files(i).name));
end

%% Execution time log
stop_time = cputime;
tot_time = abs(start_time - stop_time);
fprintf('\nExecution time = %.5fsec\n', tot_time);
