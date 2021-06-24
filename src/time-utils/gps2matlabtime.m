function matlabTime = gps2matlabtime(gpstime)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to convert GPS Week number and GPS second of week to MATLAB
% internal time representation (days since year 0, 0:00:00).
%
% Peter Spanik, 3.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gpsWeek = gpstime(:,1);
gpsSecond = gpstime(:,2);

GPSTstart = datenum([1980 1 6 0 0 0]);
matlabTime = GPSTstart + gpsWeek*7 + gpsSecond/86400;
