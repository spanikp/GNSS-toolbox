function [pos,aux] = getSatPosGPS(GPStime,eph)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute position of GPS satellites using set of broadcast
% parameters according to GPS ICD document.
%
% Input:  GPStime - [n x 2] matrix of [GPSWeek, GPSSecondOfWeek] format
%         eph     - [42 x 1] ephemeris structure as outputed by function
%                   "loadRINEXNavigation.m"
%
% Output: pos     - [n x 3] matrix containing sat. coordinates [X, Y, Z]
%         aux     - [n x 8] matrix with auiliary vars from computations
%                 - aux = [tk,Mk,Ek,vk,uk,rk,ik,lamk];
%
% Peter Spanik, 16.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Assigning eph values to variables
TOE      = eph(23);
WEEKNo   = eph(33);
a        = eph(22);
ecc      = eph(20);
Delta_n  = eph(17);
M0       = eph(18);
Omega    = eph(25);
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
const      = getBroadcastConstants('G');
tol_Kepler = 0.00001;  % Criterion to stop Kepler equation in arcseconds

% Argument of ephemeris in seconds (GPS week jumps are accepted!)
tk = GPStime(:,2) - TOE;
if nnz(GPStime(:,1) ~= WEEKNo) ~= 0
    selWeekNo_isBefore_tk = GPStime(:,1) < WEEKNo;
    tk(selWeekNo_isBefore_tk) = tk(selWeekNo_isBefore_tk) - 604800;
    selWeekNo_isAfter_tk = GPStime(:,1) > WEEKNo;
    tk(selWeekNo_isAfter_tk) = tk(selWeekNo_isAfter_tk) + 604800;
end

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

% Longitude of ascending node
lamk = Omega + (DOmega - const.wE)*tk - const.wE*TOE;
lamk = mod(lamk, 2*pi);

% ECEF X,Y,Z coordinates
pos = [rk.*(cos(lamk).*cos(uk) - sin(lamk).*sin(uk).*cos(ik)),...
       rk.*(sin(lamk).*cos(uk) + cos(lamk).*sin(uk).*cos(ik)),...
       rk.*sin(uk).*sin(ik)];
   
% Auxiliary utput variables
aux = [tk,Mk,Ek,vk,uk,rk,ik,lamk];
