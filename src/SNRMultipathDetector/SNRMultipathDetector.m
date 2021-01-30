classdef SNRMultipathDetector
    properties
        gnss (1,1) char
        snrIdentifiers (1,:) cell
        snr (:,:) double
        sats (1,:) double
        elevation (:,:) double
        azimuth (:,:) double
        
        refPolyDiff             % Reference polynomials for SNR differences
        refPolyS                % Reference polynomials for SNR differences
        refPolySatBlocks
        refPolySat
        
        detectionThreshold
    end
   properties (Dependent)
      nSNR
      nPoly
   end
    methods
        function obj = SNRMultipathDetector(obsrnx,gnss,snrIdentifiers)
            validateattributes(obsrnx,{'OBSRNX'},{'size',[1,1]},1)
            validateattributes(gnss,{'char'},{'size',[1,1]},2)
            validateattributes(snrIdentifiers,{'cell'},{},3)
            assert(ismember(length(snrIdentifiers),[2,3]),'Only 2 or 3 SNR identifiers are possible for input!');
            
            % Checking if data can be extracted from OBSRNX object
            assert(contains(obsrnx.gnss,gnss),sprintf('Observation data not available for system "%s"!',gnss));
            availableSatposGnss = char(arrayfun(@(x) x.gnss,obsrnx.satpos));
            assert(~isempty(obsrnx.satpos) && contains(availableSatposGnss,gnss),'invalidInput:noSattelitePositions',...
                sprintf('Satellite elevation data not available for system "%s"! Run OBSRNX.computeSatPosition first!',gnss));
            availableSignals = obsrnx.obsTypes.(gnss)(cellfun(@(x) strcmp(x(1),'S'),obsrnx.obsTypes.(gnss)));
            assert(all(ismember(snrIdentifiers,availableSignals)),'Not all required signals available in OBSRNX!');
            
            % Set properties
            obj.gnss = gnss;
            obj.snrIdentifiers = snrIdentifiers;
            obj.sats = obsrnx.satpos(availableSatposGnss == gnss).satList;
            
            nObsEpochs = size(obsrnx.t,1);
            nSats = length(obj.sats);
            
            obj.elevation = nan(nObsEpochs,nSats);
            obj.azimuth = nan(nObsEpochs,nSats);
            slantRange = nan(nObsEpochs,nSats);
            
            % Assign local coordinates for satellites (elevation, azimuth, slant range)
            for i = 1:length(obj.sats)
                [obj.elevation(:,i),obj.azimuth(:,i),slantRange(:,i)] = obsrnx.getLocal(gnss,obj.sats(i));
            end
            a = 1;
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