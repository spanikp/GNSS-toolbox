function obsData = getBroadcastPosition(obsData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute position of satellites of satsys GNSS system using
% broadcast ephemeris. 
%
% Input:  satsys - satellite system identifier
%         obsData - observation structure as loaded by function "loadRINEXObservation.m"
%         # -> not neccessary: navData - navigation structure as loaded by "getBroadcastData.m"
%
% Output: obsData - observation structure updated with field "satpos"
%            .satpos: {1 x nSats}(nEpochs x 6) cell with following columns:
%              
%              1     2     3         4              5               6
%            [X(m), Y(m), Z(m), elevation(deg), azimuth(deg), slant-range(m)]
%
%                 - values are available only for epochs where at least one
%                   observation was recorded, otherwise line is null
%
% Peter Spanik, 17.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loading navigation
time_frame = [obsData.t(1,1:3);obsData.t(end,1:3)];

% Looping over all satellite systems in 
for sss = 1:length(obsData.gnss)
    satsys = obsData.gnss(sss);
    fprintf('\n############################################################\n')
    fprintf('##### Load and compute satellite position for %s system #####\n',satsys)
    fprintf('############################################################\n')
    
    % Load navigation data
    navData = getBroadcastData(satsys,time_frame);

    % Allocate satellite position (satpos) cells
    obsData.satpos.(satsys) = cell(1,length(obsData.sat.(satsys)));
    obsData.satpos.(satsys)(:) = {zeros(size(obsData.t,1),6)};
 
    % Looping throught all satellites in observation file
    fprintf('\n>>> Computing satellite positions >>>\n')
    nSats = length(obsData.sat.(satsys));
    for i = 1:nSats
        PRN = obsData.sat.(satsys)(i);
        fprintf(' -> computing satellite %s%02d ',satsys,PRN);
        
        % Selection of only non-zero epochs
        PRNtimeSel = logical(sum(obsData.obs.(satsys){i},2));
        selEph = PRN == navData.sat;
        if sum(selEph) == 0
            fprintf('(skipped - missing ephemeris for satellite)\n');
            continue;
        end
        
        PRNephAll  = navData.eph{selEph};
        pos        = zeros(sum(PRNtimeSel),6);
        
        % Time variables
        mTimeWanted   = obsData.t(PRNtimeSel,9);
        GPSTimeWanted = obsData.t(PRNtimeSel,7:8);
        mTimeGiven    = PRNephAll(11,:)';
        
        % In case of GLONASS -> change mTimeWanted to UTC.
        % Values of mTimeGiven are from BRDC message and these are already in UTC timescale.
        % Also value of GPS week and GPS second of week will be transformed to UTC time.
        if satsys == 'R'
            mTimeWanted   = mTimeWanted - navData.hdr.leapSeconds/86400;
            GLOTimeWanted = GPS2UTCtime(GPSTimeWanted,navData.hdr.leapSeconds);
        end
        
        % In case of BEIDOU/COMPASS -> change mTimeWanted to UTC at 1.1.2006.
        % Values of mTimeGiven are from BRDC message and these are already in UTC timescale.
        % Also value of GPS week and GPS second of week will be transformed to BDT time.
        if satsys == 'C'
            mTimeWanted   = mTimeWanted - 14/86400;
            BDSTimeWanted = GPS2UTCtime(GPSTimeWanted,14);
        end

        % Find previous epochs and throw error if there are NaN values
        ageCritical = getEphCriticalAge(satsys);
        [ephAge, idxEpoch] = getEphReferenceEpoch(satsys,mTimeWanted,mTimeGiven,ageCritical);
        if all(isnan(idxEpoch))
            fprintf('(skipped - missing previous ephemeris)\n');
            continue;
        else
            percNotSuitableEpochs = (sum(ephAge >= ageCritical)/length(ephAge))*100;
            if percNotSuitableEpochs ~= 0
                fprintf('(%.1f%% epochs not computed - old ephemeris age)',percNotSuitableEpochs)
            end
        end
        
        % Compute satellite position for group of intervals related to common ephemeris block
        uniqueIdxEpoch = unique(idxEpoch);
        uniqueIdxEpoch(isnan(uniqueIdxEpoch)) = [];
        for j = 1:length(uniqueIdxEpoch)
            selTime = uniqueIdxEpoch(j) == idxEpoch;
            GPStime = GPSTimeWanted(selTime,:);
            eph     = PRNephAll(:,uniqueIdxEpoch(j));
            
            % Select function according to satellite system
            switch satsys
                case 'G'
                    xyz = getSatPosGPS(GPStime,eph);
                case 'R'
                    GLOtime = GLOTimeWanted(selTime,:);
                    xyz = getSatPosGLO(GLOtime,eph)';
                case 'E'
                    xyz = getSatPosGAL(GPStime,eph);
                case 'C'
                    BDStime = BDSTimeWanted(selTime,:);
                    xyz = getSatPosBDS(BDStime,eph);
            end
            
            % Compute azimuth, alevation and slant range
            ell = referenceEllipsoid('wgs84');
            [lat0, lon0, h0]          = ecef2geodetic(obsData.approxPos(1),obsData.approxPos(2),obsData.approxPos(3),ell,'degrees');
            [azi,   elev, slantRange] = ecef2aer(xyz(:,1),xyz(:,2),xyz(:,3),lat0,lon0,h0,ell);
            pos(selTime,:) = [xyz, elev, azi, slantRange];
        end
        
        obsData.satpos.(satsys){i}(PRNtimeSel,:) = pos;
        if sum(sum(pos)) ~= 0
            fprintf('(done)\n');
        end
    end
    
    % Clear obsData.satpos.(satsys) cell -> remove satellites without computed position
    selNotComputedPositions = cellfun(@(x) sum(sum(x)) == 0, obsData.satpos.(satsys));
    obsData.satpos.(satsys)(selNotComputedPositions) = [];
    obsData.sat.(satsys)(selNotComputedPositions) = [];
    obsData.obs.(satsys)(selNotComputedPositions) = [];
    obsData.obsqi.(satsys)(selNotComputedPositions) = [];
end

