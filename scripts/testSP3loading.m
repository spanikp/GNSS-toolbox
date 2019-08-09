close all
clear
clc

addpath(genpath('../src'))

% Load SP3 file
tic
eph = SP3({'../data/COD0MGXFIN_20190790000_01D_05M_ORB.SP3',...
           '../data/COD0MGXFIN_20190790000_01D_05M_ORB.SP3',...
           '../data/COD0MGXFIN_20190800000_01D_05M_ORB.SP3'},900);
toc

