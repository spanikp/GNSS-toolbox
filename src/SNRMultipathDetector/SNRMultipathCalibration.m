classdef SNRMultipathCalibration
    properties (SetAccess = protected)
        calibrationMode (1,1) SNRCalibrationMode = SNRCalibrationMode.ALL
        fit (1,:) SNRFitParam = reshape(SNRFitParam.empty(),[1,0])
    end
    properties (Dependent)
        isUsable (1,1) logical
    end
    methods
        function obj = SNRMultipathCalibration(snrData,elevation,satIDs,t0,calibrationMode,opts)
            validateattributes(snrData,{'cell'},{'size',[1,nan]},1);
            validateattributes(elevation,{'double'},{},2);
            validateattributes(satIDs,{'double'},{'size',[1,nan]},3);
            validateattributes(t0,{'datetime'},{'size',[1,1]},4);
            validateattributes(calibrationMode,{'SNRCalibrationMode'},{'size',[1,1]},5);
            if nargin < 6, opts = SNRMultipathDetectorOptions(); end
            validateattributes(opts,{'SNRMultipathDetectorOptions'},{'size',[1,1]},6);
            
            assert(all(cellfun(@(x) isequal(size(x),size(elevation)),snrData)),'Input data size mismatch: SNR <-> Elevation!');
            assert(length(satIDs) == length(unique(satIDs)),'Duplicity in input satellite identifiers!');
            assert(size(elevation,2) == length(satIDs),'Input data size mismatch: Elevation <-> SatIDs!');
            nSNR = size(snrData,2);
            
            obj.calibrationMode = calibrationMode;
            satIDs = sort(satIDs); % Order satellite IDs
            
            % Get satellite block info
            satInfo = SatelliteInfo();
            blockIDs = satInfo.getSatelliteBlock(satIDs,opts.gnss,t0);
            
            % In case only two SNR signals are available copy S1 data to S5
            if nSNR == 2, snrData{1,3} = snrData{1,1}; end
            
            % Form differences (S1 - S2) and (S1 - S5)
            for i = 1:3, snrData{i}(snrData{i} == 0) = nan; end % Replace zeros by nans
            dSNR{1} = movmean(snrData{1,1} - snrData{1,2},opts.snrDifferenceSmoothing(1));
            dSNR{2} = movmean(snrData{1,1} - snrData{1,3},opts.snrDifferenceSmoothing(2));
            
            iValid = 0;
            switch obj.calibrationMode
                case SNRCalibrationMode.ALL
                    elevBinsMinimal = opts.elevBinsMinimal([1,3]);
                    obj.fit = SNRMultipathCalibration.getFit(dSNR{1},dSNR{2},elevation,satIDs,blockIDs,elevBinsMinimal,opts);
                case SNRCalibrationMode.BLOCK
                    elevBinsMinimal = opts.elevBinsMinimal([1,2]);
                    uBlocks = unique(blockIDs);
                    for i = 1:length(uBlocks)
                        selBlock = blockIDs == uBlocks(i);
                        fitObject = SNRMultipathCalibration.getFit(dSNR{1}(:,selBlock),dSNR{2}(:,selBlock),elevation(:,selBlock),...
                            satIDs(selBlock),blockIDs(selBlock),elevBinsMinimal,opts);
                        if isempty(fitObject)
                            fprintf('SNR calibration: Not enough data for satellite block %s %d\n',opts.gnss,uBlocks(i));
                        else
                            iValid = iValid + 1;
                            obj.fit(1,iValid) = fitObject;
                        end
                    end
                case SNRCalibrationMode.INDIVIDUAL
                    elevBinsMinimal = opts.elevBinsMinimal([1,1]);
                    for i = 1:length(satIDs)
                        fitObject = SNRMultipathCalibration.getFit(dSNR{1}(:,i),dSNR{2}(:,i),elevation(:,i),...
                            satIDs(i),blockIDs(i),elevBinsMinimal,opts);
                        if isempty(fitObject)
                            fprintf('SNR calibration: Not enough data for satellite %s%02d (block %d)\n',...
                                opts.gnss,satIDs(i),blockIDs(i));
                        else
                            iValid = iValid + 1;
                            obj.fit(1,iValid) = fitObject;
                        end
                    end
            end
        end
        function value = get.isUsable(obj)
            if ~isempty(obj.fit)
                value  = true;
            else
                value = false;
            end
        end
    end
    methods (Static)
        function [snrFit,threshold_function] = getFit(dSNR1,dSNR2,elevation,satIDs,blockIDs,elevBinsMinimalGroup,opts)
            validateattributes(dSNR1,{'double'},{},1);
            validateattributes(dSNR2,{'double'},{},2);
            validateattributes(elevation,{'double'},{},3);
            validateattributes(satIDs,{'double'},{'size',[1,nan],'positive','integer'},4);
            validateattributes(blockIDs,{'double'},{'size',[1,nan],'positive','integer'},5);
            if nargin < 6, opts = SNRMultipathDetectorOptions(); end
            snrFit = reshape(SNRFitParam.empty(),[1,0]);
            
            % Filter and get only valid data (enough for fit and with enough elevation coverage)
            selValid1 = ~isnan(dSNR1);
            selValid2 = ~isnan(dSNR2);
            isValid = sum(selValid1) > opts.coeffEnoughFitData*opts.polyOrders(1) & ...
                sum(selValid2) > opts.coeffEnoughFitData*opts.polyOrders(2);
            for i = 1:length(isValid)
                if isValid(i)
                    elevToValidate = elevation(~isnan(elevation(:,i)),i);
                    elevCoverageSat = nnz(unique(round(elevToValidate)) >= 0);
                    if elevCoverageSat < elevBinsMinimalGroup(1)
                        isValid(i) = false;
                    end
                end
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
                if opts.fitByOptimization
                    if ~all(dSNR1(selValid1) == 0)
                        fitC12 = fitWithOptimization(opts.funcs{1},elevation(selValid1),dSNR1(selValid1),opts.verbosity);
                    else
                        fitC12 = @(x) zeros(size(x));
                    end
                    if ~all(dSNR2(selValid2) == 0)
                        fitC15 = fitWithOptimization(opts.funcs{2},elevation(selValid2),dSNR2(selValid2),opts.verbosity);
                    else
                        fitC15 = @(x) zeros(size(x));
                    end
                else
                    if ~all(dSNR1(selValid1) == 0)
                        pC12 = polyfit(elevation(selValid1),dSNR1(selValid1),opts.polyOrders(1));
                    else
                        pC12 = zeros(1,opts.polyOrders(1)+1);
                    end
                    if ~all(dSNR2(selValid2) == 0)
                        pC15 = polyfit(elevation(selValid2),dSNR2(selValid2),opts.polyOrders(2));
                    else
                        pC15 = zeros(1,opts.polyOrders(2)+1);
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
                if nnz(~isnan(S)) > opts.polyOrders(3)
                    % Get fits of S detection statistics
                    selValidS = ~isnan(S);
                    if opts.fitByOptimization
                        fitS = fitWithOptimization(opts.funcs{3},elevation(selValidS),S(selValidS),opts.verbosity);
                    else
                        pS = polyfit(elevation(selValidS),S(selValidS),opts.polyOrders(3));
                        fitS = @(x) polyval(pS,x);
                    end
                    sigma1 = sqrt(sum(dS1(selValid1).^2)/nnz(selValid1)); if sigma1 == 0, sigma1 = nan; end
                    sigma2 = sqrt(sum(dS2(selValid2).^2)/nnz(selValid2)); if sigma2 == 0, sigma2 = nan; end
                    sigmaS = sqrt(sum((S(selValidS) - fitS(elevation(selValidS))).^2)/nnz(selValidS));
                    elevCoverageBinS = unique(round(elevation(selValidS)))';
                    if nnz(elevCoverageBinS >= 0) < elevBinsMinimalGroup(2), return; end
                    
                    % Fix fit parameters if all elements are zero
                    if all(fitC12(0:90) == 0), fitC12 = @(x) nan(size(x)); end
                    if all(fitC15(0:90) == 0), fitC15 = @(x) nan(size(x)); end
                    
                    % Estimate threshold function (later to be used for
                    % multipath detection). Estimation of function
                    % parameters are controlled via SNRMultipathDetectorOptions
                    %    threshold_func  - function handle of threshold function
                    %    threshold_significancy - percentage of S-samples
                    %       marked as not-multipath
                    %    threshold_iteration_increment - value used in
                    %       iterative process (smaller value means longer
                    %       computation, but higher accuracy in requred percentage)
                    threshold_function = SNRMultipathCalibration.getThresholdFunctionGeneric(elevation(selValidS),S(selValidS),fitS,sigmaS,opts);
                    
                    % Setup all SNR fit function to single class object
                    snrFit = SNRFitParam(opts.gnss,satIDs,blockIDs,fitC12,fitC15,fitS,threshold_function,sigma1,sigma2,sigmaS,...
                        {elevCoverageBinC12,elevCoverageBinC15,elevCoverageBinS});
                end

                % Development figure
                if ~isempty(snrFit) && opts.verbosity > 1
                    snrFit.plot(elevation,dSNR1,dSNR2,S);
                end
            end
        end
        function threshold_function = getThresholdFunction(elev,Svalues,S,s0,opts)
            validateattributes(elev,{'double'},{'size',[nan,1]},1);
            validateattributes(Svalues,{'double'},{'size',[nan,1]},2);
            validateattributes(S,{'function_handle'},{'size',[1,1]},3);
            validateattributes(s0,{'double'},{'size',[1,1]},4);
            validateattributes(opts,{'SNRMultipathDetectorOptions'},{'size',[1,1]},5);
            assert(isequal(size(elev),size(Svalues)),'Elevation and S-statitistic array has to have same dimensions!');
            assert(all(~isnan(elev)),'Elevation array cannot contain NaN values!');
            assert(all(~isnan(Svalues)),'S-statistics array cannot contain NaN values!');
            
            significancy_percentage = opts.threshold_significancy;
            T = opts.threshold_function;
            ns = length(Svalues);
            
            % Initialize iterative process to find required significancy_percentage
            t = 0;
            percentage_below_threshold = nnz(Svalues <= T(elev,S,s0,t))/ns;
            
            % Determine the way to optimize (increase/decrease t in iterations)
            dt = opts.threshold_iteration_increment;
            if significancy_percentage > percentage_below_threshold
            else
                dt = -dt;
            end
            
            % Iterative search
            while true
                t = t + dt;
                percentage_below_threshold = nnz(Svalues <= T(elev,S,s0,t))/ns;
                
                % Breaking condition in both cases of iteration process
                if dt > 0
                    if percentage_below_threshold >= significancy_percentage
                        t_significant = t;
                        break;
                    end
                else
                    if (percentage_below_threshold <= significancy_percentage) && (significancy_percentage >= 0)
                        t_significant = t;
                        break;
                    end
                end
            end
            
            threshold_function = @(x) T(x,S,s0,t_significant);
            
            % Development figure - showing threshold function & threshold_significancy
            %f = figure();
            %plot(elev,Svalues,'k.','DisplayName','S-values'); hold on;
            %plot(0:90,S(0:90),'r-','LineWidth',2,'DisplayName','fit S');
            %plot(0:90,threshold_function(0:90),'--','LineWidth',1,'DisplayName',...
            %  sprintf('threshold function: t=%.2f (%.0f%%)',t_significant,100*significancy_percentage));
            %sel_above = Svalues >= threshold_function(elev);
            %plot(elev(sel_above),Svalues(sel_above),'ro','DisplayName','values above threshold');
            %legend('Location','NorthEast');
        end
        function threshold_function = getThresholdFunctionGeneric(elev,Svalues,S,s0,opts)
            validateattributes(elev,{'double'},{'size',[nan,1]},1);
            validateattributes(Svalues,{'double'},{'size',[nan,1]},2);
            validateattributes(S,{'function_handle'},{'size',[1,1]},3);
            validateattributes(s0,{'double'},{'size',[1,1]},4);
            validateattributes(opts,{'SNRMultipathDetectorOptions'},{'size',[1,1]},5);
            assert(isequal(size(elev),size(Svalues)),'Elevation and S-statitistic array has to have same dimensions!');
            assert(all(~isnan(elev)),'Elevation array cannot contain NaN values!');
            assert(all(~isnan(Svalues)),'S-statistics array cannot contain NaN values!');
            
            T = opts.threshold_function;
            ns = length(Svalues);
            
            % Initialize iterative process to find significancy_levels
            t0 = 0;
            perc_below = @(t) nnz(Svalues <= T(elev,S,s0,t))/ns;
            perc_below0 = perc_below(t0);
            perc_below1 = []; t1 = []; % for positive dt
            perc_below2 = []; t2 = []; % for negative dt
            
            % Determine the way to optimize (increase/decrease t in iterations)
            dt = opts.threshold_iteration_increment;
            t = t0;
            while true
                t = t + dt;
                t1 = [t1; t];
                perc_below1 = [perc_below1; perc_below(t)];
                
                if perc_below1(end) == 1, break; end
            end
            t = t0;
            while true
                t = t - dt;
                t2 = [t; t2];
                perc_below2 = [perc_below(t); perc_below2];
                
                if perc_below2(1) == 0, break; end
            end
            
            % Get threshold function with required percentage below threshold
            tt = [t2; t0; t1];
            perc_below_tt = [perc_below2; perc_below0; perc_below1];
            [perc_below_tt_u,iUnique_percentage] = unique(perc_below_tt);
            tt_u = tt(iUnique_percentage);
            icdf_percentage = @(x) interp1(perc_below_tt_u,tt_u,x,'linear');
            threshold_function = @(x,p) T(x,S,s0,icdf_percentage(p));
            
            % Development figure - showing threshold function & threshold_significancy
            %figure; plot(tt,perc_below_tt,'.-'); hold on; plot(0:dt:1,icdf_percentage(0:dt:1),'.-'); plot(tt,tt,'k--')
            %f = figure();
            %p = 0.1345;
            %plot(elev,Svalues,'k.','DisplayName','S-values'); hold on;
            %plot(0:90,S(0:90),'r-','LineWidth',2,'DisplayName','fit S');
            %plot(0:90,threshold_function(0:90,p),'--','LineWidth',1,'DisplayName',...
            %    sprintf('threshold function: t=%.2f for p=%.2f',icdf_percentage(p),p));
            %sel_above = Svalues >= threshold_function(elev,p);
            %plot(elev(sel_above),Svalues(sel_above),'ro','DisplayName','values above threshold');
            %legend('Location','NorthEast');
        end
    end
end