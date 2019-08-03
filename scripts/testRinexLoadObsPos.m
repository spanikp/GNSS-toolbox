close all
clear
clc

diary processing.log
addpath(genpath('../src'))

jab1file = '../data/JAB1080mM.19o';
jab1brdc = '../data/brdc';

param = OBSRNX.getDefaults();
param.filtergnss = 'GE';

% First time run (load from RINEX)
jab1 = OBSRNX(jab1file);
jab1 = jab1.computeSatPosition('broadcast');
jab1.saveToMAT();

% Load from MAT
%jab1 = OBSRNX.loadFromMAT('../data/JAB1080M.mat');
