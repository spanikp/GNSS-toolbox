classdef SNRMultipathDetector
    properties
%         refPolyDiff             % Reference polynomials for SNR differences
%         refPolyS                % Reference polynomials for test statistic
%         refPolySatBlocks
%         refPolySat
%         
%         detectionThreshold
    end
    properties (Dependent)
        nSNR
        nPoly
    end
    properties (SetAccess = protected)
        gnss (1,1) char
        snrIdentifiers (1,:) cell
        t0 (1,1) datetime
        sats (1,:) double
        detectorType (1,:) char {mustBeMember(detectorType,{'moderate','strict','block'})} = 'strict'
    end
    properties (SetAccess = private)
        snr (1,:) cell
        elevation (:,:) double
        azimuth (:,:) double
    end
    methods
        function obj = SNRMultipathDetector(obsrnx,gnss,snrIdentifiers,detectorType)
            validateattributes(obsrnx,{'OBSRNX'},{'size',[1,1]},1)
            validateattributes(gnss,{'char'},{'size',[1,1]},2)
            validateattributes(snrIdentifiers,{'cell'},{},3)
            assert(ismember(length(snrIdentifiers),[2,3]),'Only 2 or 3 SNR identifiers are possible for input!');
            
            if nargin < 4, detectorType = 'strict'; end
            validatestring(detectorType,{'moderate','strict'});
            obj.detectorType = detectorType;
            
            % Checking if data can be extracted from OBSRNX object
            assert(contains(obsrnx.gnss,gnss),sprintf('Observation data not available for system "%s"!',gnss));
            availableSatposGnss = char(arrayfun(@(x) x.gnss,obsrnx.satpos));
            assert(~isempty(obsrnx.satpos) && contains(availableSatposGnss,gnss),'invalidInput:noSattelitePositions',...
                sprintf('Satellite elevation data not available for system "%s"! Run OBSRNX.computeSatPosition first!',gnss));
            availableSignals = obsrnx.obsTypes.(gnss)(cellfun(@(x) strcmp(x(1),'S'),obsrnx.obsTypes.(gnss)));
            assert(all(ismember(snrIdentifiers,availableSignals)),'Not all required signals available in OBSRNX!');
            assert(length(unique(snrIdentifiers))==length(snrIdentifiers),'SNR identifiers have to be unique!');
            
            % Set properties
            obj.gnss = gnss;
            obj.snrIdentifiers = snrIdentifiers;
            obj.sats = obsrnx.satpos(availableSatposGnss == gnss).satList;
            obj.t0 = datetime(obsrnx.t(1,1:6));
            
            nObsEpochs = size(obsrnx.t,1);
            nSats = length(obj.sats);
            
            obj.elevation = nan(nObsEpochs,nSats);
            obj.azimuth = nan(nObsEpochs,nSats);
            
            % Assign local coordinates for satellites (elevation, azimuth, slant range)
            for i = 1:length(obj.sats)
                [obj.elevation(:,i),obj.azimuth(:,i)] = obsrnx.getLocal(gnss,obj.sats(i));
                obj.elevation(obj.elevation(:,i) == 0,i) = nan;
                obj.azimuth(obj.azimuth(:,i) == 0,i) = nan;
            end
            
            % Get SNR data from obsrnx object
            obj.snr = cell(1,obj.nSNR);
            obj.snr(:) = {zeros(nObsEpochs,nSats)};
            for i = 1:obj.nSNR
                for j = 1:nSats
                    obj.snr{1,i}(:,j) = obsrnx.getObservation(gnss,obj.sats(j),snrIdentifiers{i});
                end
                obj.snr{1,i}(obj.snr{1,i} == 0) = nan;
            end
            
            calibrationMode = 'all';
            snrCal_all = SNRMultipathCalibration(obj.gnss,obj.sats,obj.snr,obj.elevation,obj.t0,calibrationMode);
            
            
        end
        function obj = smoothSNRdifferences(obj,smoothingWindowLengths)
            
            
        end
        function obj = getCalibration(obsrnx)
            
        end
        function obj = detectMultipath(obsrnx)
            
        end
        
        % Getter methods
        function value = get.nSNR(obj)
            value = length(obj.snrIdentifiers);
        end
        
    end
end