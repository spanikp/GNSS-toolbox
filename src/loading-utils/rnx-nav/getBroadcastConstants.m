function const = getBroadcastConstants(satsys)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function defining constants for given GNSS.
%
% Input:  satsys - character defining GNSS system (e.g. 'R')
% Output: const - structure with the following fields:
%           .GM - geocentric gravitational constant (m^3*s^-2)
%           .wE - angular rotation of Earth (rad*s^-1)
%           .a - major-axis of Earth ellipsoid (m)
%           .e - numeric eccentricity of ellipsoid (-)
%           .f - flattening of Earth ellipsoid (-)
%
% Peter Spanik, 8.5.2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch satsys
    case 'G'
        const.GM  = 3.986005e14;
        const.wE  = 7.2921151467e-5;
        const.a   = 6378137;
        const.e   = 0.0818191908426215;
        const.f   = 1/298.257223563;
        
    case 'R'
        const.GM  = 3.9860044e14;
        const.wE  = 7.292115e-5;
        const.a   = 6378136;
        const.C20 = -1082.63e-6;
        
    case 'E'
        const.GM  = 3.986004418e14;
        const.wE  = 7.2921151467e-5;
        const.a   = 6378137;
        
    case 'C'
        const.GM  = 3.986004418e14;
        const.wE  = 7.292115e-5;
        const.a   = 6378137;
        const.f   =  1/298.257222101;
end
