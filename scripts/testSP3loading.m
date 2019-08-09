close all
clear
clc

addpath(genpath('../src'))

%% Load SP3 file
%eph = SP3({'../data/COD0MGXFIN_20190790000_01D_05M_ORB.SP3',...
%           '../data/COD0MGXFIN_20190800000_01D_05M_ORB.SP3'},900);
%eph.saveToMAT('../data/testEph.mat');
%clear

% Loading from MAT file
eph = SP3.loadFromMAT('../data/testEph.mat');

% Test SATPOS with precise ephemeris
[gpsw, gpss] = greg2gps([2019 03 20 00 00 00;
                         2019 03 20 00 00 02]);
satpos = SATPOS('G',[1,2,5],'precise','../data/eph',[gpsw, gpss]);


