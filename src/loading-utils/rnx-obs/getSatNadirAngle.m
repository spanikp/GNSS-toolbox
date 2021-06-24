function nadir_angle = getSatNadirAngle(el,gnss)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute satellite nadir angle pointing from sat to user.
%
% Input:  el - sat elevation angle in local system (deg)
%         gnss - satellite system identificator (G,R,E,C allowed)
%
% Output: nadir_angle - nadir angle in (deg)
%
% Usage: getSatNadirAngle(el,'G')
%
% Reference: Steigenberger, Peter, Steffen Thoelert, Oliver Montenbruck: 
% GNSS Satellite Transmit Power and Its Impact on Orbit Determination.
% Journal of Geodesy, November 11, 2017. doi.org/10.1007/s00190-017-1082-2.
%
% Peter Spanik, 25.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RE = 6378137;
switch gnss
    case 'G'
        RS = 20200e3 + RE;
    case 'R'
        RS = 19100e3 + RE;
    case 'E'
        RS = 23200e3 + RE;
    case 'C'
        RS = 21528e3 + RE;
    otherwise
        error('Not known satellite system!')
end

nadir_angle = asind(sind(el + 90).*RE./RS);
