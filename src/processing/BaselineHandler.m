classdef BaselineHandler
    properties
        gnss 
        base
        rover
        tCommon
        satsCommon
        sessions
    end
    properties (Access = private)
        phaseObs
    end
    methods
        function obj = BaselineHandler(obsrnx,sys)
            obj.gnss = sys;
            temp = obsrnx(1).keepGNSSs(sys);
            obj.base = temp.harmonizeObsWithSatpos();
            temp = obsrnx(2).keepGNSSs(sys);
            obj.rover = temp.harmonizeObsWithSatpos();
            obj.validateInputs();
            
            % Harmonize Base and Rover times and satellites
            [obj.base, obj.rover] = obj.base.harmonizeWith(obj.rover,'HarmonizeObsTypes',true);
            obj.tCommon = datetime(obj.base.t(:,9),'ConvertFrom','datenum');
            obj.satsCommon = obj.base.sat.(sys);
            
            % Get common phase observation types (we can select just from
            % base, since obsTypes are already harmonized via harmonizeWith method)
            ot = obj.base.obsTypes.(obj.gnss);
            obj.phaseObs = ot(cellfun(@(x) strcmp(x(1),'L'),ot));
            
            % Find reference satellite and prepare sessions
            obj.sessions = obj.getSessionsByMaxElevation();
            %obj.sessions = obj.getSessionsByInterval(900,30);
        end
        function sessions = getSessionsByMaxElevation(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Prepare session structure, which comprise information about
            % the reference satellite (sat with maximum elevation), available
            % slave satellites and corresponding time indices
            %
            % Output:
            % sessions(n,1) struct with fields:
            %    .id - session identifier (order number, starts from 1)
            %    .refSat - satellite number (as in RINEX, not index)
            %    .slaveSats - slave's satellite numbers
            %    .idxRange - index range (indices valid for obs.tCommon
            %    .from
            %    .to - from and to are timestamps of corresponding idxRange
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Get elevation of all simultaneously observed satellites
            satsElevBase = cell2mat(cellfun(@(x) x(:,1),obj.base.satpos.local,'UniformOutput',false));
            satsElevRover = cell2mat(cellfun(@(x) x(:,1),obj.rover.satpos.local,'UniformOutput',false));
            satsElevBase(satsElevBase == 0) = nan;
            satsElevRover(satsElevRover == 0) = nan;
            satsElevation = (satsElevBase + satsElevRover)/2;
            
            % Find satellite with maximum elevation
            [~,idxSatMaxElev] = max(satsElevation,[],2);
            maxSatChangeIdx = find(diff(idxSatMaxElev) ~= 0) + 1;
            maxSatIdxs = [[1; maxSatChangeIdx], [maxSatChangeIdx-1; numel(obj.tCommon)]];
            
            % Create output structure and fill it
            sessions = repmat(struct('id',[],'refSat',[],'slaveSats',[],'idxRange',[],'from',datetime(),'to',datetime()),[size(maxSatIdxs,1),1]);
            for i = 1:size(maxSatIdxs,1)
                sessions(i).id = i;
                sessions(i,1).refSat = obj.base.sat.(obj.gnss)(idxSatMaxElev(maxSatIdxs(i,1)));
                sessions(i,1).idxRange = maxSatIdxs(i,1):maxSatIdxs(i,2);
                sessions(i,1).from = datetime(obj.tCommon(maxSatIdxs(i,1)));
                sessions(i,1).to = datetime(obj.tCommon(maxSatIdxs(i,2)));
                availableSats = obj.base.sat.(obj.gnss)(sum(~isnan(satsElevation(sessions(i,1).idxRange,:)),1) ~= 0);
                sessions(i,1).slaveSats = setdiff(availableSats,sessions(i,1).refSat);
            end
        end
        function sessions = getSessionsByInterval(obj,minRefSatDurationInSeconds,minSlaveSatDurationInSeconds)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Prepare session structure, which comprise information about
            % the reference satellite (sat with maximum mean elevation),
            % during given  session period. Minimal period duration is
            % controlled via "minRefSatDurationInSeconds" input variable. 
            % Option "minSlaveSatDurationInSeconds" is available to restrict
            % slave satellites in given session according observation count.
            %
            % Inputs (optional):
            % minRefSatDurationInSeconds (default: 900 seconds)
            %    - minimal session duration in seconds. Session can be longer
            %      (merging more sessions into longer one with the same 
            %      reference satellite)
            %
            % minSlaveSatDurationInSeconds (default: 30 seconds)
            %    - minimal observation period in seconds to assign observed
            %      satellite among slaveSats
            %
            % Output:
            % sessions(n,1) struct with fields:
            %    .id - session identifier (order number, starts from 1)
            %    .refSat - satellite number (as in RINEX, not index)
            %    .slaveSats - slave's satellite numbers
            %    .idxRange - index range (indices valid for obs.tCommon
            %    .from
            %    .to - from and to are timestamps of corresponding idxRange
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if nargin < 3
                minSlaveSatDurationInSeconds = 30;
                if nargin < 2
                    minRefSatDurationInSeconds = 900;
                end
            end
            validateattributes(minRefSatDurationInSeconds,{'double'},{'scalar'},2)
            
            satsElevBase = cell2mat(cellfun(@(x) x(:,1),obj.base.satpos.local,'UniformOutput',false));
            satsElevRover = cell2mat(cellfun(@(x) x(:,1),obj.rover.satpos.local,'UniformOutput',false));
            satsElevBase(satsElevBase == 0) = nan;
            satsElevRover(satsElevRover == 0) = nan;
            satsElevation = (satsElevBase + satsElevRover)/2;
            
            % Derive sampling and get minimal reference sat epoch count
            sampling = mode(seconds(diff(obj.tCommon)));
            refSatEpochCount = minRefSatDurationInSeconds/sampling;
            slaveSatEpochCount = minSlaveSatDurationInSeconds/sampling;
            
            % Get approximate sessions
            fullIntervalsCount = floor(numel(obj.tCommon)/refSatEpochCount);
            ses_temp = repmat(struct('refSat',[],'slaveSats',[],'idxRange',[]),[fullIntervalsCount,1]);
            for i = 1:fullIntervalsCount
                if i ~= fullIntervalsCount
                    idxRange = (refSatEpochCount*(i-1) + 1):(refSatEpochCount*i);
                else
                    idxRange = (refSatEpochCount*(i-1) + 1):numel(obj.tCommon);
                end
                ses_temp(i).idxRange = idxRange;
                meanElevInInterval = mean(satsElevation(idxRange,:));
                [~,idxMax] = max(meanElevInInterval);
                ses_temp(i).refSat = obj.satsCommon(idxMax);
                ses_temp(i).slaveSats = setdiff(obj.satsCommon(sum(~isnan(satsElevation(idxRange,:)))>=slaveSatEpochCount),ses_temp(i).refSat);
            end
            
            % Merge sessions with same refSat into bigger ones
            refSatChangedSessionIdx = find(diff([ses_temp.refSat]) ~= 0);
            sessionsIdx = [[1; (refSatChangedSessionIdx+1)'],[refSatChangedSessionIdx'; fullIntervalsCount]];
            Nsessions = size(sessionsIdx,1);
            sessions = repmat(struct('id',[],'refSat',[],'slaveSats',[],'idxRange',[],'from',datetime(),'to',datetime()),[Nsessions,1]);
            for i = 1:Nsessions
                sessions(i).id = i;
                sessions(i).refSat = ses_temp(sessionsIdx(i,1)).refSat;
                sessionsIdxRange = sessionsIdx(i,1):sessionsIdx(i,2);
                sessions(i).slaveSats = unique(cell2mat({ses_temp(sessionsIdxRange).slaveSats}));
                sessions(i).idxRange = cell2mat({ses_temp(sessionsIdxRange).idxRange});
                sessions(i).from = obj.tCommon(sessions(i).idxRange(1));
                sessions(i).to = obj.tCommon(sessions(i).idxRange(end));
            end
        end
        function dd = getDD(obj,phases,units)
            if nargin < 3
                units = 'cycles';
                if nargin < 2
                    phases = obj.phaseObs;
                end
            end
            validateattributes(phases,{'cell'},{'size',[1,nan]},2)
            assert(all(cellfun(@(x) length(x)==3 & isa(x,'char'),phases)),'Measurement''s identifier has to comply rules according RINEX3 format! (three chars)')
            assert(all(cellfun(@(x) strcmp(x(1),'C') | strcmp(x(1),'L'),phases)),'Only phase or code measurement are valid as input for DD computation!')
            mustBeMember(phases,obj.phaseObs)
            mustBeMember(units,{'cycles','meters'})
            refSatUnitFactor = ones(1,numel(phases));
            slaveSatUnitFactor = ones(1,numel(phases));
            nPhases = numel(phases);
            
            maxSatNo = max([[obj.sessions.refSat]'; [obj.sessions.slaveSats]']);
            dd = cell(1,nPhases);
            dd(:) = {nan(numel(obj.tCommon),maxSatNo)};
            for i = 1:numel(obj.sessions)
                refSat = obj.sessions(i).refSat;
                if strcmp(units,'meters')
                    refSatUnitFactor = cellfun(@(x) getWavelength(obj.gnss,str2double(x(2)),refSat),phases);
                end
                
                % Compute single difference for reference satellite
                oBaseRefsat = obj.base.getObservation(obj.gnss,refSat,phases,obj.sessions(i).idxRange).*refSatUnitFactor;
                oRoverRefsat = obj.rover.getObservation(obj.gnss,refSat,phases,obj.sessions(i).idxRange).*refSatUnitFactor;
                oBaseRefsat(oBaseRefsat == 0) = nan;
                oRoverRefsat(oRoverRefsat == 0) = nan;
                sdRef = oRoverRefsat - oBaseRefsat;
                
                % Compute single difference for slave satellite and
                % subsequently compute double difference
                for slaveSat = obj.sessions(i).slaveSats
                    if strcmp(units,'meters')
                        slaveSatUnitFactor = cellfun(@(x) getWavelength(obj.gnss,str2double(x(2)),slaveSat),phases);
                    end
                    oBaseSlave = obj.base.getObservation(obj.gnss,slaveSat,phases,obj.sessions(i).idxRange).*slaveSatUnitFactor;
                    oRoverSlave = obj.rover.getObservation(obj.gnss,slaveSat,phases,obj.sessions(i).idxRange).*slaveSatUnitFactor;
                    oBaseSlave(oBaseSlave == 0) = nan;
                    oRoverSlave(oRoverSlave == 0) = nan;
                    sdSlave = oRoverSlave - oBaseSlave;
                    for phaseIdx = 1:nPhases
                        dd{phaseIdx}(obj.sessions(i).idxRange,slaveSat) = sdSlave(:,phaseIdx) - sdRef(:,phaseIdx);
                    end
                end
            end
        end
        function ddres = getDDres(obj,phases,units,tryFixDDresCS)
            narginchk(2,4)
            if nargin < 4
                tryFixDDresCS = false;
                if nargin < 3
                    units = 'cycles';
                    if nargin < 2
                        phases = obj.phaseObs;
                    end
                end
            end
            validateattributes(phases,{'cell'},{'size',[1,nan]},2)
            assert(all(cellfun(@(x) length(x)==3 & isa(x,'char'),phases)),'Input cell has to consist of valid phase or code measurement identifier!')
            assert(all(cellfun(@(x) strcmp(x(1),'C') | strcmp(x(1),'L'),phases)),'Only phase or code measurement are valid as input for DD computation!')
            mustBeMember(phases,obj.phaseObs)
            mustBeMember(units,{'cycles','meters'})
            refSatUnitFactor = 1;
            nPhases = numel(phases);
            slaveSatUnitFactor = ones(1,nPhases);
            
            % Get observation double differences
            dd = obj.getDD(phases,units);
            
            % Get slant distance double differences (refers to obj.base.recpos and obj.rover.recpos)
            maxSatNo = max([[obj.sessions.refSat]'; [obj.sessions.slaveSats]']);
            ddres = cell(1,nPhases);
            ddres(:) = {nan(numel(obj.tCommon),maxSatNo)};
            for i = 1:numel(obj.sessions)
                refSat = obj.sessions(i).refSat;
                if strcmp(units,'cycles')
                    refSatUnitFactor = cellfun(@(x) 1/getWavelength(obj.gnss,str2double(x(2)),refSat),phases);
                end
                [~,~,rBaseRefsat] = obj.base.getLocal(obj.gnss,refSat,obj.sessions(i).idxRange);
                [~,~,rRoverRefsat] = obj.rover.getLocal(obj.gnss,refSat,obj.sessions(i).idxRange);
                rBaseRefsat(rBaseRefsat == 0) = nan;
                rRoverRefsat(rRoverRefsat == 0) = nan;
                rsdRef = (rRoverRefsat - rBaseRefsat).*refSatUnitFactor;
                
                % Compute single and double slant range differences
                for slaveSat = obj.sessions(i).slaveSats
                    if strcmp(units,'cycles')
                        slaveSatUnitFactor = cellfun(@(x) 1/getWavelength(obj.gnss,str2double(x(2)),slaveSat),phases);
                    end
                    [~,~,rBaseSlave] = obj.base.getLocal(obj.gnss,slaveSat,obj.sessions(i).idxRange);
                    [~,~,rRoverSlave] = obj.rover.getLocal(obj.gnss,slaveSat,obj.sessions(i).idxRange);
                    rBaseSlave(rBaseSlave == 0) = nan;
                    rRoverSlave(rRoverSlave == 0) = nan;
                    rsdSlave = (rRoverSlave - rBaseSlave).*slaveSatUnitFactor;
                    
                    % Compute range double difference
                    rdd = rsdSlave - rsdRef;
                    %figure; plot(rdd,'.-','DisplayName','dd range'); hold on; plot(dd{1}(obj.sessions(i).idxRange,1),'.-','DisplayName','dd phase'); legend();
                    for phaseIdx = 1:nPhases
                        ddres{phaseIdx}(obj.sessions(i).idxRange,slaveSat) = dd{phaseIdx}(obj.sessions(i).idxRange,slaveSat) - rdd(:,phaseIdx);
                        %figure; plot(ddres{phaseIdx}(obj.sessions(i).idxRange,slaveSat)); title(sprintf('ref: %.0f, slave: %.0f',refSat,slaveSat))
                        if tryFixDDresCS
                            %dd_to_correct = ddres{phaseIdx}(obj.sessions(i).idxRange,slaveSat)/1;
                            ddresWithCSfixed = BaselineHandler.fixCSinDDres(ddres{phaseIdx}(obj.sessions(i).idxRange,slaveSat));
                            ddres{phaseIdx}(obj.sessions(i).idxRange,slaveSat) = ddresWithCSfixed;
                        end
                    end
                end
            end
        end
    end
    methods (Access = private)
        function validateInputs(obj)
            if isempty(obj.base.satpos) || isempty(obj.rover.satpos)
                error('ValidationError:NotValidObservationStruct','Empty observation struct is not allowed as input!')
            end
            if isempty(obj.base.satpos) || isempty(obj.rover.satpos)
                error('ValidationError:NotValidSATPOS','Empty SATPOS is not allowed as input!')
            end
        end
    end
    methods (Static)
        function ddresFixed = fixCSinDDres(ddRes)
            % Require ddRes to be in cycles!
            N = round(ddRes);
            diffToMostFrequentN = mode(N) - N ;
            ddresFixed = ddRes + diffToMostFrequentN;
            
            %figure
            %plot(ddRes,'.')
            %hold on;
            %plot(ddresFixed,'ro')
        end 
    end
end