function [ephAge,idxEphemeris] = getEphReferenceEpoch(satsys,mTimeWanted,mTimeGiven,ageCritical,brdcEphemerisComputationDirection)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to get index 
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

if nargin < 5, brdcEphemerisComputationDirection = 'backward'; end

validateattributes(satsys,{'char'},{'size',[1,1]},1);
mustBeMember(satsys,{'G','R','E','C'});
validateattributes(mTimeWanted,{'double'},{'size',[nan,1]},2);
validateattributes(mTimeGiven,{'double'},{'size',[nan,1]},3);
validateattributes(ageCritical,{'double'},{'size',[1,1],'nonnegative'},4);
validateattributes(brdcEphemerisComputationDirection,{'char'},{'size',[1,nan]},5);
mustBeMember(brdcEphemerisComputationDirection,{'backward','forward','closest'});

% Initializing output index array
idxEphemeris = nan(size(mTimeWanted));
ephAge = nan(size(mTimeWanted));

% If brdcEphemerisComputationDirection is different from both in case
% GLONASS then this needs to be retyped to 'both', since for GLONASS this
% is the way how satellite position should be computed according ICD.
if strcmp(satsys,'R'), brdcEphemerisComputationDirection = 'both'; end

% Looping through all required timestamps in mTimeWanted
for j = 1:length(mTimeWanted)
    dt = mTimeWanted(j) - mTimeGiven;
    dt(abs(dt) < 1e-9) = 0; % Handling numeric inacuracies due to usage of datenum
    switch brdcEphemerisComputationDirection
        case 'backward'
            selDirection = dt <= 0;
        case 'forward'
            selDirection = dt >= 0;
        case 'closest'
            selDirection = true(size(dt));
    end
    dt(~selDirection) = nan;
    selMinumum = abs(dt) == min(abs(dt));
    idxMin = find(selDirection & selMinumum);
    if ~isempty(idxMin)
        if abs(dt(idxMin(1))) < ageCritical % index 1 in idxMin(1) is used in case there are more ephemeris with same reference time
            ephAge(j) = dt(idxMin(1));
            idxEphemeris(j) = idxMin(1);
        end
    end
end


