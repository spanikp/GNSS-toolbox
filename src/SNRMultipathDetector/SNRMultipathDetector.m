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
                snrCalType = snrCalTypes{iCalType};
                snrCal = SNRMultipathCalibration(obj.snr,obj.elevation,obj.sats,obj.t0,snrCalType,opts);
                if ~isempty(snrCal.fit), obj.snrCal.(snrCalType) = snrCal; end
            end
        end
        function plotCalibrationFit(obj,calibrationMode)
            if nargin == 1, calibrationMode = 'all'; end
            validateattributes(calibrationMode,{'char'},{'size',[1,nan]},2);
            validatestring(calibrationMode,{'all','individual','block'});
            availableCalibrations = fieldnames(obj.snrCal);
            assert(ismember(calibrationMode,availableCalibrations),...
                sprintf('Required calibrationMode: "%s" not available!',calibrationMode));
            
            % Get required calibration object
            snr_cal = obj.snrCal.(calibrationMode);
            
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
                addStr = ''; cols = lines(2);
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
                                plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC12(elevToPlotInt),'-','Color',cols(1,:),'LineWidth',3,'DisplayName',['fit (\sigma=',sprintf('%.2f)',snr_cal.fit(iCal).sigmaC12)]);
                            else
                                plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC12(elevToPlotInt),'-','Color',cols(1,:),'LineWidth',3,'HandleVisibility','off');
                            end
                        end
                        
                        if obj.nSNR == 3
                            plot(ax(1),elevToPlot,snr_cal.fit(iCal).fitC15(elevToPlot),'--','Color',cols(2,:),'HandleVisibility','off');
                            fitIntC15 = snr_cal.fit(iCal).fitIntervals_C15;
                            for ii = 1:size(fitIntC15,1)
                                elevToPlotInt = fitIntC15(ii,1):fitIntC15(ii,2);
                                if ii == 1
                                    plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC15(elevToPlotInt),'-',...
                                        'Color',cols(2,:),'LineWidth',3,'DisplayName',['fit (\sigma=',sprintf('%.2f)',snr_cal.fit(iCal).sigmaC15)]);
                                else
                                    plot(ax(1),elevToPlotInt,snr_cal.fit(iCal).fitC15(elevToPlotInt),'-',...
                                        'Color',cols(2,:),'LineWidth',3,'HandleVisibility','off');
                                end
                            end
                        end
                    end
                end
                
                % Append string to title (has meaning for block/satellite mode)
                if strcmp(calibrationMode,'block'), addStr = sprintf('(%s-%d)',obj.gnss,unique(snr_cal.fit(iCal).block)); end
                if strcmp(calibrationMode,'individual'), addStr = sprintf('(%s%02d)',obj.gnss,snr_cal.fit(iCal).sat); end
                
                % Add labels and titles
                title(ax(1),sprintf('SNR differences & reference function(s)\nGNSS: %s, calibration mode: %s %s',obj.gnss,calibrationMode,addStr));
                ylabel(ax(1),'SNR differences (dBHz)'); xlabel(ax(1),'Elevation (deg)');
                set(ax(1),'XLim',[-1,91]);
                legend(ax(1),'Location','NorthEast');
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
                plot(ax(2),elev,S,'k.','DisplayName','S statistics'); hold on; grid on; box on;
                plot(ax(2),elevToPlot,snr_cal.fit(iCal).fitS(elevToPlot),'r--','HandleVisibility','off');
                fitIntS = snr_cal.fit(iCal).fitIntervals_S;
                for ii = 1:size(fitIntS,1)
                    if ii == 1
                        plot(fitIntS(ii,1):fitIntS(ii,2),snr_cal.fit(iCal).fitS(fitIntS(ii,1):fitIntS(ii,2)),'-',...
                            'Color','r','LineWidth',3,'DisplayName',['fit (\sigma=',sprintf('%.2f)',snr_cal.fit(iCal).sigmaS)]);
                    else
                        plot(fitIntS(ii,1):fitIntS(ii,2),snr_cal.fit(iCal).fitS(fitIntS(ii,1):fitIntS(ii,2)),'-',...
                            'Color','r','LineWidth',3,'HandleVisibility','off');
                    end
                end
                
                
                % Add labels and titles
                title(ax(2),sprintf('Multipath detection statics S\nGNSS: %s, calibration mode: %s %s',obj.gnss,calibrationMode,addStr));
                ylabel(ax(2),'S-statistics (dBHz)'); xlabel(ax(2),'Elevation (deg)');
                legend(ax(2),'Location','NorthEast');
                yLim = get(gca,'YLim'); set(gca,'YLim',[0,yLim(2)],'XLim',[-1,91]);
                %%%%%%%%%%%%%%% End of figure S-statistics %%%%%%%%%%%%%%%%
            end
        end
        
        % Getter methods
        function value = get.nSNR(obj)
            value = length(obj.snrIdentifiers);
        end
        
    end
    methods (Access = private)
        function [dSNR,elev] = getDifferences(obj,satNo,diffNo,removeNanFlag)
            validateattributes(satNo,{'double'},{'size',[1,nan],'integer'},2);
            validateattributes(diffNo,{'double'},{'size',[1,1],'integer'},3);
            if nargin < 4, removeNanFlag = true; end
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
    end
end