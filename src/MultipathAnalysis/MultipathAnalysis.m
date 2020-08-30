function MultipathAnalysis

% Settings of main window 
fig = figure('Name','MultipathAnalysis (Peter Spanik, 2015)','NumberTitle','off','Toolbar','none','Menubar','none',...
             'Units','pixels','Position',[400 120 600 520],'Resize','off','Color',[0.85 0.85 1],'Visible','on','CloseRequestFcn',@my_close);
         
INPUT = guihandles(fig);
INPUT.ObsFileStatus = 0;      % Status of loading observation file
INPUT.EphFileStatus = 0;      % Status of loading ephemeris file
INPUT.GNSS = [];              % Initialization of GNSS choice
INPUT.ObsFileName = [];       % Initialization of observation filename variable
INPUT.EphFileName = [];       % Initialization of ephemeris filename variable
INPUT.CurrentSats = [];
INPUT.EphFilePositions.G = 0; % Initialization for cases if no ephemeris or no observation are available from input files
INPUT.EphFilePositions.E = 0; % (in loading files there are conditions with these values, so they must be initialized)
INPUT.EphFilePositions.R = 0;
INPUT.EphFilePositions.C = 0;
INPUT.EphFilePositions.J = 0;
INPUT.EphFilePositions.S = 0;
INPUT.ObsFileObservations.G = 0;
INPUT.ObsFileObservations.E = 0;
INPUT.ObsFileObservations.R = 0;
INPUT.ObsFileObservations.C = 0;
INPUT.ObsFileObservations.J = 0;
INPUT.ObsFileObservations.S = 0;
INPUT.ObsPosCurrent{1} = [];
INPUT.CSdetector.New = 'XX';
INPUT.CSdetector.Old = 'XX';
INPUT.CurrentCode = [];
INPUT.CurrentPhase1 = [];
INPUT.CurrentPhase2 = [];
INPUT.Multipath.E.Selection = 0;
INPUT.Multipath.G.Selection = 0;
INPUT.Multipath.FType = 1;
INPUT.ComputedPositions = 0;

% Initialize of statusbar
INPUT.StatusBar.GNSS = 'GNSS: --- || ';
INPUT.StatusBar.Sats = 'Satellite(s): --- || ';
INPUT.StatusBar.Code = 'MP code: --- || ';
INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
INPUT.StatusBar.Phase2 = '--- || ';
guidata(fig,INPUT)

% Panels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uipanel('Title','INPUT files','Units','normalized','Position',[.02 .74 .96 .20],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);
    
uipanel('Title','GNSS selection','Units','normalized','Position',[.02 .56 .46 .16],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);
   
uipanel('Title','Satellites selection','Units','normalized','Position',[.50 .56 .48 .16],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);
    
uipanel('Title','Code multipath computation options','Units','normalized','Position',[.02 .31 .46 .22],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);
    
uipanel('Title','Code multipath outputs','Units','normalized','Position',[.50 .31 .48 .22],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);
    
uipanel('Title','SNR options','Units','normalized','Position',[.02 .12 .46 .17],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);
    
uipanel('Title','SNR outputs','Units','normalized','Position',[.50 .12 .48 .17],'FontSize',9,'FontWeight','bold',...
        'FontName','Arial','BackgroundColor',[.85 .85 1],'BorderType','beveledout','BorderWidth',2);

% Static text field    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('style','text','Units','normalized','position',[.05 .945 .9 .04],'string','MultipathAnalysis tool (Peter Spanik, 2015)','ForeGroundColor','blue',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'FontWeight','bold','FontSize',11,'FontAngle','italic','HorizontalAlignment','center');

