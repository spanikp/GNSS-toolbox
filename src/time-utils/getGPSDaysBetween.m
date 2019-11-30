function [gpsWeek, doy, dow, dt] = getGPSDaysBetween(timeFrame,extendDays)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return GPS week, DOY and DOW of all days which lies between dates
% defined in input matrix timeFrame
%
% Input:
% timeFrame - [2,3] matrix of [day1Year, day1Month, day1Day;
%                              day2Year, day2Month, day2Day]
% 
% Optional:
% extendDays - number of days to extend timeFrame (default=0)
%
% Output:
% gpsWeek - GPS week of all days which lies between day1 and day2
% doy - DOY of all days which lies between day1 and day2
% dow - DOW of all days which lies between day1 and day2
% dt - datetime object of all days which lies between day1 and day2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validateattributes(timeFrame,{'numeric'},{'size',[2,3]},1);
if nargin == 1
    extendDays = 0;
end
validateattributes(extendDays,{'scalar','numeric'},{'nonnegative'},2);

% Extent input timeFrame by one day
t = datetime(timeFrame) + extendDays*[-day(1); day(1)];
timeFrame = datevec(t);
timeFrame = timeFrame(:,1:6);

% Check if day2 is after day1
if datenum(timeFrame(2,:)) <= datenum(timeFrame(1,:))
    warning('Second day is before first day, output will be empty arrays!')
end

% Time conversions
mTime = datenum(timeFrame(1,:)):1:datenum(timeFrame(2,:));
dt = datetime(mTime,'ConvertFrom','datenum')';
[y,m,d] = ymd(dt); [hh,mm,ss] = hms(dt);
[gpsWeek, ~, doy, dow] = greg2gps([y,m,d,hh,mm,ss]);