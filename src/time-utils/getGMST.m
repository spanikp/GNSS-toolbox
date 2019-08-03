function ThetaG0 = getGMST(YMD)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute Greenwich mean sidereal time (GMST) for particular
% day specified by [year, month, day].
% 
% For control see astronomic table: 
%
% http://www.igik.edu.pl/pl/geodezja-i-geodynamika-rocznik-astronomiczny
%
% Input:  YMD - [1 x 3] array containing [year, month, day] of UTC/UT1 moment
%
% Output: ThetaG0 - Greenwich mean sidereal time in radians
%
% Peter Spanik, 18.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

JD = juliandate(datetime(YMD(:,1),YMD(:,2),YMD(:,3)));
Tu = (JD -  2451545.0)/36525;

ThetaG0 = (6*3600 + 41*60 + 50.5481) + 8640184.812866*Tu + 0.0931104*Tu.^2 - (6.2e-6)*Tu.^3; % in seconds
ThetaG0 = (rem(ThetaG0,86400)/86400)*2*pi; % in radians
