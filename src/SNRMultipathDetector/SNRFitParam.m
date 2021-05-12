classdef SNRFitParam
    properties (SetAccess = protected)
        gnss (1,1) char
        sat (1,:) double
        block (1,:) double
        
        fitC12 (1,1) function_handle = @(x) x
        fitC15 (1,1) function_handle = @(x) x
        fitS (1,:) function_handle = @(x) x
        T_t (1,:) function_handle = @(x) x
        T_p (1,:) function_handle = @(x) x
        sigmaC12 (1,1) double
        sigmaC15 (1,1) double
        sigmaS (1,1) double
        
        elevCoverageBins_C12 (1,:) double
        elevCoverageBins_C15 (1,:) double
        elevCoverageBins_S (1,:) double
        
        fitIntervals_C12 (:,2) double
        fitIntervals_C15 (:,2) double
        fitIntervals_S (:,2) double
    end
    properties (Dependent)
        nFreq (1,1) double
        elevCoverage (1,3) double
    end
    methods
        function obj = SNRFitParam(gnss,satIDs,blockIDs,fitC12,fitC15,fitS,T_t,T_p,sigmaC12,sigmaC15,sigmaS,elevCoverageBins)
            validateattributes(gnss,{'char'},{'size',[1,1]},1);
            assert(ismember(gnss,{'G','R','E','C'}),'Invalid GNSS identifier!');
            validateattributes(satIDs,{'double'},{'size',[1,nan],'positive','integer'},2);
            validateattributes(blockIDs,{'double'},{'size',[1,nan],'positive','integer'},3);
            validateattributes(fitC12,{'function_handle'},{'size',[1,1]},4);
            validateattributes(fitC15,{'function_handle'},{'size',[1,1]},5);
            validateattributes(fitS,{'function_handle'},{'size',[1,nan]},6);
            validateattributes(T_t,{'function_handle'},{'size',[1,nan]},7);
            validateattributes(T_p,{'function_handle'},{'size',[1,nan]},8);
            validateattributes(sigmaC12,{'double'},{'size',[1,1],'nonnegative'},9);
            validateattributes(sigmaC15,{'double'},{'size',[1,1],'nonnegative'},10);
            validateattributes(sigmaS,{'double'},{'size',[1,1],'nonnegative'},11);
            validateattributes(elevCoverageBins,{'cell'},{'size',[1,3]},12);
            
            obj.gnss = gnss;
            obj.sat = satIDs;
            obj.block = blockIDs;
            
            obj.fitC12 = fitC12;
            obj.fitC15 = fitC15;
            obj.fitS = fitS;
            obj.T_t = T_t;
            obj.T_p = T_p;
            obj.sigmaC12 = sigmaC12;
            obj.sigmaC15 = sigmaC15;
            obj.sigmaS = sigmaS;
            
            obj.elevCoverageBins_C12 = elevCoverageBins{1};
            obj.elevCoverageBins_C15 = elevCoverageBins{2};
            obj.elevCoverageBins_S = elevCoverageBins{3};
            obj = obj.getFitIntervals();
        end
        function value = get.nFreq(obj)
            if all(~isnan(obj.fitC12(0:90))) && all(~isnan(obj.fitC15(0:90)))
                value = 3;
            else
                value = 2;
            end
        end
        function value = get.elevCoverage(obj)
            value = nan(1,3);
            coverageIds = {'C12','C15','S'};
            for i = 1:length(coverageIds)
                name = sprintf('elevCoverageBins_%s',coverageIds{i});
                value(i) = nnz(obj.(name) >= 0)/90;
            end
        end
        function plot(obj,elevation,dSNR1,dSNR2,S,p)
            figure('Position',[220,500,1200,450]);
            subplot(1,2,1)
            cols = lines(2);
            sampleElevation = 0:90;
            plot(elevation,dSNR1,'.','Color',cols(1,:),'DisplayName','dSNR1');
            hold on; box on; grid on
            plot(sampleElevation,obj.fitC12(sampleElevation),'--','Color',cols(1,:),'HandleVisibility','off');
            for i = 1:size(obj.fitIntervals_C12,1)
                elevToPlot = obj.fitIntervals_C12(i,1):obj.fitIntervals_C12(i,2);
                if i == 1
                    plot(elevToPlot,obj.fitC12(elevToPlot),'-','Color',cols(1,:),'LineWidth',3,'DisplayName',['C12 (\sigma=',sprintf('%.2f)',obj.sigmaC12)]);
                else
                    plot(elevToPlot,obj.fitC12(elevToPlot),'-','Color',cols(1,:),'LineWidth',3,'HandleVisibility','off');
                end
            end
            if obj.nFreq == 3
                plot(elevation,dSNR2,'.','Color',cols(2,:),'DisplayName','dSNR2');
                plot(sampleElevation,obj.fitC15(sampleElevation),'--','Color',cols(2,:),'HandleVisibility','off');
                for i = 1:size(obj.fitIntervals_C15,1)
                    elevToPlot = obj.fitIntervals_C15(i,1):obj.fitIntervals_C15(i,2);
                    if i == 1
                        plot(elevToPlot,obj.fitC15(elevToPlot),'-','Color',cols(2,:),'LineWidth',3,'DisplayName',['C15 (\sigma=',sprintf('%.2f)',obj.sigmaC15)]);
                    else
                        plot(elevToPlot,obj.fitC15(elevToPlot),'-','Color',cols(2,:),'LineWidth',3,'HandleVisibility','off');
                    end
                end
            end
            yMin = min([dSNR1; dSNR2]);
            yMax = max([dSNR1; dSNR2]);
            yRange = yMax - yMin;
            xlim([0,90]); ylim([yMin-0.1*yRange,yMax+0.1*yRange]);
            xlabel('Elevation (deg)'); ylabel('SNR difference (dBHz)');
            legend('Location','NorthEast','Interpreter','tex');
            
            subplot(1,2,2)
            plot(elevation,S,'.','Color','k','DisplayName','S statistics');
            hold on; box on; grid on;
            plot(sampleElevation,obj.fitS(sampleElevation),'--','Color','r','DisplayName',['fitS (all elevations)\newline\sigma=',sprintf('%.2f',obj.sigmaS)]);
            for i = 1:size(obj.fitIntervals_S,1)
                elevToPlot = obj.fitIntervals_S(i,1):obj.fitIntervals_S(i,2);
                if i == 1
                    plot(elevToPlot,obj.fitS(elevToPlot),'-','Color','r','LineWidth',3,'DisplayName','fitS (used for fit)');
                else
                    plot(elevToPlot,obj.fitS(elevToPlot),'-','Color','r','LineWidth',3,'HandleVisibility','off');
                end
            end
            plot(sampleElevation,obj.T_p(sampleElevation,p),'--','Color','r','LineWidth',3,'DisplayName','threshold function (p=99%)');
            xlim([0,90]); ylim([-0.1,max(S)+0.1*max(S)]);
            xlabel('Elevation (deg)'); ylabel('Detection statistic S');
            satsStr = ['[',strjoin(strsplit(num2str(obj.sat),' '),','),']'];
            legend('Location','NorthEast');
            sgtitle(sprintf('GNSS: %s, sats: %s, nFreq: %.0f, elevation coverage: %.0f deg (%.1f%%)',...
                obj.gnss,satsStr,obj.nFreq,length(obj.elevCoverageBins_S),100*obj.elevCoverage(3)));
        end
        function obj = getFitIntervals(obj)
            coverageIds = {'C12','C15','S'};
            for i = 1:length(coverageIds)
                name = sprintf('elevCoverageBins_%s',coverageIds{i});
                breakIdx = find(diff(obj.(name)) > 1);
                if isempty(obj.(name))
                    tmp = reshape([],[0,2]);
                else
                    tmp = [[obj.(name)(1);          obj.(name)(breakIdx+1)'],...
                           [obj.(name)(breakIdx)';  obj.(name)(end)]];
                end
                obj.(sprintf('fitIntervals_%s',coverageIds{i})) = tmp;
            end
        end
    end
end