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
[gpsw, gpss] = greg2gps([2019 03 20 00 00 00;
                         2019 03 20 00 00 02]);
satpos = SATPOS('G',[1,2,5],'precise','../data/eph',[gpsw, gpss]);


