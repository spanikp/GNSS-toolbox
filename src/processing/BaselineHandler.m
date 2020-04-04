classdef BaselineHandler
    properties
        gnss 
        base
        rover
        tCommon
        refSat
        
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
            
            % Harmonize Base and Rover times and satellites
            [obj.base, obj.rover] = obj.base.harmonizeWith(obj.rover);
            obj.tCommon = datetime(obj.base.t(:,9),'ConvertFrom','datenum');
            
            % Find reference satellite
            obj.refSat = obj.getReferenceSats();
        end
        function refSat = getReferenceSats(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Find reference satellite as satellite with maximum height and
            % return structure with useful fields (prn, indices, times)
            %
            % Output:
            % refSat(n,1) struct with fields:
            %    .prn - satellite number (as in RINEX, not index)
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
            refSat = repmat(struct('prn',[],'idxRange',[],'from',datetime(),'to',datetime()),[size(maxSatIdxs,1),1]);
            for i = 1:size(maxSatIdxs,1)
                refSat(i,1).prn = obj.base.sat.(obj.gnss)(idxSatMaxElev(maxSatIdxs(i,1)));
                refSat(i,1).idxRange = maxSatIdxs(i,1):maxSatIdxs(i,2);
                refSat(i,1).from = datetime(obj.tCommon(maxSatIdxs(i,1)));
                refSat(i,1).to = datetime(obj.tCommon(maxSatIdxs(i,2)));
            end
        end
    end
end