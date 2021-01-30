classdef SNRMultipathCalibration
    properties
        refPolyDiff
        fit (1,:) SNRDifferenceFit
    end
    properties (Access = protected)
        calibrationMode (1,:) char {mustBeMember(calibrationMode,{'all','individual','block'})} = 'all'
    end
    methods
        function obj = SNRMultipathCalibration(gnss,satIDs,snrData,elevation,t0,calibrationMode,polyOrders,snrDifferenceSmoothing)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Inputs:
        % snrData - cell(1,2) or cell(1,3) assuming 
        %     snrData{1} -> S1
        %     snrData{2} -> S2
        %     snrData{3} -> S5
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            validateattributes(gnss,{'char'},{'size',[1,1]},1);
            validateattributes(satIDs,{'double'},{'size',[1,nan]},2);
            validateattributes(snrData,{'cell'},{'size',[1,nan]},3);
            validateattributes(elevation,{'double'},{},4);
            validateattributes(t0,{'datetime'},{'size',[1,1]},5);
            
            assert(all(cellfun(@(x) isequal(size(x),size(elevation)),snrData)),'Input data size mismatch: SNR <-> Elevation!');
            assert(size(elevation,2) == length(satIDs),'Input data size mismatch: Elevation <-> SatIDs!');
            
            nSNR = size(snrData,2);
            if nargin < 8
                snrDifferenceSmoothing = [ones(1,nSNR),ones(1,3-nSNR)];
                if nargin < 7
                    polyOrders = [3,3,3];
                    if nargin < 6
                        calibrationMode = 'all';
                    end
                end
            end
            
            validateattributes(calibrationMode,{'char'},{'size',[1,nan]},6);
            validateattributes(polyOrders,{'double'},{'size',[1,3]},7);
            validateattributes(snrDifferenceSmoothing,{'double'},{'size',[1,3]},8);
            
            obj.calibrationMode = calibrationMode;

            % In case only two SNR signals are available copy S1 data to S5
            if nSNR == 2, snrData{1,3} = snrData{1,1}; end
            
            % Form differences (S1 - S2) and (S1 - S5)
            for i = 1:3, snrData{i}(snrData{i} == 0) = nan; end % Replace zeros by nans
            dSNR{1} = movmean(snrData{1,1} - snrData{1,2},snrDifferenceSmoothing(1));
            dSNR{2} = movmean(snrData{1,1} - snrData{1,3},snrDifferenceSmoothing(2));
            
            switch obj.calibrationMode
                case 'all'
                    obj.fit = obj.getFits(dSNR{1}(:),dSNR{2}(:),elevation(:),polyOrders);
                case 'individual'
                    for i = 1:length(satIDs)
                        obj.fit(1,i) = obj.getFits(dSNR{1}(:,i),dSNR{2}(:,i),elevation(:,i),polyOrders);
                    end
                case 'block'
                    satInfo = SatelliteInfo();
                    satelliteBlocks = satInfo.getSatelliteBlock(satIDs,gnss,t0);
                    uniqueSatelliteBlocks = unique(satelliteBlocks);
                    for i = 1:length(uniqueSatelliteBlocks)
                        selBlock = satelliteBlocks == uniqueSatelliteBlocks(i);
                        obj.fit(1,i) = obj.getFits(dSNR{1}(:,selBlock),dSNR{2}(:,selBlock),elevation(:,selBlock),polyOrders);
                    end
            end
        end
    end
    methods (Access = private)
        function snrFit = getFits(obj,dSNR1,dSNR2,elevation,polyOrders)
            dSNR1 = dSNR1(:);
            dSNR2 = dSNR2(:);
            elevation = elevation(:);
            selValid1 = ~isnan(dSNR1);
            selValid2 = ~isnan(dSNR2);
            
            fitC12 = polyfit(elevation(selValid1),dSNR1(selValid1),polyOrders(1));
            fitC15 = polyfit(elevation(selValid2),dSNR2(selValid2),polyOrders(2));
            
            aa = (dSNR1 - polyval(fitC12,elevation)).^2;
            bb = (dSNR2 - polyval(fitC15,elevation)).^2;
            S = sqrt(aa + bb);
            selValidS = ~isnan(S);
            fitS = polyfit(elevation(selValidS),S(selValidS),polyOrders(3));
            
            % Development figure
            figure();
            subplot(1,2,1)
            cols = lines(2);
            sampleElevation = 0:90;
            plot(elevation(selValid1),dSNR1(selValid1),'.','Color',cols(1,:),'DisplayName','dSNR1');
            hold on; box on; grid on;
            plot(elevation(selValid2),dSNR2(selValid2),'.','Color',cols(2,:),'DisplayName','dSNR2');
            plot(sampleElevation,polyval(fitC12,sampleElevation),'-','Color',cols(1,:),'LineWidth',1.5,'DisplayName','fitC12')
            plot(sampleElevation,polyval(fitC15,sampleElevation),'-','Color',cols(2,:),'LineWidth',1.5,'DisplayName','fitC15')
            yMin = min([dSNR1;dSNR2]);
            yMax = max([dSNR1;dSNR2]);
            yRange = yMax - yMin;
            xlim([0,90]);
            ylim([yMin-0.1*yRange,yMax+0.1*yRange]);
            legend('Location','SouthEast');
            
            subplot(1,2,2)
            plot(elevation(selValidS),S(selValidS),'.','Color','k','DisplayName','S');
            hold on; box on; grid on;
            plot(sampleElevation,polyval(fitS,sampleElevation),'-','Color','r','LineWidth',1.5,'DisplayName','fitS')
            xlim([0,90]);
            ylim([-0.1,max(S)+0.1*max(S)])
            
            snrFit = SNRDifferenceFit(fitC12,fitC15,fitS);
        end
    end
end