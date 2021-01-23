classdef Skyplot < handle
    properties 
        fig
        labels = {}
        lgd
        cb
        R
    end
    methods
        function obj = Skyplot(backgroundFile,transparency)
            if nargin < 2
                transparency = 50;
                if nargin < 1
                    classFolder = fileparts(mfilename('fullpath'));
                    sampleSkyplot = 'sampleSkyplot.png';
                    backgroundFile = fullfile(classFolder,sampleSkyplot);
                end
            end
            
            % Load background image (load empty circle by default)
            [img,~,alpha] = imread(backgroundFile);

            % Open new figure with proper paper settings
            obj.fig = figure('Position',[200,200,600,600],'Resize','on');
            set(obj.fig,'Units','centimeters');
            set(obj.fig,'PaperUnits','centimeters');
            set(obj.fig,'PaperPositionMode','Auto');
            hold on;
            pos = get(obj.fig,'Position');
            set(obj.fig,'PaperSize',[pos(3),pos(4)])
            
            % Put transparency to non-transparent pixels
            alpha(alpha ~= 0) = alpha(alpha ~= 0) - (transparency/100)*255;
            
            % Showing figure
            f = imshow(img,'InitialMagnification','fit');
            set(f,'AlphaData',alpha);
            axis equal off;
            
            % Determine fisheye panorama diameter from image size
            obj.R = mean([size(img,1),size(img,2)])/2;
            th = 0:1:360;
            th1 = [280:1:360, 1:1:260];
            th2 = [275:1:360, 1:1:265];
            
            % Elevation circles
            line(obj.R*cosd(th)+obj.R,obj.R*sind(th)+obj.R,'linestyle','-','LineWidth',0.5,'Color','k','HandleVisibility','off');
            e60 = line((obj.R/3)*cosd(th1)+obj.R,(obj.R/3)*sind(th1)+obj.R,'LineWidth',0.5,'Color','k','HandleVisibility','off'); e60.Color(4) = 0.2;
            e30 = line(2*(obj.R/3)*cosd(th2)+obj.R,2*(obj.R/3)*sind(th2)+obj.R,'LineWidth',0.5,'Color','k','HandleVisibility','off'); e30.Color(4) = 0.2;
           
            % Elevation annotations
            text(1.01*obj.R,2*obj.R/3,'60$^\circ$','verticalalignment','middle','horizontalalignment','center','fontsize',11,'Interpreter','Latex');
            text(1.01*obj.R,obj.R/3,'30$^\circ$','verticalalignment','middle','horizontalalignment','center','fontsize',11,'Interpreter','Latex');
            
            % Azimuth lines
            a = line([0 2*obj.R],[obj.R obj.R],'LineWidth',0.5,'Color','k','HandleVisibility','off'); a.Color(4) = 0.2;
            a = line([obj.R obj.R],[0 0.29*obj.R],'LineWidth',0.5,'Color','k','HandleVisibility','off'); a.Color(4) = 0.2;
            a = line([obj.R obj.R],[0.37*obj.R 0.62*obj.R],'LineWidth',0.5,'Color','k','HandleVisibility','off'); a.Color(4) = 0.2;
            a = line([obj.R obj.R],[0.70*obj.R 2*obj.R],'LineWidth',0.5,'Color','k','HandleVisibility','off'); a.Color(4) = 0.2;
            
            % Azimuth annotations
            uh = [0 -30 -60 0 60 30 0 -30 -60 0 60 30];
            for i = 0:30:330
                x = obj.R + [obj.R*cosd(i) (0.96*obj.R)*cosd(i)];
                y = obj.R + [obj.R*sind(i) (0.96*obj.R)*sind(i)];
                line(x,y,'LineWidth',0.75,'Color','k','HandleVisibility','off');
                if i ~= 0 && i ~= 90 && i ~= 180 && i ~= 270
                    text(obj.R + 1.05*obj.R*cosd(i-90),obj.R + 1.05*obj.R*sind(i-90),[num2str(i),'$^\circ$'],'verticalalignment','middle','horizontalalignment','center','fontsize',11,'rotation',uh(1+i/30),'Interpreter','Latex')
                end
            end
            text(obj.R,-0.04*obj.R,'N','verticalalignment','middle','horizontalalignment','center','handlevisibility','off','fontsize',12,'Interpreter','Latex')
            text(obj.R,2.05*obj.R,'S','verticalalignment','middle','horizontalalignment','center','handlevisibility','off','fontsize',12,'Interpreter','Latex')
            text(-0.05*obj.R,obj.R,'W','verticalalignment','middle','horizontalalignment','center','handlevisibility','off','fontsize',12,'Interpreter','Latex')
            text(2.04*obj.R,obj.R,'E','verticalalignment','middle','horizontalalignment','center','handlevisibility','off','fontsize',12,'Interpreter','Latex')
        end
        function obj = addPlot(obj,elev,azi,label,symbol,color)
            narginchk(3,6)
            if nargin < 6
                cols = lines(numel(obj.labels)+1);
                color = cols(end,:);
                if nargin < 5
                    symbol = '.-';
                    if nargin < 4
                        label = sprintf('line%.0f',numel(obj.labels)+1);
                    end
                end
            end
            obj.labels = [obj.labels, label];
            [x,y] = obj.polar2cart(elev,azi);
            set(0,'CurrentFigure',obj.fig); % Set gcf to obj.fig
            if isempty(label)
                plot(x,y,symbol,'Color',color,'HandleVisibility','off');
                plot(x(1),y(1),'*','Color',color,'HandleVisibility','off');
                plot(x(end),y(end),'s','MarkerEdgeColor',color,'HandleVisibility','off');
            else
                plot(x,y,symbol,'Color',color,'DisplayName',label);
                plot(x(1),y(1),'*','Color',color,'HandleVisibility','off');
                plot(x(end),y(end),'s','MarkerEdgeColor',color,'HandleVisibility','off');
                obj.showLegend();
                obj.adjustLegend();
            end
        end
        function obj = addScatter(obj,elev,azi,vals,markerSize)
            narginchk(4,5)
            if nargin < 5
                markerSize = 20;
            end
            [x,y] = obj.polar2cart(elev,azi);
            set(0,'CurrentFigure',obj.fig) % Set gcf to obj.fig
            scatter(x,y,markerSize,vals,'filled','MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5,'HandleVisibility','off')
            obj.initializeColorbar();
        end
        function obj = plotRegion(obj,regionElevation,regionAzimuth,color,transparency,lineStyle)
            validateattributes(regionElevation,{'double'},{'size',[1,nan]},2);
            validateattributes(regionAzimuth,{'double'},{'size',[1,nan]},3);
            if nargin < 6
                lineStyle = '-';
                if nargin < 5
                    transparency = [0.2, 0.2]; % [FaceAlpha, EdgeAlpha]
                    if nargin < 4
                        color = 'red';
                    end
                end
            end
            
            % Interpolate to spherical coordinates
            xRegion = []; yRegion = [];
            pointsInBetween = 20;
            for i = 1:length(regionElevation)-1
                if regionAzimuth(i) == regionAzimuth(i+1)
                    azimuthRange = repmat(regionAzimuth(i),[1,pointsInBetween]);
                else
                    dAzi = regionAzimuth(i+1)-regionAzimuth(i);
                    if dAzi < -180
                        regionAzimuth(i) = regionAzimuth(i)-360;
                    end
                    azimuthRange = linspace(regionAzimuth(i),regionAzimuth(i+1),pointsInBetween);
                end
                if regionElevation(i) == regionElevation(i+1)
                    elevationRange = repmat(regionElevation(i),[1,pointsInBetween]);
                else
                    elevationRange = linspace(regionElevation(i),regionElevation(i+1),pointsInBetween);
                end
                [xRegionPoints,yRegionPoints] = obj.polar2cart(regionElevation,regionAzimuth);
                [x,y] = obj.polar2cart(elevationRange,azimuthRange);
                xRegion = [xRegion, x];
                yRegion = [yRegion, y];
            end
            set(0,'CurrentFigure',obj.fig);
            %plot(xRegionPoints,yRegionPoints,'r.','HandleVisibility','off');
            patch('XData',xRegion,'YData',yRegion,'FaceColor',color,'FaceAlpha',transparency(1),...
                'EdgeAlpha',transparency(2),'LineStyle',lineStyle,'HandleVisibility','off');
        end
        function obj = adjustColorbarLimits(obj,limits)
            if ~isempty(obj.cb)
                set(obj.cb,'Limits',limits)
            end
        end
        function exportToFile(obj,filename,printer,resolution)
            narginchk(2,4)
            if nargin < 4
                resolution = 200;
                if nargin < 3
                    printer = 'png';
                end
            end
            mustBeMember(printer,{'png','pdf'})
            printerStr = ['-d',printer];
            resolutionStr = sprintf('-r%.0f',resolution);
            switch printer
                case 'png'
                    print(obj.fig,filename,printerStr,resolutionStr);
                case 'pdf'
                    print(obj.fig,filename,printerStr,'-r0');
            end
        end
    end
    methods (Access = private)
        function [x,y] = polar2cart(obj,elev,azi)
            r = ((90 - elev)/90)*obj.R;
            x = obj.R + r.*sind(azi);
            y = obj.R - r.*cosd(azi);
        end
        function obj = showLegend(obj)
            if isempty(obj.lgd)
                obj.lgd = legend('Location','NorthEastOutside','Box','on');
                obj.changeFigureDimensions([600+100,600]);
                if ~isempty(obj.cb)
                    obj.cb.Position = [0.185 0.05 0.54 0.03];
                end
            end
        end
        function obj = adjustLegend(obj)
            nLines = numel(obj.labels);
            if  nLines > 28
                obj.lgd.NumColumns = ceil(nLines/28);
                obj.changeFigureDimensions([600+obj.lgd.NumColumns*100,600])
                obj.lgd.Position = [obj.lgd.Position(1)+obj.lgd.NumColumns*0.02, obj.lgd.Position(2),obj.lgd.Position(3:4)];
            end
        end
        function obj = changeFigureDimensions(obj,figSize)
            set(obj.fig,'Units','pixels')
            set(obj.fig,'Position',[[200,200],figSize]);
            set(obj.fig,'Units','centimeters')
        end
        function obj = initializeColorbar(obj)
            if isempty(obj.cb)
                % polarmap() % Download from https://www.mathworks.com/matlabcentral/fileexchange/37099-polarmap-polarized-colormap
                % Set colormap manually
                map = [repmat([0,0,1],[32,1]);repmat([1,0,0],[32,1])];
                r = repmat(abs(linspace(1,-1,64)),[3,1])';
                map = map.*r + 1 - r;
                colormap(map)
                caxis([-1,1]*max(abs(caxis)))
                
                obj.cb = colorbar();
                obj.cb.Location = 'SouthOutside';
                obj.cb.TickLabelInterpreter = 'latex';
                obj.cb.FontSize = 11;
                obj.cb.Box = 'on';
                if isempty(obj.lgd)
                    obj.cb.Position = [0.20 0.05 0.64 0.03];
                else
                    obj.cb.Position = [0.185 0.05 0.54 0.03];
                end
            end
        end
    end
    methods (Static)
        function [x,y] = getCartFromPolar(R,elev,azi)
            r = ((90 - elev)/90)*R;
            x = R + r.*sind(azi);
            y = R - r.*cosd(azi);
        end
    end
end