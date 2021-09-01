function [gpsWeek, gpsSecond] = yearDoySecond2gps(t_year,t_doy,t_second)

validateattributes(t_year,{'double'},{'size',[nan,1]},1);
validateattributes(t_doy,{'double'},{'size',[nan,1]},2);
validateattributes(t_second,{'double'},{'size',[nan,1]},3);
assert(isequal(size(t_year),size(t_doy)),'Inputs has to have same dimensions!');
assert(isequal(size(t_year),size(t_second)),'Inputs has to have same dimensions!');

t_size = size(t_year);
[gpsWeek, gpsSecond] = greg2gps([t_year, ones(t_size), t_doy, zeros(t_size), zeros(t_size), t_second]);