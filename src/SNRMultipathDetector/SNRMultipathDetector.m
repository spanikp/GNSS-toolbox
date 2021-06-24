%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Class SNRMultipathDetector encapsulated all data used for SNR calibration together
% with estimated reference calibration functions for all SNR calibration scenarios.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        opts (1,1) SNRMultipathDetectorOptions
    end
    properties (Dependent)
        nSNR
        nPoly
        usableSnrCal
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
            availableSignalsStr = strjoin(availableSignals,', ');
            assert(all(ismember(opts.snrIdentifiers,availableSignals)),...
                sprintf('Not all required signals available in OBSRNX!\nSignals available: %s',availableSignalsStr));
            
            % Set properties
            obj.gnss = opts.gnss;
            obj.snrIdentifiers = opts.snrIdentifiers;
            obj.sats = obsrnx.satpos(availableSatposGnss == obj.gnss).satList;
            obj.t0 = datetime(obsrnx.t(1,1:6));
            obj.opts = opts;
            
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
            snrCalTypes = {'all','block','individual'};
            for iCalType = 1:length(snrCalTypes)
                calibrationMode = SNRCalibrationMode.(upper(snrCalTypes{iCalType}));
                snrCal = SNRMultipathCalibration(obj.snr,obj.elevation,obj.sats,obj.t0,calibrationMode,opts);
                if snrCal.isUsable
                    obj.snrCal.(calibrationMode.toString()) = snrCal;
                end
            end
        end
        function plotCalibrationFit(obj,calibrationMode,parameter_value,parameter_type)
            if nargin < 4
                parameter_type = 't';
                if nargin < 3
                    parameter_value = 3;
                    if nargin < 2
                        calibrationMode = SNRCalibrationMode.ALL;
                    end
                end
            end
            validateattributes(calibrationMode,{'SNRCalibrationMode'},{'size',[1,1]},2);
            assert(ismember(calibrationMode,obj.usableSnrCal),sprintf('Required calibrationMode: "%s" not available!',calibrationMode));
            validateattributes(parameter_value,{'double'},{'size',[1,1]},3);
            validateattributes(parameter_type,{'char'},{'size',[1,1]},4);
            mustBeMember(parameter_type,{'p','t'});
            if strcmp(parameter_type,'p'), mustBeInRange(parameter_value,0,1); end
            
            % Get required calibration object
            snr_cal = obj.getCalibrationByMode(calibrationMode);
            
            % Get constants
            elevToPlot = 0:90;
            
            % Looping through available calibrations (for block/satellite
            % mode there can be more calibration)
            for iCal = 1:length(snr_cal.fit)
                %%%%%%%%%%%%%% Make figure of SNR differences %%%%%%%%%%%%%
                figure('Units','Normalized','Position',[0.1,0.4,0.8,0.45]);
                ax(1) = subplot(1,2,1);
                ax(2) = subplot(1,2,2);
                hold(ax,'on'); grid(ax,'on'); box(ax,'on');
                
                % Looping though calibrations (for block/satellite there
                % can be more calibration objects)
                addStr = ''; cols = lines(4);
                for i = 1:length(snr_cal.fit(iCal).sat)
                    satNo = snr_cal.fit(iCal).sat(i);
                    [d1,elev] = obj.getDifferences(satNo,1,false);
                    if i == 1
                        plot(ax(1),elev,d1,'.','Color',cols(1,:),'DisplayName',sprintf('%s-%s',obj.snrIdentifiers{1},obj.snrIdentifiers{2}));
                    else
                        plot(ax(1),elev,d1,'.','Color',cols(1,:),'HandleVisibility','off');
                    end
                    if obj.nSNR == 3
                        d2 = obj.getDifferences(satNo,2,false);
                        if i == 1
                            plot(ax(1),elev,d2,'.','Color',cols(2,:),'DisplayName',sprintf('%s-%s',obj.snrIdentifiers{1},obj.snrIdentifiers{3}));
                        else
                            plot(ax(1),elev,d2,'.','Color',cols(2,:),'HandleVisibility','off');
                        end
                    end

                    % Plot reference functions C12 & C15 (if exist)
                    if i == length(snr_cal.fit(iCal).sat)
                        plot(ax(1),elevToPlot,snr_cal.fit(iCal).fitC12(elevToPlot),'--','Color',cols(1,:),'HandleVisibility','off');
                        fitIntC12 = snr_cal.fit(iCal).fitIntervals_C12;
                        for ii = 1:size(fitIntC12,1)
                            elevToPlotInt = fitIntC12(ii,1):fitIntC12(ii,2);
                            if ii == 1
                                plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC12(elevToPlotInt),'-','Color',cols(3,:),'LineWidth',3,'DisplayName',['fit ($\sigma=',sprintf('%.2f$)',snr_cal.fit(iCal).sigmaC12)]);
                            else
                                plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC12(elevToPlotInt),'-','Color',cols(3,:),'LineWidth',3,'HandleVisibility','off');
                            end
                        end
                        
                        if obj.nSNR == 3
                            plot(ax(1),elevToPlot,snr_cal.fit(iCal).fitC15(elevToPlot),'--','Color',cols(2,:),'HandleVisibility','off');
                            fitIntC15 = snr_cal.fit(iCal).fitIntervals_C15;
                            for ii = 1:size(fitIntC15,1)
                                elevToPlotInt = fitIntC15(ii,1):fitIntC15(ii,2);
                                if ii == 1
                                    plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC15(elevToPlotInt),'-',...
                                        'Color',cols(4,:),'LineWidth',3,'DisplayName',['fit ($\sigma=',sprintf('%.2f$)',snr_cal.fit(iCal).sigmaC15)]);
                                else
                                    plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC15(elevToPlotInt),'-',...
                                        'Color',cols(4,:),'LineWidth',3,'HandleVisibility','off');
                                end
                            end
                        end
                    end
                end
                
                % Append string to title (has meaning for block/satellite mode)
                if calibrationMode == SNRCalibrationMode.BLOCK, addStr = sprintf('(%s-%d)',obj.gnss,unique(snr_cal.fit(iCal).block)); end
                if calibrationMode == SNRCalibrationMode.INDIVIDUAL, addStr = sprintf('(%s%02d)',obj.gnss,snr_cal.fit(iCal).sat); end
                
                % Add labels and titles
                title(ax(1),sprintf('SNR differences and reference fit function(s)\nGNSS: %s, calibration mode: %s %s, signals: %s',...
                    obj.gnss,calibrationMode,addStr,strjoin(obj.snrIdentifiers,',')),'interpreter','latex');
                ylabel(ax(1),'SNR differences (dBHz)','interpreter','latex'); xlabel(ax(1),'Elevation (deg)','interpreter','latex');
                set(ax(1),'XLim',[-1,91]);
                set(ax(1),'TickLabelInterpreter','latex','FontSize',11);
                legend(ax(1),'Location','best','interpreter','latex');
                %%%%%%%%%%%%%% Send figure of SNR differences %%%%%%%%%%%%%
                
                %%%%%%%%%%%%%%% Plot figure of S-statistics %%%%%%%%%%%%%%%
                [d1,elev] = obj.getDifferences(snr_cal.fit(iCal).sat,1,false);
                d1 = d1 - snr_cal.fit(iCal).fitC12(elev);
                if obj.nSNR == 3
                    d2 = obj.getDifferences(snr_cal.fit(iCal).sat,2,false);
                    d2 = d2 - snr_cal.fit(iCal).fitC15(elev);
                else
                    d2 = zeros(size(d1));
                end
                
                selValid = ~isnan(d1) & ~isnan(d2);
                elev = elev(selValid);
                S = sqrt(d1(selValid).^2 + d2(selValid).^2);
                plot(ax(2),elev,S,'k.','DisplayName','$S$ statistics'); hold on; grid on; box on;
                plot(ax(2),elevToPlot,snr_cal.fit(iCal).fitS(elevToPlot),'r--','HandleVisibility','off');
                fitIntS = snr_cal.fit(iCal).fitIntervals_S;
                for ii = 1:size(fitIntS,1)
                    if ii == 1
                        plot(fitIntS(ii,1):fitIntS(ii,2),snr_cal.fit(iCal).fitS(fitIntS(ii,1):fitIntS(ii,2)),'-',...
                            'Color','r','LineWidth',3,'DisplayName',['fit ($\sigma=',sprintf('%.2f$)',snr_cal.fit(iCal).sigmaS)]);
                    else
                        plot(fitIntS(ii,1):fitIntS(ii,2),snr_cal.fit(iCal).fitS(fitIntS(ii,1):fitIntS(ii,2)),'-',...
                            'Color','r','LineWidth',3,'HandleVisibility','off');
                    end
                end
                
                % Plot threshold function
                if strcmp(parameter_type,'p')
                    T = snr_cal.fit(iCal).T_p;
                    p_value = parameter_value;
                    other_parameter = 't';
                else
                    T = snr_cal.fit(iCal).T_t;
                    t_value = parameter_value;
                    other_parameter = 'p';
                end
                selAbove = S >= T(elev,parameter_value);
                if strcmp(other_parameter,'t')
                    t_value = 3;
                    beta = snr_cal.fit(iCal).icdf_percentage(p_value);
                else
                    p_value = nnz(~selAbove)/length(S);
                    beta = snr_cal.fit(iCal).icdf_percentage(p_value)/t_value;
                end
                param_str = [sprintf('threshold function\n($p=%.3f$, $t=%.3f$, ',p_value,t_value),'$\beta=',sprintf('%.3f$)',beta)];
                plot(ax(2),elevToPlot,T(elevToPlot,parameter_value),'r--','DisplayName',param_str);
                plot(ax(2),elev(selAbove),S(selAbove),'ro','DisplayName','$S$ above threshold');
                
                % Add labels and titles
                title(ax(2),sprintf('Multipath detection statistics $S$\nGNSS: %s, calibration mode: %s %s',obj.gnss,calibrationMode,addStr),'interpreter','latex');
                ylabel(ax(2),'$S-$statistics (dBHz)','interpreter','latex'); xlabel(ax(2),'Elevation (deg)','interpreter','latex');
                set(ax(2),'TickLabelInterpreter','latex','FontSize',11);
                legend(ax(2),'Location','NorthEast','interpreter','latex');
                yLim = get(gca,'YLim'); set(gca,'YLim',[0,yLim(2)],'XLim',[-1,91]);
                %%%%%%%%%%%%%%% End of figure S-statistics %%%%%%%%%%%%%%%%
            end
        end
        function plotCalibrationFitMultiple(obj,calToPlot,showExtrapolation,showSNRhulls)
            if nargin < 4
                showSNRhulls = false;
                if nargin < 3
                    showExtrapolation = true;
                end
            end
            mustBeMember(calToPlot,[SNRCalibrationMode.BLOCK,SNRCalibrationMode.INDIVIDUAL]);
            validateattributes(showExtrapolation,{'logical'},{'size',[1,1]},3);
            
            % Get required calibration object
            snr_cal = obj.getCalibrationByMode(calToPlot);
            
            % Get constants
            elevToPlot = 0:90;
            
            % Looping through available calibrations (for block/satellite
            % mode there can be more calibration)
            nCals = length(snr_cal.fit);
            cols = lines(nCals);
            
            figure('Units','Normalized','Position',[0.1,0.4,0.8,0.45]);
            ax(1) = subplot(1,2,1);
            ax(2) = subplot(1,2,2);
            hold(ax,'on'); grid(ax,'on'); box(ax,'on');
            
            for i = 1:nCals
                % Plots of C12,C15 reference functions
                f = snr_cal.fit(i);
                if showExtrapolation
                    plot(ax(1),elevToPlot,f.fitC12(elevToPlot),':','Color',cols(i,:),'HandleVisibility','off');
                    if obj.nSNR == 3
                        plot(ax(1),elevToPlot,f.fitC15(elevToPlot),':','Color',cols(i,:),'HandleVisibility','off');
                    end
                end
                for j = 1:size(f.fitIntervals_S,1)
                    if j == 1
                        elev = f.fitIntervals_S(j,1):f.fitIntervals_S(j,2);
                        if showSNRhulls
                            d1 = []; e1 = [];
                            for iSat = 1:length(f.sat)
                                [d1tmp,e1tmp] = obj.getDifferences(f.sat(iSat),1,true);
                                d1 = [d1;d1tmp];
                                e1 = [e1;e1tmp];
                            end
                            boundPointsIdx = boundary(e1,d1);
                            patch(ax(1),'XData',e1(boundPointsIdx),'YData',d1(boundPointsIdx),'FaceColor',cols(i,:),'EdgeColor','none','FaceAlpha',0.05,'HandleVisibility','off');
                        end
                        if calToPlot == SNRCalibrationMode.BLOCK
                            plot(ax(1),elev,f.fitC12(elev),'-','Color',cols(i,:),'LineWidth',2,'DisplayName',...
                                [sprintf('%s block %d (C12)\n(%d sats, ',f.gnss,unique(f.block),length(f.sat)),'$\sigma$=',sprintf('%.2f)',f.sigmaC12)]);
                        else
                            plot(ax(1),elev,f.fitC12(elev),'-','Color',cols(i,:),'LineWidth',2,'DisplayName',sprintf('%s%02d (C12)',f.gnss,f.sat));
                        end
                        
                        if obj.nSNR == 3
                            if showSNRhulls
                                d2 = []; e2 = [];
                                for iSat = 1:length(f.sat)
                                    [d2tmp,e2tmp] = obj.getDifferences(f.sat(iSat),2,true);
                                    d2 = [d2;d2tmp];
                                    e2 = [e2;e2tmp];
                                end
                                boundPointsIdx = boundary(e2,d2);
                                patch(ax(1),'XData',e2(boundPointsIdx),'YData',d2(boundPointsIdx),'FaceColor',cols(i,:),'EdgeColor','none','FaceAlpha',0.05,'HandleVisibility','off');
                            end
                            if calToPlot == SNRCalibrationMode.BLOCK
                                plot(ax(1),elev,f.fitC15(elev),'--','Color',cols(i,:),'LineWidth',2,'DisplayName',...
                                    [sprintf('%s block %d (C15)\n(%d sats, ',f.gnss,unique(f.block),length(f.sat)),'$\sigma$=',sprintf('%.2f)',f.sigmaC15)]);
                            else
                                plot(ax(1),elev,f.fitC15(elev),'--','Color',cols(i,:),'LineWidth',2,'DisplayName',sprintf('%s%02d (C15)',f.gnss,f.sat));
                            end
                        end
                    else
                        plot(ax(1),elev,f.fitS(elev),'-','Color',cols(i,:),'LineWidth',2,'HandleVisibility','off');
                    end
                end
                
                % Plots of S-statistics functions
                if showExtrapolation
                    plot(ax(2),elevToPlot,f.fitS(elevToPlot),'--','Color',cols(i,:),'HandleVisibility','off');
                end
                for j = 1:size(f.fitIntervals_S,1)
                    if j == 1
                        if showSNRhulls
                            if obj.nSNR == 2
                                sVals = abs(d1 - f.fitC12(e1));
                            else
                                sVals = []; eVals = [];
                                for iSat = 1:length(f.sat)
                                    [dS1tmp,E1tmp] = obj.getDifferences(f.sat(iSat),1,false);
                                    [dS2tmp,E2tmp] = obj.getDifferences(f.sat(iSat),2,false);
                                    selValid = ~isnan(dS1tmp) & ~isnan(dS2tmp);
                                    sVals = [sVals; sqrt((dS1tmp(selValid)-f.fitC12(E1tmp(selValid))).^2 + (dS2tmp(selValid)-f.fitC15(E2tmp(selValid))).^2)];
                                    eVals = [eVals; E1tmp(selValid)];
                                end
                                e1 = eVals;
                            end
                            boundPointsIdx = boundary(e1,sVals);
                            patch(ax(2),'XData',e1(boundPointsIdx),'YData',sVals(boundPointsIdx),'FaceColor',cols(i,:),'EdgeColor','none','FaceAlpha',0.05,'HandleVisibility','off');
                        end
                        elev = f.fitIntervals_S(j,1):f.fitIntervals_S(j,2);
                        if calToPlot == SNRCalibrationMode.BLOCK
                            plot(ax(2),elev,f.fitS(elev),'-','Color',cols(i,:),'LineWidth',2,'DisplayName',sprintf('%s block %d',f.gnss,unique(f.block)));
                        else
                            plot(ax(2),elev,f.fitS(elev),'-','Color',cols(i,:),'LineWidth',2,'DisplayName',sprintf('%s%02d',f.gnss,f.sat));
                        end
                    else
                        plot(ax(2),elev,f.fitS(elev),'-','Color',cols(i,:),'LineWidth',2,'HandleVisibility','off');
                    end
                end
            end
            
            % Set labels and legends
            if calToPlot == SNRCalibrationMode.BLOCK
                nColumns = 2;
            else
                nColumns = 4;
            end
            leg(1) = legend(ax(1),'Location','best','interpreter','latex','FontSize',10,'NumColumns',nColumns,'box','on');
            set(leg(1).BoxFace,'ColorType','truecoloralpha','ColorData',uint8(255*[1;1;1;.5]),'AmbientStrength',0.0);
            xlabel(ax(1),'Elevation (deg)','interpreter','latex');
            ylabel(ax(1),'SNR differences (dBHz)','interpreter','latex');
            title(ax(1),sprintf('Fitted reference functions\ncalibration mode: %s, signals: %s',...
                upper(calToPlot.toString()),strjoin(obj.snrIdentifiers,',')),'interpreter','latex');
            set(ax(1),'TickLabelInterpreter','latex','FontSize',11,'XLim',[0,90]);
            
            leg(2) = legend(ax(2),'Location','best','interpreter','latex','FontSize',10,'NumColumns',4,'box','on');
            set(leg(2).BoxFace,'ColorType','truecoloralpha','ColorData',uint8(255*[1;1;1;.5]),'AmbientStrength',0.0);
            xlabel(ax(2),'Elevation (deg)','interpreter','latex');
            ylabel(ax(2),'$S-$statistics (dBHz)','interpreter','latex');
            title(ax(2),sprintf('Fitted functions for $S-$statistics\ncalibration mode: %s, signals: %s',...
                upper(calToPlot.toString()),strjoin(obj.snrIdentifiers,',')),'interpreter','latex');
            ax2YLim = get(ax(2),'YLim');
            set(ax(2),'TickLabelInterpreter','latex','FontSize',11,'XLim',[0,90],'YLim',[0,ax2YLim(2)]);
        end
        function isAboveThreshold = compareToThreshold(obj,satNo,blockNo,satElev,satSNR,calModeToUse,parameter_value,parameter_type)
            validateattributes(satNo,{'double'},{'size',[1,1]},2);
            validateattributes(blockNo,{'double'},{'size',[1,1]},3);
            validateattributes(satElev,{'double'},{'size',[nan,1]},4);
            validateattributes(satSNR,{'double'},{},5);
            validateattributes(calModeToUse,{'SNRCalibrationMode'},{'size',[1,1]},6);
            validateattributes(parameter_value,{'double'},{'size',[1,1]},7);
            validateattributes(parameter_type,{'char'},{'size',[1,1]},8);
            mustBeMember(parameter_type,{'p','t'});
            if strcmp(parameter_type,'p'), mustBeInRange(parameter_value,0,1); end
            
            assert(size(satSNR,2) <= 3,'Number of columns in "SNRdata" has to be 2 or 2 according SNR detector identifiers!"');
            assert(isequal(size(satElev,1),size(satSNR,1)),'Mismatch size between SNR data and provided elevations!');
            nSNRfreq = size(satSNR,2);
            snrCalToUse = obj.getCalibrationByMode(calModeToUse);
            
            % Initialize output
            isAboveThreshold = false(size(satElev));
            
            % Replace 0 by nan in SNR data
            satSNR(satSNR == 0) = nan;
            if ismember(calModeToUse,obj.usableSnrCal)
                switch calModeToUse
                    case SNRCalibrationMode.ALL
                        fitToUse = snrCalToUse.fit;
                    case SNRCalibrationMode.BLOCK
                        calBlocksAvailable = arrayfun(@(x) unique(x.block),snrCalToUse.fit);
                        fitToUse = snrCalToUse.fit(blockNo == calBlocksAvailable);
                        if isempty(fitToUse), return; end
                        assert(length(fitToUse) == 1,'SNRFitParam used further should be single value, not array!');
                    case SNRCalibrationMode.INDIVIDUAL
                        calSatsAvailable = arrayfun(@(x) x.sat,snrCalToUse.fit);
                        fitToUse = snrCalToUse.fit(satNo == calSatsAvailable);
                        if isempty(fitToUse), return; end
                        assert(length(fitToUse) == 1,'SNRFitParam used further should be single value, not array!');
                end

                dSNR1 = movmean(satSNR(:,1) - satSNR(:,2),obj.opts.snrDifferenceSmoothing(1));
                d12 = dSNR1 - fitToUse.fitC12(satElev);
                if nSNRfreq == 3
                    dSNR2 = movmean(satSNR(:,1) - satSNR(:,3),obj.opts.snrDifferenceSmoothing(2));
                    d15 = dSNR2 - fitToUse.fitC15(satElev);
                else
                    d15 = zeros(size(d12));
                end
                S = sqrt(d12.^2 + d15.^2);
                if strcmp(parameter_type,'p')
                    T = fitToUse.T_p;
                else
                    T = fitToUse.T_t;
                end
                isAboveThreshold = S >= T(satElev,parameter_value);
            end
        end
        
        % Getter methods
        function value = get.nSNR(obj)
            value = length(obj.snrIdentifiers);
        end
        function value = get.usableSnrCal(obj)
            fnames = fieldnames(obj.snrCal);
            snrCalAvailable = [];
            for i = 1:length(fnames)
                snrCalAvailable = [snrCalAvailable,SNRCalibrationMode.(upper(fnames{i}))];
            end
            value = snrCalAvailable;
        end
        
    end
    methods (Access = private)
        function [dSNR,elev] = getDifferences(obj,satNo,diffNo,removeNanFlag)
            validateattributes(satNo,{'double'},{'size',[1,nan],'integer'},2);
            validateattributes(diffNo,{'double'},{'size',[1,1],'integer'},3);
            if nargin < 4, removeNanFlag = false; end
            validateattributes(removeNanFlag,{'logical'},{'size',[1,1]},4);
            mustBeMember(satNo,obj.sats);
            mustBeMember(diffNo,[1,2]);
            
            if length(satNo) == 1
                selSat = satNo == obj.sats;
                elev = obj.elevation(:,selSat);
                dSNR = obj.snr{1}(:,selSat) - obj.snr{diffNo+1}(:,selSat);

                if removeNanFlag
                    selValid = ~isnan(elev) & ~isnan(dSNR);
                    elev = elev(selValid);
                    dSNR = dSNR(selValid);
                end
            else
                dSNR = []; elev = [];
                for i = 1:length(satNo)
                    [dSNRTmp,elevTmp] = obj.getDifferences(satNo(i),diffNo,removeNanFlag);
                    dSNR = [dSNR; dSNRTmp];
                    elev = [elev; elevTmp];
                end
            end
        end
        function cal = getCalibrationByMode(obj,calMode)
            validateattributes(calMode,{'SNRCalibrationMode'},{'size',[1,1]},2);
            mustBeMember(calMode,obj.usableSnrCal);
            cal = obj.snrCal.(calMode.toString());
        end
    end
end