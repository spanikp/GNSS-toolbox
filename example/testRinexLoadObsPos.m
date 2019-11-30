close all
clear
clc

addpath(genpath('../src'))

jab1file = '../test/data/JAB1080M.19o';

param = OBSRNX.getDefaults();
param.filtergnss = 'GREC';

% First time run (load from RINEX)
jabBroadcast = OBSRNX(jab1file,param);
jabBroadcast = jabBroadcast.computeSatPosition('broadcast');
jabBroadcast.saveToMAT('../test/data/JAB1080M_ephBrdc.mat');
jabPrecise = OBSRNX(jab1file,param);
jabPrecise = jabPrecise.computeSatPosition('precise');
jabPrecise.saveToMAT('../test/data/JAB1080M_ephPrecise.mat');

% % Possible second run: load from MAT
% jabBroadcast = OBSRNX.loadFromMAT('../test/data/JAB1080M_ephBrdc.mat');
% jabPrecise = OBSRNX.loadFromMAT('../test/data/JAB1080M_ephPrecise.mat');

% Comparison of broadcast and precise satellite positions
% Consider that Broadcast positions are related to APC, while precise
% positions are related to satellite CoM!
clc
for j = 1:numel(jabBroadcast.gnss)
    sp1 = jabBroadcast.satpos(j);
    sp2 = jabPrecise.satpos(j);
    commonSats = intersect(sp1.satList,sp2.satList);
    fprintf('\n===== Satellite system: %s =====\n',jabBroadcast.gnss(j))
    for i = 1:numel(commonSats)
        prn = commonSats(i);
        selSat1 = sp1.satList == prn;
        selSat2 = sp2.satList == prn;
        x1 = sp1.ECEF{selSat1}(:,1);
        x2 = sp2.ECEF{selSat2}(:,1);
        fprintf('Sat %s%02d max diff: %.3f m\n',sp1.gnss,prn,max(abs(x1-x2)));
    end
end

% Extract any measurement
% Available observations: jabPrecise.header.obsTypes.(gnss)
satNo = 10;
R1 = jabPrecise.getObservation('G',satNo,'C1C');
L1 = jabPrecise.getObservation('G',satNo,'C1C');
L2 = jabPrecise.getObservation('G',satNo,'C2W');
L5 = jabPrecise.getObservation('G',satNo,'C5X');

