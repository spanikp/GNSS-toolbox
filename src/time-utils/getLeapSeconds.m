function leapSeconds = getLeapSeconds(gpstime)
% leapSeconds seconds is number of between the GPS Epoch and utcTime(i,:)
% See IERS Bulletin C, https://hpiers.obspm.fr/iers/bul/bulc/bulletinc.dat  
leapSeconds = NaN(size(gpstime,1),1);
utcTable = [1982 1 1 0 0 0;
            1982 7 1 0 0 0;
            1983 7 1 0 0 0;
            1985 7 1 0 0 0;
            1988 1 1 0 0 0;
            1990 1 1 0 0 0;
            1991 1 1 0 0 0;
            1992 7 1 0 0 0;
            1993 7 1 0 0 0;
            1994 7 1 0 0 0;
            1996 1 1 0 0 0;
            1997 7 1 0 0 0;
            1999 1 1 0 0 0;
            2006 1 1 0 0 0;
            2009 1 1 0 0 0;
            2012 7 1 0 0 0;
            2015 7 1 0 0 0;
            2017 1 1 0 0 0];

mtimeGiven = gps2matlabtime(gpstime);
mtimeJumps = datenum(utcTable);
for i = 1:numel(mtimeGiven)
    leapSeconds(i) = find((mtimeGiven(i) - mtimeJumps) > 0,1,'last');
end