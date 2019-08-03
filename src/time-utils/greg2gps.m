function [gpsweek, tow, doy, dow] = greg2gps(time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute GPS week number, second of week, DOY and DOW from
% time given in year, month, day, hour, minute, second format.
%
% Input: time - [n x 6] matrix containing columns
%               [year, month, day, hour, minute, second]
%
% Output: gpstime - [n x 4] matrix containing columns
%                   [gpsweek, tow, doy, dow]
%
% Note: Input time has to be in GPST (defaults in RINEX)
%
% Peter Spanik, 23.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute julian date
JD = juliandate(datetime(time(:,1),time(:,2),time(:,3)));

% Compute GPS time
gpsweek = floor((JD - 2444244.5)/7);
dow = JD - (2444244.5 + gpsweek*7);
tow = dow*86400 + time(:,4)*3600 + time(:,5)*60 + time(:,6);
doy = JD - juliandate(time(:,1),1,1) + 1;

% Output
gpstime = [gpsweek, tow, doy, dow];