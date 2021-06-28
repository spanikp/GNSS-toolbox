close all
clear
clc
addpath(genpath(fullfile(userpath,'GNSS-toolbox/src')));

% Load RINEX observation file
obsrnx = OBSRNX('../test/data/IonoCalculationExample/COM4_Today_13_00_2021_com.obs');

% Set receiver position (I do not know this and I put here place in Paris just for example.
% Keep in mind that definition of your receiver position will affect elevation/azimuth computation!
fi = 48.872747; % Geodetic coordinates of sample point in Paris
la = 2.4452513;
h = 100;
[x,y,z] = geodetic2ecef(referenceEllipsoid('wgs84'),fi,la,h,'degrees');
obsrnx.recpos = [x,y,z];

% Compute satellite position using broadcast ephemeris
obsrnx = obsrnx.computeSatPosition('broadcast');

% Define frequencies for GPS L1
f0 = 10.23e6;
f1 = 154*f0;
c = 299792458;

% Get all observed satellite list
sats_available = obsrnx.sat.G;

% Loop through available satellites
for iSat = 1:length(sats_available)
    % Get satellite for which we want to compute observation combination
    satNo = sats_available(iSat);
    
    % Get phase/pseudorange observations (you may change observation type
    % identifiers if needed: C1C, L1C, ...)
    C1 = obsrnx.getObservation('G',satNo,'C1C');
    L1 = obsrnx.getObservation('G',satNo,'L1C');
    L2 = obsrnx.getObservation('G',satNo,'L2X');
    
    % Replace zero values (not available observation at given time by NaN values)
    % This is needed, since by default zeros are assigned to not-measured values at given time.
    L1(L1 == 0) = nan;
    L2(L2 == 0) = nan;

    % Get elevation of satellite
    elev = obsrnx.getLocal('G',satNo); % These values has no meaning because I set imaginary receiver position!
    
    % Compute combination and make a plot
    if any(~isnan(L1)) && any(~isnan(L2))
        lambda1 = (c/f1); % Get wavelength of GPS L1
        I_rel = L1*lambda1 - C1; % Compute L1 - C1 difference (or any combination you want to do, e.g. TEC/STEC)
        
        % Note: see that L1 is multiplied by lambda1. This is needed to
        % combine phase measurements with code measurements. Phase
        % measurements are stored in RINEX in cycles, while range
        % measurements are strored in meters. For that reason conversion
        % from cycles to loops with wavelength multiplication is needed!
        
        % Make plot
        figure;
        plot(elev,I_rel,'.-');
        xlabel('Elevation (degrees)');
        ylabel('L1C - C1C (m)');
        title(sprintf('L1C - C1C for satellite G%02d',satNo));
    else
        % Raise warning for satellites which has not dual-frequency
        % measurements available
        warning(sprintf('Dual frequency observations available for G%02d',satNo));
    end
end


% Make skyplot with different color for each satellite
sp = Skyplot(); % Initialize Skyplot object
cols = lines(length(sats_available)); % Define colors for available satellites
for iSat = 1:length(sats_available)
    satNo = sats_available(iSat);
    [elev,azi] = obsrnx.getLocal('G',satNo); % Get elevation/azimuth for satellite
    satColor = cols(iSat,:);
    sp = sp.addPlot(elev,azi,sprintf('G%02d',satNo),'.',satColor);
    firstValidValue = find(elev ~= 0,1,'first');
    [xLabel,yLabel] = Skyplot.getCartFromPolar(sp.R,elev(firstValidValue),azi(firstValidValue));
    text(xLabel,yLabel,sprintf('G%02d',satNo),'Color',satColor);
end
legend off % Turn on/off legend


% Make default skyplot (all sats same color, but added names next to satellite paths)
% sp2 = obsrnx.makeSkyplot('G',true); legend off;





