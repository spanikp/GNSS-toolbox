close all
clear
clc

addpath(genpath('../src'))

jab1file = '../data/JAB1080M.19o';

param = OBSRNX.getDefaults();
param.filtergnss = 'GREC';

% % First time run (load from RINEX)
% jabBroadcast = OBSRNX(jab1file,param);
% jabBroadcast = jabBroadcast.computeSatPosition('broadcast');
% jabBroadcast.saveToMAT('../data/testBroadcast.mat');
% jabPrecise = OBSRNX(jab1file,param);
% jabPrecise = jabPrecise.computeSatPosition('precise');
% jabPrecise.saveToMAT('../data/testPrecise.mat');

% Load from MAT
jabBroadcast = OBSRNX.loadFromMAT('../data/testBroadcast.mat');
jabPrecise = OBSRNX.loadFromMAT('../data/testPrecise.mat');

for j = 1:numel(jabBroadcast.gnss)
    sp1 = jabBroadcast.satpos(j);
    sp2 = jabPrecise.satpos(j);
    commonSats = intersect(sp1.satList,sp2.satList);
    for i = 1:numel(commonSats)
        prn = commonSats(i);
        selSat1 = sp1.satList == prn;
        selSat2 = sp2.satList == prn;
        x1 = sp1.ECEF{selSat1}(:,1);
        x2 = sp2.ECEF{selSat2}(:,1);
        fprintf('Sat %s%02d max diff: %.3f m\n',sp1.gnss,prn,max(abs(x1-x2)));
    end
end

