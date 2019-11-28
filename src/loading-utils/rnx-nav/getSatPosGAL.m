function [pos,aux] = getSatPosGAL(GPStime,eph)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute position of Galileo satellites using set of broadcast
% parameters according to Galileo OS SIS ICD document.
%
% Input:  GPStime - [n x 2] matrix of [GPSWeek, GPSSecondOfWeek] moments
%         eph     - [42 x 1] ephemeris structure as outputed by function
%                   "loadRINEXNavigation.m"
%
% Output: pos     - [n x 3] matrix containing sat. coordinates [X, Y, Z]
%         aux     - [n x 8] matrix with auiliary vars from computations
%                 - aux = [tk,Mk,Ek,vk,uk,rk,ik,lamk];
%
% Peter Spanik, 21.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Assigning eph values to variables
TOE      = eph(23);
a        = eph(22);
ecc      = eph(20);
Delta_n  = eph(17);
M0       = eph(18);
Omega0   = eph(25);
DOmega   = eph(30);
omega    = eph(29);
i0       = eph(27);
Di       = eph(31);
CRS      = eph(16); 
CRC      = eph(28); 
CIS      = eph(26); 
CIC      = eph(24); 
CUS      = eph(21); 
CUC      = eph(19); 

% Loading GPS constants, set parameters of computation
const      = getBroadcastConstants('E');
tol_Kepler = 0.001;  % Criterion to stop Kepler equation in arcseconds

% Argument of ephemeris in seconds
% (Be carefull, GPS week jumps are accepted!)
tk = GPStime(:,2) - TOE;
tk(tk < 0) = tk(tk < 0) + 604800;

% Mean daily motion
n0 = sqrt(const.GM*a^-3);
n = n0 + Delta_n;

% Mean anomaly (have to be in range <0, 2*pi>)
Mk = mod(M0 + n*tk, 2*pi);

% Eccentrix anomaly - solve Kepler equation
Ek = Mk;
for d = 1:length(Mk)
    Ek(d) = kepler(ecc, Mk(d), tol_Kepler);
end
Ek = mod(Ek, 2*pi);

% Testing correctness of Ek computation
if max(abs(Ek - ecc.*sin(Ek) - Mk)) > tol_Kepler*(pi/648000)
    error('Kepler equation not computed correct values !!!');
end

% True anomaly
vk = mod(atan2(sqrt(1 - ecc^2)*sin(Ek), cos(Ek) - ecc), 2*pi);

% Approximate radius
r0k = a.*(1 - ecc*cos(Ek));

% Approximate argument of declination
Phik = mod(vk + omega, 2*pi);

% Computation of correction terms
delta_uk = CUC.*cos(2*Phik) + CUS.*sin(2*Phik);
delta_rk = CRC.*cos(2*Phik) + CRS.*sin(2*Phik);
delta_ik = CIC.*cos(2*Phik) + CIS.*sin(2*Phik);

% Argument of declination, radius, orbit inclination
uk = mod(Phik + delta_uk, 2*pi);
rk = r0k + delta_rk;
ik = i0 + Di*tk + delta_ik;

% Posiotionin orbital plane
xDash = rk.*cos(uk);
yDash = rk.*sin(uk);

% Longitude of ascending node
Omega = Omega0 + (DOmega - const.wE)*tk - const.wE*TOE;
Omega = mod(Omega, 2*pi);

% ECEF X,Y,Z coordinates
X = xDash.*cos(Omega) - yDash.*cos(ik).*sin(Omega);
Y = xDash.*sin(Omega) + yDash.*cos(ik).*cos(Omega);
Z = yDash.*sin(ik);
pos = [X, Y, Z];

% Auxiliary utput variables
aux = [tk,Mk,Ek,vk,uk,rk,ik,Omega];
