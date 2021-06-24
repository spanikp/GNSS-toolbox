classdef CorrectionMap
    % Correction map, all values are in meters
    properties
        gnss(1,1) char
        obsType(1,3) char   % Observation identifier (as in RINEX)
        corr(:,:) double    % Correction values in meters
        azi(:,1) double {}  % Correction map Azimuth in degrees
        elev(:,1) double {} % Correction map Elevation in degrees
    end
    methods
        function obj = CorrectionMap(gnss,obsType,correctionMap,azimuth,elevation,noCoverageValue)
            if nargin < 6
                noCoverageValue = nan;
            end
            assert(ismember(gnss,{'G','R','E','C'}),'Not allowed GNSS system "%s"!',gnss);
            assert(obsType(1)=='L','Input observation type "%s" is not a valid phase identifier!',obsType);
            assert(size(correctionMap,1)==numel(elevation),'Correction map size does not agree with input elevations!');
            assert(size(correctionMap,2)==numel(azimuth),'Correction map size does not agree with input azimuths!');
            assert(all(azimuth>=0) & all(azimuth<=360),'Input azimuth has to be between 0 - 360 degrees!');
            assert(all(elevation>=0) & all(elevation<=90),'Input elevation has to be between 0 - 90 degrees!');
            assert(isa(noCoverageValue,'double'),'Input value "noCoverageValue" has to be double!');
            
            obj.gnss = gnss;
            obj.obsType = obsType;
            corrMap = correctionMap;
            corrMap(isnan(corrMap)) = noCoverageValue;
            obj.corr = corrMap;
            obj.azi = azimuth;
            obj.elev = elevation;
        end
        function corrValues = getCorrection(obj,azimuth,elevation,interpolationMethod)
            validateattributes(azimuth,{'double'},{},1)
            validateattributes(elevation,{'double'},{},2)
            if nargin < 4
                interpolationMethod = 'linear';
            end
            validatestring(interpolationMethod,{'linear','quadratic','cubic'});
            
            assert(isequal(size(azimuth),size(elevation)),'Size of azimuth(%d x %d) does not agree with size of elevation (%d x %d)!',...
                size(azimuth,1),size(azimuth,2),size(elevation,1),size(elevation,2))
            assert(min(obj.azi)<=min(azimuth) & max(obj.azi)>=max(azimuth),'ValidationError:QuerryPointOutOfSkyBounds',...
                'Input azimuth out of correction specified area!')
            assert(min(obj.elev)<=min(elevation) & max(obj.elev)>=max(elevation),'ValidationError:QuerryPointOutOfSkyBounds',...
                'Input elevation out of correction specified area!')
            
            % Correction interpolation
            corrValues = interp2(obj.azi,obj.elev,obj.corr,azimuth,elevation,interpolationMethod);
        end
        function f = plot(obj,plotType,caxisLimits)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Method to create correction map plot.
        %
        % plotType - 'skyplot' or 'regular'
        % caxisLimits - plot limits in milimeters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if nargin < 3
                caxisLimits = obj.getCorrLimits();
                if nargin < 2
                    plotType = 'skyplot';
                end
            end
            validateattributes(plotType,{'char'},{'size',[1,nan]},2);
            validatestring(plotType,{'skyplot','regular'});
            validateattributes(caxisLimits,{'double'},{'size',[1,2],'increasing'},3)
            
            % Replace nan by 0 (only for plotting purposes)
            corrForPlotting = 1e3*obj.corr;
            %corrForPlotting(isnan(corrForPlotting)) = 1000; % Nan regions are red
            corrForPlotting(isnan(corrForPlotting)) = 0;     % Nan regions are white
            
            f = figure();
            plotTitle = sprintf('Correction grid (%s, %s)',obj.gnss,obj.obsType);
            switch plotType
                case 'skyplot'
                    f.Position = [681,374,797,605];
                    polarplot3d(flipud(corrForPlotting),'PlotType','surfn','RadialRange',[0 90],'PolarGrid',{6,12},...
                        'GridStyle','-','GridColor',[0 0 0 0.15],'AxisLocation','surf','TickSpacing',15);
                    view(90,-90);
                    colormap(polarmap());
                    axis equal;
                    axis tight;
                    axis off;
                    hold on;
                    text(60,0,-100,'30','FontSize',10,'HorizontalAlignment','center','fontname','arial','FontWeight','bold','background','w');
                    text(30,0,-100,'60','FontSize',10,'HorizontalAlignment','center','fontname','arial','FontWeight','bold','background','w');
                    a = gca();
                    ap = get(a,'Position');
                    set(a,'Position',ap+[0,-0.05,0,0]);
                    title(plotTitle,'Position',[108,0],'FontSize',12);
                    caxis(caxisLimits);
                    c = colorbar();
                    set(c,'Box',matlab.lang.OnOffSwitchState('on'));
                    ylabel(c,'Correction value (mm)');
                    tmpPos = c.Position;
                    cX = tmpPos(1); cY = tmpPos(2);
                    cW = tmpPos(3); cH = tmpPos(4);
                    set(c,'Position',[cX+0.035,cY+0.08,0.8*cW,0.8*cH]);
                case 'regular'
                    f.Position = [681,381,896,598];
                    imagesc(corrForPlotting);
                    grid on; hold on;
                    set(gca,'YDir','normal');
                    colormap([polarmap(); 0,0,0]);
                    xlabel('Azimuth (deg)');
                    ylabel('Elevation (deg)');
                    title(plotTitle,'FontSize',12);
                    dAzi = mode(diff(obj.azi));
                    dElev = mode(diff(obj.elev));
                    xRange = [min(obj.azi),max(obj.azi)/dAzi];
                    yRange = [min(obj.elev),max(obj.elev)/dElev];
                    xlim(xRange);
                    ylim(yRange);
                    caxis(caxisLimits);
                    c = colorbar();
                    set(c,'Box',matlab.lang.OnOffSwitchState('on'));
                    ylabel(c,'Correction value (mm)');
                    tmpPos = c.Position;
                    cX = tmpPos(1); cY = tmpPos(2);
                    cW = tmpPos(3); cH = tmpPos(4);
                    set(c,'Position',[cX+0.06,cY+0.08,0.8*cW,0.8*cH]);
            end
        end
    end
    methods (Access = private)
        function corrLimits = getCorrLimits(obj)
            maxAbs = max(max(abs(obj.corr)));
            corrLimits = [-maxAbs, maxAbs];
            %corrLimits = [min(min(obj.corr)), max(max(obj.corr))];
        end
    end
    methods (Static)
        function corrMap = getZeroMap(gnss,obsType)
            elevation = 0:1:90;
            azimuth = 0:1:360;
            correctionMap = zeros(length(elevation),length(azimuth));
            corrMap = CorrectionMap(gnss,obsType,correctionMap,azimuth,elevation);
        end
        function corrMap = getConstantMap(gnss,obsType,constantCorrection)
            elevation = 0:1:90;
            azimuth = 0:1:360;
            correctionMap = constantCorrection*ones(length(elevation),length(azimuth));
            corrMap = CorrectionMap(gnss,obsType,correctionMap,azimuth,elevation);
        end
    end
end