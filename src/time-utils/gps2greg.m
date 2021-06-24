function gregTime = gps2greg(gpstime)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to convert GPS Week number and GPS second of week to gregorian
% date representation (Year,month,day,hour,minute,second).
%
% Peter Spanik, 3.8.2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gpsWeek = gpstime(:,1);
gpsSecond = gpstime(:,2);

GPSTstart = datenum([1980 1 6 0 0 0]);
matlabTime = GPSTstart + gpsWeek*7 + gpsSecond/86400;
gregTime = datevec(matlabTime);

