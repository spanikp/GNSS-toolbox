close all
clear
clc

addpath(genpath('../src'))

% % Load SP3 file - multiple GNSS
% eph = SP3({'../data/COD0MGXFIN_20190790000_01D_05M_ORB.SP3',...
%           '../data/COD0MGXFIN_20190800000_01D_05M_ORB.SP3'},300,'G');
% eph.saveToMAT('../data/testEphMulti.mat');
% 
% % Load SP3 file - single GNSS
% eph = SP3({'../data/COD0MGXFIN_20190790000_01D_05M_ORB.SP3',...
%           '../data/COD0MGXFIN_20190800000_01D_05M_ORB.SP3'},900,'G');
% eph.saveToMAT('../data/testEphG.mat');
% 
% % Load SP3 file - single GNSS
% eph = SP3({'../data/COD0MGXFIN_20190790000_01D_05M_ORB.SP3',...
%           '../data/COD0MGXFIN_20190800000_01D_05M_ORB.SP3'},900,'GR');
% eph.saveToMAT('../data/testEphGR.mat');

% Loading from MAT file
%eph = SP3.loadFromMAT('../data/testEphMulti.mat');

% Test SATPOS with precise ephemeris
d = (datetime(2019,03,21,0,0,0):seconds(60):datetime(2019,03,21,23,0,0))';
[gpsw, gpss] = greg2gps([year(d),month(d),day(d),hour(d),minute(d),second(d)]);
satposG = SATPOS('G',[1,2,5],'precise','../test/data/eph',[gpsw, gpss]);
satposR = SATPOS('R',[1,2,5],'precise','../test/data/eph',[gpsw, gpss]);

% GPS plot
figure
crdOrder = {'X_{ECEF}','Y_{ECEF}','Z_{ECEF}'};
for i = 1:3
    plot(d,satposG.ECEF{3}(:,i),'DisplayName',crdOrder{i})
    hold on; grid on; box on;
end
ylabel('Coordinates (m)')
legend()
title('Satellite G05 ECEF coordinates of CoM')

% GLONASS plot
figure
for i = 1:3
    plot(d,satposR.ECEF{3}(:,i),'DisplayName',crdOrder{i})
    hold on; grid on; box on;
end
ylabel('Coordinates (m)')
legend()
title('Satellite R05 ECEF coordinates of CoM')