uicontrol('style','text','Units','normalized','position',[.045 .825 .18 .025],'string','Observation file: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Observation file   
               
uicontrol('style','text','Units','normalized','position',[.045 .765 .18 .025],'string','Ephemeris file: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Ephemeris file
      
uicontrol('style','text','Units','normalized','position',[.57 .825 .385 .025],'string','Loaded file: ---',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'tag','LoadObsStatus'); % Text: Loaded file: --- (obs)    

uicontrol('style','text','Units','normalized','position',[.57 .765 .385 .025],'string','Loaded file: ---',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'tag','LoadEphStatus'); % Text: Loaded file: --- (eph)
      
uicontrol('style','text','Units','normalized','position',[.045 .65 .3 .025],'string','Available GNSS from observations: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Available GNSS from observations:  
      
uicontrol('style','text','Units','normalized','position',[.045 .59 .4 .025],'string','Selected GNSS constellation:  ---',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'tag','GNSStext'); % Text: Selected GNSS constellation:  

uicontrol('style','text','Units','normalized','position',[.525 .65 .3 .025],'string','Available satellites from constellation: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Available satellites from constellation:    
      
uicontrol('style','text','Units','normalized','position',[.525 .59 .4 .025],'string','Manual satellites selection:',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Manual satellites selection:
      
uicontrol('style','text','Units','normalized','position',[.045 .46 .30 .025],'string','Select code measurement for MP: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Select code measurements for MP:
      
uicontrol('style','text','Units','normalized','position',[.045 .40 .30 .025],'string','Phase measurements: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Select first phase measurements:
      
uicontrol('style','text','Units','normalized','position',[.045 .34 .18 .025],'string','Cycle-slip detector:',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Cycle-slip detector:  
      
uicontrol('style','text','Units','normalized','position',[.525 .46 .30 .025],'string','Satellite(s) availability outputs:',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Visibility outputs:
      
uicontrol('style','text','Units','normalized','position',[.525 .40 .30 .025],'string','Code multipath (MP) outputs:',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Code multipath (MP) outputs:
      
uicontrol('style','text','Units','normalized','position',[.525 .34 .30 .025],'string','Export computed MP values:',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Export computed MP values
      
uicontrol('style','text','Units','normalized','position',[.045 .22 .30 .025],'string','Select satellite SNR measurement: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Select satellite's SNR measurements:
      
uicontrol('style','text','Units','normalized','position',[.045 .16 .11 .025],'string','Select fly-by:',... % [.045 .29 .11 .025]
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'tag','flyby1','Enable','off'); % Text: Select fly-by:
    
uicontrol('style','text','Units','normalized','position',[.525 .22 .35 .025],'string','SNR values graphical outputs: ',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: SNR graphical outputs:

uicontrol('style','text','Units','normalized','position',[.525 .16 .35 .025],'string','Save SNR values from file:',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1]); % Text: Save SNR values from file:
      
uicontrol('style','text','Units','normalized','position',[0 0 1 .025],'String',[INPUT.StatusBar.GNSS,INPUT.StatusBar.Sats,INPUT.StatusBar.Code,INPUT.StatusBar.Phase1,INPUT.StatusBar.Phase2],...
          'HorizontalAlignment','left','tag','statusbar','backgroundcolor',[.5 .5 1],'FontSize',8); % Status bar  
      
% Dynamic text field  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('style','edit','Units','normalized','position',[.75 .585 .21 .04],'HorizontalAlignment','left',...
          'String','SVN in format: 1,2,3 ...','tag','DFsats','Callback',@DFsats_Callback); % Text: Field to manual satellites selection    

% Pushbuttons   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('style','pushbutton','Units','normalized','position',[.20 0.815 .17 .05],'string','Browse ...',...
          'Callback',@BrowseObsData_Callback,'tag','BrowsObs'); % Browse observation file button
      
uicontrol('style','pushbutton','Units','normalized','position',[.38 0.815 .17 .05],'string','Load file',...
          'Callback',@LoadObsData_Callback,'tag','LoadObs'); % Load observation file button 
                
uicontrol('style','pushbutton','Units','normalized','position',[.20 0.755 .17 .05],'string','Browse ...',...
          'Callback',@BrowseEphData_Callback,'tag','BrowsEph'); % Browse ephemeris file button 
      
uicontrol('style','pushbutton','Units','normalized','position',[.38 0.755 .17 .05],'string','Load file',...
          'Callback',@LoadEphData_Callback,'tag','LoadEph'); % Load Ephemeris file button    

uicontrol('style','pushbutton','Units','normalized','position',[.845 0.87 .12 .045],'string','Run',...
          'Callback',@Run_Callback,'tag','run','FontWeight','bold','ForeGroundColor','blue'); % Run button   
      
uicontrol('style','pushbutton','Units','normalized','position',[.78 .33 .18 .045],'string','Export code MP',...
          'Callback',@ExportCode_Callback,'tag','ExportCode','FontWeight','bold'); % Export code MP button   

uicontrol('style','pushbutton','Units','normalized','position',[.78 .15 .18 .045],'string','Export SNR',...
          'Callback',@ExportSNR_Callback,'tag','ExportSNR','FontWeight','bold'); % Export code MP button 
      
uicontrol('style','pushbutton','Units','normalized','position',[.72 0.06 .12 .045],'string','Clear',...
          'Callback',@CA_Callback,'FontWeight','bold'); % Clear
      
uicontrol('style','pushbutton','Units','normalized','position',[.86 0.06 .12 .045],'string','Exit',...
          'Callback',@my_close,'FontWeight','bold'); % Exit
      
uicontrol('style','pushbutton','Units','normalized','position',[.55 0.06 .15 .045],'string','Save INPUT',...
          'Callback',@SaveINPUT_Callback,'FontWeight','bold'); % Save raw INPUT
      
% Pop-up menus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('style','popup','Units','normalized','position',[.34 .66 .12 .025],'string','       ---',...
          'tag','popupGNSS','Callback',@PopupGNSS_Callback); % Pop-up menu for GNSS selection

uicontrol('style','popup','Units','normalized','position',[.84 .66 .12 .025],'string','       ---',...
          'tag','popupSat','Callback',@PopupSat_Callback); % Pop-up menu for satellites selection 
      
uicontrol('style','popup','Units','normalized','position',[.35 .47 .11 .025],'string','      ---',...
          'tag','popupCode','Callback',@PopupCode_Callback); % Pop-up menu for code measurement  
      
uicontrol('style','popup','Units','normalized','position',[.23 .41 .11 .025],'string','      ---',...
          'tag','popupPhase1','Callback',@PopupPhase1_Callback); % Pop-up menu for phase1 measurement 
      
uicontrol('style','popup','Units','normalized','position',[.35 .41 .11 .025],'string','      ---',...
          'tag','popupPhase2','Callback',@PopupPhase2_Callback); % Pop-up menu for phase2 measurement      
      
uicontrol('style','popup','Units','normalized','position',[.780 .47 .18 .025],'string',{'Satellite visibility / time','Satellite elevation / time','Satellite visibility skyplot','Satellite signals availability'},...
          'tag','popupVisibilityOut','Callback',@GraphicAvaOutputs_Callback); % Pop-up menu for availability outputs
      
uicontrol('style','popup','Units','normalized','position',[.780 .41 .18 .025],'string',{'MP as a function of time','MP as a function of elevation','MP skyplot (coloured dots)','MP skyplot (tiny bars)','MP skyplot (interpolated)','MP histogram','Detected cycleslips', 'MP in elevation bins'},...
          'tag','popupMPOut','Callback',@GraphicMPOutputs_Callback); % Pop-up menu for MP outputs
      
uicontrol('style','popup','Units','normalized','position',[.35 .23 .11 .025],'string','      ---',...
          'tag','popupSNR','Callback',@PopupSNR_Callback); % Pop-up menu for SNR measurement 
      
uicontrol('style','popup','Units','normalized','position',[.18 .17 .28 .025],'string','                          ---',... % [.165 .30 .08 .025]
          'tag','popupFlyBy','Callback',@PopupFlyBy_Callback,'Enable','off'); % Pop-up menu for fly-by 

uicontrol('style','popup','Units','normalized','position',[.780 .23 .18 .025],'string',{'SNR in time','SNR in elevation','SNR in skyplot','RMS SNR (interpolated)'},...
          'tag','popupSNRGraphic','Callback',@GraphicSNR_Callback); % Pop-up menu for SNR graphical outputs

% Radiobuttons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('Style','radiobutton','String','Input files in form of -ASCII files (*.**o, *.sp3)','Units','normalized','Position',[.04 .88 .40 .025],...
          'backgroundcolor',[.85 .85 1],'tag','ascii','Value',1,'Callback',@Asciiselection_Callback) 
               
uicontrol('Style','radiobutton','String','Input files in MATLAB format (*.mat)','Units','normalized','backgroundcolor',...
          [.85 .85 1],'Position',[.46 .88 .35 .025],'tag','mat','Value',0,'Callback',@Matselection_Callback)     
      
uicontrol('Style','radiobutton','Units','normalized','position',[.22 .34 .15 .025],'string','Geometry free',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'tag','GF','Value',1,'Callback',@GFselection_Callback); % Text: Geometry free  
      
uicontrol('Style','radiobutton','Units','normalized','position',[.39 .34 .07 .025],'string','MW',...
          'HorizontalAlignment','left','backgroundcolor',[.85 .85 1],'tag','MW','Value',0,'Callback',@MWselection_Callback); % Text: MW 

% Handle radiobutton options for INPUT files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Asciiselection_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if get(findobj('tag','ascii'),'Value') == get(findobj('tag','ascii'),'Max') 
         set(findobj('tag','mat'),'Value',0)
      else
         set(findobj('tag','mat'),'Value',1) 
      end
      guidata(fig,INPUT)
end

function Matselection_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if get(findobj('tag','mat'),'Value') == get(findobj('tag','ascii'),'Max') 
         set(findobj('tag','ascii'),'Value',0)
      else
         set(findobj('tag','ascii'),'Value',1)
      end
      guidata(fig,INPUT)
end

function GFselection_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if get(findobj('tag','GF'),'Value') == get(findobj('tag','GF'),'Max')
         INPUT.CSdetector.Old = INPUT.CSdetector.New;
         INPUT.CSdetector.New = 'GF';
         set(findobj('tag','MW'),'Value',0)
      else
         set(findobj('tag','MW'),'Value',1) 
      end
      guidata(fig,INPUT)
end

function MWselection_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if get(findobj('tag','MW'),'Value') == get(findobj('tag','MW'),'Max') 
         INPUT.CSdetector.Old = INPUT.CSdetector.New;
         INPUT.CSdetector.New = 'MW';
         set(findobj('tag','GF'),'Value',0)
      else
         set(findobj('tag','GF'),'Value',1) 
      end
      guidata(fig,INPUT)
end

% Common used functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lagrange interpolation function
function inty = lagrangeint(X,Y,mytime)

      % Cheking inputs
      if size(X,1) > 1,  X = X'; end
      if size(Y,1) > 1,  Y = Y'; end
      if size(mytime,1) > 1,  mytime = mytime'; end

      % Length of optional vector
      N = length(mytime);

      if length(X) <= 11 % Inputs are smaller than 11 elements 
         for i = 1:N
             DX = mytime(i) - X;
             for j = 1:length(X)
                 DXX = DX;
                 DXX(j) = [];
                 DXXX = X(j) - X;
                 DXXX(j) = [];
                 produ = prod(DXX);
                 prodd = prod(DXXX);
                 LX(j) = Y(j)*(produ/prodd);
             end
             inty(i) = sum(LX);    
         end
      end
      
      if length(X) > 11
         for i = 1:N
             dt = abs(X - mytime(i));
             indexmin = find(abs(dt) == min(abs(dt)));
             indexmin = indexmin(1);
             if indexmin - 5 <= 0
                XX = X(1:11);
                YY = Y(1:11);
             end
        
             if indexmin + 5 >= length(X)
                XX = X(end-11:end);
                YY = Y(end-11:end);
             end
        
             if (indexmin - 5 > 0) && (indexmin + 5 < length(X))
                XX = X(indexmin-5:indexmin+5);
                YY = Y(indexmin-5:indexmin+5);
             end
        
             DX = mytime(i) - XX;
             for j = 1:length(XX)
                 DXX = DX;
                 DXX(j) = [];
                 DXXX = XX(j) - XX;
                 DXXX(j) = [];
                 produ = prod(DXX);
                 prodd = prod(DXXX);
                 LX(j) = YY(j)*(produ/prodd);
             end
             inty(i) = sum(LX);    
         end
     end
end

% Function to adjust FontSize in legend
function fsize = fontsize(list)
      leng = length(list);
      if leng <= 32
         fsize = 6;
         if leng <= 28
            fsize = 7;
            if leng <= 25
               fsize = 8;
               if leng <= 23
                  fsize = 9;
                  if leng <= 21
                     fsize = 10; 
                  end
               end
            end
         end
      end
end

% Check function to put negative angle to interval 0 - 2*pi
function correct = check(incorrect)
% Function to angular correct value, if it is large than 2*pi, or smaller 
% than 0. Output is real number in interval <0, 2*pi>
%
% Created: 31.10.2014
% Creator: Peter Spanik
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      dim = size(incorrect);
      if dim(2) ~= 1, incorrect = incorrect'; end

      for i = 1:size(incorrect,1)
          d = rem(incorrect(i,1), 2*pi);
          n = (incorrect(i,1) - d)/(2*pi); 
          if incorrect(i,1) < 0, correct(i,1) = incorrect(i,1) - (n-1)*2*pi; end
          if incorrect(i,1) > 0, correct(i,1) = incorrect(i,1) - n*2*pi; end 
          if incorrect(i,1) == 0, correct(i,1) = incorrect(i,1);   end
      end
end

% Function to round NUMBER to the closest multiple of MULTIPLE
function out = myround(number,multiple,mode)
% Function to round NUMBER to the closest multiple of MULTIPLE (integer
% number). Variable MODE define if it should be round as floor or ceil.
      numberD = (2*multiple)*floor(number/(2*multiple));
      numberDD = number - numberD; 
      if numberDD < multiple
         out = numberD + multiple; 
      end
      if numberDD >= multiple && strcmp(mode,'ceil')
         out = numberD + 2*multiple; 
      end
      if numberDD >= multiple && strcmp(mode,'floor')
         out = numberD + multiple; 
      end
end

% Function to create comma separated string of input array
function out = mynum2str(input,statustype)
      input = num2str(input);
      
      clear new
      j = 1;
      for i = 1:length(input)
          if strcmp(input(i),' ')
             new(j) = ',';
             if i > 1 && new(j-1) ~= ','
                j = j + 1;
             end
          else
             new(j) = input(i);
             j = j + 1;
          end
      end
      
      switch statustype
          case 'default'
             out = new; 
          case 'Sats'
             if exist('new')
                out = ['Satellite(s): ', new, ' || '];
             else
                out = ['Satellite(s): --- || '];
             end
      end
end

% Function to find indices of SNR observations
function snr_indices = find_snr_indices(obs,par)
    snr_indices = zeros(1,length(obs));
    for i = 1:length(obs)
        if ismember(par,obs{i})
           snr_indices(i) = 1; 
        end
    end
end

% Plot the skeleton of MP skyplot with ticks and other stuff like that :)  
function skyplot_base(ext)
  
    newplot % Prepares axes at current active figure
    hold on

    set(gca,'dataaspectratio',[1 1 1],'plotboxaspectratiomode','auto')
    set(gca,'xlim',[-115 115])
    set(gca,'ylim',[-115 120])
    set(gca,'Units','normalized','Position',ext) % Create axis tight to figure

    % Define a circle and radial circles at 60, 30 and 0 degrees
    th = 0:pi/50:2*pi;
    xunit = cos(th);
    yunit = sin(th);
   
    patch('xdata',95*xunit,'ydata',95*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle','-');
    patch('xdata',90*xunit,'ydata',90*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle',':');
    patch('xdata',60*xunit,'ydata',60*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle',':');
    patch('xdata',30*xunit,'ydata',30*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle',':');
    line([-95 95],[0 0],'color',[0 0 0],'linestyle',':')
    line([-95 95],[0 0],'color',[0 0 0],'linestyle',':')
    line([0 0],[-95 95],'color',[0 0 0],'linestyle',':')
    line([-cos(pi/6)*95 cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
    line([cos(pi/6)*95 -cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
    line([-95/2 95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
    line([95/2 -95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')

    % Add ticks to graph
    text(2,90,'0°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','w','handlevisibility','off','fontsize',9)
    text(2,60,'30°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','w','handlevisibility','off','fontsize',9)
    text(2,30,'60°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','w','handlevisibility','off','fontsize',9)
    text(0,101,'North','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(0,-101,'South','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(105,0,'East','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(-105,0,'West','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(100/2,sqrt(3)*100/2,'30°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(-95/2,sqrt(3)*100/2,'330°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(sqrt(3)*100/2,100/2,'60°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(-sqrt(3)*98/2,100/2,'300°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(95/2,-sqrt(3)*102/2,'150°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(-92/2,-sqrt(3)*102/2,'210°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(-sqrt(3)*98/2,-105/2,'240°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    text(sqrt(3)*98/2,-105/2,'120°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
    axis off
end

% Function to plot visibility skyplot
function skyplot(INPUT) 
% Plot coded skyplot of satellite trajectory defined by azimuth from north and elevation angle.
      figure('Name','Skyplot of satellite(s) visibility','NumberTitle','off','Visible','on',...
             'Units','pixels','Position',[300 75 700 600],'Color',[0.85 0.85 1],'tag','skyplot','Resize','off');
      skyplot_base([0 0 1 1])

      % Plot content of graph
      color = hsv(length(INPUT.ObsPosCurrent));
      for i = 1:length(INPUT.ObsPosCurrent)
          x{i} = (90 - INPUT.ObsPosCurrent{i}(15+INPUT.ObsTypes,:)').*sin((INPUT.ObsPosCurrent{i}(16+INPUT.ObsTypes,:)')*pi/180);
          y{i} = (90 - INPUT.ObsPosCurrent{i}(15+INPUT.ObsTypes,:)').*cos((INPUT.ObsPosCurrent{i}(16+INPUT.ObsTypes,:)')*pi/180);
          sp(i) = plot(x{i},y{i},'o','MarkerSize',3,'MarkerEdgeColor',color(i,:),'MarkerFaceColor',color(i,:));
          hold on
      end

      legend(sp,INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats));
      switch INPUT.GNSS
          case 1
             titul = 'Visibility skyplot of GPS satellite(s)';
          case 2
             titul = 'Visibility skyplot of Galileo satellite(s)';
      end
      text(0,115,titul,'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',12,'fontweight','bold')

      set(gca,'dataaspectratio',[1 1 1])
end

% Function to plot multipath as function of time and elevation and GF/MW combination with detected cycleslips
function INPUT = MP_time_elev_slips(INPUT,plottype) 
% Function to plot code multipath variable MP as function of time/elevation
% or plot selected code-phase combination and detected cycle-slips

      if strcmp(INPUT.CSdetector.Old,'XX') % For case if user let detector selection by default
         switch get(findobj('tag','GF'),'Value') == get(findobj('tag','GF'),'Max')
             case 0 
                INPUT.CSdetector.New = 'MW';
             case 1 
                INPUT.CSdetector.New = 'GF';        
         end
      end

      % Numeric identifier of selected MP combination (for example: 332, 223 ...)
      INPUT.MPCombination = 100*get(findobj('tag','popupCode'),'Value') + 10*get(findobj('tag','popupPhase1'),'Value') + get(findobj('tag','popupPhase2'),'Value');
      switch INPUT.GNSS
          case 1
             if isempty(INPUT.Multipath.G.MP.GF{INPUT.MPCombination}) && isempty(INPUT.Multipath.G.MP.MW{INPUT.MPCombination})
                INPUT.Multipath.G.MP.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.MP.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.MPF.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.MPF.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.RMS.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.RMS.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.Cyclslplot.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.Cyclslplot.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.CSdetector.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
                INPUT.Multipath.G.CSdetector.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.G));
             end
          case 2
             if isempty(INPUT.Multipath.E.MP.GF{INPUT.MPCombination}) && isempty(INPUT.Multipath.E.MP.MW{INPUT.MPCombination})
                INPUT.Multipath.E.MP.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.MP.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.MPF.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.MPF.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.RMS.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.RMS.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.Cyclslplot.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.Cyclslplot.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.CSdetector.GF{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
                INPUT.Multipath.E.CSdetector.MW{INPUT.MPCombination} = cell(1,length(INPUT.ObsFileSats.E));
             end
      end
      
      MPressum = 0;  % Initialize variable to compute residuals
      noobs = 0;     % Initialize variable to compute total number of observations from all selected sats
      
      clear a b c
      for j = 1:length(INPUT.ObsTypesAll)
          if strcmp(INPUT.ObsTypesAll{j},INPUT.CurrentCode),  a = j;  end
          if strcmp(INPUT.ObsTypesAll{j},INPUT.CurrentPhase1),  b = j;  end
          if strcmp(INPUT.ObsTypesAll{j},INPUT.CurrentPhase2),  c = j;  end
      end

      j = 1;
      logic_reselect = zeros(1,length(INPUT.SelectedSats));
      for i = 1:length(INPUT.SelectedSats)
          code_flag = max(unique(INPUT.ObsPosCurrent{i}(8+a,:)));
          phase1_flag = max(unique(INPUT.ObsPosCurrent{i}(8+b,:)));
          phase2_flag = max(unique(INPUT.ObsPosCurrent{i}(8+c,:)));
            
          if code_flag ~= 0 && phase1_flag ~= 0 && phase2_flag ~= 0
             ReSelectedSats(j) = INPUT.SelectedSats(i);
             logic_reselect(i) = 1;
             j = j + 1;
          end
      end 
      logic_reselect = logical(logic_reselect);
      
      if j == 1 % No changes in j means that variable ReSelectedSats does not exist
         ReSelectedSats = []; 
      end
      
      if sum(logic_reselect) ~= length(INPUT.SelectedSats)
         outnew = mynum2str(setdiff(INPUT.SelectedSats,ReSelectedSats),'default');
         if ~isempty(setdiff(INPUT.SelectedSats,ReSelectedSats))
            errordlg({'Selected satellites do not have all necessary observations to compute multipath variable MP. If you do not change satellite selection, software will compute only with available ones and selected satellite(s) will be redefined.';'';['Satellites without all necessary observations: ' outnew]},'Satellite selection interruption')
         end
         clear out 
      end

      clear i j pl sigma F           % clear handle to potential previous plots and variable sigma
      code = INPUT.CurrentCode;      % selected code by pop-up code menu 
      phase1 = INPUT.CurrentPhase1;  % selected phase by pop-up phase1 menu 
      phase2 = INPUT.CurrentPhase2;  % selected phase by pop-up phase2 menu 
      phaseall = INPUT.ObsTypesAll;  % phaseall = all types of observation from RINEX
      c = 299792458;                 % Speed of light 
      
      INPUT.SelectedSats = ReSelectedSats;
      INPUT.ObsPosCurrent = INPUT.ObsPosCurrent(logic_reselect);
      INPUT.SelectedSatsString = INPUT.SelectedSatsString(logic_reselect);
      INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
      
      
if ~isempty(ReSelectedSats)
      switch INPUT.GNSS
          case 1 %%%%%%% GPS CASE %%%%%%%
            % Frequencies and wavelengths of GPS L1,L2 and L5 carriers  
            freqG = [1575.42e6, 1227.60e6, 1176.45e6]; 
            lamG = c./freqG;  
            gnsssattitul = 'GPS satellite(s) ';
            availablesats = INPUT.ObsFileSats.G;
            
            switch phase1(2)
                case '1'
                   lamA = lamG(1);
                   freqA = freqG(1);
                case '2'
                   lamA = lamG(2);
                   freqA = freqG(2);
                case '5'
                   lamA = lamG(3);
                   freqA = freqG(3);
            end

            switch phase2(2)
                case '1'
                   lamB = lamG(1);
                   freqB = freqG(1);
                case '2'
                   lamB = lamG(2);
                   freqB = freqG(2);
                case '5'
                   lamB = lamG(3);
                   freqB = freqG(3);
            end
            
            switch code(2)
                case '1'
                   lam_code = lamG(1);
                case '2'
                   lam_code = lamG(2);
                case '5'
                   lam_code = lamG(3);
            end
            
            
          case 2 %%%%%%% GALILEO CASE %%%%%%%
            % Frequencies and wavelengths of Galileo E1,E5a, E5b and E5 carriers  
            freqE = [1575.42e6, 1176.45e6, 1207.140e6, 1191.795e6,];
            lamE = c./freqE;
            gnsssattitul = 'Galileo satellite(s) ';
            availablesats = INPUT.ObsFileSats.E;
            
            switch phase1(2)
                case '1'
                  lamA = lamE(1);
                  freqA = freqE(1);
                case '5'
                  lamA = lamE(2);
                  freqA = freqE(2);
                case '7'
                  lamA = lamE(3);
                  freqA = freqE(3);
                case '8'
                  lamA = lamE(4);
                  freqA = freqE(4);
            end

            switch phase2(2)
                case '1'
                  lamB = lamE(1);
                  freqB = freqE(1);
                case '5'
                  lamB = lamE(2);
                  freqB = freqE(2);
                case '7'
                  lamB = lamE(3);
                  freqB = freqE(3);
                case '8'
                  lamB = lamE(4);
                  freqB = freqE(4);
            end  
            
            switch code(2)
                case '1'
                   lam_code = lamE(1);
                case '5'
                   lam_code = lamE(2);
                case '7'
                   lam_code = lamE(3);
                case '8'
                   lam_code = lamE(4);
            end
      end
      
      % Finds indicies of selected code and frequencies 
      for i = 1:length(phaseall)
          if strcmp(phaseall{i},code), codeindex = i; end
          if strcmp(phaseall{i},phase1), phase1index = i; end
          if strcmp(phaseall{i},phase2), phase2index = i; end
          if strcmp(phaseall{i},[code(1),phase2(2:3)]), code2index = i; end % Important to compute MW combination
      end
      
      % Phase to write in information window
      switch INPUT.CSdetector.New
          case 'GF'
             ccc = 'geometry free combination';
          case 'MW'
             ccc = 'Melbourne-Wubbena combination';
      end

      % Loop for multiple satellite selection in Satellite selection panel
      for satsel = 1:length(availablesats) %ReSelectedSats
          clear cycleslip SMW meanMW newMP rightsat
          if satsel > length(ReSelectedSats),  break;  end

          for t = 1:length(availablesats)
              if ReSelectedSats(satsel) == availablesats(t)
                 rightsat = t; % rightsat variable is sequence number (poradove cislo) from availablesats array
              end
          end
          
          % If there exist MP for satellite defined by variable rightsat then go to next satellite in array ReSelectedSats
          next_satsel = 0; % Variable to control if there is need to skip this satsel (rightsat) loop
          
          switch INPUT.GNSS
              case 1
                 switch INPUT.CSdetector.New
                     case 'GF'
                        if sum(~cellfun('isempty',INPUT.Multipath.G.MP.GF{INPUT.MPCombination})) ~= 0
                           mp_cell = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                           if ~isempty(mp_cell{rightsat})
                              next_satsel = 1; 
                           end
                        end
                     case 'MW'
                        if sum(~cellfun('isempty',INPUT.Multipath.G.MP.MW{INPUT.MPCombination})) ~= 0
                           mp_cell = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
                           if ~isempty(mp_cell{rightsat})
                              next_satsel = 1; 
                           end
                        end
                 end
                     
              case 2    
                 switch INPUT.CSdetector.New
                     case 'GF'
                        if sum(~cellfun('isempty',INPUT.Multipath.E.MP.GF{INPUT.MPCombination})) ~= 0
                           mp_cell = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                           if ~isempty(mp_cell{rightsat})
                              next_satsel = 1; 
                           end
                        end
                     case 'MW'
                        if sum(~cellfun('isempty',INPUT.Multipath.E.MP.MW{INPUT.MPCombination})) ~= 0
                           mp_cell = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
                           if ~isempty(mp_cell{rightsat})
                              next_satsel = 1; 
                           end
                        end
                 end
          end
          
          if next_satsel == 1 % Very important command because it can skip whole one satsel(rightsat) loop
             continue 
          end
          
          % If righsat do not exist skip loop
          if exist('rightsat')
             sat = INPUT.ObsPos{rightsat};
          else
             continue
          end

          %%%%%%%%%%%%%%%%% Window with information about MP computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          if satsel == 1
             iw = figure('Name','Computation of MP','NumberTitle','off','Toolbar','none','Menubar','none','Resize','off',...
                         'Units','pixels','Position',[550 400 300 80],'Color',[0.85 0.85 1],'Visible','off','tag','iw');
             mpcomb = [INPUT.CurrentCode, ', ', INPUT.CurrentPhase1, ', ',INPUT.CurrentPhase2,'.'];
             uicontrol(iw,'Style','Text','Units','normalized','Position',[.05 .80 .90 .15],'BackgroundColor',[.85 .85 1],...
                       'String','Computation of MP variable for selected satellites.')
             uicontrol(iw,'Style','Text','Units','normalized','Position',[.05 .60 .90 .15],'BackgroundColor',[.85 .85 1],'tag','iwmpc')  
             uicontrol(iw,'Style','Text','Units','normalized','Position',[.05 .38 .90 .17],'BackgroundColor',[.85 .85 1],'tag','iwcs') 
             uicontrol(iw,'Style','Text','Units','normalized','Position',[.05 .12 .90 .17],'BackgroundColor',[.85 .85 1],'tag','iw_var')
             set(findobj('tag','iwcs'),'String',['Cycle slip detector: ', ccc])
             set(findobj('tag','iwmpc'),'String',['Selected MP combination: ', mpcomb])
          end
          
          set(findobj('tag','iw'),'Visible','on')
          set(findobj('tag','iw'),'CloseRequestFcn',[])
          
          selsat = get(findobj('tag','popupSat'),'String');
          switch INPUT.GNSS
              case 1
                 set(findobj('tag','iw_var'),'String',['Computed GPS satellite: ', selsat{rightsat}])
              case 2
                 set(findobj('tag','iw_var'),'String',['Computed Galileo satellite: ', selsat{rightsat}])
          end
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          switch INPUT.CSdetector.New
              case 'GF'
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              % Computation of geometry free combination and cycleslips detection
              L1 = sat(8+phase1index,:)*lamA;
              L2 = sat(8+phase2index,:)*lamB;
              DL{rightsat} = L1 - L2;

              interval = 30;
              j = 1;
              ii = 2; % Similar like i, but starts again from 2 for each cycleslip
              t = sat(8,:);
              t = (t - mean(t)); % transform t to fraction of horus
              window = 10;
              %treshold = 3*(lamB-lamA);
              treshold = 0.20;


              for i = 2:length(sat(8,:))
                  if round(1000*(t(i) - t(i-1))) > 2*round(1000*interval/3600)
                     cycleslip(j) = i;
                     j = j + 1;
                     ii = 1;
                  else
                     %ii = i 
                     if ii >= window 
                        x = t(i-(window-1):i-1);
                        y = DL{rightsat}(i-(window-1):i-1);
                        parfit = polyfit(x,y,2); % Estimate parameters of fitting curve
                        predictval = polyval(parfit,t(i));
                        if abs(DL{rightsat}(i) - predictval) > treshold
                           cycleslip(j) = i;
                           j = j + 1;
                           ii = 1;
                        end
                     else % For cases after detected cycleslip
                        if exist('cycleslip')
                           if DL{rightsat}(i) - DL{rightsat}(i-1) > treshold                             
                              cycleslip(j) = i;
                              j = j + 1;
                              ii = 1;
                           end 
                        else
                           if DL{rightsat}(i) - mean(DL{rightsat}(1:i-1)) > treshold 
                              cycleslip(j) = i;
                              j = j + 1;
                              ii = 1; 
                           end
                        end
                     end
                     ii = ii + 1;
                     %ii = i + 1
                  end
              end

              cyclslplot{rightsat} = NaN(1,length(DL{rightsat})); 
              if exist('cycleslip')
                 for i = 1:length(cycleslip)
                     cyclslplot{rightsat}(cycleslip(i)) = DL{rightsat}(cycleslip(i));
                 end
              end
              
              case 'MW'
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              % Computation of Melbourne-Wubbena combination and cycleslips detection
              phaseWL = (freqA*sat(8+phase1index,:)*lamA - freqB*sat(8+phase2index,:)*lamB)/(freqA - freqB); % Wide phase combination
              codeN = (freqA*sat(8+codeindex,:) + freqB*sat(8+code2index,:))/(freqA + freqB); % Narrow code combination
              MW{rightsat} = phaseWL - codeN; % Melbourne-Wubbena combination

              interval = 30; % Can be changed if it is necessary
              j = 1;
              ii = 2;
              from = 1;
              Kfactor = 6;        %%%%% Very important
              SMW{1}(1) = 0.43;   % Lambda_Wide/2 = 0.86m/2

              for i = 2:size(sat,2)
                  if round(1000*(sat(8,i)-sat(8,i-1))) > 2*round(1000*interval/3600)
                     cycleslip(j) = i;
                     j = j + 1;
                     SMW{j}(1) = 0.43;
                     ii = 2;
                     from = i;
                  else
                     meanMW{j}(ii-1) = mean(MW{rightsat}(from:i)); 
                     if abs(MW{rightsat}(i) - meanMW{j}(ii-1)) > Kfactor*SMW{j}(ii-1)
                        cycleslip(j) = i;
                        j = j + 1;
                        SMW{j}(1) = 0.43;
                        meanMW{j}(1) = MW{rightsat}(i);
                        ii = 2;
                        from = i;
                     end
                     % ii = i
                     SMW{j}(ii) = sqrt(((ii-1)/ii)*SMW{j}(ii-1)^2 + (1/ii)*(MW{rightsat}(i) - meanMW{j}(ii-1))^2);
                     ii = ii + 1;
                     % ii = i + 1
                  end
              end

              cyclslplot{rightsat} = NaN(1,length(MW{rightsat})); 
              if exist('cycleslip')
                 for i = 1:length(cycleslip)
                     cyclslplot{rightsat}(cycleslip(i)) = MW{rightsat}(cycleslip(i));
                 end
              end 
          end
         
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          % Computation of multipath
          if phase1(2) == code(2) || phase2(2) == code(2)
             m = (2*lamA^2)/(lamA^2 - lamB^2);
          else
             m = (lam_code^2 + lamA^2)/(lamA^2 - lamB^2); 
          end
          
          MP{rightsat} = sat(8+codeindex,:) + (m - 1)*sat(8+phase1index,:)*lamA - m*sat(8+phase2index,:)*lamB;

          window = 20;  %%%%%%%%%%%%%%%%%%%%%% Very important
    
          if exist('cycleslip')
             for i = 1:length(cycleslip) 
                 if i == 1 % If there is only one cycleslip
                    newMP{i} = MP{rightsat}(1:cycleslip(i)-1) - mean(MP{rightsat}(1:cycleslip(i)-1));
                 end
                 if i == length(cycleslip)
                    newMP{i+1} = MP{rightsat}(cycleslip(i):end) - mean(MP{rightsat}(cycleslip(i):end));
                    if i ~= 1
                       newMP{i} = MP{rightsat}(cycleslip(i-1):cycleslip(i)-1) - mean(MP{rightsat}(cycleslip(i-1):cycleslip(i)-1));
                    end
                 end
                 if i ~= 1 && i ~= length(cycleslip)
                    newMP{i} = MP{rightsat}(cycleslip(i-1):cycleslip(i)-1) - mean(MP{rightsat}(cycleslip(i-1):cycleslip(i)-1));
                 end
             end
    
             MP{rightsat} = cell2mat(newMP);
    
             % Put NaN where cycleslip occurs (in plot look like empty space; looks better than zeros)
             MP{rightsat}(cycleslip) = NaN;

             for i = 1:length(cycleslip)-1
                 if (cycleslip(i+1) - cycleslip(i)) < window
                    MP{rightsat}(cycleslip(i):cycleslip(i+1)) = NaN; 
                 end
             end
          else
             % If there is no cycleslip just remove mean of MP variable 
             MP{rightsat} = MP{rightsat} - mean(MP{rightsat});
          end
          
          % RMS of MP for every satellite from INPUT.SelectedSats 
          RMS{rightsat} = std(MP{rightsat}(not(isnan(MP{rightsat}))),1); 
      end % Ends satsel loop
      
      set(findobj('tag','iw'),'Visible','off')
      set(findobj('tag','iw'),'CloseRequestFcn','default')
      delete(findobj('tag','iw'))
      clear iw
      
      %%%%%%%%%%%%%%%%%%%%%% Assign MP and others to INPUT variable %%%%%%%%%%%%%%%%%%%%%%
      switch INPUT.GNSS
          case 1
             if exist('MP')
                switch INPUT.CSdetector.New 
                    case 'GF'
                       a = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                       MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP));
                       RMS(length(RMS)+1:length(a)) = cell(1,length(a)-length(RMS));
                       cyclslplot(length(cyclslplot)+1:length(a)) = cell(1,length(a)-length(cyclslplot)); 
                
                       if sum(~cellfun('isempty',INPUT.Multipath.G.MP.GF{INPUT.MPCombination})) == 0
                          INPUT.Multipath.G.MP.GF{INPUT.MPCombination} = MP;
                          INPUT.Multipath.G.MPF.GF{INPUT.MPCombination} = MP;
                          INPUT.Multipath.G.RMS.GF{INPUT.MPCombination} = RMS;
                          INPUT.Multipath.G.Cyclslplot.GF{INPUT.MPCombination} = cyclslplot;
                          INPUT.Multipath.G.CSdetector.GF{INPUT.MPCombination} = DL;
                       else 
                          needed = ones(1,length(a));
                          needed(~cellfun('isempty',a)) = 0;
                          MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP)); % Add empty cell to equal number of cell with a
                          final_choose = needed & ~cellfun('isempty',MP);
               
                          INPUT.Multipath.G.MP.GF{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.G.MPF.GF{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.G.RMS.GF{INPUT.MPCombination}(final_choose) = RMS(final_choose);
                          INPUT.Multipath.G.Cyclslplot.GF{INPUT.MPCombination}(final_choose) = cyclslplot(final_choose); 
                          INPUT.Multipath.G.CSdetector.GF{INPUT.MPCombination}(final_choose) = DL(final_choose);
                       end
                    case 'MW'
                       a = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
                       MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP));
                       RMS(length(RMS)+1:length(a)) = cell(1,length(a)-length(RMS));
                       cyclslplot(length(cyclslplot)+1:length(a)) = cell(1,length(a)-length(cyclslplot)); 
                
                       if sum(~cellfun('isempty',INPUT.Multipath.G.MP.MW{INPUT.MPCombination})) == 0
                          INPUT.Multipath.G.MP.MW{INPUT.MPCombination} = MP;
                          INPUT.Multipath.G.MPF.MW{INPUT.MPCombination} = MP;
                          INPUT.Multipath.G.RMS.MW{INPUT.MPCombination} = RMS;
                          INPUT.Multipath.G.Cyclslplot.MW{INPUT.MPCombination} = cyclslplot;
                          INPUT.Multipath.G.CSdetector.MW{INPUT.MPCombination} = MW;
                       else 
                          needed = ones(1,length(a));
                          needed(~cellfun('isempty',a)) = 0;
                          MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP)); % Add empty cell to equal number of cell with a
                          final_choose = needed & ~cellfun('isempty',MP);
               
                          INPUT.Multipath.G.MP.MW{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.G.MPF.MW{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.G.RMS.MW{INPUT.MPCombination}(final_choose) = RMS(final_choose);
                          INPUT.Multipath.G.Cyclslplot.MW{INPUT.MPCombination}(final_choose) = cyclslplot(final_choose); 
                          INPUT.Multipath.G.CSdetector.MW{INPUT.MPCombination}(final_choose) = MW(final_choose);
                       end
                end
             end
             
          case 2
             if exist('MP')
                switch INPUT.CSdetector.New 
                    case 'GF'
                       a = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                       MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP));
                       RMS(length(RMS)+1:length(a)) = cell(1,length(a)-length(RMS));
                       cyclslplot(length(cyclslplot)+1:length(a)) = cell(1,length(a)-length(cyclslplot)); 
                
                       if sum(~cellfun('isempty',INPUT.Multipath.E.MP.GF{INPUT.MPCombination})) == 0
                          INPUT.Multipath.E.MP.GF{INPUT.MPCombination} = MP;
                          INPUT.Multipath.E.MPF.GF{INPUT.MPCombination} = MP;
                          INPUT.Multipath.E.RMS.GF{INPUT.MPCombination} = RMS;
                          INPUT.Multipath.E.Cyclslplot.GF{INPUT.MPCombination} = cyclslplot;
                          INPUT.Multipath.E.CSdetector.GF{INPUT.MPCombination} = DL;
                       else 
                          needed = ones(1,length(a));
                          needed(~cellfun('isempty',a)) = 0;
                          MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP)); % Add empty cell to equal number of cell with a
                          final_choose = needed & ~cellfun('isempty',MP);
               
                          INPUT.Multipath.E.MP.GF{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.E.MPF.GF{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.E.RMS.GF{INPUT.MPCombination}(final_choose) = RMS(final_choose);
                          INPUT.Multipath.E.Cyclslplot.GF{INPUT.MPCombination}(final_choose) = cyclslplot(final_choose); 
                          INPUT.Multipath.E.CSdetector.GF{INPUT.MPCombination}(final_choose) = DL(final_choose);
                       end
                    case 'MW'
                       a = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
                       MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP));
                       RMS(length(RMS)+1:length(a)) = cell(1,length(a)-length(RMS));
                       cyclslplot(length(cyclslplot)+1:length(a)) = cell(1,length(a)-length(cyclslplot)); 
                
                       if sum(~cellfun('isempty',INPUT.Multipath.E.MP.MW{INPUT.MPCombination})) == 0
                          INPUT.Multipath.E.MP.MW{INPUT.MPCombination} = MP;
                          INPUT.Multipath.E.MPF.MW{INPUT.MPCombination} = MP;
                          INPUT.Multipath.E.RMS.MW{INPUT.MPCombination} = RMS;
                          INPUT.Multipath.E.Cyclslplot.MW{INPUT.MPCombination} = cyclslplot;
                          INPUT.Multipath.E.CSdetector.MW{INPUT.MPCombination} = MW;
                       else 
                          needed = ones(1,length(a));
                          needed(~cellfun('isempty',a)) = 0;
                          MP(length(MP)+1:length(a)) = cell(1,length(a)-length(MP)); % Add empty cell to equal number of cell with a
                          final_choose = needed & ~cellfun('isempty',MP);
               
                          INPUT.Multipath.E.MP.MW{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.E.MPF.MW{INPUT.MPCombination}(final_choose) = MP(final_choose);
                          INPUT.Multipath.E.RMS.MW{INPUT.MPCombination}(final_choose) = RMS(final_choose);
                          INPUT.Multipath.E.Cyclslplot.MW{INPUT.MPCombination}(final_choose) = cyclslplot(final_choose); 
                          INPUT.Multipath.E.CSdetector.MW{INPUT.MPCombination}(final_choose) = MW(final_choose);
                       end
                end
             end
      end
      guidata(fig,INPUT)
          
          switch plottype % Selection of plottype
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              case 1 % MP in time
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              figure('Name','Code multipath as a function of time','NumberTitle','off','Units','pixels',...
                        'Position',[300 150 800 500],'Resize','on','Color',[0.85 0.85 1],'Visible','off','tag','MPwin') 
              
              switch INPUT.GNSS
                  case 1
                      switch INPUT.CSdetector.New
                          case 'GF'
                             MP = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                             RMS = INPUT.Multipath.G.RMS.GF{INPUT.MPCombination};
                          case 'MW'
                             MP = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
                             RMS = INPUT.Multipath.G.RMS.MW{INPUT.MPCombination};
                      end
                  case 2
                      switch INPUT.CSdetector.New
                          case 'GF'
                             MP = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                             RMS = INPUT.Multipath.E.RMS.GF{INPUT.MPCombination};
                          case 'MW'
                             MP = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
                             RMS = INPUT.Multipath.E.RMS.MW{INPUT.MPCombination};
                      end
              end
              
              colorMP = hsv(length(ReSelectedSats)); % INPUT.SelectedSats
              for i = 1:length(ReSelectedSats)
                  [~,index] = ismember(ReSelectedSats(i),availablesats);
                  sat = INPUT.ObsPos{index};
                  time = datenum(sat(2,:),sat(3,:),sat(4,:),sat(5,:),sat(6,:),sat(7,:));
                  if i == 1
                     minmaxt = [time(1)-0.01, time(end)+0.02];
                     minmaxY2 = [-myround(max(abs(MP{index})),0.5,'ceil'), myround(max(abs(MP{index})),0.5,'ceil')];
                  end
                  
                  pl(i) = plot(time,MP{index},'o','MarkerSize',3,'color',colorMP(i,:));
                  mprms{i} = MP{index}(not(isnan(MP{index})));
                  hold on
                  
                  if time(1)-0.01 < minmaxt(1)
                     minmaxt(1) = time(1)-0.01;
                  end
                  if time(end)+0.02 > minmaxt(2)
                     minmaxt(2) = time(end)+0.02;
                  end
              
                  if myround(max(abs(MP{index})),0.5,'ceil') > minmaxY2(2)
                     minmaxY2(1) = -myround(max(abs(MP{index})),0.5,'ceil');
                     minmaxY2(2) = +myround(max(abs(MP{index})),0.5,'ceil');
                  end
              end
              
              % Computation of RMS from all MP cells
              RMS = std(cat(2,mprms{:}),1);
              title(['Code multipath (RMS = ', sprintf('%.2f', RMS), ' m)'],'FontSize',12,'FontWeight','bold')
              xlabel('GPS time (h)')
              ylabel(['MP of code ', INPUT.CurrentCode, ' (', INPUT.CurrentPhase1, ' ,', INPUT.CurrentPhase2, ') (m)'])
              set(gca,'Xlim',minmaxt,'Ylim',minmaxY2)
              datetick('x',15,'keepticks','keeplimits')
              grid on
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              case 2 % MP in elevation
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              figure('Name','Code multipath as a function of elevation','NumberTitle','off','Units','pixels',...
                        'Position',[300 150 800 500],'Resize','on','Color',[0.85 0.85 1],'Visible','off','tag','MPwin') 
              
              switch INPUT.GNSS
                  case 1
                      switch INPUT.CSdetector.New
                          case 'GF'
                             MP = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                             RMS = INPUT.Multipath.G.RMS.GF{INPUT.MPCombination};
                          case 'MW'
                             MP = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
                             RMS = INPUT.Multipath.G.RMS.MW{INPUT.MPCombination};
                      end
                  case 2
                      switch INPUT.CSdetector.New
                          case 'GF'
                             MP = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                             RMS = INPUT.Multipath.E.RMS.GF{INPUT.MPCombination};
                          case 'MW'
                             MP = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
                             RMS = INPUT.Multipath.E.RMS.MW{INPUT.MPCombination};
                      end
              end
              
              sigma = 0;
              colorMP = hsv(length(ReSelectedSats));
              for i = 1:length(ReSelectedSats)
                  [~,index] = ismember(ReSelectedSats(i),availablesats);
                  sat = INPUT.ObsPos{index};

                  if i == 1
                     minmaxX = [-5, myround(max(sat(15+length(INPUT.ObsTypesAll),:)),5,'ceil')];
                     minmaxY = [-myround(max(abs(MP{index})),0.5,'ceil'), myround(max(abs(MP{index})),0.5,'ceil')];
                  end
                  
                  pl(i) = plot(sat(15+length(INPUT.ObsTypesAll),:),MP{index},'o','MarkerSize',3,'color',colorMP(i,:));
                  mprms{i} = MP{index}(not(isnan(MP{index})));
                  hold on
                  
                  if myround(max(sat(15+length(INPUT.ObsTypesAll),:)),5,'ceil') > minmaxX(2)
                     minmaxX = [-5, myround(max(sat(15+length(INPUT.ObsTypesAll),:)),5,'ceil')];
                  end
                  
                  if myround(max(abs(MP{index})),0.5,'ceil') > minmaxY(2)
                     minmaxY(1) = -myround(max(abs(MP{index})),0.5,'ceil');
                     minmaxY(2) = +myround(max(abs(MP{index})),0.5,'ceil');
                  end
              end
              
              RMS = std(cat(2,mprms{:}),1);
              title(['Code mulitpath (RMS = ', sprintf('%.2f', RMS), ' m)'],'FontSize',12,'FontWeight','bold')
              xlabel('Satellite elevation (degrees)')
              ylabel(['MP of code ', INPUT.CurrentCode, ' (', INPUT.CurrentPhase1, ' ,', INPUT.CurrentPhase2, ') (m)'])
              
              set(gca,'Xlim',minmaxX,'Ylim',minmaxY)
              grid on
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              case 3 % MP skyplot (coloured dots)
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              INPUT = mpskyplot(INPUT,1);
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              case 4 % MP skyplot (tiny bars)
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              INPUT = mpskyplot(INPUT,2);
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              case 5 % MP skyplot (interpolated)
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              INPUT = mpskyplot(INPUT,3);
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              case 6 % MP histogram in time
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              INPUT = histogram_cutoff(INPUT);
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
              case 7 % Selected combination and cycleslip detector
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              figure('NumberTitle','off','Units','pixels',...
                     'Position',[300 150 800 500],'Resize','on','Color',[0.85 0.85 1],'Visible','off','tag','MPcs');
            
              switch INPUT.GNSS
                  case 1
                      switch INPUT.CSdetector.New
                          case 'GF'
                             Cyclslplot = INPUT.Multipath.G.Cyclslplot.GF{INPUT.MPCombination};
                             Comb = INPUT.Multipath.G.CSdetector.GF{INPUT.MPCombination};
                          case 'MW'
                             Cyclslplot = INPUT.Multipath.G.Cyclslplot.MW{INPUT.MPCombination};
                             Comb = INPUT.Multipath.G.CSdetector.MW{INPUT.MPCombination};
                      end
                  case 2
                      switch INPUT.CSdetector.New
                          case 'GF'
                             Cyclslplot = INPUT.Multipath.E.Cyclslplot.GF{INPUT.MPCombination};
                             Comb = INPUT.Multipath.E.CSdetector.GF{INPUT.MPCombination};
                          case 'MW'
                             Cyclslplot = INPUT.Multipath.E.Cyclslplot.MW{INPUT.MPCombination};
                             Comb = INPUT.Multipath.E.CSdetector.MW{INPUT.MPCombination};
                      end
              end   
                 
              switch INPUT.CSdetector.New
                  case 'GF'
                     tit = 'Geometry free combination ';
                     set(gcf,'Name','Geometry free combination and detected cycleslips')
                  case 'MW'
                     tit = 'Melbourne-Wubbena combination '; 
                     set(gcf,'Name','Melbourne-Wubbena combination and detected cycleslips')
              end

              if length(ReSelectedSats) == 1
                 color = [0.5 0.5 0.5]; % If there is only one selected satellite the color will be gray
              else
                 color = hsv(length(ReSelectedSats));
              end

              for i = 1:length(ReSelectedSats)
                  [~,index] = ismember(ReSelectedSats(i),availablesats);
                  sat = INPUT.ObsPos{index};
                  time = datenum(sat(2,:),sat(3,:),sat(4,:),sat(5,:),sat(6,:),sat(7,:));
                  
                  if i == 1
                     minmaxt = [time(1)-0.01, time(end)+0.02];
                     minmaxY = [floor(min(Comb{index}))-0.5, ceil(max(Comb{index}))+0.5];
                     hold on
                  end
                  
                  pl(i) = plot(time,Comb{index},'+','color',color(i,:));

                  if length(ReSelectedSats) == 1
                     plot(time,Cyclslplot{index},'o','MarkerSize',3,'MarkerEdgeColor','red','MarkerFaceColor','red');
                     title([tit, '(number of cycleslips = ', num2str(sum(not(isnan(Cyclslplot{index})))), ')'],'FontSize',12,'FontWeight','bold')
                  else
                     plot(time,Cyclslplot{index},'*','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0 0 0]);
                     title(tit,'FontSize',12,'FontWeight','bold') 
                  end
                  
                  if time(1)-0.01 < minmaxt(1)
                     minmaxt(1) = time(1)-0.01;
                  end
                  if time(end)+0.02 > minmaxt(2)
                     minmaxt(2) = time(end)+0.02;
                  end
              
                  if floor(min(Comb{index}))-0.5 < minmaxY(1)
                     minmaxY(1) = floor(min(Comb{index}))-0.5;
                  end
                  if ceil(max(Comb{index}))+0.5 > minmaxY(2)
                     minmaxY(2) = ceil(max(Comb{index}))+0.5;
                  end
              end

              xlabel('GPS time (h)')
              ylabel([tit, '(m)'])
              set(gca,'Xlim',minmaxt,'Ylim',minmaxY)
              datetick('x',15,'keepticks','keeplimits')
              grid on
              set(findobj('tag','MPcs'),'Visible','on')

              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              case 8 % Multipath in elevation bins
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              figure('Name','Multipath in elevation bins','NumberTitle','off','Units','pixels','Visible','off',...
                     'Position',[300 150 800 500],'Resize','off','Color',[0.85 0.85 1],'tag','MPelevbins')
              
              switch INPUT.GNSS
                  case 1
                      switch INPUT.CSdetector.New
                          case 'GF'
                             MP = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                          case 'MW'
                             MP = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
                      end
                  case 2
                      switch INPUT.CSdetector.New
                          case 'GF'
                             MP = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                          case 'MW'
                             MP = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
                      end
              end
                 
              for i = 1:length(ReSelectedSats)
                  [~,index] = ismember(ReSelectedSats(i),availablesats);
                  sat = INPUT.ObsPos{index};
                  choose = not(isnan(MP{index}));
                  %elev = sat(15+length(INPUT.ObsTypesAll),:);
                  
                  if i == 1,  MPel = [[]; []];  end
                  MPel = [MPel, [MP{index}(choose); sat(15+length(INPUT.ObsTypesAll),choose)]]; % Every satellite add abslute MP values
              end
              
              hold on
              el = 0:10:90;
              for i = 1:9
                  MPelbin_pos = MPel(1,MPel(2,:) >= el(i) & MPel(2,:) < el(i+1) & MPel(1,:) >= 0);
                  MPelbin_neg = abs(MPel(1,MPel(2,:) >= el(i) & MPel(2,:) < el(i+1) & MPel(1,:) < 0));
                  meanMPelbin_pos(i) = mean(MPelbin_pos);
                  meanMPelbin_neg(i) = mean(MPelbin_neg);
                  sigma_pos(i) = std(MPelbin_pos,1);
                  sigma_neg(i) = std(MPelbin_neg,1);
                  
                  if i >= 2
                     plot([0.5*(el(i-1)+el(i)), 0.5*(el(i)+el(i+1))],[meanMPelbin_pos(i-1), meanMPelbin_pos(i)],':','Color','red')
                     plot([0.5*(el(i-1)+el(i))+1, 0.5*(el(i)+el(i+1))+1],[meanMPelbin_neg(i-1), meanMPelbin_neg(i)],':','Color','blue') 
                  end
                  
                  % Positive part
                  line([0.5*(el(i) + el(i+1)), 0.5*(el(i) + el(i+1))], [meanMPelbin_pos(i), meanMPelbin_pos(i)+sigma_pos(i)],'color','red','LineWidth',2)
                  line([0.5*(el(i) + el(i+1)), 0.5*(el(i) + el(i+1))], [meanMPelbin_pos(i), meanMPelbin_pos(i)-sigma_pos(i)],'color','red','LineWidth',2)
                  line([0.5*(el(i) + el(i+1))-1, 0.5*(el(i) + el(i+1))+1], [meanMPelbin_pos(i)+sigma_pos(i), meanMPelbin_pos(i)+sigma_pos(i)],'color','red','LineWidth',2)
                  line([0.5*(el(i) + el(i+1))-1, 0.5*(el(i) + el(i+1))+1], [meanMPelbin_pos(i)-sigma_pos(i), meanMPelbin_pos(i)-sigma_pos(i)],'color','red','LineWidth',2)
                  plot(0.5*(el(i) + el(i+1)),meanMPelbin_pos(i),'o','MarkerSize',7,'MarkerEdgeColor','red','MarkerFaceColor','red')
                 
                  % Negative part
                  line([0.5*(el(i) + el(i+1))+1, 0.5*(el(i) + el(i+1))+1], [meanMPelbin_neg(i), meanMPelbin_neg(i)+sigma_neg(i)],'color','blue','LineWidth',2)
                  line([0.5*(el(i) + el(i+1))+1, 0.5*(el(i) + el(i+1))+1], [meanMPelbin_neg(i), meanMPelbin_neg(i)-sigma_neg(i)],'color','blue','LineWidth',2)
                  line([0.5*(el(i) + el(i+1)), 0.5*(el(i) + el(i+1))+2], [meanMPelbin_neg(i)+sigma_neg(i), meanMPelbin_neg(i)+sigma_neg(i)],'color','blue','LineWidth',2)
                  line([0.5*(el(i) + el(i+1)), 0.5*(el(i) + el(i+1))+2], [meanMPelbin_neg(i)-sigma_neg(i), meanMPelbin_neg(i)-sigma_neg(i)],'color','blue','LineWidth',2)
                  plot(0.5*(el(i) + el(i+1))+1,meanMPelbin_neg(i),'o','MarkerSize',7,'MarkerEdgeColor','blue','MarkerFaceColor','blue')
              end 
%                  % Graph with one value for elevation bin
%                  el = 0:10:90;
%                  sigma = zeros(length(el)-1,1);
%                  for i = 1:9
%                      MPelbin = MPel(1,MPel(2,:) >= el(i) & MPel(2,:) < el(i+1));
%                      meanMPelbin(i) = mean(MPelbin);
%                      sigma(i) = std(MPelbin,1);
%                      if i >= 2
%                         plot([0.5*(el(i-1)+el(i)), 0.5*(el(i)+el(i+1))],[meanMPelbin(i-1), meanMPelbin(i)],':','Color','red') 
%                      end
%                      line([0.5*(el(i) + el(i+1)), 0.5*(el(i) + el(i+1))], [meanMPelbin(i), meanMPelbin(i)+sigma(i)],'color','red','LineWidth',2)
%                      line([0.5*(el(i) + el(i+1)), 0.5*(el(i) + el(i+1))], [meanMPelbin(i), meanMPelbin(i)-sigma(i)],'color','red','LineWidth',2)
%                      line([0.5*(el(i) + el(i+1))-1, 0.5*(el(i) + el(i+1))+1], [meanMPelbin(i)+sigma(i), meanMPelbin(i)+sigma(i)],'color','red','LineWidth',2)
%                      line([0.5*(el(i) + el(i+1))-1, 0.5*(el(i) + el(i+1))+1], [meanMPelbin(i)-sigma(i), meanMPelbin(i)-sigma(i)],'color','red','LineWidth',2)
%                      plot(0.5*(el(i) + el(i+1)),meanMPelbin(i),'o','MarkerSize',7,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0 0 0])
%                  end 
              
                 title(['Multipath varible MP (', INPUT.CurrentCode, ', ', INPUT.CurrentPhase1, ', ', INPUT.CurrentPhase2, ') in elevation bins'],'FontSize',12,'FontWeight','bold')
                 xlabel('Elevation (degrees)')
                 ylabel('Mean multipath and corresponding RMS (m)')
                 set(gca,'XLim',[0, myround(max(MPel(2,:)),10,'ceil')])
                 maxY = max([max(meanMPelbin_pos+sigma_pos), max(meanMPelbin_neg+sigma_neg)]);
                 set(gca,'YLim',[0, myround(maxY,0.1,'ceil')])
                 a = get(gca,'XLim');
                 xax = a(2) - a(1);
                 b = get(gca,'YLim');
                 yax = b(2) - b(1);
                 patch([xax*0.68 xax*0.98 xax*0.98 xax*0.68],[yax*0.78 yax*0.78 yax*0.97 yax*0.97],zeros(4,1),'w')
                 plot(xax*0.70, yax*0.93, 'o','MarkerSize',5,'MarkerEdgeColor','red','MarkerFaceColor','red')
                 plot(xax*0.70, yax*0.88, 'o','MarkerSize',5,'MarkerEdgeColor','blue','MarkerFaceColor','blue')
                 line([xax*0.692, xax*0.71], [yax*0.85, yax*0.85], 'Color',[0 0 0],'LineWidth',2)
                 line([xax*0.692, xax*0.71], [yax*0.81, yax*0.81], 'Color',[0 0 0],'LineWidth',2)
                 line([xax*0.70, xax*0.70], [yax*0.81, yax*0.85], 'Color',[0 0 0],'LineWidth',2)
                 text(xax*0.73, yax*0.93, 'Mean positive MP in bin')
                 text(xax*0.73, yax*0.88, 'Mean negative MP in bin')
                 text(xax*0.73, yax*0.83, 'RMS in corresponding bin')
                 grid on
                 set(findobj('tag','MPelevbins'),'Visible','on')
          end
          
          % Add legend to graph
          if plottype == 1 || plottype == 2 || plottype == 7
             legend(pl,INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSatsString)); % ,'FontSize',fontsize(INPUT.SelectedSats)
             hold off
             set(findobj('tag','MPwin'),'Visible','on') % Make figure visible
          end 
end % End ~isempty(ReSelectedSats) condition

      % Update status bar
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      if length(get(findobj('tag','statusbar'),'String')) >= 130
         set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
      else
         set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
      end
      guidata(fig,INPUT)
%       kkk = INPUT;
%       save('INPUT.mat','INPUT')
end 

% Function to show histogram of MP and selection of cut-off value
function INPUT = histogram_cutoff(INPUT)
      INPUT = guidata(fig);
      ff = figure('Name','Multipath histogram','NumberTitle','off','Units','pixels','Visible','off','Toolbar','figure',...
                  'Position',[300 120 800 500],'Resize','on','Color',[0.85 0.85 1],'tag','hist');
      axes('Units','normalized','Position',[0.12 0.24 0.80 0.70])
      uicontrol(ff,'Style','slider','Units','Normalized','Position',[0.27 0.085 0.2 0.04],'Visible','on',...
                   'Callback',@Slider_Callback,'tag','slider');
      uicontrol(ff,'Style','text','Units','Normalized','Position',[0.11 0.09 0.15 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
                   'String','Select cut-off value: ','HorizontalAlignment','left'); 
      uicontrol(ff,'Style','text','Units','Normalized','Position',[0.55 0.09 0.02 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
                   'String','m');
%       uicontrol(ff,'Style','text','Units','Normalized','Position',[0.55 0.04 0.02 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
%                    'String','%');
      uicontrol(ff,'Style','edit','Units','Normalized','Position',[0.48 0.085 0.07 0.04],'Fontsize',10,...
                   'tag','edittext','Callback',@Edittext_Callback); 
%       uicontrol(ff,'Style','edit','Units','Normalized','Position',[0.48 0.035 0.07 0.04],'Fontsize',10,...
%                    'tag','editperc','Callback',@Editperc_Callback);  
      uicontrol(ff,'Style','text','Units','Normalized','Position',[0.11 0.04 0.16 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
                   'String','Choosen cut-off value: ','HorizontalAlignment','left'); 
      uicontrol(ff,'Style','text','Units','Normalized','Position',[0.29 0.04 0.10 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
                   'String','','HorizontalAlignment','left','tag','cutoff'); 
      uicontrol(ff,'Style','text','Units','Normalized','Position',[0.60 0.09 0.21 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
                   'String','MP samples out of cut-off:','HorizontalAlignment','left'); 
      uicontrol(ff,'Style','text','Units','Normalized','Position',[0.82 0.09 0.15 0.03],'BackgroundColor',[0.85 0.85 1],'Fontsize',10,...
                   'String','','HorizontalAlignment','left','tag','count'); 
      uicontrol(ff,'Style','pushbutton','Units','Normalized','Position',[0.77 0.025 0.16 0.05],'Fontsize',10,...
                   'String','Process filtration','HorizontalAlignment','center','tag','proc','Callback',@Filter_Callback);
      
      switch INPUT.GNSS
          case 1
             switch INPUT.CSdetector.New
                 case 'GF'
                    MP = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                 case 'MW'
                    MP = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
             end
          case 2
             switch INPUT.CSdetector.New
                 case 'GF'
                    MP = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                 case 'MW'
                    MP = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
             end
      end
      
      MPF = []; % Filtered MP is the same as original MP
      MPhist = cat(2,MP{:});
      in = num2str(sum(not(isnan(MPhist))));

      % Plot histogram of MP
      xx = -myround(max(abs(MPhist)),0.10,'ceil'):0.05:myround(max(abs(MPhist)),0.10,'ceil');
      yy = hist(MPhist,xx);
      bar(xx,yy)
      com = ['(', INPUT.CurrentCode, ', ', INPUT.CurrentPhase1, ', ', INPUT.CurrentPhase2, ')'];
      title(['Multipath variable MP ', com, ' histogram'],'FontSize',12,'FontWeight','bold')
      xlabel('Multipath value (m)')
      ylabel('Occurence count')
      hold on
      grid on

      pd = fitdist(MPhist','Normal');
      la = line([-pd.sigma -pd.sigma],[0 max(yy)],'color','red','Linewidth',2);
      lb = line([pd.sigma pd.sigma],[0 max(yy)],'color','red','Linewidth',2);
      out =  MPhist <= -pd.sigma | MPhist >= pd.sigma;
      set(findobj('tag','count'),'String',[num2str(sum(out)), '/', in])
      set(gca,'YLim',[0 max(yy)+50],'XLim',[-max(abs(MPhist))-0.1, max(abs(MPhist))+0.1])
      set(findobj('tag','slider'),'Max',max(abs(MPhist))+0.1,'Min',0.05,'Value',pd.sigma)
      set(findobj('tag','cutoff'),'String',sprintf('%.2f m',pd.sigma))
      set(findobj('tag','hist'),'Visible','on')
      INPUT.Multipath.Cutoff = pd.sigma; 
      
      % Draw cutoff value to histogram if it exists
      switch INPUT.GNSS
          case 1
             switch INPUT.CSdetector.New
                 case 'GF'
                    if INPUT.Multipath.G.CutoffTrue.GF(INPUT.MPCombination) == 0
                       cola = line([-max(xx)-10, -max(xx)-10],[0 max(yy)],'color','green','Linewidth',2); colb = line([+max(xx)+10, +max(xx)+10],[0 max(yy)],'color','green','Linewidth',2);
                    else
                       ppp = INPUT.Multipath.G.CutoffTrue.GF(INPUT.MPCombination); 
                       cola = line([-ppp, -ppp],[0 max(yy)],'color','green','Linewidth',2); colb = line([+ppp, +ppp],[0 max(yy)],'color','green','Linewidth',2);
                    end
                 case 'MW'
                    if INPUT.Multipath.G.CutoffTrue.MW(INPUT.MPCombination) == 0
                       cola = line([-max(xx)-10, -max(xx)-10],[0 max(yy)],'color','green','Linewidth',2); colb = line([+max(xx)+10, +max(xx)+10],[0 max(yy)],'color','green','Linewidth',2);
                    else
                       ppp = INPUT.Multipath.G.CutoffTrue.MW(INPUT.MPCombination); 
                       cola = line([-ppp, -ppp],[0 max(yy)],'color','green','Linewidth',2); colb = line([+ppp, +ppp],[0 max(yy)],'color','green','Linewidth',2);
                    end
             end
          case 2
             switch INPUT.CSdetector.New
                 case 'GF'
                    if INPUT.Multipath.E.CutoffTrue.GF(INPUT.MPCombination) == 0
                       cola = line([-max(xx)-10, -max(xx)-10],[0 max(yy)],'color','green','Linewidth',2); colb = line([+max(xx)+10, +max(xx)+10],[0 max(yy)],'color','green','Linewidth',2);
                    else
                       ppp = INPUT.Multipath.E.CutoffTrue.GF(INPUT.MPCombination); 
                       cola = line([-ppp, -ppp],[0 max(yy)],'color','green','Linewidth',2); colb = line([+ppp, +ppp],[0 max(yy)],'color','green','Linewidth',2);
                    end
                 case 'MW'
                    if INPUT.Multipath.E.CutoffTrue.MW(INPUT.MPCombination) == 0
                       cola = line([-max(xx)-10, -max(xx)-10],[0 max(yy)],'color','green','Linewidth',2); colb = line([+max(xx)+10, +max(xx)+10],[0 max(yy)],'color','green','Linewidth',2);
                    else
                       ppp = INPUT.Multipath.E.CutoffTrue.MW(INPUT.MPCombination); 
                       cola = line([-ppp, -ppp],[0 max(yy)],'color','green','Linewidth',2); colb = line([+ppp, +ppp],[0 max(yy)],'color','green','Linewidth',2);
                    end
             end
      end

      % Very important to update also object ff because nested function would not work properly
      guidata(ff,INPUT)
      guidata(fig,INPUT)
      
      % Local functions which have allowed access to local variables la, lb, MPhist andothers ...
      % Function to find value of slider tool and update information about cut-off value and out/in values
      function Slider_Callback(ff,INPUT)
           INPUT = guidata(ff);
           set(findobj('tag','cutoff'),'String',sprintf('%.2f m',get(findobj('tag','slider'),'Value')))
           delete(la); delete(lb);
           la = line([-get(findobj('tag','slider'),'Value') -get(findobj('tag','slider'),'Value')],[0 max(yy)],'color','red','Linewidth',2);
           lb = line([+get(findobj('tag','slider'),'Value') +get(findobj('tag','slider'),'Value')],[0 max(yy)],'color','red','Linewidth',2);
           out = MPhist <= -get(findobj('tag','slider'),'Value') | MPhist >= get(findobj('tag','slider'),'Value');
           set(findobj('tag','count'),'String',[num2str(sum(out)), '/', in])
           INPUT.Multipath.Cutoff = get(findobj('tag','slider'),'Value');
           guidata(ff,INPUT)
           guidata(fig,INPUT)
      end

      % Function to read text from editable box and update information about cut-off value and out/in values
      function Edittext_Callback(ff,INPUT)
           INPUT = guidata(ff);
           if isempty(str2num(get(findobj('tag','edittext'),'String'))) || ismember(' ',get(findobj('tag','edittext'),'String')) || ismember(',',get(findobj('tag','edittext'),'String'))
              errordlg('If you want to select cut-off value manually you have to write number with decimal point, not with comma. For example 1.07 or 0.75.','Wrong input format')
           else
              if str2num(get(findobj('tag','edittext'),'String')) > max(abs(MPhist))
                 errordlg('Selected cut-off value is greater than maximum MP value. Filtration will not perform.','Non-permisible number') 
              else
                 if str2num(get(findobj('tag','edittext'),'String')) <= 0
                    errordlg('Selected cut-off value have to be positive number. Please choose different value or use slider.','Non-permisible number')  
                 else
                    set(findobj('tag','cutoff'),'String',sprintf('%.2f m',str2num(get(findobj('tag','edittext'),'String'))))
                    set(findobj('tag','slider'),'Value',str2num(get(findobj('tag','edittext'),'String')))
                    delete(la); delete(lb);
                    la = line([-str2num(get(findobj('tag','edittext'),'String')) -str2num(get(findobj('tag','edittext'),'String'))],[0 max(yy)],'color','red','Linewidth',2);
                    lb = line([+str2num(get(findobj('tag','edittext'),'String')) +str2num(get(findobj('tag','edittext'),'String'))],[0 max(yy)],'color','red','Linewidth',2);
                    out = MPhist <= -str2num(get(findobj('tag','edittext'),'String')) | MPhist >= str2num(get(findobj('tag','edittext'),'String'));
                    set(findobj('tag','count'),'String',[num2str(sum(out)), '/', in])
                    INPUT.Multipath.Cutoff = str2num(get(findobj('tag','edittext'),'String'));
                 end
              end
           end
           set(findobj('tag','edittext'),'String','')
           guidata(ff,INPUT)
           guidata(fig,INPUT)
      end

%       % Function to read percentage of all epochs to be excluded
%       function Editperc_Callback(ff,INPUT)
%            INPUT = guidata(ff);
%            if isempty(str2num(get(findobj('tag','editperc'),'String'))) || ismember(' ',get(findobj('tag','editperc'),'String')) || ismember(',',get(findobj('tag','editperc'),'String'))
%               errordlg('If you want to select cut-off value by excluded percentage you have to write number with decimal point, not with comma. For example 1.07 or 0.75.','Wrong input format')
%            else
%               if str2num(get(findobj('tag','editperc'),'String')) >= 100
%                  errordlg('Selected cut-off percentage is greater than 100. Filtration will not perform.','Non-permisible number') 
%               else
%                  if str2num(get(findobj('tag','editperc'),'String')) <= 0
%                     errordlg('Selected cut-off percentage have to be positive number. Please choose different value or use slider.','Non-permisible number')  
%                  else
%                      
%                     set(findobj('tag','cutoff'),'String',sprintf('%.2f m',str2num(get(findobj('tag','editperc'),'String'))))
%                     set(findobj('tag','slider'),'Value',str2num(get(findobj('tag','edittext'),'String')))
%                     delete(la); delete(lb);
%                     la = line([-str2num(get(findobj('tag','edittext'),'String')) -str2num(get(findobj('tag','edittext'),'String'))],[0 max(yy)],'color','red','Linewidth',2);
%                     lb = line([+str2num(get(findobj('tag','edittext'),'String')) +str2num(get(findobj('tag','edittext'),'String'))],[0 max(yy)],'color','red','Linewidth',2);
%                     out = MPhist <= -str2num(get(findobj('tag','edittext'),'String')) | MPhist >= str2num(get(findobj('tag','edittext'),'String'));
%                     set(findobj('tag','count'),'String',[num2str(sum(out)), '/', in])
%                     INPUT.Multipath.Cutoff = str2num(get(findobj('tag','edittext'),'String'));
%                  end
%               end
%            end
%            set(findobj('tag','edittext'),'String','')
%            guidata(ff,INPUT)
%            guidata(fig,INPUT)
%       end
      
      % Function to read text from editable box and update information about cut-off value and out/in values 
      function Filter_Callback(ff,INPUT)
        INPUT = guidata(ff);  
        % Find information if selected satellites are all available with particular MP variable combination
        switch INPUT.GNSS
            case 1
               [~,index_code] = ismember(INPUT.CurrentCode,INPUT.ObsTypesAllString.G);
               [~,index_phase1] = ismember(INPUT.CurrentPhase1,INPUT.ObsTypesAllString.G);
               [~,index_phase2] = ismember(INPUT.CurrentPhase2,INPUT.ObsTypesAllString.G);
               set = INPUT.ObsPosBoth.G;
               sat_rnx = INPUT.ObsFileSats.G;
            case 2
               [~,index_code] = ismember(INPUT.CurrentCode,INPUT.ObsTypesAllString.E);
               [~,index_phase1] = ismember(INPUT.CurrentPhase1,INPUT.ObsTypesAllString.E);
               [~,index_phase2] = ismember(INPUT.CurrentPhase2,INPUT.ObsTypesAllString.E);
               set = INPUT.ObsPosBoth.E;
               sat_rnx = INPUT.ObsFileSats.E;
        end
        
        nsats = length(set);
        SatsSignalsAvailability = zeros(INPUT.ObsTypes,nsats);
        for i = 1:length(set)
            for j = 1:INPUT.ObsTypes
                if unique(set{i}(8+j,:)) ~= 0
                   SatsSignalsAvailability(j,i) = 1; 
                end
            end
        end

        capable_sats1 = SatsSignalsAvailability([index_code, index_phase1, index_phase2],:);
        capable_sats2 = capable_sats1(1,:) & capable_sats1(2,:) & capable_sats1(3,:);
        capable_sats3 = sat_rnx(capable_sats2);

        if ~isequal(INPUT.SelectedSats,capable_sats3)
           errordlg('It is not allowed to filter data if not all available satellites for particular MP combination have been selected. If you want to define cut-off value please select all satellites in Satellite selection panel by choice "all".','No allowed operation')
        else
           switch INPUT.GNSS
               case 1
                  switch INPUT.CSdetector.New
                      case 'GF'
                         INPUT.Multipath.G.CutoffTrue.GF(INPUT.MPCombination) = INPUT.Multipath.Cutoff;
                      case 'MW'
                         INPUT.Multipath.G.CutoffTrue.MW(INPUT.MPCombination) = INPUT.Multipath.Cutoff;
                  end
               case 2
                  switch INPUT.CSdetector.New
                      case 'GF'
                         INPUT.Multipath.E.CutoffTrue.GF(INPUT.MPCombination) = INPUT.Multipath.Cutoff;
                      case 'MW'
                         INPUT.Multipath.E.CutoffTrue.MW(INPUT.MPCombination) = INPUT.Multipath.Cutoff;
                  end
           end
           MPhist2 = MPhist;
           MPhist2(out) = NaN; % Fill places which are out of interval by NaN values
           for j = 1:length(MP)
               if j == 1
                  MPF{j} = MPhist2(1:length(MP{j}));
                  nextindex = length(MP{j}) + 1;
               else
                  MPF{j} = MPhist2(nextindex:nextindex+length(MP{j})-1);
                  nextindex = nextindex + length(MP{j});
               end
           end
           
           % Save filtered MPF to INPUT cell structure
           switch INPUT.GNSS
               case 1
                  switch INPUT.CSdetector.New
                      case 'GF'
                         INPUT.Multipath.G.MPF.GF{INPUT.MPCombination} = MPF;
                      case 'MW'
                         INPUT.Multipath.G.MPF.MW{INPUT.MPCombination} = MPF;
                  end
               case 2
                  switch INPUT.CSdetector.New
                      case 'GF'
                         INPUT.Multipath.E.MPF.GF{INPUT.MPCombination} = MPF;
                      case 'MW'
                         INPUT.Multipath.E.MPF.MW{INPUT.MPCombination} = MPF;
                  end
           end
           
           % Plot green lines at position of current cut-off values
           delete(cola); delete(colb);
           cola = line([-INPUT.Multipath.Cutoff, -INPUT.Multipath.Cutoff],[0 max(yy)],'color','green','Linewidth',2);
           colb = line([+INPUT.Multipath.Cutoff, +INPUT.Multipath.Cutoff],[0 max(yy)],'color','green','Linewidth',2);
           
           % Information dialog about processed filtration
           kk = figure('Name','Filtering information','NumberTitle','off','Units','pixels','Position',[550 320 300 100],'Toolbar','none','Menubar','none','Resize','off','Color',[0.85 0.85 1],'Visible','on','tag','filtinfo'); 
           uicontrol(kk,'Style','Text','Units','Normalized','Position',[0.02 0.80 0.96 0.15],'BackgroundColor',[0.85 0.85 1],'Fontsize',8,'String',['Filtering MP by cut-off value = ', sprintf('%.2f m',INPUT.Multipath.Cutoff), ' was processed.'])
           uicontrol(kk,'Style','Text','Units','Normalized','Position',[0.02 0.65 0.96 0.15],'BackgroundColor',[0.85 0.85 1],'Fontsize',8,'String',['Totally ', num2str(sum(out)), ' of ' num2str(in),' original MP epochs were removed.'])
           uicontrol(kk,'Style','Text','Units','Normalized','Position',[0.02 0.50 0.96 0.15],'BackgroundColor',[0.85 0.85 1],'Fontsize',8,'HorizontalAlignment','center','String',['Original MP variable RMS = ', sprintf('%.2f m',std(MPhist(not(isnan(MPhist))),1))])
           uicontrol(kk,'Style','Text','Units','Normalized','Position',[0.02 0.35 0.96 0.15],'BackgroundColor',[0.85 0.85 1],'Fontsize',8,'HorizontalAlignment','center','String',['Filtered MP variable RMS = ', sprintf('%.2f m',std(MPhist2(not(isnan(MPhist2))),1))])
           uicontrol(kk,'Style','PushButton','Units','Normalized','Position',[0.70 0.05 0.25 0.25],'Fontsize',8,'String','OK','Callback',@OK_Callback)
           guidata(kk,INPUT)
           guidata(ff,INPUT)
        end % Ends condition to all available sats    
        guidata(ff,INPUT)
        guidata(fig,INPUT)
        %save('INPUT.mat','INPUT')
      end
      
      function OK_Callback(kk,INPUT)
        INPUT = guidata(kk);
        set(findobj('tag','filtinfo'),'Visible','off')
        guidata(kk,INPUT)
      end
      
      guidata(ff,INPUT)
      guidata(fig,INPUT)
end

% Function to plot MP skyplot with option for original/filtered MP values
function INPUT = mpskyplot(INPUT,type)
	INPUT = guidata(fig);
      sk = figure('Name','Multipath skyplot','NumberTitle','off','Visible','on','tag','MPskyplot','ToolBar','figure',...
                  'Units','pixels','Position',[300 75 700 600],'Color',[0.85 0.85 1],'Resize','off');
      uicontrol(sk,'Style','Text','Units','normalized','Position',[0.78 0.12 0.17 0.03],'String','Select MP type:',...
                'BackgroundColor',[0.85 0.85 1],'fontsize',10,'Horizontalalignment','left','HandleVisibility','off')
      tt = uicontrol(sk,'Style','CheckBox','Units','normalized','Position',[0.78 0.16 0.17 0.03],'String','Show positions',...
                'BackgroundColor',[0.85 0.85 1],'fontsize',10,'Horizontalalignment','left','HandleVisibility','off','Callback',@ShowSats_Callback);      
      gg = uicontrol(sk,'Style','popup','Units','normalized','Position',[0.78 0.08 0.17 0.03],'String',{'Unfiltered MP';'Filtered MP'},...
                    'tag','mppopup','Callback',@MPType_Callback,'fontsize',9,'HandleVisibility','off');   
      INPUT.Multipath.FType = 1; % Multipath filtering type
      guidata(sk,INPUT)
      guidata(fig,INPUT) 
      
      switch INPUT.GNSS
          case 1
             availablesats = INPUT.ObsFileSats.G;
             switch INPUT.CSdetector.New
                 case 'GF'
                    MP = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                 case 'MW'
                    MP = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
             end
          case 2
             availablesats = INPUT.ObsFileSats.E;
             switch INPUT.CSdetector.New
                 case 'GF'
                    MP = INPUT.Multipath.E.MP.GF{INPUT.MPCombination}; 
                 case 'MW'
                    MP = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
             end
      end
      
      switch type
          case 1
             % Plot content of graph
             set(tt,'HandleVisibility','off','Visible','off')
             skyplot_base([0.0 0.0 0.95 1]) % Plot skeleton of skyplot
             X = []; Y = []; xt = []; yt = []; mult = [];
             for i = 1:length(INPUT.SelectedSats)
                 [~,index] = ismember(INPUT.SelectedSats(i),availablesats);
                 x = (90 - INPUT.ObsPos{index}(15+INPUT.ObsTypes,:)).*sin((INPUT.ObsPos{index}(16+INPUT.ObsTypes,:))*pi/180);
                 y = (90 - INPUT.ObsPos{index}(15+INPUT.ObsTypes,:)).*cos((INPUT.ObsPos{index}(16+INPUT.ObsTypes,:))*pi/180);
                 X = [X x]; xt = [xt x(end)];
                 Y = [Y y]; yt = [yt y(end)];
                 mult = [mult MP{index}];
             end

             scatter(X,Y,30,mult,'o','filled')
             text(0,112,['Unfiltered MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') skyplot'],...
                  'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
             set(gca,'dataaspectratio',[1 1 1])
             colormap jet
             colorbar
             pos = [0.90,0.23,0.03,0.60];
             set(findobj(gcf,'Tag','Colorbar'),'Position',pos)
             text(125,89,'MP (m)','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontweight','bold')
             guidata(sk,INPUT)
             guidata(fig,INPUT)
             
          case 2
             set(tt,'HandleVisibility','off','Visible','off')
             % Plotting content of graph
             skyplot_base([0.0 0.0 0.95 1])
             X = []; Y = []; xt = []; yt = []; mult = [];
             rangeMP = 5; % V metroch
             range_xycoord = 30; % V rozsahu dielikov gca
             
             colorowe = hsv(length(INPUT.SelectedSats));
             for f = 1:length(INPUT.SelectedSats)
                 [~,index] = ismember(INPUT.SelectedSats(f),availablesats);
                 %time = INPUT.ObsPos{index}(8,:);
                 elev = INPUT.ObsPos{index}(15+INPUT.ObsTypes,:);  % Elevation in degrees
                 azi = (INPUT.ObsPos{index}(16+INPUT.ObsTypes,:)); % Azimuth in degrees
                 mult = MP{index};
                 x = (90 - elev).*sin(azi*pi/180);
                 y = (90 - elev).*cos(azi*pi/180);
    
                 for jj = 1:length(mult)-1
                     koeficient = (mult(jj)/rangeMP)*range_xycoord;
                     vec = sqrt((x(jj+1) - x(jj))^2 + (y(jj+1) - y(jj))^2);
                     if vec < 50
                        vecx = (x(jj+1) - x(jj))/vec;
                        vecy = (y(jj+1) - y(jj))/vec; 
                        vecnx = -koeficient*vecy;
                        vecny = koeficient*vecx;
                        line([x(jj) x(jj+1)],[y(jj) y(jj+1)],'Color',colorowe(f,:))
                        pll(f) = line([x(jj) x(jj)+vecnx],[y(jj) y(jj)+vecny],'Color',colorowe(f,:));
                     end
                 end
             end
             
             
             text(0,112,['Unfiltered MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') skyplot'],...
                  'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
             set(gca,'dataaspectratio',[1 1 1])
             legend(pll,INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats));
             set(gca,'dataaspectratio',[1 1 1])
             line([67 97],[-98 -98],'Color',[0 0 0])
             line([67 67],[-96 -100],'Color',[0 0 0])
             line([97 97],[-96 -100],'Color',[0 0 0])
             text(84,-102,1,'5 m','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','fontsize',11)

             
          case 3
             set(sk,'Name','Interpolated MP skyplot')
            
             scatter_x = [];
             scatter_y = [];
             scatter_RMS = [];
             sampling = 50;
             
             for i = 1:length(INPUT.SelectedSats)
                 [~,index] = ismember(INPUT.SelectedSats(i),availablesats);
                 time = INPUT.ObsPos{index}(8,:);
                 time = (time - time(1))*24; % time in hours
                 elev = INPUT.ObsPos{index}(15+INPUT.ObsTypes,:);  % Elevation in degrees
                 azi = (INPUT.ObsPos{index}(16+INPUT.ObsTypes,:)); % Azimuth in degrees
                 mult = MP{index};
                 x = (90 - elev).*sin(azi*pi/180);
                 y = (90 - elev).*cos(azi*pi/180);
                 rangeMP = length(mult);
           
                 p = 1;
                 clear splitting_value
                 splitting_value(1) = 1; 
                 for j = 1:length(time)-1
                     if time(j+1) - time(j) > 0.15 %if Delta is greater than 15 minutes
                        mult_splitted{p} = mult(splitting_value(p):j);
                       X{p} = x(splitting_value(p):j);
                        Y{p} = y(splitting_value(p):j);
                        p = p + 1;
                        splitting_value(p) = j + 1; 
                     end  
                     if j == length(time)-1
                        mult_splitted{p} = mult(splitting_value(p):end);
                        X{p} = x(splitting_value(p):end);
                        Y{p} = y(splitting_value(p):end);
                     end
                 end
    
                 cc = 1;
                 for j = 1:length(mult_splitted)
                     for jj = sampling:sampling:length(mult_splitted{j})
                         if ~isempty(jj)
                            subset = mult_splitted{j}(jj-sampling+1:jj);
                            subset_X = X{j}(jj-sampling+1:jj);
                            subset_Y = Y{j}(jj-sampling+1:jj);
               
                            % Find intersection of three logical vectors
                            right = not(isnan(subset)) & not(isnan(subset_X)) & not(isnan(subset_Y));
                            subset = subset(right);
                            subset_X = subset_X(right);
                            subset_Y = subset_Y(right);
               
                            if sum(right) ~= 0
                               RMS_bin{j}(cc) = std(subset,1);
                               Mean_X{j}(cc) = mean(subset_X);
                               Mean_Y{j}(cc) = mean(subset_Y);
                               cc = cc + 1;
                            end
                         end
                     end
                     cc = 1;
                 end
                 
                 if exist('RMS_bin')
                    for j = 1:length(RMS_bin)
                        scatter_RMS = [scatter_RMS, RMS_bin{j}];
                        scatter_x = [scatter_x, Mean_X{j}];
                        scatter_y = [scatter_y, Mean_Y{j}];
                    end
                 else
                    continue
                 end
             end
             
             if exist('RMS_bin')
                newplot % Prepares axes at current active figure
                hold on

                set(gca,'dataaspectratio',[1 1 1],'plotboxaspectratiomode','auto')
                set(gca,'xlim',[-115 115])
                set(gca,'ylim',[-115 120])
                set(gca,'Units','normalized','Position',[0.0 0.0 0.95 1]) % Create axis tight to figure

                % Define a circle and radial circles at 60, 30 and 0 degrees
                th = 0:pi/100:2*pi;
                xunit = cos(th);
                yunit = sin(th);
   
                patch('xdata',95*xunit,'ydata',95*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle','-');

             
                % Find redundant couples in scatter_x & scatter_y
                [~,unique_index] = unique(scatter_x + sqrt(-1)*scatter_y);
                [XX,YY] = meshgrid(unique(scatter_x(unique_index)),unique(scatter_y(unique_index)));
                ZZ = griddata(scatter_x(unique_index),scatter_y(unique_index),scatter_RMS(unique_index),XX,YY);
             
                % Cutting invisible hat from data
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                deg = pi/180;
                DELTA = (0:1:359)*deg;
                R = 6378137;
                [phi0,~,h0] = ecef2geodetic(INPUT.Aproxpos(1),INPUT.Aproxpos(2),INPUT.Aproxpos(3),[R, sqrt(0.00669438002290)]);
                lam0 = 0;
             
                switch INPUT.GNSS
                    case 1
                        INC = 55*deg;
                        a = R + 20200000;
                    case 2              
                        INC = 56*deg;   
                        a = R + 23000000;
                end
             
                X_sat = a.*cos(INC).*cos(DELTA);
                Y_sat = a.*cos(INC).*sin(DELTA);
                Z_sat = ones(1,length(X_sat)).*a.*sin(INC);
                [e, n, u] = ecef2lv(X_sat,Y_sat,Z_sat, phi0, lam0, h0, [R, sqrt(0.00669438002290)]);

                zenit = 90 - atan(u./sqrt(n.^2 + e.^2))/deg;
                azimuth = atan2(e,n)*180/pi;
                for brr = 1:length(azimuth)
                    if azimuth(brr) < 0
                       azimuth(brr) = 360 + azimuth(brr);
                    end
                end
             
                x_edge = zenit.*sin(azimuth*deg);
                y_edge = zenit.*cos(azimuth*deg);
             
                % Slightly change boundaries
                x_edge = x_edge*0.92;
                y_edgee = y_edge - mean(y_edge);
                y_edgee = y_edgee*0.92;
                y_edge = y_edgee + mean(y_edge);
             
                % Control if edge is not out of pre-defined area
                for i = 1:length(y_edge)
                    if sqrt(y_edge(i)^2+x_edge(i)^2) > 95;
                       x_edge(i) = 94*sin(azimuth(i)*deg);
                       y_edge(i) = 94*cos(azimuth(i)*deg);
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                pcolor(XX,YY,ZZ)
                patch('xdata',x_edge,'ydata',y_edge,'facecolor',[1 1 1],'handlevisibility','off','EdgeColor',[1 1 1]);
                plot(90*xunit(1:49),90*yunit(1:49),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                plot(90*xunit(51:end),90*yunit(51:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                plot(75*xunit,75*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                plot(60*xunit(1:47),60*yunit(1:47),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                plot(60*xunit(53:end),60*yunit(53:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                plot(45*xunit,45*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                plot(30*xunit(1:44),30*yunit(1:44),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                plot(30*xunit(55:end),30*yunit(55:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                plot(15*xunit,15*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                line([-95 95],[0 0],'color',[0 0 0],'linestyle','--')
                line([0 0],[-95 27],'color',[0 0 0],'linestyle','--')
                line([0 0],[33 57],'color',[0 0 0],'linestyle','--')
                line([0 0],[63 87],'color',[0 0 0],'linestyle','--')
                line([-cos(pi/6)*95 cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
                line([cos(pi/6)*95 -cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
                line([-95/2 95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
                line([95/2 -95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
                axis off
                
                shading flat
                colormap jet
                colorbar
                pos = [0.90,0.23,0.03,0.60];
                set(findobj(gcf,'Tag','Colorbar'),'Position',pos)
                text(123,89,1,'RMS MP (m)','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontweight','bold')
                text(0,112,1,['Unfiltered interpolated MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') skyplot'],...
                  'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
             
                % Add ticks to graph
                text(2,90,5,'0°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                text(2,60,5,'30°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                text(2,30,5,'60°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                text(0,101,1,'North','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(0,-101,1,'South','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(105,0,1,'East','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(-105,0,1,'West','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(100/2,sqrt(3)*100/2,1,'30°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(-95/2,sqrt(3)*100/2,1,'330°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(sqrt(3)*100/2,100/2,1,'60°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(-sqrt(3)*98/2,100/2,1,'300°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(95/2,-sqrt(3)*102/2,1,'150°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(-92/2,-sqrt(3)*102/2,1,'210°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(-sqrt(3)*98/2,-105/2,1,'240°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                text(sqrt(3)*98/2,-105/2,1,'120°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
             
                %%%%%%%%%%%%%%%%%%%%%%% Ends case 3 (Interpolated MP skyplot) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             else
                set(sk,'HandleVisibility','off','Visible','off')
                errordlg('Not enough observation to make RMS statistics. Please choose more satellites','Not enoght RMS points')
             end
          guidata(sk,INPUT)
          guidata(fig,INPUT)   
      end
      
      function ShowSats_Callback(sk,INPUT)
          INPUT = guidata(sk);
          
          if get(tt,'Value') == get(tt,'Max')
	       INPUT.MultipathPlotSats = plot(scatter_x(unique_index),scatter_y(unique_index),'k.');
          else
	       delete(INPUT.MultipathPlotSats)
          end
          
          guidata(sk,INPUT)
          guidata(fig,INPUT)
      end
      
      function MPType_Callback(sk,INPUT)
          INPUT = guidata(sk);
           
          if get(gg,'value') == 1
             INPUT.Multipath.FType = 1; % disp('Unfiltered')
          end
          if get(gg,'value') == 2
             INPUT.Multipath.FType = 2; % disp('Filtered')
          end

          % Switch for system, CS detector and Original/filtered option
          switch INPUT.GNSS
              case 1
                 availablesats = INPUT.ObsFileSats.G;
                 switch INPUT.CSdetector.New
                     case 'GF'
                        switch INPUT.Multipath.FType
                            case 1
                               MP = INPUT.Multipath.G.MP.GF{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.G.CutoffTrue.GF(INPUT.MPCombination);
                            case 2
                               MP = INPUT.Multipath.G.MPF.GF{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.G.CutoffTrue.GF(INPUT.MPCombination);
                        end
                     case 'MW'
                        switch INPUT.Multipath.FType
                            case 1
                               MP = INPUT.Multipath.G.MP.MW{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.G.CutoffTrue.MW(INPUT.MPCombination);
                            case 2
                               MP = INPUT.Multipath.G.MPF.MW{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.G.CutoffTrue.MW(INPUT.MPCombination);
                        end
                 end
              case 2
                 availablesats = INPUT.ObsFileSats.E;
                 switch INPUT.CSdetector.New
                     case 'GF'
                        switch INPUT.Multipath.FType
                            case 1
                               MP = INPUT.Multipath.E.MP.GF{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.E.CutoffTrue.GF(INPUT.MPCombination);
                            case 2
                               MP = INPUT.Multipath.E.MPF.GF{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.E.CutoffTrue.GF(INPUT.MPCombination);
                        end
                     case 'MW'
                        switch INPUT.Multipath.FType
                            case 1
                               MP = INPUT.Multipath.E.MP.MW{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.E.CutoffTrue.MW(INPUT.MPCombination);
                            case 2
                               MP = INPUT.Multipath.E.MPF.MW{INPUT.MPCombination};
                               cutoff = INPUT.Multipath.E.CutoffTrue.MW(INPUT.MPCombination);
                        end
                 end
          end
          
          if cutoff ~= 0
             clf
             cla

             switch type
                 case 1
                    skyplot_base([0.0 0.0 0.95 1]) % Plots skeleton
                    X = []; Y = []; xt = []; yt = []; mult = [];
                    for i = 1:length(INPUT.SelectedSats)
                        [~,index] = ismember(INPUT.SelectedSats(i),availablesats);
                        x = (90 - INPUT.ObsPos{index}(15+INPUT.ObsTypes,:)).*sin((INPUT.ObsPos{index}(16+INPUT.ObsTypes,:))*pi/180);
                        y = (90 - INPUT.ObsPos{index}(15+INPUT.ObsTypes,:)).*cos((INPUT.ObsPos{index}(16+INPUT.ObsTypes,:))*pi/180);
                        X = [X x]; xt = [xt x(end)];
                        Y = [Y y]; yt = [yt y(end)];
                        mult = [mult MP{index}];
                    end

                    scatter(X,Y,30,mult,'o','filled')
                    switch INPUT.Multipath.FType
                        case 1
                           text(0,112,['Unfiltered MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') skyplot'],...
                                'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
                        case 2
                           text(0,112,['Filtered MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') by cut-off value = ', sprintf('%.2f m',cutoff)],...
                                'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
                    end

                    set(gca,'dataaspectratio',[1 1 1])
                    colormap jet
                    colorbar
                    pos = [0.90,0.23,0.03,0.60];
                    set(findobj(gcf,'Tag','Colorbar'),'Position',pos)
                    text(125,89,'MP (m)','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontweight','bold')
                    
                 case 2
                    skyplot_base([0.0 0.0 0.95 1]) % Plots skeleton
                    X = []; Y = []; xt = []; yt = []; mult = [];
                    rangeMP = 5; % V metroch
                    range_xycoord = 30; % V rozsahu dielikov gca
             
                    colorowe = hsv(length(INPUT.SelectedSats));
                    for f = 1:length(INPUT.SelectedSats)
                        [~,index] = ismember(INPUT.SelectedSats(f),availablesats);
                        elev = INPUT.ObsPos{index}(15+INPUT.ObsTypes,:);  % Elevation in degrees
                        azi = (INPUT.ObsPos{index}(16+INPUT.ObsTypes,:)); % Azimuth in degrees
                        mult = MP{index};
                        x = (90 - elev).*sin(azi*pi/180);
                        y = (90 - elev).*cos(azi*pi/180);
    
                        for jj = 1:length(mult)-1
                            koeficient = (mult(jj)/rangeMP)*range_xycoord;
                            vec = sqrt((x(jj+1) - x(jj))^2 + (y(jj+1) - y(jj))^2);
                            if vec < 50
                               vecx = (x(jj+1) - x(jj))/vec;
                               vecy = (y(jj+1) - y(jj))/vec; 
                               vecnx = -koeficient*vecy;
                               vecny = koeficient*vecx;
                               line([x(jj) x(jj+1)],[y(jj) y(jj+1)],'Color',colorowe(f,:))
                               pll(f) = line([x(jj) x(jj)+vecnx],[y(jj) y(jj)+vecny],'Color',colorowe(f,:));
                            end
                        end
                    end
             
                    text(0,112,['Filtered MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') skyplot'],...
                         'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
                    set(gca,'dataaspectratio',[1 1 1])
                    legend(pll,INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats));
                    line([67 97],[-98 -98],'Color',[0 0 0])
                    line([67 67],[-96 -100],'Color',[0 0 0])
                    line([97 97],[-96 -100],'Color',[0 0 0])
                    text(84,-102,1,'5 m','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','fontsize',11)
                    
                 case 3   %%%%% Interpolated RMS MP
                    set(tt,'Value',0)
                    scatter_x = [];
                    scatter_y = [];
                    scatter_RMS = [];
                    sampling = 50;
             
                    for i = 1:length(INPUT.SelectedSats)
                        [~,index] = ismember(INPUT.SelectedSats(i),availablesats);
                        time = INPUT.ObsPos{index}(8,:);
                        time = (time - time(1))*24; % time in hours
                        elev = INPUT.ObsPos{index}(15+INPUT.ObsTypes,:);  % Elevation in degrees
                        azi = (INPUT.ObsPos{index}(16+INPUT.ObsTypes,:)); % Azimuth in degrees
                        mult = MP{index};
                        x = (90 - elev).*sin(azi*pi/180);
                        y = (90 - elev).*cos(azi*pi/180);
                        rangeMP = length(mult);
           
                        p = 1;
                        clear splitting_value
                        splitting_value(1) = 1; 
                        for j = 1:length(time)-1
                            if time(j+1) - time(j) > 0.15 %if Delta is greater than 15 minutes
                               mult_splitted{p} = mult(splitting_value(p):j);
                               X{p} = x(splitting_value(p):j);
                               Y{p} = y(splitting_value(p):j);
                               p = p + 1;
                               splitting_value(p) = j + 1; 
                            end  
                            if j == length(time)-1
                               mult_splitted{p} = mult(splitting_value(p):end);
                               X{p} = x(splitting_value(p):end);
                               Y{p} = y(splitting_value(p):end);
                            end
                        end
    
                        cc = 1;
                        for j = 1:length(mult_splitted)
                            for jj = sampling:sampling:length(mult_splitted{j})
                                if ~isempty(jj)
                                   subset = mult_splitted{j}(jj-sampling+1:jj);
                                   subset_X = X{j}(jj-sampling+1:jj);
                                   subset_Y = Y{j}(jj-sampling+1:jj);
               
                                   % Find intersection of three logical vectors
                                   right = not(isnan(subset)) & not(isnan(subset_X)) & not(isnan(subset_Y));
                                   subset = subset(right);
                                   subset_X = subset_X(right);
                                   subset_Y = subset_Y(right);
               
                                   if sum(right) ~= 0
                                      RMS_bin{j}(cc) = std(subset,1);
                                      Mean_X{j}(cc) = mean(subset_X);
                                      Mean_Y{j}(cc) = mean(subset_Y);
                                      cc = cc + 1;
                                   end
                                end
                            end
                            cc = 1;
                        end
    
                        for j = 1:length(RMS_bin)
                            scatter_RMS = [scatter_RMS, RMS_bin{j}];
                            scatter_x = [scatter_x, Mean_X{j}];
                            scatter_y = [scatter_y, Mean_Y{j}];
                        end
                    end
             
                    newplot % Prepares axes at current active figure
                    hold on

                    set(gca,'dataaspectratio',[1 1 1],'plotboxaspectratiomode','auto')
                    set(gca,'xlim',[-115 115])
                    set(gca,'ylim',[-115 120])
                    set(gca,'Units','normalized','Position',[0.0 0.0 0.95 1]) % Create axis tight to figure

                    % Define a circle and radial circles at 60, 30 and 0 degrees
                    th = 0:pi/100:2*pi;
                    xunit = cos(th);
                    yunit = sin(th);

                    patch('xdata',95*xunit,'ydata',95*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle','-');

                    % Find redundant couples in scatter_x & scatter_y
                    [~,unique_index] = unique(scatter_x + sqrt(-1)*scatter_y);
                    [XX,YY] = meshgrid(unique(scatter_x(unique_index)),unique(scatter_y(unique_index)));
                    ZZ = griddata(scatter_x(unique_index),scatter_y(unique_index),scatter_RMS(unique_index),XX,YY);
             
                    % Cutting invisible hat from data
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    deg = pi/180;
                    DELTA = (0:1:359)*deg;
                    R = 6378137;
                    [phi0,~,h0] = ecef2geodetic(INPUT.Aproxpos(1),INPUT.Aproxpos(2),INPUT.Aproxpos(3),[R, sqrt(0.00669438002290)]);
                    lam0 = 0;
             
                    switch INPUT.GNSS
                        case 1
                           INC = 55*deg;
                           a = R + 20200000;
                        case 2              
                           INC = 56*deg;   
                           a = R + 23000000;
                    end
             
                    X_sat = a.*cos(INC).*cos(DELTA);
                    Y_sat = a.*cos(INC).*sin(DELTA);
                    Z_sat = ones(1,length(X_sat)).*a.*sin(INC);
                    [e, n, u] = ecef2lv(X_sat,Y_sat,Z_sat, phi0, lam0, h0, [R, sqrt(0.00669438002290)]);

                    zenit = 90 - atan(u./sqrt(n.^2 + e.^2))/deg;
                    azimuth = atan2(e,n)*180/pi;
                    for brr = 1:length(azimuth)
                        if azimuth(brr) < 0
                           azimuth(brr) = 360 + azimuth(brr);
                        end
                    end
             
                    x_edge = zenit.*sin(azimuth*deg);
                    y_edge = zenit.*cos(azimuth*deg);
             
                    % Slightly change boundaries
                    x_edge = x_edge*0.92;
                    y_edgee = y_edge - mean(y_edge);
                    y_edgee = y_edgee*0.92;
                    y_edge = y_edgee + mean(y_edge);
             
                    % Control if edge is not out of pre-defined area
                    for i = 1:length(y_edge)
                        if sqrt(y_edge(i)^2+x_edge(i)^2) > 95;
                           x_edge(i) = 94*sin(azimuth(i)*deg);
                           y_edge(i) = 94*cos(azimuth(i)*deg);
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    pcolor(XX,YY,ZZ)
                    patch('xdata',x_edge,'ydata',y_edge,'facecolor',[1 1 1],'handlevisibility','off','EdgeColor',[1 1 1]);
                    plot(90*xunit(1:49),90*yunit(1:49),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                    plot(90*xunit(51:end),90*yunit(51:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                    plot(75*xunit,75*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                    plot(60*xunit(1:47),60*yunit(1:47),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                    plot(60*xunit(53:end),60*yunit(53:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                    plot(45*xunit,45*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                    plot(30*xunit(1:44),30*yunit(1:44),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                    plot(30*xunit(55:end),30*yunit(55:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                    plot(15*xunit,15*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                    line([-95 95],[0 0],'color',[0 0 0],'linestyle','--')
                    line([0 0],[-95 27],'color',[0 0 0],'linestyle','--')
                    line([0 0],[33 57],'color',[0 0 0],'linestyle','--')
                    line([0 0],[63 87],'color',[0 0 0],'linestyle','--')
                    line([-cos(pi/6)*95 cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
                    line([cos(pi/6)*95 -cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
                    line([-95/2 95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
                    line([95/2 -95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
                    axis off
                    
                    shading flat
                    colormap jet
                    colorbar
                    pos = [0.90,0.23,0.03,0.60];
                    set(findobj(gcf,'Tag','Colorbar'),'Position',pos)
                    text(123,89,1,'RMS MP (m)','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontweight','bold')
                    text(0,112,1,['Filtered interpolated MP (',INPUT.CurrentCode,', ',INPUT.CurrentPhase1,', ',INPUT.CurrentPhase2,') skyplot'],...
                         'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
             
                     % Add ticks to graph
                     text(2,90,5,'0°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(2,60,5,'30°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(2,30,5,'60°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(0,101,1,'North','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(0,-101,1,'South','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(105,0,1,'East','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(-105,0,1,'West','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(100/2,sqrt(3)*100/2,1,'30°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(-95/2,sqrt(3)*100/2,1,'330°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(sqrt(3)*100/2,100/2,1,'60°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(-sqrt(3)*98/2,100/2,1,'300°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(95/2,-sqrt(3)*102/2,1,'150°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(-92/2,-sqrt(3)*102/2,1,'210°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(-sqrt(3)*98/2,-105/2,1,'240°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                     text(sqrt(3)*98/2,-105/2,1,'120°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold') 
             end
          end
          guidata(sk,INPUT)
          guidata(fig,INPUT)
      end
      guidata(sk,INPUT)
      guidata(fig,INPUT)
end

% Callback function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BrowseObsData_Callback(fig,INPUT)
    if get(findobj('tag','ascii'),'Value') == get(findobj('tag','ascii'),'Max') 
      INPUT = guidata(fig);
      [INPUT.ObsFileName, INPUT.ObsFilePath] = uigetfile({'*.**o','Observation files (*.yyo)'},'Select the observation file');
      guidata(fig,INPUT)
    else
      INPUT = guidata(fig);
      [INPUT.ObsFileName, INPUT.ObsFilePath] = uigetfile({'*.mat','Observation files (*.mat)'},'Select the observation file');
      guidata(fig,INPUT)
    end
end

function BrowseEphData_Callback(fig,INPUT)
    if get(findobj('tag','ascii'),'Value') == get(findobj('tag','ascii'),'Max') 
      INPUT = guidata(fig);
      [INPUT.EphFileName, INPUT.EphFilePath] = uigetfile({'*.sp3','Standard product format(*.sp3)'},'Select the ephemeris file');
      guidata(fig,INPUT)
    else
      INPUT = guidata(fig);
      [INPUT.EphFileName, INPUT.EphFilePath] = uigetfile({'*.mat','Ephemeris files (*.mat)'},'Select the ephemeris file');
      guidata(fig,INPUT)
    end
end

function LoadObsData_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if get(findobj('tag','ascii'),'Value') == get(findobj('tag','ascii'),'Max')
          
         if isempty(INPUT.ObsFileName) || isnumeric(INPUT.ObsFileName)
            errordlg('Please select observation file by Browse button.','Loading file interruption')
         else
             
            INPUT.ObsFileStatus = 0;      % Status of loaded observation file
                  fop = fopen([INPUT.ObsFilePath, INPUT.ObsFileName]); % Open file
                  nosys = 0;             % Number of GNSS systems
                  headlines = 0;         % Number of headerlines file
      
                  %%%%%%%%%%%%%%%%%%%%%%%%%% Loop for finding observation types of GPS and Galileo %%%%%%%%%%%%%%%%%%%%%%%%   
                  while 1  % GPS types
                      line = fgetl(fop);
                      answer = findstr(line,'SYS / # / OBS TYPES');
                        
                      if ~isempty(answer) && line(1) == 'G'
                          notypes = str2num(line(2:6));   % Number of observation types
                          types = cell(notypes,1);        % Allocate space for types
                          alltypes = line(7:58);

                          for i = 1:26
                              if i <=13
                                 types(i) = {alltypes((i*4-2):(i*4))}; 
                              end
          
                              if i == 14
                                 line = fgetl(fop);
                                 alltypes = line(7:58);
                              end
          
                              if i >= 14 && line(1) == ' '
                                 types(i) = {alltypes(((i-13)*4-2):((i-13)*4))};
                              end
                          end
                      end
 
                      if ~isempty(findstr(line,'END OF HEADER'))
                          break
                      end
                 end % while loop end
                 
                 if exist('notypes')
                    types = types(1:notypes)';
                    INPUT.ObsTypesAllString.G = types;
                    j = 1; k = 1; l = 1;
                    
                    for i = 1:length(types)
                        if strcmp(types{i}(1),'C')
                           INPUT.ObsCodeString.G{j} = types{i};
                           j = j + 1;
                        end
                
                        if strcmp(types{i}(1),'L')
                           INPUT.ObsPhase1String.G{k} = types{i};
                           k = k + 1;
                        end
                
                        if strcmp(types{i}(1),'S')
                           INPUT.ObsSNRString.G{l} = types{i};
                           l = l + 1;
                        end
                    end
                 end
     
                 frewind(fop)
                 clear types answer line notypes alltypes
     
                 while 1  % Galileo types
                     line = fgetl(fop);
                     answer = findstr(line,'SYS / # / OBS TYPES');
                        
                     if ~isempty(answer) && line(1) == 'E'
                         notypes = str2num(line(2:6));   % Number of observation types
                         clear types
                         types = cell(notypes,1);        % Allocate space for types
                         alltypes = line(7:58);

                         for i = 1:26
                             if i <=13
                                types(i) = {alltypes((i*4-2):(i*4))}; 
                             end
          
                             if i == 14
                                line = fgetl(fop);
                                alltypes = line(7:58);
                             end
                      
                             if i >= 14 && line(1) == ' '
                                types(i) = {alltypes(((i-13)*4-2):((i-13)*4))};
                             end
                         end
                     end
 
                     if ~isempty(findstr(line,'END OF HEADER'))
                         break
                     end
                 end % while loop end

                 
                 if exist('notypes')
                    types = types(1:notypes)';
                    INPUT.ObsTypesAllString.E = types;
                    j = 1; k = 1; l = 1;
                    
                    for i = 1:length(types)
                        if strcmp(types{i}(1),'C')
                           INPUT.ObsCodeString.E{j} = types{i};
                           j = j + 1;
                        end
                
                        if strcmp(types{i}(1),'L')
                           INPUT.ObsPhase1String.E{k} = types{i};
                           k = k + 1;
                        end
                
                        if strcmp(types{i}(1),'S')
                           INPUT.ObsSNRString.E{l} = types{i};
                           l = l + 1;
                        end
                    end
                 end
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                 frewind(fop)
                 clear types answer line notypes alltypes
     
                 while 1  % Beidou types
                     line = fgetl(fop);
                     answer = findstr(line,'SYS / # / OBS TYPES');
                        
                     if ~isempty(answer) && line(1) == 'C'
                         notypes = str2num(line(2:6));   % Number of observation types
                         clear types
                         types = cell(notypes,1);        % Allocate space for types
                         alltypes = line(7:58);

                         for i = 1:26
                             if i <=13
                                types(i) = {alltypes((i*4-2):(i*4))}; 
                             end
          
                             if i == 14
                                line = fgetl(fop);
                                alltypes = line(7:58);
                             end
                      
                             if i >= 14 && line(1) == ' '
                                types(i) = {alltypes(((i-13)*4-2):((i-13)*4))};
                             end
                         end
                     end
 
                     if ~isempty(findstr(line,'END OF HEADER'))
                         break
                     end
                 end % while loop end

                 
                 if exist('notypes')
                    types = types(1:notypes)';
                    INPUT.ObsTypesAllString.C = types;
                    j = 1; k = 1; l = 1;
                    
                    for i = 1:length(types)
                        if strcmp(types{i}(1),'C')
                           INPUT.ObsCodeString.C{j} = types{i};
                           j = j + 1;
                        end
                
                        if strcmp(types{i}(1),'L')
                           INPUT.ObsPhase1String.C{k} = types{i};
                           k = k + 1;
                        end
                
                        if strcmp(types{i}(1),'S')
                           INPUT.ObsSNRString.C{l} = types{i};
                           l = l + 1;
                        end
                    end
                 end
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                 frewind(fop)
                 clear types answer line notypes alltypes
     
                 while 1  % GLONASS types
                     line = fgetl(fop);
                     answer = findstr(line,'SYS / # / OBS TYPES');
                        
                     if ~isempty(answer) && line(1) == 'R'
                         notypes = str2num(line(2:6));   % Number of observation types
                         clear types
                         types = cell(notypes,1);        % Allocate space for types
                         alltypes = line(7:58);

                         for i = 1:26
                             if i <=13
                                types(i) = {alltypes((i*4-2):(i*4))}; 
                             end
          
                             if i == 14
                                line = fgetl(fop);
                                alltypes = line(7:58);
                             end
                      
                             if i >= 14 && line(1) == ' '
                                types(i) = {alltypes(((i-13)*4-2):((i-13)*4))};
                             end
                         end
                     end
 
                     if ~isempty(findstr(line,'END OF HEADER'))
                         break
                     end
                 end % while loop end

                 
                 if exist('notypes')
                    types = types(1:notypes)';
                    INPUT.ObsTypesAllString.R = types;
                    j = 1; k = 1; l = 1;
                    
                    for i = 1:length(types)
                        if strcmp(types{i}(1),'C')
                           INPUT.ObsCodeString.R{j} = types{i};
                           j = j + 1;
                        end
                
                        if strcmp(types{i}(1),'L')
                           INPUT.ObsPhase1String.R{k} = types{i};
                           k = k + 1;
                        end
                
                        if strcmp(types{i}(1),'S')
                           INPUT.ObsSNRString.R{l} = types{i};
                           l = l + 1;
                        end
                    end
                 end
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                 frewind(fop)
                 clear types answer line notypes alltypes
                 
                 % Loop for finding number of GNSS systems and number of types
                  while 1  
                        line = fgetl(fop);
                        answer = findstr(line,'SYS / # / OBS TYPES');
                        answerpos = findstr(line,'APPROX POSITION XYZ');
                        headlines = headlines + 1;

                       if ~isempty(answerpos)   % Find aproximative position from RINEX file
                            INPUT.Aproxpos(1) = str2num(line(1:14));
                            INPUT.Aproxpos(2) = str2num(line(15:28));
                            INPUT.Aproxpos(3) = str2num(line(29:42));
                        end
   
                        if ~isempty(answer) && line(1) ~= ' '
                              nosys = nosys + 1;  
                        end
              
                        if line(1) ~= ' ' && nosys > 0 && isempty(answer) == false  
                              type(nosys) = line(1); 
                              notypes(nosys) = str2num(line(5:7));  % Number of observation types from different GNSS systems
                        end
   
                        if ~isempty(findstr(line,'END OF HEADER'))
                            break 
                        end
                  end

                  % Loop for finding number of observation from all GNSS systems
                  noobshelp = zeros(nosys,1);
                  noobs = zeros(nosys,1);
                  epochs = 0;
      
                  while 1
                        line = fgetl(fop);
                        if line(1) == '>' % Char '>' reset noobs
                              linedate = line;
                              epochs = epochs + 1;
                              noobshelp(:,end+1) = noobs;
                              noobs = zeros(nosys,1);
                        end
   
                        if line(1) ~= '>'
                              for i = 1:length(type)
                                    if line(1) == type(i), noobs(i) = noobs(i) + 1; end
                              end
                        end
            
                        if line == -1, 
                              noobshelp(:,end+1) = noobs;
                              break 
                        end
                  end
    
                  noobs = noobshelp(:,3:end);
      
                  % Allocate cells for different GNSS systems
                  for i = 1:nosys
                        observation{i} = zeros(7 + notypes(i),sum(noobs(i,:))); % Create cell structure
                        in1{i} = ones(notypes(i),1);
                        in2{i} = ones(notypes(i),1);
                        in1{i}(:) = 4:16:(16*notypes(i) - 12);
                        in2{i}(:) = 17:16:(16*notypes(i) + 1);
                  end

                  % Filling cells by observation data
                  frewind(fop);
                  for i = 1:headlines, 
                      line = fgetl(fop);  
                  end  % Jump from start to data
      
                  start = ones(nosys,1);
                  index = ones(nosys,1);
                  h = waitbar(0,'1','Name','Loading observation file','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
                  setappdata(h,'canceling',0)
      
                  for i = 1:epochs
                      error = 0;
                      if getappdata(h,'canceling')
                            error = 1;
                            set(findobj('tag','LoadObsStatus'),'String','Loaded file: ---')
                            errordlg('No observation file loaded !!!','Loading interruption')
                            break
                      end
            
                      waitbar(i/epochs,h,['Please wait ... Loading file: ' INPUT.ObsFileName])
                      for j = 1:(sum(noobs(:,i))+1)
                            line = fgetl(fop);
                            for k = 1:nosys
                                if line(1) == '>'
                                   observation{k}(2,start(k):sum(noobs(k,1:i))) = str2num(line(3:7));
                                   observation{k}(3,start(k):sum(noobs(k,1:i))) = str2num(line(8:10));
                                   observation{k}(4,start(k):sum(noobs(k,1:i))) = str2num(line(11:13));
                                   observation{k}(5,start(k):sum(noobs(k,1:i))) = str2num(line(14:16));
                                   observation{k}(6,start(k):sum(noobs(k,1:i))) = str2num(line(17:19));
                                   observation{k}(7,start(k):sum(noobs(k,1:i))) = str2num(line(20:30));
                                   observation{k}(8,start(k):sum(noobs(k,1:i))) = datenum(str2num(line(3:7)),str2num(line(8:10)),str2num(line(11:13)),str2num(line(14:16)),str2num(line(17:19)),str2num(line(20:30)));
                                end

                                if line(1) == type(k)
                                   observation{k}(1,index(k)) = str2num(line(2:3));
                                   for t = 1:notypes(k)
                                       if t > (length(line)-1)/16
                                          break;
                                       end
                                       if line((in1{k}(t)):(in2{k}(t))) == '              '
                                          continue
                                       else
                                          observation{k}(t+8,index(k)) = str2num(line((in1{k}(t)):(in2{k}(t))));
                                       end
                                   end 
                                   index(k) = index(k) + 1;
                                end
                            end
                      end
                      start = start + noobs(:,i);
                  end
                  delete(h)
                  fclose(fop);
                  
                  if error == 0
                        set(findobj('tag','LoadObsStatus'),'String',['Loaded file: ' INPUT.ObsFileName])
                        if ~isempty(type(type == 'G')), set(findobj('tag','popupGNSS'),'String',{'       ---','GPS'}); end
                        if ~isempty(type(type == 'E')), set(findobj('tag','popupGNSS'),'String',{'       ---','Galileo'}); end
                        if ~isempty(type(type == 'G')) && ~isempty(type(type == 'E')), set(findobj('tag','popupGNSS'),'String',{'       ---','GPS','Galileo'}); end
       
                        for i = 1:nosys
                              switch type(i)
                                    case 'G'
                                          Observations.G = observation{i}(:,:);
                                          INPUT.ObsFileSats.G = unique(Observations.G(1,:));
                                    case 'E'
                                          Observations.E = observation{i}(:,:);
                                          INPUT.ObsFileSats.E = unique(Observations.E(1,:));
                                    case 'R'
                                          Observations.R = observation{i}(:,:);
                                          INPUT.ObsFileSats.R = unique(Observations.R(1,:));
                                    case 'C'
                                          Observations.C = observation{i}(:,:);
                                          INPUT.ObsFileSats.C = unique(Observations.C(1,:));
                                    case 'J'
                                          Observations.J = observation{i}(:,:);
                                          INPUT.ObsFileSats.J = unique(Observations.J(1,:));
                                    case 'S'
                                          Observations.S = observation{i}(:,:);
                                          INPUT.ObsFileSats.S = unique(Observations.S(1,:));
                              end
                        end
            
                        INPUT.ObsFileStatus = 1;
                        INPUT.ObsFileGNSSTypes = type;
                        INPUT.ObsFileSignalTypes = notypes;
                        INPUT.ObsFileEpochs = epochs;
                        INPUT.ObsFileObservations = Observations;

                        % Open dialog file with question if you want to save observation in *.mat file
                        ChoiceObs = questdlg('Would you like to store observation data in *.mat file? It saves your time if you want to analyze observation data next time.', 'Save observation file');
                        switch(ChoiceObs)
                            case 'Yes'
                                 [name, path] = uiputfile('observations.mat','Save observation data in *mat');
                                 Observations.ObsFileGNSSTypes = type;
                                 Observations.ObsFileSignalTypes = notypes;
                                 Observations.ObsFileEpochs = epochs;
                                 Observations.ObsFileSats = INPUT.ObsFileSats;
                                 Observations.ObsCodeString = INPUT.ObsCodeString;
                                 Observations.ObsPhase1String = INPUT.ObsPhase1String;
                                 Observations.ObsSNRString = INPUT.ObsSNRString;
                                 Observations.Aproxpos = INPUT.Aproxpos;
                                 Observations.ObsTypesAllString = INPUT.ObsTypesAllString;
                     
                                 if ischar(path) && ischar(name)
                                    save([path name],'Observations') 
                                 end
                        end
                  else
                        INPUT.ObsFileGNSSTypes = 0;         INPUT.ObsFileSignalTypes = 0; 
                        INPUT.ObsFileEpochs = 0;            INPUT.ObsFileObservations.G = 0;
                        INPUT.ObsFileObservations.E = 0;    INPUT.ObsFileObservations.R = 0;
                        INPUT.ObsFileObservations.J = 0;    INPUT.ObsFileObservations.S = 0;
                  end 
         end % End isempty condition
         
      else % Case of *.mat input files
         if isempty(INPUT.ObsFileName) || isnumeric(INPUT.ObsFileName)
            errordlg('Please select observation file by Browse button.','Loading file interruption')
         else 
            if ischar(INPUT.ObsFilePath) && ischar(INPUT.ObsFileName)
               if strcmp(fieldnames(load([INPUT.ObsFilePath, INPUT.ObsFileName])),'Observations')
              
                  load([INPUT.ObsFilePath, INPUT.ObsFileName]);  
                  INPUT.ObsFileStatus = 1;
                  INPUT.ObsFileGNSSTypes = Observations.ObsFileGNSSTypes;
                  INPUT.ObsFileSignalTypes = Observations.ObsFileSignalTypes;
                  INPUT.ObsFileEpochs = Observations.ObsFileEpochs;
                  INPUT.ObsFileSats =  Observations.ObsFileSats;
                  INPUT.ObsCodeString = Observations.ObsCodeString;
                  INPUT.ObsPhase1String = Observations.ObsPhase1String;
                  INPUT.ObsSNRString = Observations.ObsSNRString;
                  INPUT.Aproxpos = Observations.Aproxpos;
                  INPUT.ObsTypesAllString = Observations.ObsTypesAllString;
             
                  a = 0;
                  for i = 1:length(INPUT.ObsFileGNSSTypes)
                      if INPUT.ObsFileGNSSTypes(i) == 'G'
                         a = a + 1;
                         INPUT.ObsFileObservations.G = Observations.G;
                      end
                      if INPUT.ObsFileGNSSTypes(i) == 'E'
                         a = a + 2;
                         INPUT.ObsFileObservations.E = Observations.E;
                      end  
                      if INPUT.ObsFileGNSSTypes(i) == 'R'
                         a = a + 3;
                         INPUT.ObsFileObservations.R = Observations.R;
                      end
                      if INPUT.ObsFileGNSSTypes(i) == 'C'
                         a = a + 4;
                         INPUT.ObsFileObservations.C = Observations.C;
                      end 
                      if INPUT.ObsFileGNSSTypes(i) == 'J'
                         a = a + 5;
                         INPUT.ObsFileObservations.J = Observations.J;
                      end
                      if INPUT.ObsFileGNSSTypes(i) == 'S'
                         a = a + 6;
                         INPUT.ObsFileObservations.S = Observations.S;
                      end 
                  end
             
                  switch a
                      case 0
                         errordlg(['Input MATLAB file "', INPUT.ObsFileName, '" does not contain any GPS or Galileo observations. Please choose another file.'],'Input file interruption')
                      case 1
                         set(findobj('tag','popupGNSS'),'String',{'       ---','GPS'})
                      case 2
                         set(findobj('tag','popupGNSS'),'String',{'       ---','Galileo'}) 
                      case 3
                         set(findobj('tag','popupGNSS'),'String',{'       ---','GPS','Galileo'})                
                  end
                 
                  if a > 0
                     set(findobj('tag','LoadObsStatus'),'String',['Loaded file: ', INPUT.ObsFileName]) 
                  end 
               else
                  errordlg(['Input observation file "', INPUT.ObsFileName, '" does not have required observations structure. Please choose another file.'], 'Input file interruption')
               end
            end
         end
      end
      guidata(fig,INPUT)
end

function LoadEphData_Callback(fig,INPUT)
      INPUT = guidata(fig);
      
      if get(findobj('tag','ascii'),'Value') == get(findobj('tag','ascii'),'Max') 
         if isempty(INPUT.EphFileName) || isnumeric(INPUT.EphFileName)
            errordlg('Please select ephemeris file by Browse button.','Loading file interruption')
         else
             
            INPUT.EphFileStatus = 0;
            fop = fopen([INPUT.EphFilePath, INPUT.EphFileName]); 
            headlines = 0;
            epochs = 0;

            while 1  % Skip header part
                  headlines = headlines + 1;
                  line = fgetl(fop);
                  answer1 = findstr(line,'*  1');
                  answer2 = findstr(line,'*  2');
                  if ~isempty(answer1) || ~isempty(answer2)
                        break  
                  end
            end
      
            frewind(fop);
            for i = 1:headlines-1
                line = fgetl(fop); 
            end

            SATPOS = zeros(12,1);
            i = 1;
            lengthephfile = numel(textread([INPUT.EphFilePath, INPUT.EphFileName],'%1c%*[^\n]'));
   
            h = waitbar(0,'1','Name','Loading ephemeris file','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
            setappdata(h,'canceling',0)
      
            while 1
                  error = 0;
                  if getappdata(h,'canceling')
                     error = 1;
                     set(findobj('tag','LoadEphStatus'),'String','Loaded file: ---')
                     errordlg('No ephemeris file loaded !!!','Loading interruption')
                     break
                  end
            
                  waitbar(i/lengthephfile,h,['Please wait ... Loading file: ' INPUT.EphFileName])
                  i = i + 1;
                  line = fgetl(fop);
                  if line == -1,  break;  end
   
                  if line(1) == '*'
                     epochs = epochs + 1;
                     year = str2num(line(4:7));
                     month = str2num(line(9:10));
                     day = str2num(line(12:13));
                     hour = str2num(line(15:16));
                     minute = str2num(line(18:19));
                     second = str2num(line(21:31));
                  end
   
                  if line(1) == 'P'
                     switch line(2)
                           case 'G'
                                 system = 1;   % GPS 
                           case 'E'
                                 system = 2;   % Galileo
                           case 'R' 
                                 system = 3;   % GLONASS
                           case 'C' 
                                 system = 4;   % Beidou
                           case 'J' 
                                 system = 5;   % IRNSS
                           case 'S'
                                 system = 6;   % Geostationary
                     end
                  
                     SV = str2num(line(3:4));        % Read SVN
                     X = str2num(line(5:19))*10^3;   % Read X
                     Y = str2num(line(20:33))*10^3;  % Read Y
                     Z = str2num(line(34:47))*10^3;  % Read Z
                     time = datenum(year,month,day,hour,minute,second);
                     helpSATPOS = [system; SV; year; month; day; hour; minute; second; time; X; Y; Z];
                     SATPOS = [SATPOS helpSATPOS];
                  end  
            end 
            delete(h)  
            fclose(fop);
      
            if error == 0
               set(findobj('tag','LoadEphStatus'),'String',['Loaded file: ' INPUT.EphFileName])
               p = 0;
               for i = 1:6
                   if sum(SATPOS(1,SATPOS(1,:) == i) ~= 0)
                      p = p + 1;
                      switch(i)
                          case 1
                             Positions.G = SATPOS(2:end,SATPOS(1,:) == i); type(p) = 'G';
                          case 2
                             Positions.E = SATPOS(2:end,SATPOS(1,:) == i); type(p) = 'E';
                          case 3
                             Positions.R = SATPOS(2:end,SATPOS(1,:) == i); type(p) = 'R';
                          case 4
                             Positions.C = SATPOS(2:end,SATPOS(1,:) == i); type(p) = 'C';
                          case 5
                             Positions.J = SATPOS(2:end,SATPOS(1,:) == i); type(p) = 'J';
                          case 6
                             Positions.S = SATPOS(2:end,SATPOS(1,:) == i); type(p) = 'S';         
                      end
                  end
               end
      
               INPUT.EphFileStatus = 1;
               INPUT.EphFileTypes = type;
               INPUT.EphFileEpochs = epochs;
               INPUT.EphFilePositions = Positions;
            
               % Open dialog file with question
               ChoiceEph = questdlg('Would you like to store ephemeris data in *.mat file? It saves your time if you want to analyze data next time.', 'Save ephemeris file');
               switch(ChoiceEph)
                   case 'Yes'
                      [name path] = uiputfile('ephemeris.mat','Save ephemeris data in *mat');
                      Positions.EphFileTypes = type;
                      Positions.EphFileEpochs = epochs;
                      if ischar(path) && ischar(name)
                         save([path name],'Positions') 
                      end
               end
            else
               INPUT.EphFilePositions.G = 0;
               INPUT.EphFilePositions.E = 0;
               INPUT.EphFilePositions.R = 0;
               INPUT.EphFilePositions.C = 0;
               INPUT.EphFilePositions.S = 0;
               INPUT.EphFilePositions.J = 0;
               INPUT.EphFileTypes = 0;
               INPUT.EphFileEpochs = 0;
            end
          end % Ends isempty condition
      
      else % If input file is *.mat file
         if isempty(INPUT.EphFileName) || isnumeric(INPUT.EphFileName)
            errordlg('Please select ephemeris file by Browse button.','Loading file interruption')
         else 
            if ischar(INPUT.EphFilePath) && ischar(INPUT.EphFileName)
               if strcmp(fieldnames(load([INPUT.EphFilePath, INPUT.EphFileName])),'Positions')
              
                  load([INPUT.EphFilePath, INPUT.EphFileName])
                  INPUT.EphFileStatus = 1;
                  INPUT.EphFileTypes = Positions.EphFileTypes;
                  INPUT.EphFileEpochs = Positions.EphFileEpochs;

                  a = 0;
                  for i = 1:length(Positions.EphFileTypes)
                      if Positions.EphFileTypes(i) == 'G'
                         a = a + 1;
                         INPUT.EphFilePositions.G = Positions.G;
                      end
                      if Positions.EphFileTypes(i) == 'E'
                         a = a + 2;
                         INPUT.EphFilePositions.E = Positions.E;
                      end
                      if Positions.EphFileTypes(i) == 'R'
                         a = a + 3;
                         INPUT.EphFilePositions.R = Positions.R;
                      end
                      if Positions.EphFileTypes(i) == 'C'
                         a = a + 4;
                         INPUT.EphFilePositions.C = Positions.C;
                      end
                      if Positions.EphFileTypes(i) == 'J'
                         a = a + 5;
                         INPUT.EphFilePositions.J = Positions.J;
                      end
                      if Positions.EphFileTypes(i) == 'S'
                         a = a + 6;
                         INPUT.EphFilePositions.S = Positions.S;
                      end
                      
                  end
            
                  if a == 0, errordlg(['Input MATLAB file ', INPUT.EphFileName, ' does not contain any GPS or Galileo ephemeris. Please choose another file.'],'Input file interruption'); end
            
                  if a > 0
                     set(findobj('tag','LoadEphStatus'),'String',['Loaded file: ', INPUT.EphFileName]) 
                  end  
             
               else
                  errordlg(['Input ephemeris file "', INPUT.EphFileName, '" does not have required ephemeris structure. Please choose another file.'], 'Input file interruption')      
               end
            end
         end
      end
      guidata(fig,INPUT)
end

function Run_Callback(fig,INPUT)
      INPUT = guidata(fig);
      INPUT.ComputedPositions = 0; % Make state that no positions are available
      
      %Dialog with interpolation of satellites positions to create structure INPUT.ObsPosBoth
      if INPUT.ObsFileStatus == 0
         if INPUT.EphFileStatus == 0
            errordlg('No observation and ephemeris file loaded. Please select and load observation and ephemeris files in INPUT files panel.','Loading interruption')
         else
            errordlg('No observation file loaded. Please select and load observation file in INPUT files panel.','Loading interruption') 
         end
      else
         if INPUT.EphFileStatus == 0
            errordlg('No ephemeris file loaded. Please select and load ephemeris file in INPUT files panel.','Loading interruption')
         else

            % Prepare figure to inform about processing
            d = figure('Name','Interpolation of ephemeris','NumberTitle','off','Toolbar','none','Menubar','none','Resize','off',...
                       'Units','pixels','Position',[550 450 300 80],'Color',[0.85 0.85 1],'Visible','off','tag','winint');          
            uicontrol(d,'Style','Text','Units','normalized','Position',[.1 .5 .80 .35],'BackgroundColor',[.85 .85 1],...
                      'String','Interpolation of satellites positions in progress ... Please wait a second.')
            uicontrol(d,'Style','Text','Units','normalized','Position',[.1 .2 .80 .17],'BackgroundColor',[.85 .85 1],...
                      'tag','statusint')
               
            % Calculate geodetic coordinate of observation site
            [phi0,lam0,h0] = ecef2geodetic(INPUT.Aproxpos(1),INPUT.Aproxpos(2),INPUT.Aproxpos(3),[6378137, sqrt(0.00669438002290)]);      
               
            if sum(ismember(INPUT.EphFileTypes,'G')) == 0
               errordlg('Missing ephemeris of GPS satellites. If you want to process observations of GPS satellites you have to load different ephemeris file.','Missing satellite ephemeris')  
            else
               if sum(ismember(INPUT.ObsFileGNSSTypes,'G'))
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GPS
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% case %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  a = unique(INPUT.EphFilePositions.G(1,:));
                  b = unique(INPUT.ObsFileObservations.G(1,:));               
                  if ~isempty(setdiff(a,b)) || strcmp(num2str(b),num2str(a))
                     % Interpolation loop create structure INPUT.ObsPosBoth with fields INPUT.ObsPosBoth.G and INPUT.ObsPosBoth.E with fields
                     % belonging to each satellite of constellation
                     for t = 1:length(INPUT.ObsFileGNSSTypes)
                         if INPUT.ObsFileGNSSTypes(t) == 'G'
                            for i = 1:length(INPUT.ObsFileSats.G) % i = index for satellite
                                INPUT.ObsPosBoth.G{i} = INPUT.ObsFileObservations.G(:,INPUT.ObsFileObservations.G(1,:) == INPUT.ObsFileSats.G(i));
                                [time,iii] = unique(INPUT.EphFilePositions.G(8,INPUT.EphFilePositions.G(1,:) == INPUT.ObsFileSats.G(i)));
                                reftime = time(1);
                                time = (time - reftime)*24;
                                timenew = INPUT.ObsPosBoth.G{i}(8,:);
                                timenew = (timenew - reftime)*24;
             
                                for j = 1:3 % Index of coordinate X=1, Y=2, Z=3
                                    coord = INPUT.EphFilePositions.G(8+j,INPUT.EphFilePositions.G(1,:) == INPUT.ObsFileSats.G(i));
                                    coord = coord(iii);
                                    INPUT.ObsPosBoth.G{i}(end+1,:) = lagrangeint(time, coord, timenew);
                                end
                 
                                % Compute n,e,u of satellites
                                clear n e u
                                [e, n, u] = ecef2lv(INPUT.ObsPosBoth.G{i}(end-2,:), INPUT.ObsPosBoth.G{i}(end-1,:), INPUT.ObsPosBoth.G{i}(end,:), phi0, lam0, h0, [6378137, sqrt(0.00669438002290)]);
                         
                                % Compute elevation and azimuth in degrees
                                elevation = atan(u./sqrt(n.^2 + e.^2))*180/pi;
                                %azimuth = (check(atan2(e,n))')*180/pi;
                                azimuth = atan2(e,n)*180/pi;
                                for brr = 1:length(azimuth)
                                    if azimuth(brr) < 0
                                       azimuth(brr) = 360 + azimuth(brr);
                                    end
                                end

                                INPUT.ObsPosBoth.G{i} = [INPUT.ObsPosBoth.G{i}; n; e; u; elevation; azimuth];

                                set(findobj('tag','winint'),'Visible','on')
                                set(findobj('tag','winint'),'CloseRequestFcn',[])
                                set(findobj('tag','statusint'),'String',['Computing satellite: ', num2str(i) '/' num2str(length(INPUT.ObsFileSats.G)), ' of GPS constellation.'])
                           end
                          
                           % Choose just observations where all available signals for one satellite are tracked
                           for i = 1:length(INPUT.ObsPosBoth.G)
                               clear totalwrong wrong totalgood
                               totalwrong = zeros(1,size(INPUT.ObsPosBoth.G{i},2));
                               for j = 1:length(INPUT.ObsTypesAllString.G)
                                   wrong = INPUT.ObsPosBoth.G{i}(8+j,:) == 0;
                                   flag = max(unique(INPUT.ObsPosBoth.G{i}(8+j,:)));
                                   if flag ~= 0
                                      totalwrong = totalwrong | wrong;
                                   end
                               end
                               totalgood = not(totalwrong);
                               INPUT.ObsPosBoth.G{i} = INPUT.ObsPosBoth.G{i}(:,totalgood);
                           end
                        
                           INPUT.ComputedPositions = 1; % Make state that positions are available  
                           set(findobj('tag','winint'),'Visible','off') % Make window d invisible
                           set(findobj('tag','winint'),'CloseRequestFcn','default')
                           delete(findobj('tag','winint'))
                        end
                     end
                  else
                    miss_sats = setdiff(b,a);
                    errordlg(['Missing ephemeris of GPS satellite(s): ', num2str(miss_sats), '. Positions of GPS satellites have not been computed. Please select another ephemeris file.'],'Missing satellite ephemeris') 
                  end
               end
            end

            if sum(ismember(INPUT.EphFileTypes,'E')) == 0
               errordlg('Missing ephemeris of Galileo satellites. If you want to process observations of Galileo satellites you have to load different ephemeris file.','Missing satellite ephemeris')  
            else
               if sum(ismember(INPUT.ObsFileGNSSTypes,'E'))
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Galileo case %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  a = unique(INPUT.EphFilePositions.E(1,:));
                  b = unique(INPUT.ObsFileObservations.E(1,:)); 
                  not_in_obs_and_eph = [];
                  if ~isempty(setdiff(a,b)) || strcmp(num2str(b),num2str(a))
                     for t = 1:length(INPUT.ObsFileGNSSTypes)
                         if INPUT.ObsFileGNSSTypes(t) == 'E'
                            for i = 1:length(INPUT.ObsFileSats.E) % i = index for satellite
                                satNo_required = INPUT.ObsFileSats.E(i);
                                satNoInEphemeris = unique(INPUT.EphFilePositions.E(1,:));
                                if ismember(satNo_required,satNoInEphemeris)
                                    INPUT.ObsPosBoth.E{i} = INPUT.ObsFileObservations.E(:,INPUT.ObsFileObservations.E(1,:) == INPUT.ObsFileSats.E(i));
                                    [time,iii] = unique(INPUT.EphFilePositions.E(8,INPUT.EphFilePositions.E(1,:) == satNo_required));
                                    reftime = time(1);
                                    time = (time - reftime)*24;
                                    timenew = INPUT.ObsPosBoth.E{i}(8,:);
                                    timenew = (timenew - reftime)*24;

                                    for j = 1:3 % Index of coordinate X=1, Y=2, Z=3
                                        coord = INPUT.EphFilePositions.E(8+j,INPUT.EphFilePositions.E(1,:) == INPUT.ObsFileSats.E(i));
                                        coord = coord(iii);
                                        INPUT.ObsPosBoth.E{i}(end+1,:) = lagrangeint(time, coord, timenew);
                                    end

                                    % Compute n,e,u of satellites
                                    clear n e u
                                    [e, n, u] = ecef2lv(INPUT.ObsPosBoth.E{i}(end-2,:), INPUT.ObsPosBoth.E{i}(end-1,:), INPUT.ObsPosBoth.E{i}(end,:), phi0, lam0, h0, [6378137, sqrt(0.00669438002290)]);

                                    % Compute elevation and azimuth in degrees
                                    elevation = atan(u./sqrt(n.^2 + e.^2))*180/pi;
                                    %azimuth = (check(atan2(e,n))')*180/pi;
                                    azimuth = atan2(e,n)*180/pi;
                                    for brr = 1:length(azimuth)
                                        if azimuth(brr) < 0
                                           azimuth(brr) = 360 + azimuth(brr);
                                        end
                                    end
                                    INPUT.ObsPosBoth.E{i} = [INPUT.ObsPosBoth.E{i}; n; e; u; elevation; azimuth];

                                    set(findobj('tag','winint'),'Visible','on')
                                    set(findobj('tag','winint'),'CloseRequestFcn',[])
                                    set(findobj('tag','statusint'),'String',['Computing satellite: ', num2str(i) '/' num2str(length(INPUT.ObsFileSats.E)), ' of Galileo constellation.'])
                                else
                                    not_in_obs_and_eph = [not_in_obs_and_eph, satNo_required];
                                end
                            end
                            sat_no_given = INPUT.ObsFileSats.E;
                            keep_sat_idx = ~ismember(sat_no_given, not_in_obs_and_eph);
                            INPUT.ObsFileSats.E = INPUT.ObsFileSats.E(keep_sat_idx);
                            INPUT.ObsPosBoth.E = INPUT.ObsPosBoth.E(keep_sat_idx);
                             
                            % Choose just observations where all available signals for one satellite are tracked
                            for i = 1:length(INPUT.ObsPosBoth.E)
                                clear totalwrong wrong totalgood
                                totalwrong = zeros(1,size(INPUT.ObsPosBoth.E{i},2));
                                for j = 1:length(INPUT.ObsTypesAllString.E)
                                    wrong = INPUT.ObsPosBoth.E{i}(8+j,:) == 0;
                                    flag = max(unique(INPUT.ObsPosBoth.E{i}(8+j,:)));
                                    if flag ~= 0
                                       totalwrong = totalwrong | wrong;
                                    end
                                end
                                totalgood = not(totalwrong);
                                INPUT.ObsPosBoth.E{i} = INPUT.ObsPosBoth.E{i}(:,totalgood);
                            end
                          
                            INPUT.ComputedPositions = 1; % Make state that positions are available
                            set(findobj('tag','winint'),'Visible','off') % Make window d invisible
                         end
                     end % End loop for create INPUT.ObsPosBoth
                  else
                    miss_sats = setdiff(b,a);
                    errordlg(['Missing ephemeris of Galileo satellite(s): ', num2str(miss_sats), '. Positions of Galileo satellites have not been computed. Please select another ephemeris file.'],'Missing satellite ephemeris') 
                  end
               end
            end
%%%            
            if sum(ismember(INPUT.EphFileTypes,'R')) == 0
               errordlg('Missing ephemeris of GLONASS satellites. If you want to process observations of GLONASS satellites you have to load different ephemeris file.','Missing satellite ephemeris')  
            else
               if sum(ismember(INPUT.ObsFileGNSSTypes,'R'))
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GLONASS case %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  a = unique(INPUT.EphFilePositions.R(1,:));
                  b = unique(INPUT.ObsFileObservations.R(1,:));
                  not_in_obs_and_eph = [];
                  if ~isempty(setdiff(a,b)) || strcmp(num2str(b),num2str(a))
                     for t = 1:length(INPUT.ObsFileGNSSTypes)
                         if INPUT.ObsFileGNSSTypes(t) == 'R'
                            for i = 1:length(INPUT.ObsFileSats.R) % i = index for satellite
                                satNo_required = INPUT.ObsFileSats.R(i);
                                satNoInEphemeris = unique(INPUT.EphFilePositions.R(1,:));
                                if ismember(satNo_required,satNoInEphemeris)
                                    disp(['Computing satellite: ', num2str(i), '/ ', num2str(length(INPUT.ObsFileSats.R))])
                                    INPUT.ObsPosBoth.R{i} = INPUT.ObsFileObservations.R(:,INPUT.ObsFileObservations.R(1,:) == INPUT.ObsFileSats.R(i));
                                    [time,iii] = unique(INPUT.EphFilePositions.R(8,INPUT.EphFilePositions.R(1,:) == INPUT.ObsFileSats.R(i)));
                                    reftime = time(1);
                                    time = (time - reftime)*24;
                                    timenew = INPUT.ObsPosBoth.R{i}(8,:);
                                    timenew = (timenew - reftime)*24;

                                    for j = 1:3 % Index of coordinate X=1, Y=2, Z=3
                                        coord = INPUT.EphFilePositions.R(8+j,INPUT.EphFilePositions.R(1,:) == INPUT.ObsFileSats.R(i));
                                        coord = coord(iii);
                                        INPUT.ObsPosBoth.R{i}(end+1,:) = lagrangeint(time, coord, timenew);
                                    end

                                    % Compute n,e,u of satellites
                                    clear n e u
                                    [e, n, u] = ecef2lv(INPUT.ObsPosBoth.R{i}(end-2,:), INPUT.ObsPosBoth.R{i}(end-1,:), INPUT.ObsPosBoth.R{i}(end,:), phi0, lam0, h0, [6378137, sqrt(0.00669438002290)]);

                                    % Compute elevation and azimuth in degrees
                                    elevation = atan(u./sqrt(n.^2 + e.^2))*180/pi;
                                    %azimuth = (check(atan2(e,n))')*180/pi;
                                    azimuth = atan2(e,n)*180/pi;
                                    for brr = 1:length(azimuth)
                                        if azimuth(brr) < 0
                                           azimuth(brr) = 360 + azimuth(brr);
                                        end
                                    end
                                    INPUT.ObsPosBoth.R{i} = [INPUT.ObsPosBoth.R{i}; n; e; u; elevation; azimuth];

                                    set(findobj('tag','winint'),'Visible','on')
                                    set(findobj('tag','winint'),'CloseRequestFcn',[])
                                    set(findobj('tag','statusint'),'String',['Computing satellite: ', num2str(i) '/' num2str(length(INPUT.ObsFileSats.R)), ' of GLONASS constellation.'])
                                else
                                    not_in_obs_and_eph = [not_in_obs_and_eph, satNo_required];
                                end
                            end
                            sat_no_given = INPUT.ObsFileSats.R;
                            keep_sat_idx = ~ismember(sat_no_given, not_in_obs_and_eph);
                            INPUT.ObsFileSats.R = INPUT.ObsFileSats.R(keep_sat_idx);
                            INPUT.ObsPosBoth.R = INPUT.ObsPosBoth.R(keep_sat_idx);
                             
                            % Choose just observations where all available signals for one satellite are tracked
                            for i = 1:length(INPUT.ObsPosBoth.R)
                                clear totalwrong wrong totalgood
                                totalwrong = zeros(1,size(INPUT.ObsPosBoth.R{i},2));
                                for j = 1:length(INPUT.ObsTypesAllString.R)
                                    wrong = INPUT.ObsPosBoth.R{i}(8+j,:) == 0;
                                    flag = max(unique(INPUT.ObsPosBoth.R{i}(8+j,:)));
                                    if flag ~= 0
                                       totalwrong = totalwrong | wrong;
                                    end
                                end
                                totalgood = not(totalwrong);
                                INPUT.ObsPosBoth.R{i} = INPUT.ObsPosBoth.R{i}(:,totalgood);
                            end
                          
                            INPUT.ComputedPositions = 1; % Make state that positions are available
                            set(findobj('tag','winint'),'Visible','off') % Make window d invisible
                         end
                     end % End loop for create INPUT.ObsPosBoth
                  else
                    miss_sats = setdiff(b,a);
                    errordlg(['Missing ephemeris of GLONASS satellite(s): ', num2str(miss_sats), '. Positions of GLONASS satellites have not been computed. Please select another ephemeris file.'],'Missing satellite ephemeris') 
                  end
               end
            end
%%%            

%%%            
            if sum(ismember(INPUT.EphFileTypes,'C')) == 0
               errordlg('Missing ephemeris of Beidou satellites. If you want to process observations of Beidou satellites you have to load different ephemeris file.','Missing satellite ephemeris')  
            else
               if sum(ismember(INPUT.ObsFileGNSSTypes,'C'))
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GLONASS case %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  a = unique(INPUT.EphFilePositions.C(1,:));
                  b = unique(INPUT.ObsFileObservations.C(1,:));               
                  if ~isempty(setdiff(a,b)) || strcmp(num2str(b),num2str(a))
                     for t = 1:length(INPUT.ObsFileGNSSTypes)
                         if INPUT.ObsFileGNSSTypes(t) == 'C'
                            for i = 1:length(INPUT.ObsFileSats.C) % i = index for satellite
                                disp(['Computing satellite: ', num2str(i), '/ ', num2str(length(INPUT.ObsFileSats.C))])
                                INPUT.ObsPosBoth.C{i} = INPUT.ObsFileObservations.C(:,INPUT.ObsFileObservations.C(1,:) == INPUT.ObsFileSats.C(i));
                                [time,iii] = unique(INPUT.EphFilePositions.C(8,INPUT.EphFilePositions.C(1,:) == INPUT.ObsFileSats.C(i)));
                                reftime = time(1);
                                time = (time - reftime)*24;
                                timenew = INPUT.ObsPosBoth.C{i}(8,:);
                                timenew = (timenew - reftime)*24;
                             
                                for j = 1:3 % Index of coordinate X=1, Y=2, Z=3
                                    coord = INPUT.EphFilePositions.C(8+j,INPUT.EphFilePositions.C(1,:) == INPUT.ObsFileSats.C(i));
                                    coord = coord(iii);
                                    INPUT.ObsPosBoth.C{i}(end+1,:) = lagrangeint(time, coord, timenew);
                                end
              
                                % Compute n,e,u of satellites
                                clear n e u
                                [e, n, u] = ecef2lv(INPUT.ObsPosBoth.C{i}(end-2,:), INPUT.ObsPosBoth.C{i}(end-1,:), INPUT.ObsPosBoth.C{i}(end,:), phi0, lam0, h0, [6378137, sqrt(0.00669438002290)]);
                      
                                % Compute elevation and azimuth in degrees
                                elevation = atan(u./sqrt(n.^2 + e.^2))*180/pi;
                                %azimuth = (check(atan2(e,n))')*180/pi;
                                azimuth = atan2(e,n)*180/pi;
                                for brr = 1:length(azimuth)
                                    if azimuth(brr) < 0
                                       azimuth(brr) = 360 + azimuth(brr);
                                    end
                                end
                                INPUT.ObsPosBoth.C{i} = [INPUT.ObsPosBoth.C{i}; n; e; u; elevation; azimuth];
              
                                set(findobj('tag','winint'),'Visible','on')
                                set(findobj('tag','winint'),'CloseRequestFcn',[])
                                set(findobj('tag','statusint'),'String',['Computing satellite: ', num2str(i) '/' num2str(length(INPUT.ObsFileSats.C)), ' of Beidou constellation.'])
                            end
                             
                            % Choose just observations where all available signals for one satellite are tracked
                            for i = 1:length(INPUT.ObsPosBoth.C)
                                clear totalwrong wrong totalgood
                                totalwrong = zeros(1,size(INPUT.ObsPosBoth.C{i},2));
                                for j = 1:length(INPUT.ObsTypesAllString.C)
                                    wrong = INPUT.ObsPosBoth.C{i}(8+j,:) == 0;
                                    flag = max(unique(INPUT.ObsPosBoth.C{i}(8+j,:)));
                                    if flag ~= 0
                                       totalwrong = totalwrong | wrong;
                                    end
                                end
                                totalgood = not(totalwrong);
                                INPUT.ObsPosBoth.C{i} = INPUT.ObsPosBoth.C{i}(:,totalgood);
                            end
                          
                            INPUT.ComputedPositions = 1; % Make state that positions are available
                            set(findobj('tag','winint'),'Visible','off') % Make window d invisible
                         end
                     end % End loop for create INPUT.ObsPosBoth
                  else
                    miss_sats = setdiff(b,a);
                    errordlg(['Missing ephemeris of Beidou satellite(s): ', num2str(miss_sats), '. Positions of Beidou satellites have not been computed. Please select another ephemeris file.'],'Missing satellite ephemeris') 
                  end
               end
            end
%%%          
            % Update GNSS popup menu 
            obs_types = INPUT.ObsFileGNSSTypes;
            eph_types = INPUT.EphFileTypes;
            out = ismember(eph_types,obs_types);
            out = eph_types(out);
            if ismember('G',out)
               set(findobj('tag','popupGNSS'),'String',{'       ---','GPS'}) 
            end
            if ismember('E',out)
               set(findobj('tag','popupGNSS'),'String',{'       ---','Galileo'}) 
            end
            if ismember('G',out) && ismember('E',out)
               set(findobj('tag','popupGNSS'),'String',{'       ---','GPS','Galileo'})
            end
            
            set(findobj('tag','winint'),'CloseRequestFcn','default')
            delete(findobj('tag','winint'))
            clear d
         end
      end
      guidata(fig,INPUT)  
end

function PopupGNSS_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.ObsFileName) || isnumeric(INPUT.ObsFileName)
         if isempty(INPUT.EphFileName) || isnumeric(INPUT.EphFileName)
            errordlg('No observation and ephemeris file loaded. Please select and load observation and ephemeris files in INPUT files panel.','GNSS selection interruption') 
            set(findobj('tag','popupGNSS'),'Value',1)
         else
            errordlg('No observation file loaded. Please select and load observation file in INPUT files panel.','GNSS selection interruption') 
            set(findobj('tag','popupGNSS'),'Value',1)
         end
      else
         if isempty(INPUT.EphFileName) || isnumeric(INPUT.EphFileName)
            errordlg('No ephemeris file loaded. Please select and load ephemeris file in INPUT files panel.','GNSS selection interruption')
            set(findobj('tag','popupGNSS'),'Value',1)
         else
            if (strcmp(INPUT.ObsFileName(end),'o') || strcmp(INPUT.ObsFileName(end),'O')) % if the input file is *.**o or *.**O
               if INPUT.ObsFileStatus == 0
                  if INPUT.EphFileStatus == 0
                      errordlg('No observation and ephemeris file loaded. Please select and load observation and ephemeris files in INPUT files panel.',...
                              'GNSS selection interruption')
                      set(findobj('tag','popupGNSS'),'Value',1)
                  else
                     errordlg('No observation file loaded. Please select and load observation file in INPUT files panel.',...
                              'GNSS selection interruption')
                     set(findobj('tag','popupGNSS'),'Value',1)
                  end
               else
                  if INPUT.EphFileStatus == 0
                     errordlg('No ephemeris file loaded. Please select and load ephemeris file in INPUT files panel.',...
                              'GNSS selection interruption')
                     set(findobj('tag','popupGNSS'),'Value',1)
                  else
                     if INPUT.ComputedPositions == 0
                        errordlg('No positions of satellites computed. Please compute satellites positions with button Run.','GNSS selection interruption') 
                        set(findobj('tag','popupGNSS'),'Value',1)
                     else
                       set(findobj('tag','DFsats'),'String','')
                       str = get(findobj('tag','popupGNSS'),'String');  
          	           switch(str{get(findobj('tag','popupGNSS'),'Value')})
                           case '       ---'
                                 errordlg('No GNSS selected. Please select one of offered GNSS systems available from observation RINEX file.',...
                                          'GNSS selection interruption')
            	         case 'GPS'
                                 set(findobj('tag','GNSStext'),'String','Selected GNSS constellation: Navstar GPS');
                                 INPUT.GNSS = 1; % GPS choice
                                 INPUT.CurrentObs = INPUT.ObsFileObservations.G;   % All observation of GPS satellites available from file
                                 INPUT.CurrentPosAll = INPUT.EphFilePositions.G;   % All ephemeris of GPS satellites available from file
                                 INPUT.CurrentSats = [];
                                 INPUT.SelectedSats = [];     %%%%%%%%%%%
                                 INPUT.ObsPos = INPUT.ObsPosBoth.G;
                                 INPUT.ObsTypes = INPUT.ObsFileSignalTypes(INPUT.ObsFileGNSSTypes == 'G');
                                 INPUT.ObsTypesAll = INPUT.ObsTypesAllString.G;
                        
                                 % Fill popups in signal selection panel
                                 INPUT.CurrentCodeString = ['      ---', INPUT.ObsCodeString.G];
                                 INPUT.CurrentPhase1String = ['      ---', INPUT.ObsPhase1String.G];
                                 INPUT.CurrentPhase2String = ['      ---', INPUT.ObsPhase1String.G];
                                 INPUT.CurrentSNRString = ['      ---', INPUT.ObsSNRString.G];
                                 INPUT.CurrentCode = INPUT.CurrentCodeString{1};
                                 INPUT.CurrentPhase1 = INPUT.CurrentPhase1String{1};
                                 INPUT.CurrentPhase2 = INPUT.CurrentPhase2String{1};
                                 INPUT.CurrentSNRstr = INPUT.CurrentSNRString{1};
                                 set(findobj('tag','popupCode'),'String',INPUT.CurrentCodeString)
                                 set(findobj('tag','popupPhase1'),'String',INPUT.CurrentPhase1String)
                                 set(findobj('tag','popupPhase2'),'String',INPUT.CurrentPhase2String)
                                 set(findobj('tag','popupSNR'),'String',INPUT.CurrentSNRString)
                                 set(findobj('tag','popupCode'),'Value',1)
                                 set(findobj('tag','popupPhase1'),'Value',1)
                                 set(findobj('tag','popupPhase2'),'Value',1)
                                 set(findobj('tag','popupSNR'),'Value',1)
                        
                                 % Create (or do not create) Field INPUT.Multipath depending on number of available signals
                                 INPUT.Multipath.G.Selection = INPUT.Multipath.G.Selection + 1;
                                 if INPUT.Multipath.G.Selection == 1
                                    numero = 100*length(INPUT.CurrentCodeString) + 10*length(INPUT.CurrentPhase1String) + length(INPUT.CurrentPhase1String);
                                    INPUT.Multipath.G.MP.GF = cell(1,numero); 
                                    INPUT.Multipath.G.MPF.GF = cell(1,numero); 
                                    INPUT.Multipath.G.MP.MW = cell(1,numero);
                                    INPUT.Multipath.G.MPF.MW = cell(1,numero); 
                                    INPUT.Multipath.G.RMS.GF = cell(1,numero); 
                                    INPUT.Multipath.G.RMS.MW = cell(1,numero);
                                    INPUT.Multipath.G.Cyclslplot.GF = cell(1,numero); 
                                    INPUT.Multipath.G.Cyclslplot.MW = cell(1,numero);
                                    INPUT.Multipath.G.CSdetector.GF = cell(1,numero); 
                                    INPUT.Multipath.G.CSdetector.MW = cell(1,numero);
                                    INPUT.Multipath.G.CutoffTrue.GF = zeros(1,1000);
                                    INPUT.Multipath.G.CutoffTrue.MW = zeros(1,1000);
                                 end
                        
                                 % Update status bar
                                 INPUT.StatusBar.GNSS = 'GNSS: GPS || ';
                                 INPUT.StatusBar.Sats = 'Satellite(s): --- || ';
                                 INPUT.StatusBar.Code = 'MP code: --- ||';
                                 INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
                                 INPUT.StatusBar.Phase2 = '--- || ';
                        
                                 N = INPUT.ObsFileSats.G';
                                 K = 'G';
                                 for i = 1:length(N), KK(i,1) = K; end
                                 str = num2str(N);
                                 for i = 1:size(str,1)
                                     for j = 1:2
                                         if str(i,j) == ' '
                                             str(i,j) = '0';
                                         end
                                     end
                                 end
                                 Ea = [KK str];
                                 INPUT.SatsStringG = cellstr(Ea)';
                                 set(findobj('tag','popupSat'),'Value',1)
                                 set(findobj('tag','popupSat'),'String',INPUT.SatsStringG)
                        
            	         case 'Galileo'
                                 set(findobj('tag','GNSStext'),'String','Selected GNSS constellation: Galileo');
                                 INPUT.GNSS = 2; % Galileo choice
                                 INPUT.CurrentObs = INPUT.ObsFileObservations.E;   % All observation of Galileo satellites available from file
                                 INPUT.CurrentPosAll = INPUT.EphFilePositions.E;   % All ephemeris of Galileo satellites available from file
                                 INPUT.CurrentSats = [];
                                 INPUT.SelectedSats = [];     %%%%%%%%%%%
                                 INPUT.ObsPos = INPUT.ObsPosBoth.E;
                                 INPUT.ObsTypes = INPUT.ObsFileSignalTypes(INPUT.ObsFileGNSSTypes == 'E');
                                 INPUT.ObsTypesAll = INPUT.ObsTypesAllString.E;

                                 % Fill popups in signal selection panel
                                 INPUT.CurrentCodeString = ['      ---', INPUT.ObsCodeString.E];
                                 INPUT.CurrentPhase1String = ['      ---', INPUT.ObsPhase1String.E];
                                 INPUT.CurrentPhase2String = ['      ---', INPUT.ObsPhase1String.E];
                                 INPUT.CurrentSNRString = ['      ---', INPUT.ObsSNRString.E];
                                 INPUT.CurrentCode = INPUT.CurrentCodeString{1};
                                 INPUT.CurrentPhase1 = INPUT.CurrentPhase1String{1};
                                 INPUT.CurrentPhase2 = INPUT.CurrentPhase2String{1};
                                 INPUT.CurrentSNRstr = INPUT.CurrentSNRString{1};
                                 set(findobj('tag','popupCode'),'String',INPUT.CurrentCodeString)
                                 set(findobj('tag','popupPhase1'),'String',INPUT.CurrentPhase1String)
                                 set(findobj('tag','popupPhase2'),'String',INPUT.CurrentPhase2String)
                                 set(findobj('tag','popupSNR'),'String',INPUT.CurrentSNRString)
                                 set(findobj('tag','popupCode'),'Value',1)
                                 set(findobj('tag','popupPhase1'),'Value',1)
                                 set(findobj('tag','popupPhase2'),'Value',1)
                                 set(findobj('tag','popupSNR'),'Value',1)
                        
                                 % Create (or do not create) Field INPUT.Multipath depending on number of available signals
                                 INPUT.Multipath.E.Selection = INPUT.Multipath.E.Selection + 1;
                                 if INPUT.Multipath.E.Selection == 1
                                    numero = 100*length(INPUT.CurrentCodeString) + 10*length(INPUT.CurrentPhase1String) + length(INPUT.CurrentPhase1String);
                                    INPUT.Multipath.E.MP.GF = cell(1,numero); 
                                    INPUT.Multipath.E.MPF.GF = cell(1,numero); 
                                    INPUT.Multipath.E.MP.MW = cell(1,numero);
                                    INPUT.Multipath.E.MPF.MW = cell(1,numero); 
                                    INPUT.Multipath.E.RMS.GF = cell(1,numero); 
                                    INPUT.Multipath.E.RMS.MW = cell(1,numero);
                                    INPUT.Multipath.E.Cyclslplot.GF = cell(1,numero); 
                                    INPUT.Multipath.E.Cyclslplot.MW = cell(1,numero);
                                    INPUT.Multipath.E.CSdetector.GF = cell(1,numero); 
                                    INPUT.Multipath.E.CSdetector.MW = cell(1,numero);
                                    INPUT.Multipath.E.CutoffTrue.GF = zeros(1,1000);
                                    INPUT.Multipath.E.CutoffTrue.MW = zeros(1,1000);
                                 end
                        
                                 % Update status bar
                                 INPUT.StatusBar.GNSS = 'GNSS: Galileo || ';
                                 INPUT.StatusBar.Sats = 'Satellite(s): --- || ';
                                 INPUT.StatusBar.Code = 'MP code: --- ||';
                                 INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
                                 INPUT.StatusBar.Phase2 = '--- || ';
                        
                                 N = INPUT.ObsFileSats.E';
                                 K = 'E';
                                 for i = 1:length(N), KK(i,1) = K; end
                                 str = num2str(N);
                                 for i = 1:size(str,1)
                                     for j = 1:2
                                         if str(i,j) == ' '
                                            str(i,j) = '0';
                                         end
                                     end
                                 end
                          
                                 Ea = [KK str];
                                 INPUT.SatsStringE = cellstr(Ea)';
                                 set(findobj('tag','popupSat'),'Value',1)
                                 set(findobj('tag','popupSat'),'String',INPUT.SatsStringE)
                       end % Ends switch  
                     end % if ComputedPositions == 0
                     
                     % Disable popup menus of SNR
                     set(findobj('tag','flyby1'),'Enable','off')
                     set(findobj('tag','popupFlyBy'),'String','                          ---')
                     set(findobj('tag','popupFlyBy'),'Enable','off')
                  end % if EphFileStatus == 0
               end % if ObsFileStatus == 0

            else % If input file is *.mat
               if INPUT.ObsFileStatus == 0
                  if INPUT.EphFileStatus == 0
                     errordlg('No observation and ephemeris file loaded. Please select and load observation and ephemeris files in INPUT files panel.',...
                              'GNSS selection interruption')
                  else
                     errordlg('No observation file loaded. Please select and load observation file in INPUT files panel.',...
                              'GNSS selection interruption')
                  end
               else
                  if INPUT.EphFileStatus == 0
                     errordlg('No ephemeris file loaded. Please select and load ephemeris file in INPUT files panel.',...
                              'GNSS selection interruption')
                  else
                     if INPUT.ComputedPositions == 0
                        errordlg('No positions of satellites computed. Please compute satellites positions with button Run.','GNSS selection interruption')
                        set(findobj('tag','popupGNSS'),'Value',1)
                     else
                        set(findobj('tag','DFsats'),'String','')
                        str = get(findobj('tag','popupGNSS'),'String');  
                        switch(str{get(findobj('tag','popupGNSS'),'Value')})
                         case '       ---'
                            errordlg('No GNSS selected. Please select one of offering GNSS systems available from observation RINEX file.',...
                                     'GNSS selection interruption')
                         case 'GPS'
                            set(findobj('tag','GNSStext'),'String','Selected GNSS constellation: Navstar GPS');
                            INPUT.GNSS = 1; % GPS choice
                            INPUT.CurrentObs = INPUT.ObsFileObservations.G;   % All observation of GPS satellites available from file
                            INPUT.CurrentPosAll = INPUT.EphFilePositions.G;   % All ephemeris of GPS satellites available from file
                            INPUT.CurrentSats = [];
                            INPUT.SelectedSats = [];     %%%%%%%%%%%
                            INPUT.ObsPos = INPUT.ObsPosBoth.G;
                            INPUT.ObsTypes = INPUT.ObsFileSignalTypes(INPUT.ObsFileGNSSTypes == 'G');
                            INPUT.ObsTypesAll = INPUT.ObsTypesAllString.G;
                           
                            % Fill popups in signal selection panel
                            INPUT.CurrentCodeString = ['      ---', INPUT.ObsCodeString.G];
                            INPUT.CurrentPhase1String = ['      ---', INPUT.ObsPhase1String.G];
                            INPUT.CurrentPhase2String = ['      ---', INPUT.ObsPhase1String.G];
                            INPUT.CurrentSNRString = ['      ---', INPUT.ObsSNRString.G];
                            INPUT.CurrentCode = INPUT.CurrentCodeString{1};
                            INPUT.CurrentPhase1 = INPUT.CurrentPhase1String{1};
                            INPUT.CurrentPhase2 = INPUT.CurrentPhase2String{1};
                            INPUT.CurrentSNRstr = INPUT.CurrentSNRString{1};
                            set(findobj('tag','popupCode'),'String',INPUT.CurrentCodeString)
                            set(findobj('tag','popupPhase1'),'String',INPUT.CurrentPhase1String)
                            set(findobj('tag','popupPhase2'),'String',INPUT.CurrentPhase2String)
                            set(findobj('tag','popupSNR'),'String',INPUT.CurrentSNRString)
                            set(findobj('tag','popupCode'),'Value',1)
                            set(findobj('tag','popupPhase1'),'Value',1)
                            set(findobj('tag','popupPhase2'),'Value',1)
                            set(findobj('tag','popupSNR'),'Value',1)
                        
                            % Create (or do not create) Field INPUT.Multipath depending on number of available signals
                            INPUT.Multipath.G.Selection = INPUT.Multipath.G.Selection + 1;
                            if INPUT.Multipath.G.Selection == 1
                               numero = 100*length(INPUT.CurrentCodeString) + 10*length(INPUT.CurrentPhase1String) + length(INPUT.CurrentPhase1String);
                               INPUT.Multipath.G.MP.GF = cell(1,numero); 
                               INPUT.Multipath.G.MPF.GF = cell(1,numero); 
                               INPUT.Multipath.G.MP.MW = cell(1,numero);
                               INPUT.Multipath.G.MPF.MW = cell(1,numero); 
                               INPUT.Multipath.G.RMS.GF = cell(1,numero); 
                               INPUT.Multipath.G.RMS.MW = cell(1,numero);
                               INPUT.Multipath.G.Cyclslplot.GF = cell(1,numero); 
                               INPUT.Multipath.G.Cyclslplot.MW = cell(1,numero);
                               INPUT.Multipath.G.CSdetector.GF = cell(1,numero); 
                               INPUT.Multipath.G.CSdetector.MW = cell(1,numero);
                               INPUT.Multipath.G.CutoffTrue.GF = zeros(1,1000);
                               INPUT.Multipath.G.CutoffTrue.MW = zeros(1,1000);
                            end
                         
                            % Update status bar
                            INPUT.StatusBar.GNSS = 'GNSS: GPS || ';
                            INPUT.StatusBar.Sats = 'Satellite(s): --- || ';
                            INPUT.StatusBar.Code = 'MP code: --- ||';
                            INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
                            INPUT.StatusBar.Phase2 = '--- || ';
                         
                            N = INPUT.ObsFileSats.G';
                            K = 'G';
                            for i = 1:length(N), KK(i,1) = K; end
                   
                            str = num2str(N);
                            for i = 1:size(str,1)
                                for j = 1:2
                                    if str(i,j) == ' '
                                       str(i,j) = '0';
                                    end
                                end
                            end
                   
                            Ea = [KK str];
                            INPUT.SatsStringG = cellstr(Ea)';
                            set(findobj('tag','popupSat'),'Value',1)
                            set(findobj('tag','popupSat'),'String',INPUT.SatsStringG)
                   
                         case 'Galileo'
                            set(findobj('tag','GNSStext'),'String','Selected GNSS constellation: Galileo');
                            INPUT.GNSS = 2; % Galileo choice
                            INPUT.CurrentObs = INPUT.ObsFileObservations.E;   % All observation of Galileo satellites available from file
                            INPUT.CurrentPosAll = INPUT.EphFilePositions.E;   % All ephemeris of Galileo satellites available from file
                            INPUT.CurrentSats = [];
                            INPUT.SelectedSats = [];     %%%%%%%%%%%
                            INPUT.ObsPos = INPUT.ObsPosBoth.E;
                            INPUT.ObsTypes = INPUT.ObsFileSignalTypes(INPUT.ObsFileGNSSTypes == 'E');
                            INPUT.ObsTypesAll = INPUT.ObsTypesAllString.E;
                         
                            % Fill popups in signal selection panel
                            INPUT.CurrentCodeString = ['      ---', INPUT.ObsCodeString.E];
                            INPUT.CurrentPhase1String = ['      ---', INPUT.ObsPhase1String.E];
                            INPUT.CurrentPhase2String = ['      ---', INPUT.ObsPhase1String.E];
                            INPUT.CurrentSNRString = ['      ---', INPUT.ObsSNRString.E];
                            INPUT.CurrentCode = INPUT.CurrentCodeString{1};
                            INPUT.CurrentPhase1 = INPUT.CurrentPhase1String{1};
                            INPUT.CurrentPhase2 = INPUT.CurrentPhase2String{1};
                            INPUT.CurrentSNRstr = INPUT.CurrentSNRString{1};
                            set(findobj('tag','popupCode'),'String',INPUT.CurrentCodeString)
                            set(findobj('tag','popupPhase1'),'String',INPUT.CurrentPhase1String)
                            set(findobj('tag','popupPhase2'),'String',INPUT.CurrentPhase2String)
                            set(findobj('tag','popupSNR'),'String',INPUT.CurrentSNRString)
                            set(findobj('tag','popupCode'),'Value',1)
                            set(findobj('tag','popupPhase1'),'Value',1)
                            set(findobj('tag','popupPhase2'),'Value',1)
                            set(findobj('tag','popupSNR'),'Value',1)
                        
                            % Create (or do not create) Field INPUT.Multipath depending on number of available signals
                            INPUT.Multipath.E.Selection = INPUT.Multipath.E.Selection + 1;
                            if INPUT.Multipath.E.Selection == 1
                               numero = 100*length(INPUT.CurrentCodeString) + 10*length(INPUT.CurrentPhase1String) + length(INPUT.CurrentPhase1String);
                               INPUT.Multipath.E.MP.GF = cell(1,numero); 
                               INPUT.Multipath.E.MPF.GF = cell(1,numero); 
                               INPUT.Multipath.E.MP.MW = cell(1,numero);
                               INPUT.Multipath.E.MPF.MW = cell(1,numero); 
                               INPUT.Multipath.E.RMS.GF = cell(1,numero); 
                               INPUT.Multipath.E.RMS.MW = cell(1,numero);
                               INPUT.Multipath.E.Cyclslplot.GF = cell(1,numero); 
                               INPUT.Multipath.E.Cyclslplot.MW = cell(1,numero);
                               INPUT.Multipath.E.CSdetector.GF = cell(1,numero); 
                               INPUT.Multipath.E.CSdetector.MW = cell(1,numero);
                               INPUT.Multipath.E.CutoffTrue.GF = zeros(1,1000);
                               INPUT.Multipath.E.CutoffTrue.MW = zeros(1,1000);
                            end
                         
                            % Update status bar
                            INPUT.StatusBar.GNSS = 'GNSS: Galileo || ';
                            INPUT.StatusBar.Sats = 'Satellite(s): --- || ';
                            INPUT.StatusBar.Code = 'MP code: --- ||';
                            INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
                            INPUT.StatusBar.Phase2 = '--- || ';
                         
                            N = INPUT.ObsFileSats.E';
                            K = 'E';
                            for i = 1:length(N), KK(i,1) = K; end
                   
                            str = num2str(N);
                            for i = 1:size(str,1)
                                for j = 1:2
                                    if str(i,j) == ' '
                                       str(i,j) = '0';
                                    end
                                end
                            end
                        
                            Ea = [KK str];
                            INPUT.SatsStringE = cellstr(Ea)';
                            set(findobj('tag','popupSat'),'Value',1)
                            set(findobj('tag','popupSat'),'String',INPUT.SatsStringE)   
                        end % ends switch
                     end
                     
                     % Disable popup menus of SNR
                     set(findobj('tag','flyby1'),'Enable','off')
                     set(findobj('tag','popupFlyBy'),'Value',1)
                     set(findobj('tag','popupFlyBy'),'Enable','off')
                  end 
               end
            end
         end
      end
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      guidata(fig,INPUT)
end

function PopupSat_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
            errordlg('No GNSS type selected !!! Please select GNSS constellation in GNSS selection panel.',...
                     'Satellite selection interruption')  
      else
            INPUT.SelectedSatsString = get(findobj('tag','popupSat'),'String');
            INPUT.SelectedSatsString = INPUT.SelectedSatsString(get(findobj('tag','popupSat'),'Value'));
            INPUT.SelectedSatsString = INPUT.SelectedSatsString{1};
            
            % Unique satellites in popup sats menu
            INPUT.CurrentSatsAll = unique(INPUT.CurrentObs(1,:));                               % Available satellite set
            INPUT.CurrentSats = INPUT.CurrentSatsAll(get(findobj('tag','popupSat'),'Value'));   % Chosen satellite is 1 number
            INPUT.CurrentSats = INPUT.CurrentObs(:,INPUT.CurrentObs(1,:) == INPUT.CurrentSats); % Chose from all current obs selected by popup GNSS just columns belong selected sat number by popup sats
            
            INPUT.SelectedSats = INPUT.CurrentSatsAll(get(findobj('tag','popupSat'),'Value'));
            INPUT.CurrentPos = INPUT.CurrentPosAll(:,INPUT.CurrentPosAll(1,:) == INPUT.SelectedSats);
            
            INPUT.ObsPosCurrent(:,2:end) = [];
            INPUT.ObsPosCurrent{1} = INPUT.ObsPos{get(findobj('tag','popupSat'),'Value')};
            
            % Assign empty observations to variables
            INPUT.CurrentCode = [];%INPUT.CurrentCodeString{1};
            INPUT.CurrentPhase1 = [];%INPUT.CurrentPhase1String{1};
            INPUT.CurrentPhase2 = [];%INPUT.CurrentPhase2String{2};
            set(findobj('tag','popupCode'),'Value',1)
            set(findobj('tag','popupPhase1'),'Value',1)
            set(findobj('tag','popupPhase2'),'Value',1)
            set(findobj('tag','popupSNR'),'Value',1)
            
            % Update status bar
            INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
            INPUT.StatusBar.Code = 'MP code: --- ||';
            INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
            INPUT.StatusBar.Phase2 = '--- || ';
            
            switch INPUT.GNSS
                case 1
                   clear a
                   a = zeros(1,length(INPUT.ObsFileSats.G));
                   for i = 1:length(INPUT.ObsFileSats.G)
                       for j = 1:length(INPUT.SelectedSats)
                           if INPUT.SelectedSats(j) == INPUT.ObsFileSats.G(i)
                              a(1,i) = 1; 
                           end
                       end
                   end
                   INPUT.SelectedSatsString = INPUT.SatsStringG(logical(a));
                   
                case 2     
                   clear a
                   a = zeros(1,length(INPUT.ObsFileSats.E));
                   for i = 1:length(INPUT.ObsFileSats.E)
                       for j = 1:length(INPUT.SelectedSats)
                           if INPUT.SelectedSats(j) == INPUT.ObsFileSats.E(i)
                              a(1,i) = 1; 
                           end
                       end
                   end
                   INPUT.SelectedSatsString = INPUT.SatsStringE(logical(a));
            end
            INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
            
            % Disable popup menus of SNR
            set(findobj('tag','flyby1'),'Enable','off')
            set(findobj('tag','popupFlyBy'),'Value',1)
            set(findobj('tag','popupFlyBy'),'String','                          ---')
            set(findobj('tag','popupFlyBy'),'Enable','off')
      end
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      if length(get(findobj('tag','statusbar'),'String')) >= 130
         set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
      else
         set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
      end
      guidata(fig,INPUT)
end

function DFsats_Callback(fig,INPUT)
        INPUT = guidata(fig);
        if isempty(INPUT.GNSS)
        	errordlg('No GNSS type selected !!! Please select GNSS constellation in GNSS selection panel.',...
                     'Satellite selection interruption')  
        else
            if strcmp(get(findobj('tag','DFsats'),'String'),'all')
                  switch(INPUT.GNSS)
                        case 1
                              INPUT.SelectedSats = INPUT.ObsFileSats.G;
                              clear a
                              a = zeros(1,length(INPUT.ObsFileSats.G));
                              for i = 1:length(INPUT.ObsFileSats.G)
                                  for j = 1:length(INPUT.SelectedSats)
                                      if INPUT.SelectedSats(j) == INPUT.ObsFileSats.G(i)
                                         a(1,i) = 1; 
                                      end
                                  end
                              end
                              INPUT.SelectedSatsString = INPUT.SatsStringG(logical(a));
                              
                              % Assign empty observations to variables
                              INPUT.CurrentCode = [];%INPUT.CurrentCodeString{1};
                              INPUT.CurrentPhase1 = [];%INPUT.CurrentPhase1String{1};
                              INPUT.CurrentPhase2 = [];%INPUT.CurrentPhase2String{2};
                              
                              set(findobj('tag','popupCode'),'Value',1)
                              set(findobj('tag','popupPhase1'),'Value',1)
                              set(findobj('tag','popupPhase2'),'Value',1)
                              set(findobj('tag','popupSNR'),'Value',1)
                              
                        case 2
                              INPUT.SelectedSats = INPUT.ObsFileSats.E; 
                              clear a
                              a = zeros(1,length(INPUT.ObsFileSats.E));
                              for i = 1:length(INPUT.ObsFileSats.E)
                                  for j = 1:length(INPUT.SelectedSats)
                                      if INPUT.SelectedSats(j) == INPUT.ObsFileSats.E(i)
                                         a(1,i) = 1; 
                                      end
                                  end
                              end
                              INPUT.SelectedSatsString = INPUT.SatsStringE(logical(a));
                              
                              % Assign empty observations to variables
                              INPUT.CurrentCode = [];%INPUT.CurrentCodeString{1};
                              INPUT.CurrentPhase1 = [];%INPUT.CurrentPhase1String{1};
                              INPUT.CurrentPhase2 = [];%INPUT.CurrentPhase2String{2};
                              set(findobj('tag','popupCode'),'Value',1)
                              set(findobj('tag','popupPhase1'),'Value',1)
                              set(findobj('tag','popupPhase2'),'Value',1)
                              set(findobj('tag','popupSNR'),'Value',1)
                  end
                  INPUT.CurrentPos = INPUT.CurrentPosAll;
                  INPUT.CurrentSats = INPUT.CurrentObs;
                  INPUT.ObsPosCurrent = INPUT.ObsPos;
                  
                  % Update status bar
                  INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
                  INPUT.StatusBar.Code = 'MP code: --- ||';
                  INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
                  INPUT.StatusBar.Phase2 = '--- || ';

                  % Make popup flyby menus unable
                  if length(INPUT.SelectedSats) ~= 1
                     set(findobj('tag','flyby1'),'Enable','off')
                     set(findobj('tag','popupFlyBy'),'Value',1)
                     set(findobj('tag','popupFlyBy'),'Enable','off')
                  end
            else
                  clear Text

                  SatsText = get(findobj('tag','DFsats'),'String');
                  j = 1;
                  TextHelp = ' ';
                  ManualSatError = 0;

                  for i = 1:length(SatsText)
                        oz = SatsText(i);
                        ii = i - 1;
                        % For case if input have wrong format with multiple
                        % commas like: 1,,2 ; ,,1,2,5 ; 1,5,6
                        if strcmp(oz,',') && i >= 2
                           if strcmp(oz,SatsText(ii)) 
                              errordlg({'Wrong input format of satellites numbers !!! Please use only satellites numbers without GNSS abbreviation and comma as delimiter.';'';'Example: 1,15,25,28,30'},'Satellite selection interruption')
                              ManualSatError = 1;
                              break  
                           end
                        end

                        if strcmp(oz,'0') || strcmp(oz,'1') || strcmp(oz,'2') || strcmp(oz,'3') || strcmp(oz,'4') || strcmp(oz,'5') || strcmp(oz,'6') || strcmp(oz,'7') || strcmp(oz,'8') || strcmp(oz,'9') || strcmp(oz,',')
                            if strcmp(oz,',') && i == length(SatsText) % For case if comma is last character
                               errordlg({'Wrong input format of satellites numbers !!! Please use only satellites numbers without GNSS abbreviation and comma as delimiter or type "all" for all available satellites of constellation.';'';'Example: 1,15,25,28,30'},'Satellite selection interruption')
                               ManualSatError = 1;
                               break 
                            end
                        else    
                              errordlg({'Wrong input format of satellites numbers !!! Please use only satellites numbers without GNSS abbreviation and comma as delimiter or type "all" for all available satellites of constellation.';'';'Example: 1,15,25,28,30'},'Satellite selection interruption')
                              ManualSatError = 1;
                              break
                        end
                  end
                  
                  if isempty(SatsText),  ManualSatError = 1;  end

                  if ManualSatError == 0
                        for i = 1:length(SatsText)
                              oz = SatsText(i);
                              if strcmp(oz,',')
                                    Text(j) = str2num(TextHelp);
                                    j = j + 1;
                                    TextHelp = ' ';
                              else
                                    TextHelp = [TextHelp oz]; 
                              end
                              if i == length(SatsText)
                                    Text(j) = str2num(TextHelp);
                              end
                        end
                        
                        Text = unique(Text);
                           
                        switch(INPUT.GNSS)
                            case 1
                                INPUT.SelectedSats = intersect(INPUT.ObsFileSats.G,Text);
                            case 2
                                INPUT.SelectedSats = intersect(INPUT.ObsFileSats.E,Text);
                        end
                        
                        if isequal(INPUT.SelectedSats,Text)
                        else
                           if length(INPUT.SelectedSats) <= length(Text)
                              out = num2str(setdiff(Text,INPUT.SelectedSats));
                           else
                              out = num2str(setdiff(INPUT.SelectedSats,Text));
                           end
                           
                           if ~isempty(INPUT.SelectedSats)
                           
                           j = 1;
                           for i = 1:length(out)
                               if strcmp(out(i),' ')
                                  new(j) = ',';
                                  if i > 1 && new(j-1) ~= ','
                                     j = j + 1;
                                  end
                               else
                                  new(j) = out(i);
                                  j = j + 1;
                               end
                           end
                           clear i j out
                           errordlg({'Some of manually selected satellites were not observed !!! Please check satellite availability. If you do not change selection of satellites software will compute only with available ones.';'';['Not observed satellites are: ' new]},'Satellite selection interruption')  
                           end
                        end
                        
                        if isempty(INPUT.SelectedSats)
                           errordlg('None of manually selected satellites is observed !!! Please check satellite availability.','Satellite selection interruption')
                           INPUT = rmfield(INPUT,'SelectedSats');
                        else
                           % Assign to INPUT.CurrentSats just columns with satellites from INPUT.SelectedSats
                           % Observations
                           I = zeros(1,size(INPUT.CurrentObs,2));
                           for i = 1:size(INPUT.CurrentObs,2)
                               for j = 1:length(INPUT.SelectedSats)
                                   if INPUT.SelectedSats(j) == INPUT.CurrentObs(1,i)
                                      I(i) = 1;  
                                   end
                               end
                           end
                           I = logical(I);
                           INPUT.CurrentSats = INPUT.CurrentObs(:,I); 
                           
                           % Ephemeris
                           J = zeros(1,size(INPUT.CurrentPosAll,2));
                           for i = 1:size(INPUT.CurrentPosAll,2)
                               for j = 1:length(INPUT.SelectedSats)
                                   if INPUT.SelectedSats(j) == INPUT.CurrentPosAll(1,i)
                                       J(i) = 1;  
                                   end
                               end
                           end
                           J = logical(J);
                           INPUT.CurrentPos = INPUT.CurrentPosAll(:,J);
                           
                           % Assign empty observations to variables
                           INPUT.CurrentCode = [];%INPUT.CurrentCodeString{1};
                           INPUT.CurrentPhase1 = [];%INPUT.CurrentPhase1String{1};
                           INPUT.CurrentPhase2 = [];%INPUT.CurrentPhase2String{2};
                           set(findobj('tag','popupCode'),'Value',1)
                           set(findobj('tag','popupPhase1'),'Value',1)
                           set(findobj('tag','popupPhase2'),'Value',1)
                           set(findobj('tag','popupSNR'),'Value',1)
                           
                           % Update status bar
                           INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
                           INPUT.StatusBar.Code = 'MP code: --- ||';
                           INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
                           INPUT.StatusBar.Phase2 = '--- || ';
                           
                           % New variable INPUT.ObsPosCurrent
                           INPUT.ObsPosCurrent(:,2:end) = [];
                           k = 1;
                           for i = 1:size(INPUT.ObsPos,2)
                               for j = 1:length(INPUT.SelectedSats)
                                   if unique(INPUT.ObsPos{i}(1,:)) == INPUT.SelectedSats(j)
                                      INPUT.ObsPosCurrent{k} = INPUT.ObsPos{i};
                                      k = k + 1;
                                   end
                               end
                           end
                           
                           % Create variable INPUT.SelectedSatsString
                           switch INPUT.GNSS
                              case 1
                                    clear a
                                    a = zeros(1,length(INPUT.ObsFileSats.G));
                                    for i = 1:length(INPUT.ObsFileSats.G)
                                        for j = 1:length(INPUT.SelectedSats)
                                            if INPUT.SelectedSats(j) == INPUT.ObsFileSats.G(i)
                                               a(1,i) = 1; 
                                            end
                                        end
                                    end
                                    INPUT.SelectedSatsString = INPUT.SatsStringG(logical(a));
                   
                              case 2     
                                    clear a
                                    a = zeros(1,length(INPUT.ObsFileSats.E));
                                    for i = 1:length(INPUT.ObsFileSats.E)
                                        for j = 1:length(INPUT.SelectedSats)
                                            if INPUT.SelectedSats(j) == INPUT.ObsFileSats.E(i)
                                               a(1,i) = 1; 
                                            end
                                        end
                                    end
                                    INPUT.SelectedSatsString = INPUT.SatsStringE(logical(a)); 
                           end
                           INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
                        end
                  end
                  
                  % Disable flyby menus
                  set(findobj('tag','flyby1'),'Enable','off')
                  set(findobj('tag','popupFlyBy'),'Value',1)
                  set(findobj('tag','popupFlyBy'),'Enable','off')
            end
            set(findobj('tag','DFsats'),'String','') % Clear text window after ENTER 
        end
        set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
        if length(get(findobj('tag','statusbar'),'String')) >= 130
           set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
        else
           set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
        end
        guidata(fig,INPUT)        
end

function PopupCode_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
         errordlg('No GNSS and satellite selected. Please select GNSS in GNSS selection panel and satellite(s) in Satellites selection panel.','Multipath options interruption')
      else
         if strcmp(INPUT.CurrentCodeString{get(findobj('tag','popupCode'),'Value')}(2),INPUT.CurrentPhase1String{get(findobj('tag','popupPhase2'),'Value')}(2)) 
            errordlg('You cannot choose code measurement for MP variable at same freqency as the second phase measurement. Please choose differenrt code or phase measurement.','Signal selection interruption')
            set(findobj('tag','popupPhase2'),'Value',1)
            INPUT.CurrentPhase2 = [];
            INPUT.StatusBar.Phase2 = '--- || ';
            INPUT.CurrentCode = INPUT.CurrentCodeString{get(findobj('tag','popupCode'),'Value')};
            INPUT.StatusBar.Code = INPUT.CurrentCode;
            INPUT.StatusBar.Code = ['MP code: ', INPUT.CurrentCode, ' || '];
         else
            INPUT.CurrentCode = INPUT.CurrentCodeString{get(findobj('tag','popupCode'),'Value')};
            INPUT.StatusBar.Code = ['MP code: ', INPUT.CurrentCode, ' || '];
         end 
         
         if get(findobj('tag','popupCode'),'Value') == 1
            INPUT.CurrentCode = [];
            INPUT.StatusBar.Code = 'MP code: --- || ';
         end
      end
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      if length(get(findobj('tag','statusbar'),'String')) >= 130
         set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
      else
         set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
      end
      guidata(fig,INPUT)
end

function PopupPhase1_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
         errordlg('No GNSS and satellite selected. Please select GNSS in GNSS selection panel and satellite(s) in Satellites selection panel.','Multipath options interruption')
      else 
         if get(findobj('tag','popupPhase1'),'Value') == get(findobj('tag','popupPhase2'),'Value')
            errordlg('You cannot choose the same phases. Please choose phases at different frequencies.','Signal selection interruption')
            set(findobj('tag','popupPhase1'),'Value',1)
            INPUT.CurrentPhase1 = [];
            INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
         else
            if strcmp(INPUT.CurrentPhase1String{get(findobj('tag','popupPhase1'),'Value')}(2),INPUT.CurrentPhase2String{get(findobj('tag','popupPhase2'),'Value')}(2))
               errordlg('You cannot choose two phases at one frequency. Please choose different phase.','Signal selection interruption')
               set(findobj('tag','popupPhase1'),'Value',1)
               INPUT.CurrentPhase1 = [];
               INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
            else
               INPUT.CurrentPhase1 = INPUT.CurrentPhase1String{get(findobj('tag','popupPhase1'),'Value')};
               INPUT.StatusBar.Phase1 = ['MP phases:', INPUT.CurrentPhase1, ' , '];
            end
         end
         
         if get(findobj('tag','popupPhase1'),'Value') == 1
            INPUT.CurrentPhase1 = [];
            INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
         end
      end
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      if length(get(findobj('tag','statusbar'),'String')) >= 130
         set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
      else
         set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
      end
      guidata(fig,INPUT)
end

function PopupPhase2_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
            errordlg('No GNSS and satellite selected. Please select GNSS in GNSS selection panel and satellite(s) in Satellites selection panel.','Multipath options interruption')
      else  
         if get(findobj('tag','popupPhase2'),'Value') == get(findobj('tag','popupPhase1'),'Value')
            errordlg('You cannot choose the same phases. Please choose phases at different frequencies.','Signal selection interruption')
            set(findobj('tag','popupPhase2'),'Value',1)
            INPUT.CurrentPhase2 = [];
            INPUT.StatusBar.Phase2 = '--- || ';
         else
            if strcmp(INPUT.CurrentPhase1String{get(findobj('tag','popupPhase2'),'Value')}(2),INPUT.CurrentPhase2String{get(findobj('tag','popupPhase1'),'Value')}(2))
               errordlg('You cannot choose two phases with the same freqency. Please choose one phase with different frequency.','Signal selection interruption')
               set(findobj('tag','popupPhase2'),'Value',1)
               INPUT.CurrentPhase2 = [];
               INPUT.StatusBar.Phase2 = '--- || ';
            else
               if strcmp(INPUT.CurrentPhase1String{get(findobj('tag','popupPhase2'),'Value')}(2),INPUT.CurrentCodeString{get(findobj('tag','popupCode'),'Value')}(2)) 
                  errordlg('You cannot choose second phase measurement at same freqency as the code measurement for MP variable. Please choose phase at different frequency.','Signal selection interruption')
                  set(findobj('tag','popupPhase2'),'Value',1)
                  INPUT.CurrentPhase2 = [];
                  INPUT.StatusBar.Phase2 = '--- || ';
               else
                  INPUT.CurrentPhase2 = INPUT.CurrentPhase2String{get(findobj('tag','popupPhase2'),'Value')};
                  INPUT.StatusBar.Phase2 = [INPUT.CurrentPhase2, ' || '];
               end
            end
         end
         
         if get(findobj('tag','popupPhase2'),'Value') == 1
            INPUT.CurrentPhase2 = [];
            INPUT.StatusBar.Phase2 = '--- || ';
         end 
      end
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      if length(get(findobj('tag','statusbar'),'String')) >= 130
         set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
      else
         set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
      end
      guidata(fig,INPUT)
end

function GraphicAvaOutputs_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
         errordlg('No GNSS selected. Please select GNSS in GNSS selection panel and then select satellite(s) in Satellites selection panel.','Multipath graphics interruption')
      else
         if isempty(INPUT.SelectedSats)
            errordlg('No satellite(s) selected. Please select satellite(s) in Satellites selection panel.','Multipath graphics interruption') 
         else
      switch get(findobj('tag','popupVisibilityOut'),'Value')
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             case 1
             %%%%%%%%% Satellite visibility in time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.CurrentSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                figure('Name','Satellite occurence window','NumberTitle','off','Units','pixels',...
                       'Position',[330 150 700 500],'Resize','on','Color',[0.85 0.85 1],'Visible','off','tag','OccWin');

                % Plotting occurence graph
                switch(INPUT.GNSS)
                    case 1
                      titul = 'GPS satellite(s) occurence during observation';
                    case 2 
                      titul = 'Galileo satellite(s) occurence during observation';
                end

                color = hsv(length(INPUT.SelectedSats));
                for i = 1:size(INPUT.ObsPosCurrent,2)
                    sat = INPUT.ObsPosCurrent{i};
                    time = datenum(sat(2,:),sat(3,:),sat(4,:),sat(5,:),sat(6,:),sat(7,:));
                    if i == 1
                       minmaxt = [time(1)-0.02, time(end)+0.02];
                    end

                    plot(time,sat(1,:),'o','MarkerSize',3,'MarkerEdgeColor',color(i,:),'MarkerFaceColor',color(i,:));
                    hold on
                    if time(1)-0.02 < minmaxt(1)
                       minmaxt(1) = time(1)-0.02;
                    end
                    if time(end)+0.02 > minmaxt(2)
                       minmaxt(2) = time(end)+0.02;
                    end
                end
         
                title(titul,'FontSize',12,'FontWeight','bold')
                %legend(INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats))
                axis([minmaxt(1) minmaxt(2) min(INPUT.SelectedSats)-1 max(INPUT.SelectedSats)+1])
                xlabel('GPS Time (h)')
                ylabel('Satellite number')
                set(gca,'YTick',INPUT.SelectedSats)
                set(findobj('tag','OccWin'),'Visible','on')
                datetick('x',15,'keepticks','keeplimits')
                grid on
             end
             
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             case 2
             %%%%%%%%% Satellite elevation in time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.CurrentSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                SatHTWin = figure('Name','Satellite elevation window','NumberTitle','off','Units','pixels',...
                                  'Position',[330 150 700 500],'Resize','on','Color',[0.85 0.85 1],'Visible','off','tag','OccWin');

                % Plotting occurence graph
                switch(INPUT.GNSS)
                    case 1
                       titul = 'GPS satellite(s) elevation above horizon as function of time';
                    case 2 
                       titul = 'Galileo satellite(s) elevation above horizon as function of time';
                end
         
                maxy = 0;
                color = hsv(length(INPUT.SelectedSats));   
                for i = 1:size(INPUT.ObsPosCurrent,2)
                    sat = INPUT.ObsPosCurrent{i};
                    time = datenum(sat(2,:),sat(3,:),sat(4,:),sat(5,:),sat(6,:),sat(7,:));
                    if i == 1
                       minmaxt = [time(1)-0.02, time(end)+0.02];
                       hold on
                    end
                    
                    plot(time,sat(15+INPUT.ObsTypes,:),'o','MarkerSize',3,'MarkerEdgeColor',color(i,:),'MarkerFaceColor',color(i,:));
                    
                    if time(1)-0.02 < minmaxt(1)
                       minmaxt(1) = time(1)-0.02;
                    end
                    if time(end)+0.02 > minmaxt(2)
                       minmaxt(2) = time(end)+0.02;
                    end
                    
                    if max(sat(15+INPUT.ObsTypes,:)) > maxy
                       maxy = max(sat(15+INPUT.ObsTypes,:));
                    end
                end

                title(titul,'FontSize',12,'FontWeight','bold')
                legend(INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats))
                axis([minmaxt(1) minmaxt(2) 0 maxy-rem(maxy,5)+5])
                xlabel('GPS Time (h)')
                ylabel('Satellite(s) elevation (degrees)')
                set(gca,'YTick',0:5:(maxy-rem(maxy,5)+5))
                set(findobj('tag','OccWin'),'Visible','on')
                datetick('x',15,'keepticks','keeplimits')
                grid on
             end
             
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             case 3
             %%%%%%%%% Satellite visibility skyplot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.CurrentSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                skyplot(INPUT)
             end
             
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             case 4
             %%%%%%%%% Satellite signals availability %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.CurrentSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                figure('Name','Satellite signals availability','NumberTitle','off','Units','pixels',...
                       'Position',[330 150 700 500],'Resize','on','Color',[0.85 0.85 1],'Visible','off','tag','SatsSignalAvailability');

                SatsSignalsAvailability = NaN(INPUT.ObsTypes,length(INPUT.ObsPosCurrent));
                color = hsv(INPUT.ObsTypes);
                for i = 1:length(INPUT.ObsPosCurrent)
                    for j = 1:INPUT.ObsTypes
                        if unique(INPUT.ObsPosCurrent{i}(8+j,:)) ~= 0
                           SatsSignalsAvailability(j,i) = j; 
                        end
                        plot(SatsSignalsAvailability(j,:),'o','MarkerSize',5,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',color(j,:))
                        hold on
                    end
                    text(i,-.7,INPUT.SelectedSatsString{i},'VerticalAlignment','middle','HorizontalAlignment','center',...
                         'BackgroundColor',[0.85 0.85 1],'Rotation',90,'Fontsize',get(gca,'FontSize'))
                end

                axis([0 length(INPUT.ObsPosCurrent)+1 0 INPUT.ObsTypes+1])
                set(gca,'XTick',1:length(INPUT.SelectedSats),'XTickLabel','','YTick',1:INPUT.ObsTypes,'YTickLabel',INPUT.ObsTypesAll)
                title('Satellite(s) signals availability','FontSize',12,'FontWeight','bold')
                ylabel('Satellite signal (code,phase,SNR)')
                set(findobj('tag','SatsSignalAvailability'),'Visible','on')
             end
      end
      end
      end
      guidata(fig,INPUT)   
end

function GraphicMPOutputs_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.CurrentCode) || isempty(INPUT.CurrentPhase1) || isempty(INPUT.CurrentPhase2)
         errordlg('No observations types selected. Please select observations types in Code multipath computation options panel.','Observation type interruption')
      else
         switch get(findobj('tag','popupMPOut'),'Value')
             case 1 %%%%%%%%% MP as a function of time
                INPUT = MP_time_elev_slips(INPUT,1); 

             case 2 %%%%%%%%% MP as a function of elevation
                INPUT = MP_time_elev_slips(INPUT,2);
             
             case 3 %%%%%%%%% MP skyplot (coloured dots)
                INPUT = MP_time_elev_slips(INPUT,3);
             
             case 4 %%%%%%%%% MP skyplot (tiny bars)
                INPUT = MP_time_elev_slips(INPUT,4);
             
             case 5 %%%%%%%%% MP skyplot (interpolated)
                INPUT = MP_time_elev_slips(INPUT,5);
             
             case 6 %%%%%%%%% MP time histogram
                INPUT = MP_time_elev_slips(INPUT,6);
             
             case 7 %%%%%%%%% MP detected cycle-slips
                INPUT = MP_time_elev_slips(INPUT,7);
             
             case 8 %%%%%%%%% MP elevation histogram
                INPUT = MP_time_elev_slips(INPUT,8);
         end
      end 
      guidata(fig,INPUT) 
end

function ExportCode_Callback(fig,INPUT)
    INPUT = guidata(fig);
    if INPUT.ComputedPositions == 0
       errordlg('No data to export. Please choose observation and ephemeris files and the compute positions.','No data interruption')
    else
       o = INPUT.Multipath;
       %save('INPUT.mat','INPUT')
    
       if ismember('G',INPUT.ObsFileGNSSTypes)
          OUTPUT.ObsPos.G = INPUT.ObsPosBoth.G;
          oG = o.G; 
          oG = myrmfield(oG);
          if ~isempty(fieldnames(oG))
             oG = editout(oG,1);
             OUTPUT.Multipath.G = oG;
          end
       end
    
       if ismember('E',INPUT.ObsFileGNSSTypes)
          OUTPUT.ObsPos.E = INPUT.ObsPosBoth.E;
          oE = o.E; 
          oE = myrmfield(oE);
          if ~isempty(fieldnames(oE))
             oE = editout(oE,2);
             OUTPUT.Multipath.E = oE;
          end
       end
    
       [name, path] = uiputfile('MP_output.mat','Save MP code outputs in *mat');
                     
       if ischar(path) && ischar(name)
          save([path name],'OUTPUT') 
       end
    end
   
    function structure_help = myrmfield(structure)
        names = fieldnames(structure);
        structure_help = structure;
        for i = 1:length(names)
            if strcmp(names{i},'Selection')
               structure_help = rmfield(structure_help,'Selection');
            end
            if strcmp(names{i},'RMS')
               structure_help = rmfield(structure_help,'RMS'); 
            end
            if strcmp(names{i},'Cyclslplot')
               structure_help = rmfield(structure_help,'Cyclslplot');
               structure_help.Cycleslips = structure.Cyclslplot; 
            end
            if strcmp(names{i},'CutoffTrue')
               structure_help = rmfield(structure_help,'CutoffTrue');
               structure_help.CutOff = structure.CutoffTrue; 
            end
        end
    end
    
    function structure_help = editout(structure,gnss_type)
        INPUT = guidata(fig);
        names = fieldnames(structure);
        for i = 1:length(names)
            if strcmp('MP',names{i})
               current_structure1 = structure.MP.GF;
               current_structure2 = structure.MP.MW;
            end    
            if strcmp('MPF',names{i})
               current_structure1 = structure.MPF.GF;
               current_structure2 = structure.MPF.MW;
            end 
            if strcmp('CSdetector',names{i})
               current_structure1 = structure.CSdetector.GF;
               current_structure2 = structure.CSdetector.MW;
            end 
            if strcmp('Cycleslips',names{i})
               current_structure1 = structure.Cycleslips.GF;
               current_structure2 = structure.Cycleslips.MW;
            end 
            if strcmp('CutOff',names{i})
               current_structure1 = structure.CutOff.GF;
               current_structure2 = structure.CutOff.MW;
            end 

            for detector = 1:2
                switch detector
                    case 1
                       current_structure = current_structure1;
                       str = 'GF';
                    case 2
                       current_structure = current_structure2;
                       str = 'MW';
                end
        
                erase = zeros(1,100);
                if i ~= 5
                   NoEmptyCells = not(cellfun('isempty',current_structure));
                   ci = 1;
                   for f = 1:length(NoEmptyCells)
                       if NoEmptyCells(f) == 1
                          combination_index(ci) = f;
                          ci = ci + 1;
                       end
                   end
                   clear f ci
                  
                   LengthNoEmptyCells = sum(NoEmptyCells);
                   NoEmptyCells = current_structure(NoEmptyCells);
                   for j = 1:LengthNoEmptyCells
                       NoEmpty = not(cellfun('isempty',NoEmptyCells{j}));
                       if sum(NoEmpty) == 0
                          erase(1,1) = erase(1,1) + 1;
                          erase(1,j+1) = erase(1,j+1) + 1;
                       end
                   end
        
                   switch i
                       case 1
                          erase_a = structure.MP;
                       case 2
                          erase_a = structure.MPF;
                       case 3
                          erase_a = structure.CSdetector;
                       case 4
                          erase_a = structure.Cycleslips;
                   end

                   if erase(1,1) == LengthNoEmptyCells
                      erase_a = rmfield(erase_a,str);
                      switch i
                          case 1
                             structure_help.MP = erase_a;
                          case 2
                             structure_help.MPF = erase_a;
                          case 3
                             structure_help.CSdetector = erase_a;
                          case 4
                             structure_help.Cycleslips = erase_a;
                      end
                   else
                      clear a 
                      switch detector
                          case 1
                             a = erase_a.GF;
                          case 2
                             a = erase_a.MW; 
                      end
                  
                      for jj = 1:LengthNoEmptyCells
                          if erase(1,jj+1) ~= 0
                             a{combination_index(jj)} = [];
                          end
                      end
                
                      combinations = find(not(cellfun('isempty',a)) == 1);
                      switch detector
                          case 1
                             combinationsGF = combinations;
                          case 2
                             combinationsMW = combinations; 
                      end

                      for gg = 1:length(combinations)
                          CODE = floor(combinations(gg)/100);
                          PHASE1 = floor((combinations(gg) - CODE*100)/10);
                          PHASE2 = combinations(gg) - CODE*100 - PHASE1*10;
                          switch gnss_type
                              case 1
                                 CODE_PHASE1_PHASE2 = [INPUT.ObsCodeString.G{CODE-1}, INPUT.ObsPhase1String.G{PHASE1-1}, INPUT.ObsPhase1String.G{PHASE2-1}];
                              case 2
                                 CODE_PHASE1_PHASE2 = [INPUT.ObsCodeString.E{CODE-1}, INPUT.ObsPhase1String.E{PHASE1-1}, INPUT.ObsPhase1String.E{PHASE2-1}];   
                          end
                          
                          CODE_PHASE1_PHASE2 = mynum2str(CODE_PHASE1_PHASE2,'default');
                          CODE_PHASE1_PHASE2(CODE_PHASE1_PHASE2 == ',') = '';
                      
                          z = 1; 
                          clear sat_names sat_values
                          for pp = 1:length(a{combinations(gg)}) 
                              xxx = a{combinations(gg)}(pp);
                              if ~isempty(xxx{1})
                                 switch gnss_type
                                     case 1
                                        sat_names{z} = INPUT.SatsStringG{pp};
                                        sat_values{z} = xxx{1};
                                        z = z + 1;
                                     case 2
                                        sat_names{z} = INPUT.SatsStringE{pp};
                                        sat_values{z} = xxx{1};
                                        z = z + 1;
                                 end
                              end
                          end
                      
                          for jjj = 1:length(sat_names)
                              if jjj == 1
                                 bb = struct(sat_names{jjj},[]);
                                 bb = setfield(bb,sat_names{jjj},sat_values{jjj});
                              else
                                 bb = setfield(bb,sat_names{jjj},sat_values{jjj}); 
                              end
                          end
                      
                          if gg == 1
                             b = struct(CODE_PHASE1_PHASE2,[]);
                             b = setfield(b,CODE_PHASE1_PHASE2,bb);
                          else
                             b = setfield(b,CODE_PHASE1_PHASE2,bb); 
                          end
                      end
           
                      switch i
                          case 1
                             switch detector
                                 case 1
                                    structure_help.MP.GF = b;
                                 case 2
                                    structure_help.MP.MW = b;
                             end
                          case 2
                             switch detector
                                 case 1
                                    structure_help.MPF.GF = b;
                                 case 2
                                    structure_help.MPF.MW = b;
                             end
                          case 3
                             switch detector
                                 case 1
                                    structure_help.CSdetector.GF = b;
                                 case 2
                                    structure_help.CSdetector.MW = b;
                             end
                          case 4
                             switch detector
                                 case 1
                                    structure_help.Cycleslips.GF = b;
                                 case 2
                                    structure_help.Cycleslips.MW = b;
                             end           
                      end
                   end
                else
                   erase_a = structure.CutOff; 
                   switch detector
                       case 1
                          ach = erase_a.GF;
                          if exist('combinationsGF')
                             comb = combinationsGF;
                          else
                             comb = [];
                             erase_a = rmfield(erase_a,str);
                             structure_help.CutOff = erase_a;
                          end
                       case 2
                          ach = erase_a.MW;
                          if exist('combinationsMW')
                             comb = combinationsMW;
                          else
                             comb = [];
                             erase_a = rmfield(erase_a,str);
                             structure_help.CutOff = erase_a;
                          end
                   end

                   clear bbb
                   for gg = 1:length(comb)
                       CODE = floor(comb(gg)/100);
                       PHASE1 = floor((comb(gg) - CODE*100)/10);
                       PHASE2 = comb(gg) - CODE*100 - PHASE1*10;
                       switch gnss_type
                           case 1
                              CODE_PHASE1_PHASE2 = [INPUT.ObsCodeString.G{CODE-1}, INPUT.ObsPhase1String.G{PHASE1-1}, INPUT.ObsPhase1String.G{PHASE2-1}];
                           case 2
                              CODE_PHASE1_PHASE2 = [INPUT.ObsCodeString.E{CODE-1}, INPUT.ObsPhase1String.E{PHASE1-1}, INPUT.ObsPhase1String.E{PHASE2-1}];   
                       end
               
                       CODE_PHASE1_PHASE2 = mynum2str(CODE_PHASE1_PHASE2,'default');
                       CODE_PHASE1_PHASE2(CODE_PHASE1_PHASE2 == ',') = '';
                          
                       if gg == 1
                          bbb = struct(CODE_PHASE1_PHASE2,[]);
                          bbb = setfield(bbb,CODE_PHASE1_PHASE2,ach(comb(gg)));
                       else
                          bbb = setfield(bbb,CODE_PHASE1_PHASE2,ach(comb(gg))); 
                       end
                       switch detector
                           case 1
                              structure_help.CutOff.GF = bbb;
                           case 2
                              structure_help.CutOff.MW = bbb; 
                       end
                   end
                end
            end
        end
        guidata(fig,INPUT)
    end
    guidata(fig,INPUT)
end

function PopupSNR_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
         errordlg('No GNSS and satellite selected. Please select GNSS in GNSS selection panel and satellite(s) in Satellites selection panel.','Multipath options interruption')
      else
         if isempty(INPUT.SelectedSats)
            errordlg('No satellite(s) selected. Please select satellite by pop-up menu in Satellite selection panel or choose satellite(s) manualy.','Satellite selection interruption')
            INPUT.CurrentSNRstr = [];
            set(findobj('tag','popupSNR'),'Value',1)
         else
            if get(findobj('tag','popupSNR'),'Value') == 1
               errordlg('No GNSS SNR observations selected. Please select SNR observations in pop-up menu above in SNR options panel.','SNR options interruption') 
               INPUT.CurrentSNRstr = [];
            
               % Disable popup menus of SNR
               set(findobj('tag','flyby1'),'Enable','off')
               set(findobj('tag','popupFlyBy'),'String','                          ---')
               set(findobj('tag','popupFlyBy'),'Enable','off')
            else
               if length(INPUT.SelectedSats) ~= 1 
                  % Disable FlyBy and Phase menus
                  set(findobj('tag','flyby1'),'Enable','off')
                  set(findobj('tag','popupFlyBy'),'String','                          ---')
                  set(findobj('tag','popupFlyBy'),'Enable','off')
                  INPUT.CurrentSNRstr = INPUT.CurrentSNRString{get(findobj('tag','popupSNR'),'Value')};
               else
                   if ~isempty(INPUT.SelectedSats)
                      % Enable popup menus of SNR
                      set(findobj('tag','flyby1'),'Enable','on')
                      set(findobj('tag','popupFlyBy'),'Enable','on')
                
                      INPUT.CurrentSNRstr = INPUT.CurrentSNRString{get(findobj('tag','popupSNR'),'Value')};
                      switch INPUT.GNSS
                          case 1
                             SNRsat = INPUT.ObsFileSats.G == INPUT.SelectedSats; 
                             SNRsat_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,INPUT.CurrentSNRstr), zeros(1,8)]);
                             INPUT.CurrentSNR.Val = INPUT.ObsPosBoth.G{SNRsat}(SNRsat_index,:);
                             INPUT.CurrentSNR.Time = INPUT.ObsPosBoth.G{SNRsat}(8,:); 
                             INPUT.CurrentSNR.Elevation = INPUT.ObsPosBoth.G{SNRsat}(end-1,:); 
                             INPUT.CurrentSNR.Azimuth = INPUT.ObsPosBoth.G{SNRsat}(end,:);
                             h = INPUT.CurrentSNR;
                             n = fieldnames(h);
                             if sum(strcmp(n,'FlyBy')) ~= 0
                                h = rmfield(h,'FlyBy');
                                INPUT.CurrentSNR = h;
                             end
                          case 2
                             SNRsat = INPUT.ObsFileSats.E == INPUT.SelectedSats; 
                             SNRsat_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,INPUT.CurrentSNRstr), zeros(1,8)]);
                             INPUT.CurrentSNR.Val = INPUT.ObsPosBoth.E{SNRsat}(SNRsat_index,:); 
                             INPUT.CurrentSNR.Time = INPUT.ObsPosBoth.E{SNRsat}(8,:); 
                             INPUT.CurrentSNR.Elevation = INPUT.ObsPosBoth.E{SNRsat}(end-1,:); 
                             INPUT.CurrentSNR.Azimuth = INPUT.ObsPosBoth.E{SNRsat}(end,:);
                             h = INPUT.CurrentSNR;
                             n = fieldnames(h);
                             if sum(strcmp(n,'FlyBy')) ~= 0
                                h = rmfield(h,'FlyBy');
                                INPUT.CurrentSNR = h;
                             end
                      end
                   
                      occurs = sum(diff(INPUT.CurrentSNR.Time) >= 3/24) + 1;
                      fbt = 1:1:length(INPUT.CurrentSNR.Time);
                      fbt = fbt(logical([0, diff(INPUT.CurrentSNR.Time) >= 3/24]));

                      for w = 1:occurs
                          if w == 1                                        % FB Matrix
                             if isempty(fbt)                               % | 1     88     199  |  <---  1st flyby: start, top, set                         
                                FB(w,1) = 1;                               % | 200   620    984  |  <---  2nd flyby: start, top, set 
                                FB(w,3) = length(INPUT.CurrentSNR.Time);   % | 985   1010   1010 |  <---  3rd flyby: start, top, set 
                             else
                                FB(w,1) = 1;                    
                                FB(w,3) = fbt(1)-1; 
                             end               
                          else                               
                             if w == occurs
                                FB(w,1) = fbt(w-1);
                                FB(w,3) = length(INPUT.CurrentSNR.Time);
                             else
                                FB(w,1) = fbt(w-1);
                                FB(w,3) = fbt(w)-1;
                             end
                          end
                          [~,FB(w,2)] = max(INPUT.CurrentSNR.Elevation(FB(w,1):FB(w,3)));
                          FB(w,2) = FB(w,2) + FB(w,1) - 1;
                          INPUT.CurrentSNR.FlyBy.Time(w,:) = [INPUT.CurrentSNR.Time(FB(w,1)), INPUT.CurrentSNR.Time(FB(w,2)), INPUT.CurrentSNR.Time(FB(w,3))];
                          INPUT.CurrentSNR.FlyBy.InsStr{w,1} = datestr(INPUT.CurrentSNR.FlyBy.Time(w,1),'mm/dd HH:MM');
                          INPUT.CurrentSNR.FlyBy.InsStr{w,1} = [INPUT.CurrentSNR.FlyBy.InsStr{w,1}, '  -  ',datestr(INPUT.CurrentSNR.FlyBy.Time(w,3),'mm/dd HH:MM')];
                      end

                      INPUT.CurrentSNR.FlyBy.FB = FB;
                      INPUT.CurrentSNR.FlyBy.InsStr = [{'                          ---'}; INPUT.CurrentSNR.FlyBy.InsStr;];
                      set(findobj('tag','popupFlyBy'),'String',INPUT.CurrentSNR.FlyBy.InsStr)
                      set(findobj('tag','popupFlyBy'),'Value',1)
                   end
               end
            end
         end
      end
      guidata(fig,INPUT)
end

function PopupFlyBy_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS)
         errordlg('No GNSS and satellite selected. Please select GNSS in GNSS selection panel and satellite(s) in Satellites selection panel.','Multipath options interruption')
      else
         if isempty(INPUT.CurrentSNRstr) || strcmp('      ---',INPUT.CurrentSNRstr) 
            errordlg('No GNSS SNR observations selected. Please select SNR observations in pop-up menu above in SNR options panel.','SNR options interruption') 
         else
            if get(findobj('tag','popupFlyBy'),'Value') == 1
               errordlg('No satellite fly-by selected. Please select one of available fly-by or choose option --- all fly-by --- to select all available fly-by from observations.','Fly-by selection interruption') 
            end
         end
      end
      guidata(fig,INPUT)
end

function GraphicSNR_Callback(fig,INPUT)
      INPUT = guidata(fig);
      if isempty(INPUT.GNSS) 
         errordlg('No GNSS and satellite selected. Please select GNSS in GNSS selection panel and satellite(s) in Satellites selection panel.','Multipath options interruption')
      else
         if get(findobj('tag','popupSNR'),'Value') ~= 1
            % Reselect INPUT.SelectedSats according to SNR pop-up 
            switch INPUT.GNSS
                case 1
                   SNR_ind = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,INPUT.CurrentSNRstr), zeros(1,8)]);
                case 2 
                   SNR_ind = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,INPUT.CurrentSNRstr), zeros(1,8)]); 
            end 
            j = 1;
            logic_reselect = zeros(1,length(INPUT.SelectedSats));
            for i = 1:length(INPUT.SelectedSats)
                snr_flag = max(unique(INPUT.ObsPosCurrent{i}(SNR_ind,:)));
            
                if snr_flag ~= 0
                   ReSelectedSats(j) = INPUT.SelectedSats(i);
                   logic_reselect(i) = 1;
                   j = j + 1;
                end
            end
            logic_reselect = logical(logic_reselect);
      
            if j == 1 % No changes in j means that variable ReSelectedSats does not exist
               ReSelectedSats = []; 
            end
      
            if sum(logic_reselect) ~= length(INPUT.SelectedSats)
               outnew = mynum2str(setdiff(INPUT.SelectedSats,ReSelectedSats),'default');
               if ~isempty(setdiff(INPUT.SelectedSats,ReSelectedSats))
                  errordlg({'Selected satellites do not have selected SNR observations. Selection of satellites will be redefined.';'';['Satellites withoutselected SNR observations: ' outnew]},'Satellite selection interruption')
               end
               clear out 
            end
      
            INPUT.SelectedSats = ReSelectedSats;
            INPUT.ObsPosCurrent = INPUT.ObsPosCurrent(logic_reselect);
            INPUT.SelectedSatsString = INPUT.SelectedSatsString(logic_reselect);
            INPUT.StatusBar.Sats = mynum2str(INPUT.SelectedSats,'Sats');
         end
      
      if isempty(INPUT.SelectedSats)
         set(findobj('tag','popupFlyBy'),'Value',1)
         set(findobj('tag','popupFlyBy'),'Enable','off') 
      end 
         
      SNRfig = figure('Name','SNR in time','NumberTitle','off','Visible','off','tag','SNR','ToolBar','figure',...
                      'Units','pixels','Position',[300 75 700 600],'Color',[0.85 0.85 1],'Resize','on'); 
         
      switch get(findobj('tag','popupSNRGraphic'),'Value')
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case 1
          %%%%%%%%% SNR in time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.SelectedSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                if isempty(INPUT.CurrentSNRstr)
                   errordlg('No SNR observations selected. Please select SNR option panel.','Satellite selection interruption')
                else
                   switch(INPUT.GNSS)
                       case 1
                         titul = 'GPS signal to noise ratio during observation';
                         txt = 'GPS SNR (';
                         txt_uno = 'GPS satellite ';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,INPUT.CurrentSNRstr), zeros(1,8)]);
                       case 2 
                         titul = 'Galileo signal to noise ratio during observation';
                         txt = 'Galileo SNR (';
                         txt_uno = 'Galileo satellite ';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,INPUT.CurrentSNRstr), zeros(1,8)]);
                   end

                   if length(INPUT.SelectedSats) == 1
                      if get(findobj('tag','popupFlyBy'),'Value') == 1
                         errordlg('No SNR fly-by selected. Please select one of available fly-by under SNR observation popup menu.','Satellite selection interruption') 
                      else
                         index = INPUT.CurrentSNR.FlyBy.FB(get(findobj('tag','popupFlyBy'),'Value')-1,:);
                         if index(1) == index(2) || index(3) == index(2)
                            set(SNRfig,'Units','Normalized','Position',[0.25 0.08 0.51 0.80])
                            time = INPUT.CurrentSNR.Time(index(1):index(3));
                            if length(time) < 60
                               koef = 24*60;
                            else
                               koef = 24;
                            end
                            tf = (time - mean(time))*koef;
                            snr = INPUT.CurrentSNR.Val(index(1):index(3));

                            subplot('Position',[0.10 0.41 0.83 0.5])
                            plot(time,snr,'o','MarkerSize',3)
                            hold on
                            if length(time) > 10
                               if (time(end) - time(1))*24 < 2
                                  order = 2;
                                  if (time(end) - time(1))*24 < 1.5
                                     order = 1; 
                                  end 
                               else
                                  order = 10; 
                               end

                               snr_fit_par = polyfit(tf,snr,order);
                               snr_fit = polyval(snr_fit_par,tf);
                               tff = tf/koef + mean(time);
                               plot(tff,snr_fit,'Color','red','LineWidth',2)
                               legend({'SNR observations',[num2str(order), 'th order fit']},'Location','southeast')

                               plot(time,snr,'o','MarkerSize',3)
                               ylabel('SNR (dB-Hz)')
                               datetick('x',15,'keepticks','keeplimits')
                               grid on 

                               subplot('Position',[0.10 0.11 0.83 0.22])
                               stem(time,snr - snr_fit,'o','MarkerSize',3)
                               datetick('x',15,'keepticks','keeplimits')
                               xlabel('GPS Time (hours)')
                               ylabel('Residuals (dB-Hz)')
                               grid on 
   
                               txt = [txt_uno, INPUT.SelectedSatsString{1},' signal to noise ratio (', INPUT.CurrentSNRstr, ') and its polynomial fit with residuals'];
                               text(0.5,3.8,txt,'Units','Normalized','verticalalignment','middle','horizontalalignment','center','fontweight','bold','fontsize',12)
                               set(SNRfig,'Visible','on')
                               
                            else
                               errordlg('Not enought SNR observations in selected fly-by.','SNR data interruption') 
                            end
                            
                         else % If there is ascending and descending phase
                            set(SNRfig,'Units','Normalized','OuterPosition',[0 0.05 1 0.95]) 
                            snr_all = INPUT.CurrentSNR.Val(index(1):index(3));
                            for i = 1:2
                                time = INPUT.CurrentSNR.Time(index(i):index(i+1));
                                if length(time) < 60
                                   koef = 24*60;
                                else
                                   koef = 24;
                                end
                                tf = (time - mean(time))*koef;
                                snr = INPUT.CurrentSNR.Val(index(i):index(i+1));
                                vec_main = [i*0.475-0.415 0.39 0.425 0.5];
                                vec_aux = [i*0.475-0.415 0.09 0.425 0.22];
       
                                subplot('Position',vec_main)
                                plot(time,snr,'o','MarkerSize',3)
                                hold on
                                if length(time) > 10
                                   if (time(end) - time(1))*24 < 2
                                      order = 2;
                                      if (time(end) - time(1))*24 < 1.5
                                          order = 1; 
                                      end 
                                   else
                                      order = 10; 
                                   end

                                   snr_fit_par = polyfit(tf,snr,order);
                                   snr_fit = polyval(snr_fit_par,tf);
                                   tff = tf/koef + mean(time);
                                   plot(tff,snr_fit,'Color','red','LineWidth',2)
                                   
                                   switch i
                                       case 1
                                          legend({'SNR observations',[num2str(order), 'th order fit']},'Location','southeast')
                                          title('Satellite ascending phase','fontsize',11)
                                       case 2
                                          legend({'SNR observations',[num2str(order), 'th order fit']},'Location','southwest')
                                          title('Satellite descending phase','fontsize',11)
                                   end

       
                                   ylabel(['SNR (', INPUT.CurrentSNRstr, ') (dB-Hz)'])
                                   axis([min(time)-0.01 max(time)+0.01 min(snr_all)-1 max(snr_all)+2])
                                   datetick('x',15,'keepticks','keeplimits')
                                   grid on 

                                   pl(i) = subplot('Position',vec_aux);
                                   stem(time,snr - snr_fit,'o','MarkerSize',3);
                                   lim_res(i,:) = [min(snr - snr_fit) max(snr - snr_fit)];
                                   set(gca,'XLim',[min(time)-0.01 max(time)+0.01])
                                   datetick('x',15,'keepticks','keeplimits')
                                   xlabel('GPS Time (hours)')
                                   ylabel('Residuals (dB-Hz)')
                                   grid on 
                                else
                                   errordlg('Not enought SNR observations in selected fly-by.','SNR data interruption') 
                                   break
                                end
                            end
                            
                            for j = 1:2
                                set(pl(j),'YLim',[min(lim_res(:,1))-0.5 max(lim_res(:,2))+0.5])
                            end
                            if i == 2
                               txt = [txt_uno, INPUT.SelectedSatsString{1},' signal to noise ratio (', INPUT.CurrentSNRstr, ') and its polynomial fit with residuals'];
                               text(0,3.97,txt,'Units','Normalized','verticalalignment','middle','horizontalalignment','center','fontweight','bold','fontsize',12)
                               set(SNRfig,'Visible','on')
                            end
                         end
                      end
                   else % If length(INPUT.SelectedSats) > 1
                      color = hsv(length(INPUT.SelectedSats));
                      for i = 1:length(INPUT.SelectedSats)
                          sat = INPUT.ObsPosCurrent{i};
                          time = sat(8,:);
                          snr = sat(SNR_index,:);
                      
                          if i == 1
                             minmaxt = [time(1)-0.02, time(end)+0.02];
                             minmaxSNR = [min(snr), max(snr)];
                          end

                          plot(time,snr,'o','MarkerSize',3,'MarkerEdgeColor',color(i,:));
                          hold on
                       
                          if time(1)-0.02 < minmaxt(1)
                             minmaxt(1) = time(1)-0.02;
                          end
                          if time(end)+0.02 > minmaxt(2)
                             minmaxt(2) = time(end)+0.02;
                          end
                          if min(snr) < minmaxSNR(1)
                             minmaxSNR(1) = min(snr);
                          end
                          if max(snr) > minmaxSNR(2)
                             minmaxSNR(2) = max(snr);
                          end
                      end
                      
                      title(titul,'FontSize',12,'FontWeight','bold')
                      legend(INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats))
                      axis([minmaxt(1) minmaxt(2) minmaxSNR(1)-3 minmaxSNR(2)+3])
                      xlabel('GPS Time (h)')
                      ylabel([INPUT.CurrentSNRstr, ' (dB-Hz)'])
                      datetick('x',15,'keepticks','keeplimits')
                      grid on
                      set(findobj('tag','SNR'),'Visible','on','Position',[330 150 700 500])
                   end % End condition length(INPUT.SelectedSats) == 1
                end
             end
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case 2
          %%%%%%%%% SNR in elevation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.SelectedSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                if isempty(INPUT.CurrentSNRstr)
                   errordlg('No SNR observations selected. Please select SNR option panel.','Satellite selection interruption')
                else
                   set(gcf,'Name','SNR in elevation') 
                   switch(INPUT.GNSS)
                       case 1
                         titul = 'GPS signal to noise ratio during observation';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,INPUT.CurrentSNRstr), zeros(1,8)]);
                       case 2 
                         titul = 'Galileo signal to noise ratio during observation';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,INPUT.CurrentSNRstr), zeros(1,8)]);
                   end

                   color = hsv(length(INPUT.SelectedSats));
                   for i = 1:length(INPUT.SelectedSats)
                       sat = INPUT.ObsPosCurrent{i};
                       elev = sat(end-1,:);
                       snr = sat(SNR_index,:);
                       
                       if i == 1
                          minmaxe = [-2, myround(max(elev),5,'ceil')];
                          minmaxSNR = [min(snr), max(snr)];
                       end

                       plot(elev,snr,'o','MarkerSize',3,'MarkerEdgeColor',color(i,:));
                       hold on
                       
                       if min(elev) < minmaxe(1)
                          minmaxe(1) = min(elev)-1;
                       end
                       if max(elev) > minmaxe(2)
                          minmaxe(2) = myround(max(elev),5,'ceil');
                       end
                       if min(snr) < minmaxSNR(1)
                          minmaxSNR(1) = min(snr);
                       end
                       if max(snr) > minmaxSNR(2)
                          minmaxSNR(2) = max(snr);
                       end
                   end
                   
                   title(titul,'FontSize',12,'FontWeight','bold')
                   legend(INPUT.SelectedSatsString,'Location','eastoutside','FontSize',fontsize(INPUT.SelectedSats))
                   axis([minmaxe(1) minmaxe(2) minmaxSNR(1)-3 minmaxSNR(2)+3])
                   xlabel('Satellite elevation (degrees)')
                   ylabel([INPUT.CurrentSNRstr, ' (dB-Hz)'])
                   grid on
                   set(findobj('tag','SNR'),'Visible','on','Position',[330 150 700 500])
                end
             end
             
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case 3
          %%%%%%%%% SNR in skyplot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.SelectedSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                if isempty(INPUT.CurrentSNRstr)
                   errordlg('No SNR observations selected. Please select SNR option panel.','Satellite selection interruption')
                else
                   set(gcf,'Name','SNR skyplot') 
                   switch(INPUT.GNSS)
                       case 1
                         titul = 'GPS signal to noise ratio skyplot';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,INPUT.CurrentSNRstr), zeros(1,8)]);
                       case 2 
                         titul = 'Galileo signal to noise ratio skyplot';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,INPUT.CurrentSNRstr), zeros(1,8)]);
                   end
                   
                   % Plot content of graph
                   skyplot_base([0.0 0.0 0.95 1]) % Plot skeleton of skyplot
                   X = []; Y = []; xt = []; yt = []; snr = [];
                   for i = 1:length(INPUT.SelectedSats)
                       sat = INPUT.ObsPosCurrent{i};
                       elev = sat(end-1,:);
                       azi  = sat(end,:);
                       snr_sat = sat(SNR_index,:);

                       x = (90 - elev).*sind(azi);
                       y = (90 - elev).*cosd(azi);
                       X = [X x]; xt = [xt x(end)];
                       Y = [Y y]; yt = [yt y(end)];
                       snr = [snr snr_sat];
                   end

                   scatter(X,Y,30,snr,'o','filled')
                   text(0,112,[titul, ' (', INPUT.CurrentSNRstr, ')'],'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
                   set(gca,'dataaspectratio',[1 1 1])
                   colormap jet
                   colorbar
                   pos = [0.90,0.23,0.03,0.60];
                   set(findobj(gcf,'Tag','Colorbar'),'Position',pos)
                   text(123,89,'SNR (dB-Hz)','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontweight','bold')
                   set(findobj('tag','SNR'),'Visible','on')
                end
             end
             
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case 4
          %%%%%%%%% RMS SNR (interpolated) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if isempty(INPUT.SelectedSats)
                errordlg('No satellites selected. Please select satellites in Satellites selection panel. If you want select all satellites of constellation choose manual selection option with parameter "all"','Satellite selection interruption') 
             else
                if isempty(INPUT.CurrentSNRstr)
                   errordlg('No SNR observations selected. Please select SNR option panel.','Satellite selection interruption')
                else
                   set(gcf,'Name','SNR skyplot (interpolated)') 
                   switch(INPUT.GNSS)
                       case 1
                         titul = 'Interpolated RMS of GPS SNR (';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,INPUT.CurrentSNRstr), zeros(1,8)]);
                       case 2 
                         titul = 'Interpolated RMS of Galileo SNR (';
                         SNR_index = logical([zeros(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,INPUT.CurrentSNRstr), zeros(1,8)]);
                   end
                   
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   scatter_x = [];
                   scatter_y = [];
                   scatter_RMS = [];
                   sampling = 50;
             
                   for i = 1:length(INPUT.SelectedSats)
                       sat = INPUT.ObsPosCurrent{i};
                       time = sat(8,:);
                       time = (time - time(1))*24; % time in hours
                       elev = sat(end-1,:);  % Elevation in degrees
                       azi = sat(end,:); % Azimuth in degrees
                       snr_sat = sat(SNR_index,:);
                       x = (90 - elev).*sind(azi);
                       y = (90 - elev).*cosd(azi);
                       rangeMP = length(snr_sat);
           
                       p = 1;
                       clear splitting_value
                       splitting_value(1) = 1; 
                       for j = 1:length(time)-1
                           if time(j+1) - time(j) > 0.15 %if Delta is greater than 15 minutes
                              snr_splitted{p} = snr_sat(splitting_value(p):j);
                              X{p} = x(splitting_value(p):j);
                              Y{p} = y(splitting_value(p):j);
                              p = p + 1;
                              splitting_value(p) = j + 1; 
                           end  
                           if j == length(time)-1
                              snr_splitted{p} = snr_sat(splitting_value(p):end);
                              X{p} = x(splitting_value(p):end);
                              Y{p} = y(splitting_value(p):end);
                           end
                       end
    
                       cc = 1;
                       for j = 1:length(snr_splitted)
                           for jj = sampling:sampling:length(snr_splitted{j})
                               if ~isempty(jj)
                                  subset = snr_splitted{j}(jj-sampling+1:jj);
                                  subset_X = X{j}(jj-sampling+1:jj);
                                  subset_Y = Y{j}(jj-sampling+1:jj);
               
                                  % Find intersection of three logical vectors
                                  right = not(isnan(subset)) & not(isnan(subset_X)) & not(isnan(subset_Y));
                                  subset = subset(right);
                                  subset_X = subset_X(right);
                                  subset_Y = subset_Y(right);
               
                                  if sum(right) ~= 0
                                     RMS_bin{j}(cc) = std(subset,1);
                                     Mean_X{j}(cc) = mean(subset_X);
                                     Mean_Y{j}(cc) = mean(subset_Y);
                                     cc = cc + 1;
                                  end
                               end
                           end
                           cc = 1;
                       end
                 
                       if exist('RMS_bin')
                          for j = 1:length(RMS_bin)
                              scatter_RMS = [scatter_RMS, RMS_bin{j}];
                              scatter_x = [scatter_x, Mean_X{j}];
                              scatter_y = [scatter_y, Mean_Y{j}];
                          end
                       else
                          continue
                       end
                   end
             
                   if exist('RMS_bin')
                      newplot % Prepares axes at current active figure
                      hold on

                      set(gca,'dataaspectratio',[1 1 1],'plotboxaspectratiomode','auto')
                      set(gca,'xlim',[-115 115])
                      set(gca,'ylim',[-115 120])
                      set(gca,'Units','normalized','Position',[0.0 0.0 0.95 1]) % Create axis tight to figure

                      % Define a circle and radial circles at 60, 30 and 0 degrees
                      th = 0:pi/100:2*pi;
                      xunit = cos(th);
                      yunit = sin(th);
   
                      patch('xdata',95*xunit,'ydata',95*yunit,'facecolor',[1 1 1],'handlevisibility','off','linestyle','-');

             
                      % Find redundant couples in scatter_x & scatter_y
                      [~,unique_index] = unique(scatter_x + sqrt(-1)*scatter_y);
                      [XX,YY] = meshgrid(unique(scatter_x(unique_index)),unique(scatter_y(unique_index)));
                      ZZ = griddata(scatter_x(unique_index),scatter_y(unique_index),scatter_RMS(unique_index),XX,YY);
             
                      % Cutting invisible hat from data
                      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                      deg = pi/180;
                      DELTA = (0:1:359)*deg;
                      R = 6378137;
                      [phi0,~,h0] = ecef2geodetic(INPUT.Aproxpos(1),INPUT.Aproxpos(2),INPUT.Aproxpos(3),[R, sqrt(0.00669438002290)]);
                      lam0 = 0;
             
                      switch INPUT.GNSS
                          case 1
                              INC = 55*deg;
                              a = R + 20200000;
                          case 2              
                              INC = 56*deg;   
                              a = R + 23000000;
                      end
             
                      X_sat = a.*cos(INC).*cos(DELTA);
                      Y_sat = a.*cos(INC).*sin(DELTA);
                      Z_sat = ones(1,length(X_sat)).*a.*sin(INC);
                      [e, n, u] = ecef2lv(X_sat,Y_sat,Z_sat, phi0, lam0, h0, [R, sqrt(0.00669438002290)]);

                      zenit = 90 - atan(u./sqrt(n.^2 + e.^2))/deg;
                      azimuth = atan2(e,n)*180/pi;
                      for brr = 1:length(azimuth)
                          if azimuth(brr) < 0
                             azimuth(brr) = 360 + azimuth(brr);
                          end
                      end
             
                      x_edge = zenit.*sin(azimuth*deg);
                      y_edge = zenit.*cos(azimuth*deg);
             
                      % Slightly change boundaries
                      x_edge = x_edge*0.92;
                      y_edgee = y_edge - mean(y_edge);
                      y_edgee = y_edgee*0.92;
                      y_edge = y_edgee + mean(y_edge);
             
                      % Control if edge is not out of pre-defined area
                      for i = 1:length(y_edge)
                          if sqrt(y_edge(i)^2+x_edge(i)^2) > 95;
                             x_edge(i) = 94*sin(azimuth(i)*deg);
                             y_edge(i) = 94*cos(azimuth(i)*deg);
                          end
                      end
                      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                      
                      pcolor(XX,YY,ZZ)
                      %scatter(scatter_x,scatter_y)
                      patch('xdata',x_edge,'ydata',y_edge,'facecolor',[1 1 1],'handlevisibility','off','EdgeColor',[1 1 1]);
                      plot(90*xunit(1:49),90*yunit(1:49),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                      plot(90*xunit(51:end),90*yunit(51:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                      plot(75*xunit,75*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                      plot(60*xunit(1:47),60*yunit(1:47),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                      plot(60*xunit(53:end),60*yunit(53:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                      plot(45*xunit,45*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                      plot(30*xunit(1:44),30*yunit(1:44),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                      plot(30*xunit(55:end),30*yunit(55:end),'color',[0 0 0],'handlevisibility','off','linestyle','--');
                      plot(15*xunit,15*yunit,'color',[0 0 0],'handlevisibility','off','linestyle',':');
                      line([-95 95],[0 0],'color',[0 0 0],'linestyle','--')
                      line([0 0],[-95 27],'color',[0 0 0],'linestyle','--')
                      line([0 0],[33 57],'color',[0 0 0],'linestyle','--')
                      line([0 0],[63 87],'color',[0 0 0],'linestyle','--')
                      line([-cos(pi/6)*95 cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
                      line([cos(pi/6)*95 -cos(pi/6)*95],[-95/2 95/2],'color',[0 0 0],'linestyle',':')
                      line([-95/2 95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
                      line([95/2 -95/2],[-cos(pi/6)*95 cos(pi/6)*95],'color',[0 0 0],'linestyle',':')
                      axis off
                
                      shading flat
                      colormap jet
                      colorbar
                      pos = [0.90,0.23,0.03,0.60];
                      set(findobj(gcf,'Tag','Colorbar'),'Position',pos)
                      text(121,89,1,'RMS SNR (dB-Hz)','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontweight','bold')
                      text(0,112,1,[titul, INPUT.CurrentSNRstr, ')'],'verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'fontsize',12,'fontweight','bold')
             
                      % Add ticks to graph
                      text(2,90,5,'0°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(2,60,5,'30°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(2,30,5,'60°','verticalalignment','middle','horizontalalignment','center','BackgroundColor','none','handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(0,101,1,'North','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(0,-101,1,'South','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(105,0,1,'East','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(-105,0,1,'West','verticalalignment','middle','horizontalalignment','center','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(100/2,sqrt(3)*100/2,1,'30°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(-95/2,sqrt(3)*100/2,1,'330°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(sqrt(3)*100/2,100/2,1,'60°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(-sqrt(3)*98/2,100/2,1,'300°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(95/2,-sqrt(3)*102/2,1,'150°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(-92/2,-sqrt(3)*102/2,1,'210°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(-sqrt(3)*98/2,-105/2,1,'240°','verticalalignment','middle','horizontalalignment','right','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                      text(sqrt(3)*98/2,-105/2,1,'120°','verticalalignment','middle','horizontalalignment','left','BackgroundColor',[0.85 0.85 1],'handlevisibility','off','fontsize',10,'fontweight','bold')
                   end
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end
             end
             set(findobj('tag','SNR'),'Visible','on')
      end
      end
      guidata(fig,INPUT)
      set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
      if length(get(findobj('tag','statusbar'),'String')) >= 130
         set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
      else
         set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
      end   
end

function ExportSNR_Callback(fig,INPUT)
    INPUT = guidata(fig);
    if INPUT.ComputedPositions == 0
       errordlg('No data to export. Please choose observation and ephemeris files and the compute positions.','No data interruption')
    else
       if ismember('G',INPUT.ObsFileGNSSTypes)
          help = INPUT.ObsPosBoth.G;
          sat_snr_index = logical([ones(1,8), find_snr_indices(INPUT.ObsTypesAllString.G,'S'), ones(1,8)]);
          for t = 1:length(help)
              OUTPUT.SNR.G{t} = help{t}(sat_snr_index,:);
          end
       end
    
       if ismember('E',INPUT.ObsFileGNSSTypes)
          help = INPUT.ObsPosBoth.E;
          sat_snr_index = logical([ones(1,8), find_snr_indices(INPUT.ObsTypesAllString.E,'S'), ones(1,8)]);
          for t = 1:length(help)
              OUTPUT.SNR.E{t} = help{t}(sat_snr_index,:);
          end
       end
    
       [name, path] = uiputfile('SNR_output.mat','Save SNR in *mat');
                     
       if ischar(path) && ischar(name)
          save([path name],'OUTPUT') 
       end
    end
    guidata(fig,INPUT)
end

function CA_Callback(fig,INPUT)
    INPUT = guidata(fig);
    %save('INPUTlong.mat','INPUT')
    sel = questdlg('All unsaved data and temporary variables will be removed. Do you wish to continue?','Remove temporary variables','Yes','No','Yes'); 
    switch sel 
        case 'Yes'
           set(findobj('tag','popupGNSS'),'Value',1)
           set(findobj('tag','popupGNSS'),'String','       ---')
           set(findobj('tag','popupSat'),'Value',1)
           set(findobj('tag','popupSat'),'String','       ---')
           set(findobj('tag','popupCode'),'Value',1)
           set(findobj('tag','popupCode'),'String','       ---')
           set(findobj('tag','popupPhase1'),'Value',1)
           set(findobj('tag','popupPhase1'),'String','       ---')
           set(findobj('tag','popupPhase2'),'Value',1)
           set(findobj('tag','popupPhase2'),'String','       ---')
           set(findobj('tag','popupSNR'),'Value',1)
           set(findobj('tag','popupSNR'),'String','      ---')
           set(findobj('tag','popupFlyBy'),'Value',1)
           set(findobj('tag','popupFlyBy'),'String','                          ---')
           set(findobj('tag','popupFlyBy'),'Enable','off')
           set(findobj('tag','DFsats'),'String','SVN in format: 1,2,3 ...')
           set(findobj('tag','GNSStext'),'String','Selected GNSS constellation:  ---')
           set(findobj('tag','LoadObsStatus'),'String','Loaded file: ---')
           set(findobj('tag','LoadEphStatus'),'String','Loaded file: ---')

           clear INPUT
           INPUT = guihandles(fig);
           INPUT.ObsFileStatus = 0;      % Status of loading observation file
           INPUT.EphFileStatus = 0;      % Status of loading ephemeris file
           INPUT.GNSS = [];              % Initialization of GNSS choice
           INPUT.ObsFileName = [];       % Initialization of observation filename variable
           INPUT.EphFileName = [];       % Initialization of ephemeris filename variable
           INPUT.CurrentSats = [];
           INPUT.EphFilePositions.G = 0; % Initialization for cases if no ephemeris or no observation are available from input files
           INPUT.EphFilePositions.E = 0; % (in loading files there are conditions with these values, so they must be initialized)
           INPUT.ObsFileObservations.G = 0;
           INPUT.ObsFileObservations.E = 0;
           INPUT.ObsPosCurrent{1} = [];
           INPUT.CSdetector.New = 'XX';
           INPUT.CSdetector.Old = 'XX';
           INPUT.CurrentCode = [];
           INPUT.CurrentPhase1 = [];
           INPUT.CurrentPhase2 = [];
           INPUT.Multipath.E.Selection = 0;
           INPUT.Multipath.G.Selection = 0;
           INPUT.Multipath.FType = 1;
           INPUT.ComputedPositions = 0;

           % Initialize of statusbar
           INPUT.StatusBar.GNSS = 'GNSS: --- || ';
           INPUT.StatusBar.Sats = 'Satellite(s): --- || ';
           INPUT.StatusBar.Code = 'MP code: --- || ';
           INPUT.StatusBar.Phase1 = 'MP phases: --- , ';
           INPUT.StatusBar.Phase2 = '--- || ';
        case 'No'
           return 
    end
    
    guidata(fig,INPUT)
    set(findobj('tag','statusbar'),'String',[INPUT.StatusBar.GNSS, INPUT.StatusBar.Sats, INPUT.StatusBar.Code, INPUT.StatusBar.Phase1, INPUT.StatusBar.Phase2])
    if length(get(findobj('tag','statusbar'),'String')) >= 130
       set(findobj('tag','statusbar'),'Position',[0 0 1 .050])
    else
       set(findobj('tag','statusbar'),'Position',[0 0 1 .025]) 
    end
end

function my_close(fig,INPUT)
    selection = questdlg('Do you really want to quit program? Are you sure you have saved all computed values?','Exit program','Yes','No','Yes'); 
    switch selection 
        case 'Yes'
           delete(gcf)
        case 'No'
           return 
    end
end

function SaveINPUT_Callback(fig,INPUT)
    INPUT = guidata(fig);
    if INPUT.ComputedPositions == 0
       errordlg('No data to export. Please choose observation and ephemeris files and the compute positions.','No data interruption')
    else
       [name, path] = uiputfile('SNR_output.mat','Save SNR in *mat');      
       if ischar(path) && ischar(name)
          save([path name],'INPUT') 
       end
    end
    guidata(fig,INPUT)
end

end % Ends main function MultipathAnalysis