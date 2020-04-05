classdef BaselineHandler
    properties
        gnss 
        base
        rover
        tCommon
        phaseObs
        
        sessions
        
        
        sdBase
        sdRover
        sdRhoBase
        sdRhoRover
        dd
        ddRho
        ddRes
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
                availableSats = find(sum(~isnan(satsElevation(maxSatIdxs(i,1):maxSatIdxs(i,2),:)),1) ~= 0);
                sessions(i,1).slaveSats = setdiff(availableSats,sessions(i,1).refSat);
            end
        end
        function dd = getDD(obj,phases)
            if nargin == 1
                phases = obj.phaseObs;
            end
            mustBeMember(phases,obj.phaseObs)
            nPhases = numel(phases);
            
            oBase = nan(numel(obj.tCommon),nPhases*(max([obj.sessions.slaveSats])+1));
            oRover = nan(numel(obj.tCommon),nPhases*(max([obj.sessions.slaveSats])+1));
            for i = 1:2%numel(obj.sessions)
                satsToProcess = [obj.sessions(i).refSat, obj.sessions(i).slaveSats];
                for j = 1:numel(satsToProcess)
                    prn = satsToProcess(j);
                    oBase(obj.sessions(i).idxRange,(nPhases*(j-1)+1):(nPhases*j)) = obj.base.getObservation(obj.gnss,prn,phases,obj.sessions(i).idxRange);
                    oRover(obj.sessions(i).idxRange,(nPhases*(j-1)+1):(nPhases*j)) = obj.rover.getObservation(obj.gnss,prn,phases,obj.sessions(i).idxRange);
                end
            end
            sd = oRover - oBase;
            
            % Form double differences
            dd = cell(1,nPhases);
            for i = 1:nPhases
                dd{i} = diff(sd(:,i:nPhases:end),1,2);
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