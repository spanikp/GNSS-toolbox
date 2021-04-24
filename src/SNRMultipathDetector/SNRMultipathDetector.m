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
            if obj.nSNR == 2
                figSize = [0.3,0.4,0.35,0.45];
            else
                figSize = [0.1,0.4,0.8,0.45];
            end
            
            % Looping through available calibrations (for block/satellite
            % mode there can be more calibration)
            for iCal = 1:length(snr_cal.fit)
                % Make figure for each block/satellite separatelly
                addStr = '';
                figure('Units','Normalized','Position',figSize);
                if obj.nSNR == 2
                    ax = gca(); 
                else
                    ax(1) = subplot(1,2,1);% hold(ax(1),'on');
                    ax(2) = subplot(1,2,2);% hold(ax(2),'on');
                end
                hold(ax,'on'); grid(ax,'on'); box(ax,'on');
                for i = 1:length(snr_cal.fit(iCal).sat)
                    satNo = snr_cal.fit(iCal).sat(i);
                    
                    elev = obj.elevation(:,obj.sats == satNo);
                    d1 = obj.snr{1}(:,obj.sats == satNo) - obj.snr{2}(:,obj.sats == satNo);
                    plot(ax(1),elev,d1,'k.','HandleVisibility','off');
                    if obj.nSNR == 3
                        d2 = obj.snr{1}(:,obj.sats == satNo) - obj.snr{3}(:,obj.sats == satNo);
                        plot(ax(2),elev,d2,'k.','HandleVisibility','off');
                    end

                    % Plot reference functions
                    if i == length(snr_cal.fit(iCal).sat)
                        scatter(ax(1),snr_cal.fit(iCal).elevCoverageBins_C12,snr_cal.fit(iCal).fitC12(snr_cal.fit(iCal).elevCoverageBins_C12),...
                            100,'c','MarkerFaceColor','y','MarkerEdgeColor','none','MarkerFaceAlpha',0.5,'HandleVisibility','off');
                        plot(ax(1),elevToPlot,snr_cal.fit(iCal).fitC12(elevToPlot),'r-','DisplayName','C12','LineWidth',1.5);
                        if obj.nSNR == 3
                            scatter(ax(2),snr_cal.fit(iCal).elevCoverageBins_C15,snr_cal.fit(iCal).fitC15(snr_cal.fit(iCal).elevCoverageBins_C15),...
                                100,'c','MarkerFaceColor','y','MarkerEdgeColor','none','MarkerFaceAlpha',0.5,'HandleVisibility','off');
                            plot(ax(2),elevToPlot,snr_cal.fit(iCal).fitC15(elevToPlot),'r-','DisplayName','C15','LineWidth',1.5);
                        end
                    end
                end
                
                if strcmp(calibrationMode,'block'), addStr = sprintf('%s-%d',obj.gnss,unique(snr_cal.fit(iCal).block)); end
                if strcmp(calibrationMode,'individual'), addStr = sprintf('%s%02d',obj.gnss,snr_cal.fit(iCal).sat); end
                
                % Add labels and titles
                diff1 = sprintf('%s-%s',obj.snrIdentifiers{1},obj.snrIdentifiers{2});
                title(ax(1),sprintf('%s difference & C12 reference function\ncalibration mode: %s %s',diff1,calibrationMode,addStr));
                ylabel(ax(1),sprintf('%s (dBHz)',diff1)); xlabel(ax(1),'Elevation (deg)');
                set(ax(1),'XLim',[-1,91]);
                if obj.nSNR == 3
                    diff2 = sprintf('%s-%s',obj.snrIdentifiers{1},obj.snrIdentifiers{3});
                    title(ax(2),sprintf('%s difference & C15 reference function\ncalibration mode: %s %s',diff2,calibrationMode,addStr));
                    ylabel(ax(2),sprintf('%s (dBHz)',diff2)); xlabel(ax(2),'Elevation (deg)');
                    set(ax(2),'XLim',[-1,91]);
                end
            end
        end
        
        % Getter methods
        function value = get.nSNR(obj)
            value = length(obj.snrIdentifiers);
        end
        
    end
end