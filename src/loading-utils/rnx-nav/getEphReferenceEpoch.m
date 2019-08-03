function [ephAge, idxEpoch] = getEphReferenceEpoch(satsys,mTimeWanted,mTimeGiven,ageCritical)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to find index of the closest previous epoch to Matlab times in
% vector mTimeWanted. This is used to select correct ephemeris from set of
% broadcast ephemeris blocks. Function print warning to console if age o
% ephemeris is greater than 2.5  hours, but process it anyway.
%
% Input:  satsys      - char defining satellite system
%
%         mTimeWanted - [1 x n] datenum vector of moments when we want to 
%                       compute satellite positions, 
%
%         mTimeGiven  - [1 x m] datenum vector of moments when ephemeris
%                       blocks are available form navigation message.
%
%         ageCritical - critical age of ephemeris (in days). Can be set
%                       manually or value gathered from "getEphCriticalAge.m".
%
% Output: idxEpoch - [1 x n] vector containing indices of mTimeGiven values
%                    closest to particular elements in mTimeWanted.
%                  - vector is initialized to NaN vector. If no earlier
%                    epoch is found, than idxEpoch vector contain NaN.
%                    Vector also contain NaN values in case that closest
%                    previous epoch is older than given value of ageCritical.
%
%         ephAge   - argument of ephemeris -> moment - refEphemerisTime in
%                    days. Values are initialize to given ageCritical.
%
% Peter Spanik, 24.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% GPS, GALILEO and BEIDOU case <- find previous closest reference epoch
if strcmp(satsys,'G') || strcmp(satsys,'E') || strcmp(satsys,'C')
    
    % Initializing output index array
    idxEpoch = nan(size(mTimeWanted));
    ephAge   = ageCritical*ones(size(mTimeWanted));
    
    % Looping for all measurement moments
    for j = 1:length(mTimeWanted)
        deltaT = mTimeWanted(j) - mTimeGiven;
        if all(deltaT < 0)
            idxEpoch(j) = nan;
        else
            positiveDeltaT = deltaT(deltaT >= 0);
            if min(positiveDeltaT) > ageCritical
                idxEpoch(j) = nan;
                ephAge(j) = min(positiveDeltaT);
            else
                idxEpoch(j) = find(deltaT == min(positiveDeltaT));
                ephAge(j) = min(positiveDeltaT);
            end
        end
    end

%%%%% GLONASS case <- find closest epoch (forward and backward directions)
elseif strcmp(satsys,'R')

    % Initializing output index array
    idxEpoch = nan(size(mTimeWanted));
    ephAge   = ageCritical*ones(size(mTimeWanted));

    % Looping for all measurement moments
    for j = 1:length(mTimeWanted)
        deltaT = abs(mTimeWanted(j) - mTimeGiven);
        if all(deltaT > ageCritical)
            idxEpoch(j) = nan;
        else
            [ephAge(j), idxEpoch(j)] = min(deltaT);
        end
    end
end

