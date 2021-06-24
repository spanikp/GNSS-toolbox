function clockCorr = getSVClockCorrection(t,toc,aPoly)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute SV clock correction according the:
%
% clockCorr = a0 + a1*(t-toc) + a2*(t-toc)^2
%
% Input:
% t - [nx2] array of [GPSweek, GPSsecond] when we want to get SV clock corr
% toc - [1x2] array of [GPSweek, GPSsecond] of reference time for SV clock
%       correction computation
% aPoly - SV clock corr. polynomial [a0, a1, a2]
%
% Output:
% clockCorr - [nx1] array of SV clock correction in seconds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if there is no week rollover
deltaWeek = t(:,1) - toc(1);
weekRolloverSel = deltaWeek ~= 0;
t(weekRolloverSel,2) = t(weekRolloverSel,2) + deltaWeek(weekRolloverSel)*604800;

% Get relatie time and compute correction
dT = t(:,2) - toc(2);
clockCorr = aPoly(1) + aPoly(2)*dT + aPoly(3)*dT.^2;

