close all
clear
clc
addpath(genpath('../src'))

jab1file = '../data/JAB1080M.19o';

param = OBSRNX.getDefaults();
param.filtergnss = 'GE';

% First time run (load from RINEX)
jab1 = OBSRNX(jab1file);
jab1.saveToMAT();

% Load from MAT
%jab1 = OBSRNX.loadFromMAT('../data/JAB1080M.mat');

% Prepare broadcast eph data
timeFrame = jab1.t([1,end],1:3);
prepareEph(jab1.gnss,'broadcast','../data/brdc',timeFrame)
