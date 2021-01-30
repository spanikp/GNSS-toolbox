classdef SNRMultipathCalibration
    properties
        calibrationMode (1,:) char {mustBeMember(calibrationMode,{'AllSatellites','IndividualSatellites','SatelliteBlock'})} = 'AllSatellites'
        refPolyDiff
        fit (1,:) SNRDifferenceFit
    end
    methods
        function obj = SNRMultipathCalibration(snrData,elevation,satIDs,calibrationMode,polyOrders,snrDifferenceSmoothing)
            validateattributes(snrData,{'cell'},{'size',[1,nan]},1);
            validateattributes(elevation,{'double'},{[1,nan]},2);
            validateattributes(satIDs,{'double'},{'size',[1,nan]},3);
            validateattributes(polyOrders,{'double'},{'size',[1,3]},5);
            assert(all(cellfun(@(x) isequal(size(x),size(elevation)),snrData)),'Input data size mismatch: SNR <-> Elevation!');
            assert(size(elevation,2) == length(satIDs),'Input data size mismatch: Elevation <-> SatIDs!');
            
            nSNR = size(snrData,2);
            if nargin < 6
                snrDifferenceSmoothing = ones(nSNR,1);
            end
            obj.calibrationMode = calibrationMode;

            % In case only two SNR signals are available copy S1 data to S5
            if nSNR == 2, snrData{3} = snrData{1}; end
            
            % Form differences (S1 - S2) and (S1 - S5)
            for i = 1:3
                snrData{i}(snrData{i} == 0) = nan;
            end
            dSNR{1} = movmean(snrData{1} - snrData{2},snrDifferenceSmoothing(1));
            dSNR{2} = movmean(snrData{1} - snrData{3},snrDifferenceSmoothing(2));
            
            switch obj.calibrationMode
                case 'AllSatellites'
                    obj.fit = obj.getFits(dSNR{1}(:),dSNR{2}(:),elevation(:),polyOrders);
                case 'IndividualSatellites'
                    for i = 1:length(satIDs)
                        elevation = elevation(:,i);
                        obj.fit(1,i) = obj.getFits(dSNR{1}(:,i),dSNR{2}(:,i),elevation(:,i),polyOrders);
                    end
                case 'SatelliteBlock'
                    satelliteBlocks = getSatelliteBlocks(satIDs);
                    blockNumbers = cellfun(@(x) x.blockNumber, meas);
                    distinctBlockNumbers = unique(blockNumbers);
                    for i = 1:length(satelliteBlocks)
                        %obj.fit(1,i)
                    end
            end
        end
    end
    methods (Access = private)
        function snrFit = getFits(dSNR1,dSNR2,elevation,polyOrders)
            selValid = ~isnan(dSNR1) || ~isnan(dSNR2);
            elevation = elevation(selValid);
            dSNR1 = dSNR1(selValid);
            dSNR2 = dSNR2(selValid);
            fitC12 = polyfit(elevation,dSNR1,polyOrders(1));
            fitC15 = polyfit(elevation,dSNR2,polyOrders(2));
            S = sqrt((dSNR1 - polyval(fitC12,elevation)).^2 + (dSNR2 - polyval(fitC15,elevation).^2));
            fitS = polyfit(elevation,S,polyOrders(3));
            snrFit = SNRDifferenceFit(fitC12,fitC15,fitS);
        end
    end
end