classdef SATPOS
    properties
        % gnss specify sat system (one of 'GREC')
        gnss (1,1) char
        
        % ephType specify if broadcast or precise ephemeris files will be
        % used for sat coordinates calculation
        ephType (1,:) char {mustBeMember(ephType,{'broadcast','precise'})} = 'broadcast';
        
        % ephFolder is path to folder with bradcast/precise ephemeris files
        ephFolder (1,:) char
        
        % ephList comprise list of files which will be loaded for sat
        % coordinates calculation
        ephList (1,:) cell
        
        % satList is array of sats which cordinates will be calculated
        satList (1,:) double

        % gpstime define epochs which will be used for sat position
        % calculation. gpstime are moments in GPS time system specified as:
        % gpstime = [GPSWeek,GPSSecond]
        gpstime (:,2) double
        
        % ECEF contains Earth-centered-Earth-fixed coordinates of sats
        % ECEF{i} is [N,3] matrix with: [X,Y,Z] in meters
        ECEF (1,:) cell
        
        % localRefPoint is topocentrum given in ECEF coordinates (meters)
        localRefPoint (1,3) double = [0,0,0]
        
        % satTimeFlags represents satellite/epochs in which given sat has at least
        % one observation
        % - rows represents epochs (specified in gpstime)
        % - columns represents sats according satList array
        satTimeFlags (:,:) logical
        
        % SVclockCorr - satellite clock correction at given timestamps
        % which takes into account also relativistic correction (in sec.)
        SVclockCorr (1,:) cell

        % local property contains local frame spherical coordinates of sats
        % local{i} is [N,3] matrix with: [elevation,azimuth,slant range]
        % (N is number of rows of gpstime property, units: degrees, meters)
        local (1,:) cell
    end
    
    methods
        function obj = SATPOS(gnss,satList,ephType,ephFolder,gpstime,localRefPoint,satTimeFlags,obsrnxLeapSeconds)
            if ~exist('localRefPoint','var'), localRefPoint = nan(1,3); end
            if nargin > 0
                obj.gnss = gnss;
                obj.satList = satList;
                obj.ephType = ephType;
                obj.ephFolder = fullpath(ephFolder);
                obj.gpstime = gpstime;
                if nargin < 8
                    leapSecondsStartStop = getLeapSeconds([gpstime(1,:);gpstime(end,:)]);
                    if leapSecondsStartStop(2) ~= leapSecondsStartStop(1)
                        error('Computation not design to make computation when number of leap second change! Code needs to be adapted!');
                    else
                        obsrnxLeapSeconds = leapSecondsStartStop(1);
                    end
                end
                if nargin < 7
                    obj.satTimeFlags = true(size(gpstime,1),numel(satList));
                else
                    obj.satTimeFlags = satTimeFlags;
                end
                    
                timeFrame = gps2greg(gpstime([1,end],:));
                timeFrame = timeFrame(:,1:3);
                
                obj.ephList = prepareEph(gnss,ephType,ephFolder,timeFrame);
                switch ephType
                    case 'broadcast'
                        brdc = loadRINEXNavigation(obj.gnss,obj.ephFolder,obj.ephList);
                        brdc = checkEphStatus(brdc);
                        
                        % Check if LEAP SECOND value is provided
                        if ~exist('obsrnxLeapSeconds','var') && isempty(brdc.hdr.leapSeconds) && strcmp(brdc.gnss,'R')
                            error('Leap seconds not provided!')
                        end
                        
                        % Check if given sat and sat in brdc corresponds
                        selSatNotPresent = ~ismember(obj.satList,brdc.sat);
                        if any(selSatNotPresent)
                            notPresentSats = obj.satList(selSatNotPresent);
                            warning('Following sats are of %s system are not present in ephemeris: %s\nThese satellites will be removed from further processing.',obj.gnss,strjoin(strsplit(num2str(notPresentSats)),','))
                            obj.satList = obj.satList(~selSatNotPresent);
                            obj.satTimeFlags = obj.satTimeFlags(:,~selSatNotPresent);
                        end
                        if isempty(obj.satList)
                            warning('No satellites to process! Program will end.')
                            return
                        end
                        
                        % Take number of leap second from navigation RINEX header (case of RINEX v2) or use value from
                        % observation RINEX header section (LEAP SECONDS element is not mandatory in navigation RINEX v3)
                        [obj.ECEF,~,obj.SVclockCorr] = SATPOS.getBroadcastPosition(obj.satList,obj.gpstime,brdc,obj.localRefPoint,obj.satTimeFlags,obsrnxLeapSeconds);

                    case 'precise'
                        fileListToLoad = cellfun(@(x) fullfile(obj.ephFolder,x),obj.ephList,'UniformOutput',false);
                        eph = SP3(fileListToLoad,900,gnss);
                        selSatNotPresent = ~ismember(obj.satList,eph.sat.(obj.gnss));
                        if any(selSatNotPresent)
                            notPresentSats = obj.satList(selSatNotPresent);
                            warning('Following sats of %s system are not present in ephemeris: %s\n         Coordinates for these satellites will not be computed!',obj.gnss,strjoin(strsplit(num2str(notPresentSats)),','))
                            obj.satList = obj.satList(~selSatNotPresent);
                            obj.satTimeFlags = obj.satTimeFlags(:,~selSatNotPresent);
                        end
                        if isempty(obj.satList)
                            warning('No satellites to process! Program will end.')
                            return
                        end
                        [obj.ECEF, ~, obj.SVclockCorr] = SATPOS.getPrecisePosition(obj.satList,obj.gpstime,eph,obj.localRefPoint,obj.satTimeFlags);
                end
                
                % Trigger computation of local coordinates by assignment of localRefPoint property
                if any(~isnan(localRefPoint))
                    obj.localRefPoint = localRefPoint;
                end
            end
        end
        function obj = set.localRefPoint(obj,localRefPoint)
            validateattributes(localRefPoint,{'numeric'},{'size',[1,3]},2)
            if all(localRefPoint == 0) || (localRefPoint(1) == 0 && localRefPoint(2) == 0)
                warning('Unable to compute local coordinates for given localRefPoint! Property "localRefPoint" not set!');
            else
                obj.localRefPoint = localRefPoint;
                obj = obj.getLocal();
            end
        end
        function [x,y,z] = getECEF(obj,satNo,indices)
            validateattributes(satNo,{'double'},{'scalar','positive'},1);
            x = []; y = []; z = [];
            satIdx = obj.satList == satNo;
            if any(satIdx)
                ecef = obj.ECEF(satIdx);
                if nargin < 3
                    indices = 1:size(ecef{1},1);
                end
                xyz = ecef{1}(indices,:);
                x = xyz(:,1); y = xyz(:,2); z = xyz(:,3);
            else
                warning('ECEF coordinates for %s%02d are not available!',obj.gnss,satNo);
            end
        end
    end
    methods (Access = private)
        function obj = getLocal(obj,assumeTravelTime)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Method to re-calculate local sat position (ele,azi,r)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if nargin < 2
                assumeTravelTime = false;
            end
            validateattributes(assumeTravelTime,{'logical'},{'scalar'},2);
            if assumeTravelTime
                assert(strcmp(obj.ephType,'precise'),'Travel time compensation available only for precise ephemeris!');
            end
            dbg = dbstack();
            if ~ismember('OBSRNX.loadFromMAT',{dbg.name}')
                fprintf('>>> Computing satellite positions (local) >>>\n')
                obj.local = cell(1,numel(obj.satList));
                obj.local(:) = {zeros(size(obj.gpstime,1),3)};
                if ~isequal(obj.localRefPoint,[0 0 0])
                    ell = referenceEllipsoid('wgs84');
                    [lat0,lon0,h0] = ecef2geodetic(obj.localRefPoint(1),obj.localRefPoint(2),obj.localRefPoint(3),ell,'degrees');
                    
                    % Load original satellite positions
                    if assumeTravelTime
                        switch obj.ephType
                            case 'broadcast'
                                error('Not implemented')
                            case 'precise'
                                eph = SP3(fullfile(obj.ephFolder,obj.ephList),900,obj.gnss);
                        end
                    end
                    
                    for i = 1:numel(obj.satList)
                        satNo = obj.satList(i);
                        fprintf(' -> computing satellite %s%02d ',obj.gnss,obj.satList(i));
                        timeSel = sum(obj.ECEF{i},2) ~= 0;
                        if assumeTravelTime
                            mTimeWanted = gps2matlabtime(obj.gpstime(timeSel,:));
                            x = obj.ECEF{i}(timeSel,1); xr = obj.localRefPoint(1);
                            y = obj.ECEF{i}(timeSel,2); yr = obj.localRefPoint(2);
                            z = obj.ECEF{i}(timeSel,3); zr = obj.localRefPoint(3);
                            slantRange = sqrt((x-xr).^2 + (y-yr).^2 + (z-zr).^2);
                            mTravelTime = (slantRange/2.99792458e8)/86400;
                            switch obj.ephType
                                case 'broadcast'
                                    error('Not implemented')
                                case 'precise'
                                    [x,y,z] = eph.interpolatePosition(obj.gnss,satNo,mTimeWanted-mTravelTime);
                            end
                            [azi,elev,slantRange] = ecef2aer(x,y,z,lat0,lon0,h0,ell);
                        else
                            [azi,elev,slantRange] = ecef2aer(obj.ECEF{i}(timeSel,1),...
                                obj.ECEF{i}(timeSel,2),...
                                obj.ECEF{i}(timeSel,3),...
                                lat0,lon0,h0,ell);
                        end
                        obj.local{i}(timeSel,:) = [elev,azi,slantRange];
                        fprintf('(done)\n');
                    end
                end
            end
        end 
    end
    methods (Static)
        function [ECEF, local, SVclockCorr] = getBroadcastPosition(satList,gpstime,brdc,localRefPoint,satTimeFlags,leapSeconds)
            validateattributes(satList,{'double'},{'nonnegative'},1)
            validateattributes(gpstime,{'double'},{'size',[NaN,2]},2)
            validateattributes(brdc,{'struct'},{},3)
            if nargin < 6
                leapSecondsStartStop = getLeapSeconds(gpstime);
                if leapSecondsStartStop(2) ~= leapSecondsStartStop(1)
                    error('Computation not design to make computation when number of leap second change! Code needs to be adapted!');
                else
                    leapSeconds = leapSecondsStartStop(1);
                end
                if nargin < 5
                   satTimeFlags = true(size(gpstime,1),numel(satList));
                   if nargin < 4
                      localRefPoint = [0,0,0];
                   end
                end
            end
            validateattributes(localRefPoint,{'double'},{'size',[1,3]},4)
            validateattributes(satTimeFlags,{'logical'},{'size',[size(gpstime,1),numel(satList)]},5)
            validateattributes(leapSeconds,{'double'},{'scalar'},6);
                
            satsys =  brdc.gnss;
            fprintf('\n############################################################\n')
            fprintf('### Computing satellite position for %s system (BROADCAST) ##\n',satsys)
            fprintf('############################################################\n')

            % Allocate satellite position (satpos) cells
            ECEF = cell(1,numel(satList));
            local = cell(1,numel(satList));
            SVclockCorr = cell(1,numel(satList));
            ECEF(:) = {zeros(size(gpstime,1),3)};
            local(:) = {zeros(size(gpstime,1),3)};
            SVclockCorr(:) = {zeros(size(gpstime,1),1)};
            
            % Looping throught all satellites in observation file
            fprintf('>>> Computing satellite positions (ECEF) >>>\n')
            selSatNotPresent = ~ismember(satList,brdc.sat);
            if any(selSatNotPresent)
                notPresentSats = satList(selSatNotPresent);
                warning('Following sats of %s system are not present in ephemeris: %s\nThese satellites will be removed from further processing.',satsys,strjoin(strsplit(num2str(notPresentSats)),','))
                satList = satList(~selSatNotPresent);
                satTimeFlags = satTimeFlags(:,~selSatNotPresent);
            end
            if isempty(satList)
                warning('No satellites to process! Program will end.')
                return 
            end
            nSats = length(satList);
            for i = 1:nSats
                PRN = satList(i);
                fprintf(' -> computing satellite %s%02d ',satsys,PRN);
                
                % Selection of only non-zero epochs
                PRNtimeSel = satTimeFlags(:,i);
                selEph = brdc.sat == PRN;
                if sum(selEph) == 0
                    fprintf('(skipped - missing ephemeris for satellite)\n');
                    continue;
                end
                
                PRNephAll = brdc.eph{selEph};
                %ecef = zeros(nnz(PRNtimeSel),3);
                
                % Time variables
                GPSTimeWanted = gpstime(PRNtimeSel,:);
                mTimeWanted   = gps2matlabtime(GPSTimeWanted);
                mTimeGiven    = PRNephAll(11,:)';
                
                % In case of GLONASS -> change mTimeWanted to UTC.
                % Values of mTimeGiven are from BRDC message and these are already in UTC timescale.
                % Also value of GPS week and GPS second of week will be transformed to UTC time.
                if satsys == 'R'
                    mTimeWanted   = mTimeWanted - leapSeconds/86400;
                    GLOTimeWanted = GPS2UTCtime(GPSTimeWanted,leapSeconds);
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
                    
                    % Select function according to satellite system and
                    % compute sat position, clock offsets and relativity
                    % correction
                    switch satsys
                        case 'G'
                            [ecef,aux] = getSatPosGPS(GPStime,eph);
                            clockPolyCorr = getSVClockCorrection(GPStime,eph(7:8)',eph(12:14)');
                            clockRelativisticCorr = getSVRelativityClockCorrection(satsys,eph(22),eph(20),rad2deg(aux(:,3)));
                        case 'R'
                            GLOtime = GLOTimeWanted(selTime,:);
                            ecef = getSatPosGLO(GLOtime,eph)';
                            % Relativistic correction for GLONASS is
                            % included in polynomial coefficients
                            clockPolyCorr = getSVClockCorrection(GLOtime,eph(7:8)',[eph(12:13);0]');
                            clockRelativisticCorr = zeros(size(GLOtime,1),1);
                        case 'E'
                            [ecef,aux] = getSatPosGAL(GPStime,eph);
                            clockPolyCorr = getSVClockCorrection(GPStime,eph(7:8)',eph(12:14)');
                            clockRelativisticCorr = getSVRelativityClockCorrection(satsys,eph(22),eph(20),rad2deg(aux(:,3)));
                        case 'C'
                            BDStime = BDSTimeWanted(selTime,:);
                            [ecef,aux] = getSatPosBDS(BDStime,eph);
                            clockPolyCorr = getSVClockCorrection(BDStime,eph(7:8)',eph(12:14)');
                            clockRelativisticCorr = getSVRelativityClockCorrection(satsys,eph(22),eph(20),rad2deg(aux(:,3)));
                    end
                    clockCorr = clockPolyCorr + clockRelativisticCorr;
                    
                    % Put selected time results to output
                    temp = ECEF{i}(PRNtimeSel,:);
                    temp(selTime,:) = ecef;
                    ECEF{i}(PRNtimeSel,:) = temp;
                    temp = SVclockCorr{i}(PRNtimeSel,:);
                    temp(selTime,:) = clockCorr;
                    SVclockCorr{i}(PRNtimeSel,:) = temp; 
                    
                    % Compute azimuth, alevation and slant range
                    if ~isequal(localRefPoint,[0 0 0])
                        ell = referenceEllipsoid('wgs84');
                        [lat0,lon0,h0] = ecef2geodetic(localRefPoint(1),localRefPoint(2),localRefPoint(3),ell,'degrees');
                        [azi,elev, slantRange] = ecef2aer(ecef(:,1),ecef(:,2),ecef(:,3),lat0,lon0,h0,ell);
                        temp = local{i}(PRNtimeSel,:);
                        temp(selTime,:) = [elev, azi, slantRange];
                        local{i}(PRNtimeSel,:) = temp;
                    end
                end

                if sum(sum([ECEF{i}, local{i}])) ~= 0
                    fprintf('(done)\n');
                end
            end
            
%             % Clear ECEF, local cells -> remove satellites without computed position
%             selNotComputedPositions = cellfun(@(x) sum(sum(x)) == 0, ECEF);
%             obsrnx.satpos.(satsys)(selNotComputedPositions) = [];
%             obsrnx.sat.(satsys)(selNotComputedPositions) = [];
%             obsrnx.obs.(satsys)(selNotComputedPositions) = [];
%             obsrnx.obsqi.(satsys)(selNotComputedPositions) = [];

        end
        function [ECEF, local, SVclockCorr] = getPrecisePosition(satList,gpstime,eph,localRefPoint,satTimeFlags)
            validateattributes(satList,{'double'},{'nonnegative'},1)
            validateattributes(gpstime,{'double'},{'size',[NaN,2]},2)
            validateattributes(eph,{'SP3'},{'size',[1,1]},3)
            if nargin < 4
                localRefPoint = [0,0,0];
                satTimeFlags = true(size(gpstime,1),numel(satList));
            elseif nargin < 5
                satTimeFlags = true(size(gpstime,1),numel(satList));
            end
            validateattributes(localRefPoint,{'double'},{'size',[1,3]},4)
            validateattributes(satTimeFlags,{'logical'},{'size',[size(gpstime,1),numel(satList)]},5)
                
            satsys =  eph.gnss;
            assert(numel(satsys)==1,'Method "SATPOS.getPrecisePosition" is limited to run with single satellite system!');
            fprintf('\n############################################################\n')
            fprintf('#### Computing satellite position for %s system (PRECISE) ###\n',satsys)
            fprintf('############################################################\n')

            % Allocate satellite position (satpos) cells
            ECEF = cell(1,numel(satList));
            local = cell(1,numel(satList));
            SVclockCorr = cell(1,numel(satList));
            ECEF(:) = {zeros(size(gpstime,1),3)};
            local(:) = {zeros(size(gpstime,1),3)};
            SVclockCorr(:) = {zeros(size(gpstime,1),1)};
            
            % Looping throught all satellites in observation file
            fprintf('>>> Computing satellite positions (ECEF) >>>\n')
            selSatNotPresent = ~ismember(satList,eph.sat.(satsys));
            if any(selSatNotPresent)
                notPresentSats = satList(selSatNotPresent);
                warning('Following sats of %s system are not present in ephemeris: %s\nThese satellites will be removed from further processing.',...
                    satsys,strjoin(strsplit(num2str(notPresentSats)),','))
                satList = satList(~selSatNotPresent);
                satTimeFlags = satTimeFlags(:,~selSatNotPresent);
            end
            if isempty(satList)
                warning('No satellites to process! Program will end.')
                return 
            end
            nSats = length(satList);
            for i = 1:nSats
                PRN = satList(i);
                fprintf(' -> computing satellite %s%02d ',satsys,PRN);
                
                % Selection of only non-zero epochs
                PRNtimeSel = satTimeFlags(:,i);
                selEph = eph.sat.(satsys) == PRN;
                if nnz(selEph) == 0
                    fprintf('(skipped - missing ephemeris for satellite)\n');
                    continue;
                end
                
                % Make Lagrange 10-th order interpolation
                GPSTimeWanted = gpstime(PRNtimeSel,:);
                mTimeWanted   = gps2matlabtime(GPSTimeWanted);
                [x,y,z] = eph.interpolatePosition(satsys,PRN,mTimeWanted);
                clockOffset = eph.interpolateClocks(satsys,PRN,mTimeWanted,2);
                ECEF{i}(PRNtimeSel,:) = [x,y,z];
                SVclockCorr{i}(PRNtimeSel) = clockOffset;
                
                % Compute azimuth, alevation and slant range
                if ~isequal(localRefPoint,[0 0 0])
                    ell = referenceEllipsoid('wgs84');
                    [lat0,lon0,h0] = ecef2geodetic(localRefPoint(1),localRefPoint(2),localRefPoint(3),ell,'degrees');
                    [azi,elev,slantRange] = ecef2aer(x,y,z,lat0,lon0,h0,ell);
                    local{i}(PRNtimeSel,:) = [elev,azi,slantRange];
                end
                if sum(sum([ECEF{i}, local{i}])) ~= 0
                    fprintf('(done)\n');
                end
            end
        end
    end
end