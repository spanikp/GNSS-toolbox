%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to interpolate PCV from ANTEX file
%
% Input: ANTEX - filename of *.atx file ('TRMR8S_NONE.atx')
%        satpos - nx2 array consisting of [Azimuth, Elevation]
%        satsys - character describing GNSS system ('G')
%        freq - callibration frequency (1,2,5)
%        fig - option to plot figure of antenna PCV (plot = 1, not plot = 0) 
%        colorbar_range - 2x1 array to define colorbar range, for default 
%                         values use []
%
% Output: APCoffset - mean APC offset form *.atx file
%         PCVsatpos - interpolated PCV values for given input parameters
%         PCV - rows: constant azimuth (1st row 0deg, last row 360deg)
%               cols: constant elevation (1st col 0deg, last col 90 deg)
%
% Note: Function uses polarplot3d function from MATHWORKS File Exchange
%       written by Ken Garrard 
%       https://www.mathworks.com/matlabcentral/fileexchange/13200-3d-polar-plot/content/polarplot3d.m
%
%       Sample ANTEX file is at Data/PCV
%
% Peter Spanik, 1.2.2017
%
% Updates: 15.2.2017 - Minor text typos fix
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [APCoffset, PCVsatpos, PCV] = antenna_PCV(ANTEX, satpos, satsys, freq, fig, colorbar_range)

   fid = fopen(ANTEX,'r');
   
   %%%%% While loop to find azimuthal step
   DAZI = true; 
   while DAZI
       line = fgetl(fid);
       if ~isempty(strfind(line,'DAZI'))
          DAZI = false;
          line = strsplit(line);
          daz = str2double(line{2});
       end
   end
   az = 0:daz:360;
   
   %%%%% While loop to find elevation step
   DZEN = true; 
   while DZEN
       line = fgetl(fid);
       if ~isempty(strfind(line,'ZEN1 / ZEN2 / DZEN'))
          DZEN = false;
          line = strsplit(line);
          zen = str2double(line{2}):str2double(line{4}):str2double(line{3});
       end
   end
   el = 90 - zen;
     
   %%%%% While loops to find right PCV table
   system = true;
   while system
      stop = true;
      while stop
         line = fgetl(fid);
         if ~isempty(strfind(line,'START OF FREQUENCY'))
            stop = false;
            line = strsplit(line);
            
            if satsys == line{2}(1) && freq == str2double(line{2}(2:3))
               system = false;
            end
         end
      end
   end
   
   line = fgetl(fid);
   line = strsplit(line);
   APCoffset = [str2double(line{2}), str2double(line{3}), str2double(line{4})];   
   line = fgetl(fid); % Skip NOAZI values
   
   %%%%% Loading coresponding PCV table
   PCV = NaN(length(az)-1,length(zen));
   for i = 1:length(az)-1
       line = fgetl(fid);
       all = str2num(line);
       PCV(i,:) = fliplr(all(2:end));
   end

   %%%%% Interpolation of PCV for input satellite's positions
   [EL, AZ] = meshgrid(fliplr(el),az(1:end-1));
   PCVsatpos = interp2(EL,AZ,PCV,satpos(:,2),satpos(:,1),'cubic')/1000;

   %%%%% Graphical output if fig = 1
   if fig == 1
      figure('Name',['PCV from file ', ANTEX],'Position',[300 100 700 480],'NumberTitle', 'off','Resize','off')
      polarplot3d(flipud(PCV'),'PlotType','surfn','RadialRange',[0 90],'PolarGrid',{6,12},'GridStyle',':');
      view(90,-90)
      
      colormap jet
      c = colorbar;
      
      if ~isempty(colorbar_range) % If colorbar_range is defined, use data range if colorbar_range = []
         caxis(colorbar_range)
      end
      c.Position = [c.Position(1)*1.02, c.Position(2)*1.4, 0.8*c.Position(3), c.Position(4)*0.9];
      c.TickDirection = 'out';
      c.LineWidth = 1.1;
      
      ylabel(c,'Phase centre variation (mm)','fontsize',10)
      axis equal
      axis tight
      axis off
      hold on
      text(54,-37,-100,'30','FontSize',9,'FontWeight','bold','HorizontalAlignment','center')
      text(28,-21,-100,'60','FontSize',9,'FontWeight','bold','HorizontalAlignment','center')
   end
    
end