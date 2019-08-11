classdef ANTEX
    properties
        version (1,:) char
        PCVtype (1,1) char {mustBeMember(PCVtype,{'A','R'})} = 'A'
        PCV (1,:) struct = struct('PCV',[],'PCVnoazi',[],'offsetNEU',[],'system','','freq',[])
        azi (1,:) double
        zen (1,:) double
        antennaType (1,:) char
        serialnumber (1,:) char
        valid (2,1) double = [-Inf, +Inf]
        meta (1,1) struct = struct('method','','agency','','date','')
    end
    methods
        function obj = ANTEX(filename)
            if nargin > 0
                fileList.checkExistence({filename});
                [folderPath,plainFileName,ext] = fileparts(filename);
                absFilePath = fullfile(fullpath(folderPath),[plainFileName, ext]);
                finp = fopen(absFilePath,'r');
                raw = textscan(finp,'%s','Delimiter','\n','whitespace','');
                raw = raw{1};
                fclose(finp);
                
                antTypesSel = cellfun(@(x) contains(x,'TYPE / SERIAL NO'),raw);
                antIds = unique(cellfun(@(x) strtrim(x(1:20)),raw(antTypesSel),'UniformOutput',false));
                
                if numel(antIds) > 1
                    error('ANTEX object can be made only for single antenna, but in file "%s" there are %d distinct antenna types!\n To load more ANTEX files in one step use class "ANTEXfile".',numel(antIds))
                else
                    obj = ANTEX.parseFromTextCells(raw);
                end
            end
        end
        function plot(obj,plotType,colorbar_range)
            if nargin == 1
                plotType = 1;
                colorbar_range = [-10,10];
            end
            if nargin == 2
                colorbar_range = [-10,10];
            end
            switch plotType
                case 1
                    for i = 1:numel(obj.PCV)
                        if isempty(obj.PCV(i).PCV)
                            figure
                            plot(obj.zen,1e3*obj.PCV(i).PCVnoazi);
                        else
                            figure
                            plot(obj.zen,1e3*obj.PCV(i).PCV');
                        end
                        grid on; box on;
                        xlabel('Zenith angle (deg)');
                        ylabel('Phase center variation (mm)');
                        title(sprintf('PCV for "%s" (%s%02d)',strrep(obj.antennaType,'_',' '),obj.PCV(i).system,obj.PCV(i).freq))
                    end
                case 2
                    for i = 1:numel(obj.PCV)
                        if isempty(obj.PCV(i).PCV)
                            warning('No azimuthal dependent pattern to show');
                        else
                            figure
                            [X,Y] = meshgrid(obj.zen,obj.azi);
                            mesh(X,Y,1e3*obj.PCV(i).PCV);
                            grid on; box on;
                            xlabel('Zenith angle (deg)');
                            ylabel('Azimuth (deg)');
                            zlabel('PCV (mm)')
                            title(sprintf('PCV for "%s" (%s%02d)',strrep(obj.antennaType,'_',' '),obj.PCV(i).system,obj.PCV(i).freq))
                        end
                    end
                case 3
                    for i = 1:numel(obj.PCV)
                        if isempty(obj.PCV(i).PCV)
                            warning('No azimuthal dependent pattern to show');
                        else
                            fprintf('%s%02d using colorbar range: [%d,%d] mm\n',obj.PCV(i).system,obj.PCV(i).freq,colorbar_range(1),colorbar_range(2));
                            figure('Position',[300 100 700 480],'NumberTitle','off','Resize','off')
                            polarplot3d(flipud(1e3*obj.PCV(i).PCV'),...
                                'PlotType','surfn',...
                                'RadialRange',[0 90],...
                                'PolarGrid',{6,12},...
                                'GridStyle',':');
                            view(90,-90)
                            
                            colormap jet
                            c = colorbar;
                            if ~isempty(colorbar_range)
                                caxis(colorbar_range)
                            end
                            
                            c.Position = [c.Position(1)*1.02, c.Position(2)*1.4, 0.8*c.Position(3), c.Position(4)*0.9];
                            c.TickDirection = 'out';
                            c.LineWidth = 1.1;
                            
                            ylabel(c,'PCV (mm)','fontsize',10)
                            axis equal
                            axis tight
                            axis off
                            hold on
                            text(54,-37,-100,'30','FontSize',9,'FontWeight','bold','HorizontalAlignment','center')
                            text(28,-21,-100,'60','FontSize',9,'FontWeight','bold','HorizontalAlignment','center')
                        end
                    end
                otherwise
                    warning('Only plotting options 1,2 or 3 are implemented!')
            end
        end
    end
    methods (Static)
        function atx = parseFromTextCells(raw)
            validateattributes(raw,{'cell'},{'size',[NaN,1]},1);
            atx = ANTEX();
            noFreq = [];
            pcvBlockIdx = 0;
            i = 0;
            
            while 1
                i = i + 1;
                if i > numel(raw)
                    break
                end
                line = raw{i};
                if contains(line,'ANTEX VERSION / SYST')
                    atx.version = strtrim(line(1:8));
                end
                if contains(line,'PCV TYPE / REFANT')
                    atx.PCVtype = line(1);
                end
                if contains(line,'TYPE / SERIAL NO')
                    atx.antennaType = strtrim(line(1:20));
                    atx.serialnumber = strtrim(line(21:40));
                end
                if contains(line,'METH / BY / # / DATE')
                    atx.meta.method = strtrim(line(1:20));
                    atx.meta.agency = strtrim(line(21:40));
                    atx.meta.date = strtrim(line(51:60));
                end
                if contains(line,'DAZI')
                    inc = str2double(line(3:10));
                    atx.azi = 0:inc:(360-inc);
                end
                if contains(line,'ZEN1 / ZEN2 / DZEN')
                    z = sscanf(line(3:20),'%f');
                    inc = z(3);
                    atx.zen = z(1):inc:z(2);
                end
                if contains(line,'VALID FROM')
                    d = str2num(line(1:43));
                    atx.valid(1) = datenum(d);
                end
                if contains(line,'VALID UNTIL')
                    d = str2num(line(1:43));
                    atx.valid(2) = datenum(d);
                end
                if contains(line,'# OF FREQUENCIES')
                    noFreq = str2double(line(1:6));
                    atx.PCV = repmat(atx.PCV,[1 noFreq]);
                    for f = 1:noFreq
                        atx.PCV(f).PCV = zeros(numel(atx.azi)-1,numel(atx.zen));
                    end
                end
                
                if contains(line,'START OF FREQUENCY')
                    if isempty(noFreq)
                        error('Attempt to made frequency section entry, but number of frequncies was not defined!\n Please check input ANTEX file'); 
                    else
                        pcvBlockIdx = pcvBlockIdx + 1;
                        atx.PCV(pcvBlockIdx).system = line(4);
                        atx.PCV(pcvBlockIdx).freq = str2double(line(5:6));
                        
                        % Reading of PCV for single frequency
                        i = i + 1; line = raw{i};
                        atx.PCV(pcvBlockIdx).offsetNEU = str2num(line(1:30))/1e3;
                        i = i + 1; line = raw{i};
                        atx.PCV(pcvBlockIdx).PCVnoazi = str2num(line(9:end))/1e3;
                        if ~isempty(atx.azi)
                            for j = 1:numel(atx.azi)
                                i = i + 1; line = raw{i};
                                atx.PCV(pcvBlockIdx).PCV(j,:) = str2num(line(9:end))/1e3;
                            end
                        end
                    end
                end
            end
        end
    end
end