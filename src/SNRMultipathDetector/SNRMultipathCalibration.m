classdef SNRMultipathCalibration
    properties (SetAccess = protected)
        calibrationMode (1,:) char {mustBeMember(calibrationMode,{'all','individual','block'})} = 'all'
        fit (1,:) SNRFitParam = reshape(SNRFitParam.empty(),[1,0])
    end
    methods
        function obj = SNRMultipathCalibration(gnss,satIDs,snrData,elevation,t0,calibrationMode,polyOrders,snrDifferenceSmoothing,elevBinsMinimal,coeffEnoughData)
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
            
            assert(ismember(gnss,{'G','R','E','C'}),'Invalid GNSS identifier');
            assert(all(cellfun(@(x) isequal(size(x),size(elevation)),snrData)),'Input data size mismatch: SNR <-> Elevation!');
            assert(length(satIDs) == length(unique(satIDs)),'Duplicity in input satellite identifiers!');
            assert(size(elevation,2) == length(satIDs),'Input data size mismatch: Elevation <-> SatIDs!');
            nSNR = size(snrData,2);
            
            % Set defualt values for not provided parameters
            if nargin < 10
                coeffEnoughData = 1;
                if nargin < 9
                    elevBinsMinimal = [10,10,20]; % 'individual','block','all'
                    if nargin < 8
                        snrDifferenceSmoothing = [ones(1,nSNR),ones(1,3-nSNR)];
                        if nargin < 7
                        	polyOrders = [3,3,3];
                            if nargin < 6
                                calibrationMode = 'all';
                            end
                        end
                    end
                end
            end
            validateattributes(calibrationMode,{'char'},{'size',[1,nan]},6);
            validateattributes(polyOrders,{'double'},{'size',[1,3]},7);
            validateattributes(snrDifferenceSmoothing,{'double'},{'size',[1,3]},8);
            validateattributes(elevBinsMinimal,{'double'},{'size',[1,3],'positive','integer'},9);
            validateattributes(coeffEnoughData,{'double'},{'size',[1,1],'positive','integer'},10);
            
            obj.calibrationMode = calibrationMode;
            satIDs = sort(satIDs); % Order satellite IDs
            
            % Get satellite block info
            satInfo = SatelliteInfo();
            blockIDs = satInfo.getSatelliteBlock(satIDs,gnss,t0);
            
            % In case only two SNR signals are available copy S1 data to S5
            if nSNR == 2, snrData{1,3} = snrData{1,1}; end
            
            % Form differences (S1 - S2) and (S1 - S5)
            for i = 1:3, snrData{i}(snrData{i} == 0) = nan; end % Replace zeros by nans
            dSNR{1} = movmean(snrData{1,1} - snrData{1,2},snrDifferenceSmoothing(1));
            dSNR{2} = movmean(snrData{1,1} - snrData{1,3},snrDifferenceSmoothing(2));
            
            iValid = 0;
            switch obj.calibrationMode
                case 'all'
                    obj.fit = obj.getFit(dSNR{1},dSNR{2},elevation,polyOrders,gnss,satIDs,blockIDs,elevBinsMinimal([1,3]),coeffEnoughData);
                    funcs = {...
                        @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x.^3 + p(4),...
                        @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x.^3 + p(4),...
                        @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x.^3 + p(4)};
                    %obj.getFunctionalFit(dSNR{1},dSNR{2},elevation,funcs,gnss,satIDs,blockIDs,elevBinsMinimal([1,3]),coeffEnoughData);
                case 'block'
                    uBlocks = unique(blockIDs);
                    for i = 1:length(uBlocks)
                        selBlock = blockIDs == uBlocks(i);
                        fitObject = obj.getFit(dSNR{1}(:,selBlock),dSNR{2}(:,selBlock),elevation(:,selBlock),...
                            polyOrders,gnss,satIDs(selBlock),blockIDs(selBlock),elevBinsMinimal([1,2]),coeffEnoughData);
                        if isempty(fitObject)
                            fprintf('SNR calibration: Not enough data for satellite block %s %d\n',gnss,uBlocks(i));
                        else
                            iValid = iValid + 1;
                            obj.fit(1,iValid) = fitObject;
                        end
                    end
                case 'individual'
                    for i = 1:length(satIDs)
                        fitObject = obj.getFit(dSNR{1}(:,i),dSNR{2}(:,i),elevation(:,i),polyOrders,gnss,satIDs(i),blockIDs(i),elevBinsMinimal(1),coeffEnoughData);
                        if isempty(fitObject)
                            fprintf('SNR calibration: Not enough data for satellite %s%02d (block %d)\n',gnss,satIDs(i),blockIDs(i));
                        else
                            iValid = iValid + 1;
                            obj.fit(1,iValid) = fitObject;
                        end
                    end
            end
        end
    end
    methods (Access = private)
        function snrFit = getFit(obj,dSNR1,dSNR2,elevation,polyOrders,gnss,satIDs,blockIDs,elevBinsMinimal,coeffEnoughFitData,showPlot)
            fitByOptimization = true;
            funcs = {...
                @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x + p(4),...
                @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x + p(4),...
                @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x + p(4)};
                %@(x,p) p(1)*exp(p(2)*sqrt(x))};
            if nargin < 11
                showPlot = false;
                if nargin < 10
                    coeffEnoughFitData = 5;
                    if nargin < 9
                        elevBinsMinimal = [10,20]; % 'individual','group' ('all' or 'block')
                    end
                end
            end
            snrFit = reshape(SNRFitParam.empty(),[1,0]);
            
            % Filter and get only valid data (enough for fit and with enough elevation coverage)
            selValid1 = ~isnan(dSNR1);
            selValid2 = ~isnan(dSNR2);
            isValid = sum(selValid1) > coeffEnoughFitData*polyOrders(1) & sum(selValid2) > coeffEnoughFitData*polyOrders(2);
            for i = 1:length(isValid)
                if isValid(i)
                    elevToValidate = elevation(~isnan(elevation(:,i)),i);
                    elevCoverageSat = nnz(unique(round(elevToValidate)) >= 0);
                    if elevCoverageSat < elevBinsMinimal(1)
                        isValid(i) = false;
                    end
                end
            end
            
            % Fnd out if two-step elevation validation is required
            if length(elevBinsMinimal) == 2
                twoStepElevValidation = true;
            else
                twoStepElevValidation = false;
            end
            
            selValid1 = selValid1(:,isValid);
            selValid2 = selValid2(:,isValid);
            dSNR1 = dSNR1(:,isValid);
            dSNR2 = dSNR2(:,isValid);
            elevation = elevation(:,isValid);
            satIDs = satIDs(isValid);
            blockIDs = blockIDs(isValid);
                        
            if ~isempty(satIDs)
                % Flattening SNR difference matrices
                selValid1 = selValid1(:);
                selValid2 = selValid2(:);
                dSNR1 = dSNR1(:);
                dSNR2 = dSNR2(:);
                elevation = elevation(:);

                % Get fits of SNR differences 
                if fitByOptimization
                    if ~all(dSNR1(selValid1) == 0)
                        fitC12 = fitWithOptimization(funcs{1},elevation(selValid1),dSNR1(selValid1));
                        %fitC12 = fitWithOptimizationNorm(funcs{1},elevation(selValid1),dSNR1(selValid1));
                    else
                        fitC12 = @(x) zeros(size(x));
                    end
                    if ~all(dSNR2(selValid2) == 0)
                        fitC15 = fitWithOptimization(funcs{2},elevation(selValid2),dSNR2(selValid2));
                    else
                        fitC15 = @(x) zeros(size(x));
                    end
                else
                    if ~all(dSNR1(selValid1) == 0)
                        pC12 = polyfit(elevation(selValid1),dSNR1(selValid1),polyOrders(1));
                    else
                        pC12 = zeros(1,polyOrders(1)+1);
                    end
                    if ~all(dSNR2(selValid2) == 0)
                        pC15 = polyfit(elevation(selValid2),dSNR2(selValid2),polyOrders(2));
                    else
                        pC15 = zeros(1,polyOrders(2)+1);
                    end
                    fitC12 = @(x) polyval(pC12,x);
                    fitC15 = @(x) polyval(pC15,x);
                end
                            
                dS1 = dSNR1 - fitC12(elevation);
                dS2 = dSNR2 - fitC15(elevation);
                dS1b = dS1; dS1b(dS1b == 0) = nan;
                dS2b = dS2; dS2b(dS2b == 0) = nan;
                elevCoverageBinC12 = unique(round(elevation(~isnan(dS1b))))';
                elevCoverageBinC15 = unique(round(elevation(~isnan(dS2b))))';
                S = sqrt(dS1.^2 + dS2.^2);
                if nnz(~isnan(S)) > polyOrders(3)
                    % Get fits of S detection statistics
                    selValidS = ~isnan(S);
                    if fitByOptimization
                        fitS = fitWithOptimization(funcs{3},elevation(selValidS),S(selValidS));
                    else
                        pS = polyfit(elevation(selValidS),S(selValidS),polyOrders(3));
                        fitS = @(x) polyval(pS,x);
                    end
                    sigma1 = std(dSNR1(selValid1)); if sigma1 == 0, sigma1 = nan; end
                    sigma2 = std(dSNR2(selValid2)); if sigma2 == 0, sigma2 = nan; end
                    sigmaS = std(S(selValidS));
                    elevCoverageBinS = unique(round(elevation(selValidS)))';
                    if twoStepElevValidation
                        if nnz(elevCoverageBinS >= 0) < elevBinsMinimal(2), return; end
                    end
                    
                    % Fix fit parameters if all elements are zero
                    if all(fitC12(0:90) == 0), fitC12 = @(x) nan(size(x)); end
                    if all(fitC15(0:90) == 0), fitC15 = @(x) nan(size(x)); end
                    snrFit = SNRFitParam(gnss,satIDs,blockIDs,fitC12,fitC15,fitS,sigma1,sigma2,sigmaS,...
                        {elevCoverageBinC12,elevCoverageBinC15,elevCoverageBinS});
                end

                % Development figure
                if ~isempty(snrFit) && showPlot
                    snrFit.plot(elevation,dSNR1,dSNR2,S);
                end
            end
        end
    end
end