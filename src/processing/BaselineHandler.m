classdef BaselineHandler
    properties
        gnss 
        base
        rover
        tCommon
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
            
            % Get common phase observation types (we can select just from
            % base, since obsTypes are already harmonized via harmonizeWith method)
            ot = obj.base.obsTypes.(obj.gnss);
            obj.phaseObs = ot(cellfun(@(x) strcmp(x(1),'L'),ot));
            
            % Find reference satellite
            obj.sessions = obj.getSessions();
        end
        function sessions = getSessions(obj)
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
            %mustBeMember(phases,obj.phaseObs)
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
                oBaseRefsat = obj.base.getObservation(obj.gnss,refSat,phases,obj.sessions(i).idxRange).*refSatUnitFactor;
                oRoverRefsat = obj.rover.getObservation(obj.gnss,refSat,phases,obj.sessions(i).idxRange).*refSatUnitFactor;
                oBaseRefsat(oBaseRefsat == 0) = nan;
                oRoverRefsat(oRoverRefsat == 0) = nan;
                sdRef = oRoverRefsat - oBaseRefsat;
                
                % Compute single and double differences
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
        function ddres = getDDres(obj,phases,units)
            if nargin < 3
                units = 'cycles';
                if nargin < 2
                    phases = obj.phaseObs;
                end
            end
            validateattributes(phases,{'cell'},{'size',[1,nan]},2)
            assert(all(cellfun(@(x) length(x)==3 & isa(x,'char'),phases)),'Input cell has to consist of valid phase or code measurement identifier!')
            assert(all(cellfun(@(x) strcmp(x(1),'C') | strcmp(x(1),'L'),phases)),'Only phase or code measurement are valid as input for DD computation!')
            %mustBeMember(phases,obj.phaseObs)
            mustBeMember(units,{'cycles','meters'})
            refSatUnitFactor = 1;
            slaveSatUnitFactor = 1;
            nPhases = numel(phases);
            
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
                rsdRef = (rRoverRefsat - rBaseRefsat).*refSatUnitFactor;
                
                % Compute single and double slant range differences
                for slaveSat = obj.sessions(i).slaveSats
                    if strcmp(units,'cycles')
                        slaveSatUnitFactor = cellfun(@(x) 1/getWavelength(obj.gnss,str2double(x(2)),refSat),phases);
                    end
                    [~,~,rBase] = obj.base.getLocal(obj.gnss,slaveSat,obj.sessions(i).idxRange);
                    [~,~,rRover] = obj.rover.getLocal(obj.gnss,slaveSat,obj.sessions(i).idxRange);
                    rsd = (rRover - rBase).*slaveSatUnitFactor;
                    for phaseIdx = 1:nPhases
                        ddres{phaseIdx}(obj.sessions(i).idxRange,slaveSat) = dd{phaseIdx}(obj.sessions(i).idxRange,slaveSat) - (rsd(:,phaseIdx) - rsdRef(:,phaseIdx));
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
end