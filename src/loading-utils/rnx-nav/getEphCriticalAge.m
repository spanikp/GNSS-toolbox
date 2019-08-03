function ageCritical = getEphCriticalAge(satsys)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to simply return critical age of ephemeris which is no more
% accepted to compute broadcast ephemeris from.
% 
% Input:  satsys - satellite system identifier (one of 'GREC')
% Output: ageCritical - critical age of satellite ephemeris (in days)
%
% Peter Spanik, 24.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Following values were set empirically and can be changed
switch satsys % Set critical age of ephemeris
    case 'G'
        ageCritical = 2.1/24;
    case 'R'
        ageCritical = 0.8/24;
    case 'E'
        ageCritical = 1.5/24;
    case 'C'
        ageCritical = 2.5/24;
end