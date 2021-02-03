close all
clear
clc

addpath(genpath(fullfile(pwd(),'../src')));

% Specify folders with navigation messages and SP3 files
brdcFolder = fullfile(pwd(),'../test/data/brdc');
ephFolder = fullfile(pwd(),'../test/data/eph');

% Set time and satellite number used for comparison
t = [2019,3,21,14,15,18];
satNo = containers.Map({'G','R','E','C'},[1,1,7,14]); % Present in both brdc and eph
[gpsWeekNo,gpsDow] = greg2gps(t);

gnsses = 'GREC';
for i = 1:length(gnsses)
    gnss = gnsses(i);

    % Get position from broadcast ephemeris
    sp_brdc = SATPOS(gnss,satNo(gnss),'broadcast',brdcFolder,[gpsWeekNo,gpsDow]);
    xyz_brdc = sp_brdc.ECEF{1};

    % Get position from precise ephemeris
    sp_precise = SATPOS(gnss,satNo(gnss),'precise',ephFolder,[gpsWeekNo,gpsDow]);
    xyz_precise = sp_precise.ECEF{1};
    
    % Compute total difference
    differences(i) = sqrt(sum((xyz_brdc-xyz_precise).^2));
end




