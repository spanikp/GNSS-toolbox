function [x_edge,y_edge] = getNoSatZone(GNSS,pos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function to get boundary of "satellite hole" in planar cartesian
% coordinates used for plotting. Boundary is relative to diameter of
% plotting area R = 100, which representing elevation range 90 degrees.
%
% Input:
% GNSS - satellite system identificator, one of 'GPS', 'GAL', 'BDS', 'GLO'
% pos - approximate ECEF position in meters
%
% Output:
% [x_edge,y_edge] - planar cartesian coordinates of satellite hole.
%                 - full elevation range (90 degrees) represent radius 100 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

deg = pi/180;
DELTA = (0:1:359)*deg;
R = 6378137;
try
    % If geodetic toolbox available
    [phi0,~,h0] = ecef2geodetic(pos(1),pos(2),pos(3),[R,sqrt(0.00669438002290)]);
catch
    [phi0,~,h0] = cartesianToGeodetic(pos(1),pos(2),pos(3),[R,sqrt(0.00669438002290)]);
end
lam0 = 0;

switch GNSS
    case 'GPS'
        INC = 55*deg;
        a = R + 20200000;
    case 'GAL'
        INC = 56*deg;
        a = R + 23000000;
    case 'BDS'
        INC = 55.5;
        a = R + 21150000;
    case 'GLO'
        INC = 64.8;
        a = R + 19100000;
    otherwise
        error('No supported system %s!',GNSS)
end

X_sat = a.*cos(INC).*cos(DELTA);
Y_sat = a.*cos(INC).*sin(DELTA);
Z_sat = ones(1,length(X_sat)).*a.*sin(INC);
try
    % If geodetic toolbox available
    [e,n,u] = ecef2enu(X_sat,Y_sat,Z_sat, phi0, lam0, h0, [R, sqrt(0.00669438002290)],'radians');
catch
    [e,n,u] = cartesianToLocalVertical(X_sat',Y_sat',Z_sat', phi0, lam0, h0, [R, sqrt(0.00669438002290)],'radians');
end
zenit = 90 - atan(u./sqrt(n.^2 + e.^2))/deg;
azimuth = atan2(e,n)*180/pi;
azimuth(azimuth<0) = azimuth(azimuth<0) + 360;

x_edge = zenit.*sin(azimuth*deg);
y_edge = zenit.*cos(azimuth*deg);

% Slightly change boundaries
x_edge = x_edge*0.95;
y_edgee = y_edge - mean(y_edge);
y_edgee = y_edgee*0.95;
y_edge = y_edgee + mean(y_edge);

% Control if edge is not out of pre-defined area
for i = 1:length(y_edge)
    if sqrt(y_edge(i)^2+x_edge(i)^2) > 95
        x_edge(i) = 94*sin(azimuth(i)*deg);
        y_edge(i) = 94*cos(azimuth(i)*deg);
    end
end

%figure
%plot(x_edge,y_edge)