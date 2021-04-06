classdef SNRMultipathDetector
    properties (SetAccess = protected)
        gnss (1,1) char
        snrIdentifiers (1,:) cell
        t0 (1,1) datetime
        sats (1,:) double
        snrCal (1,1) struct
    end
    properties (Access = private)
        snr (1,:) cell
        elevation (:,:) double
        azimuth (:,:) double
    end
    properties (Dependent)
        nSNR
        nPoly
    end
    methods
        function obj = SNRMultipathDetector(obsrnx,opts)
            if nargin < 2, opts = SNRMultipathDetectorOptions(); end
            validateattributes(obsrnx,{'OBSRNX'},{'size',[1,1]},1);
            validateattributes(opts,{'SNRMultipathDetectorOptions'},{'size',[1,1]},2);
            
            % Checking if data can be extracted from OBSRNX object
            assert(contains(obsrnx.gnss,opts.gnss),sprintf('Observation data not available for system "%s"!',opts.gnss));
            availableSatposGnss = char(arrayfun(@(x) x.gnss,obsrnx.satpos));
            assert(~isempty(obsrnx.satpos) && contains(availableSatposGnss,opts.gnss),'invalidInput:noSattelitePositions',...
                sprintf('Satellite elevation data not available for system "%s"! Run OBSRNX.computeSatPosition first!',opts.gnss));
            availableSignals = obsrnx.obsTypes.(opts.gnss)(cellfun(@(x) strcmp(x(1),'S'),obsrnx.obsTypes.(opts.gnss)));
            assert(all(ismember(opts.snrIdentifiers,availableSignals)),'Not all required signals available in OBSRNX!');
            
            % Set properties
            obj.gnss = opts.gnss;
            obj.snrIdentifiers = opts.snrIdentifiers;
            obj.sats = obsrnx.satpos(availableSatposGnss == obj.gnss).satList;
            obj.t0 = datetime(obsrnx.t(1,1:6));
            
            nObsEpochs = size(obsrnx.t,1);
            nSats = length(obj.sats);
            obj.elevation = nan(nObsEpochs,nSats);
            obj.azimuth = nan(nObsEpochs,nSats);
            
            % Assign local coordinates for satellites (elevation, azimuth, slant range)
            for i = 1:length(obj.sats)
                [obj.elevation(:,i),obj.azimuth(:,i)] = obsrnx.getLocal(obj.gnss,obj.sats(i));
                obj.elevation(obj.elevation(:,i) == 0,i) = nan;
                obj.azimuth(obj.azimuth(:,i) == 0,i) = nan;
            end
            
            % Get SNR data from obsrnx object
            obj.snr = cell(1,obj.nSNR);
            obj.snr(:) = {zeros(nObsEpochs,nSats)};
            for i = 1:obj.nSNR
                for j = 1:nSats
                    obj.snr{1,i}(:,j) = obsrnx.getObservation(obj.gnss,obj.sats(j),obj.snrIdentifiers{i});
                end
                obj.snr{1,i}(obj.snr{1,i} == 0) = nan;
            end
            
            % Estimate calibration parameters for 'all', 'block' and 'individual' calibration mode
            snrCalAll = SNRMultipathCalibration(obj.snr,obj.elevation,obj.sats,obj.t0,'all',opts);
            if ~isempty(snrCalAll.fit), obj.snrCal.all = snrCalAll; end
            
%             snrCalBlock = SNRMultipathCalibration(obj.snr,obj.elevation,obj.sats,obj.t0,'block',opts);
%             if ~isempty(snrCalBlock.fit), obj.snrCal.block = snrCalBlock; end
%             
%             snrCalIndividual = SNRMultipathCalibration(obj.snr,obj.elevation,obj.sats,obj.t0,'individual',opts);
%             if ~isempty(snrCalIndividual.fit), obj.snrCal.individual = snrCalIndividual; end
        end
        
        % Getter methods
        function value = get.nSNR(obj)
            value = length(obj.snrIdentifiers);
        end
        
    end
end