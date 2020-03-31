function [gpsWeek, gpsSecond] = getGPSTimeBetween(GPSTimeFrame,interval)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return GPS week, DOY and DOW of all days which lies between dates
% defined in input matrix timeFrame
%
% Input:
% timeFrame - [2,2] matrix of [gpsWeek1, gpsSecond1;
%                              gpsWeek2, gpsSecond2]
% interval - interval between GPS time samples (in seconds)
%
% Output:
% gpsWeek - GPS week for all moments between GPSTime1 and GPSTime2
% gpsSecond - GPS second for all moments between GPSTime1 and GPSTime2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validateattributes(GPSTimeFrame,{'numeric'},{'size',[2,2]},1);
validateattributes(interval,{'scalar','numeric'},{'nonnegative'},2);

% Check if day2 is after day1
if gps2matlabtime(GPSTimeFrame(2,:)) <= gps2matlabtime(GPSTimeFrame(1,:))
    error('Second moment is not after first moment, please check order!')
end
 
GPSWeekRel = GPSTimeFrame(2,1) - GPSTimeFrame(1,1);
GPSSecondsStart = GPSTimeFrame(1,2);
GPSSecondsEnd = GPSWeekRel*604800 + GPSTimeFrame(2,2);
GPSSecondsBetween = (GPSSecondsStart:interval:GPSSecondsEnd)';
gpsWeek =  GPSTimeFrame(1,1) + floor(GPSSecondsBetween/604800);
gpsSecond = rem(GPSSecondsBetween,604800);
