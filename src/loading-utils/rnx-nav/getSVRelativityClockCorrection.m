function relClockCorr = getSVRelativityClockCorrection(satsys,a,ecc,Ek)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute relativistic clock correction for SV clock for GPS,
% Galileo and Beidou navigation satellites.
%
% References:
% * GPS Interface Specification IS-GPS-200H (p. 96)
% * Galileo Open Service - Signal-In-Space Interface Control Document (p. 47)
% * BeiDou Navigation Satellite System Signal In Space Interface Control Document (p. 30)
%
% Input:
% satsys = satellite system specifier (one of 'GEC')
% a - [1x1] semi-major axis of orbital ellipse (meters)
% ecc - [1x1] eccentricity of orbital ellipse (unitless)
% E - [nx1] eccentric anomaly (in degrees)
%
% Output:
% relClockCorr - [nx1] array of SV clock relativity correction in seconds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch satsys
    case 'G'
        F = -4.442807633e-10; % GPS
    case {'E','C'}
        F = -4.442807309e-10; % Galileo, Beidou
    otherwise
        error('Function can only give results for GPS,Galileo and Beidou satellites!');
end
relClockCorr = F*ecc*sqrt(a).*sind(Ek);
