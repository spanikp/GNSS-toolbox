function UTCtime = GPS2UTCtime(GPStime, leapSeconds)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to perform transformation from GPS time defined by GPS week
% number and second of the week to UTC time realization. Basically, time
% will be just shifted by given number of leap seconds and following week
% rollovers will be corrected.
%
% Input:  GPStime - [n x 2] matrix of GPS time [GPSweek, GPSsecondOfWeek]
%         leapSeconds - number of GPS leap seconds (leap seconds since
%                    start of GPST)
%                     - can be used any number of leapseconds
%
% Output: UTCtime - [n x 2] matrix of UTC time
%
% Usage: GLOtime = GPS2UTCtime(GPStime, 18) -> in 2018
%        BDTtime = GPS2UTCtime(GPStime, 14) -> for all years ->
%                  delta(BDT,GPST) = 14s = constant
%
% Peter Spanik, 23.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

UTCtime = zeros(size(GPStime));
UTCtime(:,1) = GPStime(:,1);
UTCtime(:,2) = GPStime(:,2) - leapSeconds;

changeWeek = UTCtime(:,2) < 0;
UTCtime(changeWeek,1) = UTCtime(changeWeek,1) - 1;
UTCtime(changeWeek,2) = UTCtime(changeWeek,2) + 604800;
