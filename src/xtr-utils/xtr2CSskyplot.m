function xtr2CSskyplot(xtrFileName, saveFig, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to read Gnut-Anubis XTR output file and make skyplot graphs of
% cycle-slip distribution over the sky. Process iterates through all
% available satellite systems and make cycle-slip density plot per azimuth/
% elevation bin (3x3 degree) for all GNSS together.
%
% Input:
% xtrFileName - name of XTR file
%
% Optional:
% saveFig - true/false flag to export plots to PNG file (default: true)
% options - structure of plot settings (see getDefaultXTRoptions.m)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validateattributes(xtrFileName,{'char'},{},1)

% Default options
opt = getDefaultXTRoptions('CS');

% Check input values
if nargin == 1
   saveFig = true;
   options = opt;
   if ~ischar(xtrFileName)
      error('Inputs "xtrFileName" has to be string!') 
   end
   
elseif nargin == 2
   saveFig = logical(saveFig);
   if ~ischar(xtrFileName) || numel(saveFig) ~= 1 
       error('Inputs "xtrFileName" has to be string and "saveFig" has to be single logical value!') 
   end
   options = opt;

elseif nargin == 3
   if numel(options) ~= numel(opt)
      error('Wrong number of elements in "options" (%d elements allowed)!',numel(opt)) 
   end
else
   error('Only 1, 2 or 3 input values are allowed!') 
end

% %%%%%%% SCRIPT
% close all
% clear
% clc
% 
% funDir = strsplit(mfilename('fullpath'),'/');
% opt = struct('colorBarLimits',[],...
%              'colorBarOn',false,...
%              'figResolution','200',...
%              'figSavePath',strjoin(funDir(1:end-1),'/'),...
%              'getMaskFromData', true,...
%              'cutOffValue',0);
%          
% saveFig = true;
% options = opt;
% xtrFileName = 'example/xtr/GANP.xtr';
% %%%%%%% END OF SCRIPT

% File loading
finp = fopen(xtrFileName,'r');
raw = textscan(finp,'%s','Delimiter','\n','Whitespace','');
data = raw{1,1};

% Find empty lines in XTR file and remove them
data = data(~cellfun(@(c) isempty(c), data));

% Find indices of Main Chapters (#)
GNScell = findGNSTypes(data);

% Satellite's data loading
allGNSSSatPos.azi = [];
allGNSSSatPos.ele = [];
for i = 1:length(GNScell)
    % Find position estimate
    selpos = cellfun(@(c) strcmp(['=XYZ', GNScell{i}],c(1:7)), data);
    postext = char(data(selpos));
    pos = str2num(postext(30:76));
    
    % Elevation loading
    selELE_GNS = cellfun(@(c) strcmp([GNScell{i}, 'ELE'],c(2:7)), data);
    dataCell = data(selELE_GNS);
    [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell);
    ELE.(GNScell{i}).time = timeStamp;
    ELE.(GNScell{i}).meanVals = meanVal;
    ELE.(GNScell{i}).vals = dataMatrix;
    sel1 = ~isnan(dataMatrix);
    
    % Azimuth loading
    selAZI_GNS = cellfun(@(c) strcmp([GNScell{i}, 'AZI'],c(2:7)), data);
    dataCell = data(selAZI_GNS);
    [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell);
    AZI.(GNScell{i}).time = timeStamp;
    AZI.(GNScell{i}).meanVals = meanVal;
    AZI.(GNScell{i}).vals = dataMatrix;
    sel2 = ~isnan(dataMatrix);
    
    % Check ELE and AZI size
    if size(sel1) == size(sel2)
       % Get timestamps
       if all(ELE.(GNScell{i}).time == AZI.(GNScell{i}).time)
          timeStampsUni = timeStamp;
       end
    else
       error('Reading ELE and AZI failed, not equal number of ELE and AZI epochs!')
    end
    
    % Multipath loading
    selCS_GNS = cellfun(@(c) strcmp([' ', GNScell{i}, 'SLP'], c(1:7)), data);
    if nnz(selCS_GNS) == 0
        warning('For %s system cycle-slip information is missing - no cycle slip occurs!',GNScell{i})
        continue
    end
    dataCell = data(selCS_GNS);
    [~, ~, CS.(GNScell{i})] = dataCell2CSmatrix(dataCell);
    
    % Add satellites position to all GNSS positions
    allGNSSSatPos.azi = [allGNSSSatPos.azi; AZI.(GNScell{i}).vals];
    allGNSSSatPos.ele = [allGNSSSatPos.ele; ELE.(GNScell{i}).vals];
end

% Check if SNR struct exist (if not then input file not contain required data)
if ~exist('CS','var')
    error('Input XTR file "%s" does not contain Cycleslip information!');
end

allGNSSSatPos.azi = allGNSSSatPos.azi(:);
allGNSSSatPos.ele = allGNSSSatPos.ele(:);
selNotNan = ~isnan(allGNSSSatPos.azi) & ~isnan(allGNSSSatPos.ele);
allGNSSSatPos.azi = allGNSSSatPos.azi(selNotNan);
allGNSSSatPos.ele = allGNSSSatPos.ele(selNotNan);

% Interpolate position of CS event
allSlips = [];
for i = 1:numel(GNScell)
    CycleSlip.(GNScell{i}) = [];
    for prn = 1:32
        if ~isempty(CS.(GNScell{i}){prn})
            % Get the data from cells
            wantedTime = CS.(GNScell{i}){prn}(:);
            givenTime  = AZI.(GNScell{i}).time;
            givenAzi   = AZI.(GNScell{i}).vals(:,prn);
            givenEle   = ELE.(GNScell{i}).vals(:,prn);
            
            % Interpolation
            wantedAzi = interp1(givenTime,givenAzi,wantedTime,'Linear');
            wantedEle = interp1(givenTime,givenEle,wantedTime,'Linear');
            
            % Not select nan values
            selNotNan = ~isnan(wantedAzi) & ~isnan(wantedEle);
            wantedAzi = wantedAzi(selNotNan);
            wantedEle = wantedEle(selNotNan);
            
            % Paste to output
            CycleSlip.(GNScell{i}) = [CycleSlip.(GNScell{i}); [wantedAzi, wantedEle]];
            
        end
    end
    allSlips = [allSlips; CycleSlip.(GNScell{i})];
end

% Get unique values
allSlips = unique(allSlips,'rows');
%totalNumberOfCS = size(allSlips,1);

% Count cycle-slips in bins, set colorbar limits if not set
binSize = [3,3];
aziBins = 0:binSize(1):360;
eleBins = 0:binSize(2):90;
[N,~,~] = histcounts2(allSlips(:,1),allSlips(:,2),aziBins,eleBins);
N = N';
maxSlipsInBin = max(max(N));
if isempty(options.colorBarLimits)
    options.colorBarLimits = [0, maxSlipsInBin];
end

% Kernel smoothing (empirical parameter)
empParam = 0.685;
try
    % Require Matlab image processing toolbox
    gaussKernel = fspecial('gaussian',binSize+[1,1],1.5);
catch
    gaussKernel = gaussian(binSize(1)+1,binSize(2)+1,1.5);
end
Nsmt = conv2(N,gaussKernel,'same');
Nsmt = empParam^2*conv2(Nsmt,ones(binSize+[1,1]),'same');
%maxSlipsInBinSmt = max(max(Nsmt));

% % Figure: Position of cycle-slips
% figure('Position',[0 200, 1200 400])
% subplot(1,2,1)
% plot(allSlips(:,1),allSlips(:,2),'.')
% axis([0 360 0 90])
% grid on;
% set(gca,'xtick',aziBins,'ytick',eleBins)
% 
% subplot(1,2,2)
% imagesc(flipud(Nsmt));
% colormap(flipud(hot))
% c = colorbar;
% c.Limits = [0 14];
% caxis(c.Limits)
% grid on; box on;
% set(gca,'xtick',0.5:1:size(Nsmt,2)+0.5,'XTickLabel',strsplit(num2str(aziBins),' '))
% set(gca,'ytick',0.5:1:size(Nsmt,1)+0.5,'YTickLabel',strsplit(num2str(fliplr(eleBins)),' '))

% Check for useDataMasking settings
if options.getMaskFromData
    visibleBins = getVisibilityMask(allGNSSSatPos.azi,allGNSSSatPos.ele,[3, 3],options.cutOffValue);
    Nsmt(~visibleBins(1:end-1,1:end-1)) = 0;
end

% Determine noSatZone bins
[azig, eleg] = meshgrid(aziBins, eleBins);
[x_edge,y_edge] = getNoSatZone('GPS',pos);
xq = (90 - eleg).*sind(azig);
yq = (90 - eleg).*cosd(azig);
in = inpolygon(xq,yq,x_edge,y_edge);
Nsmt(in(2:end,2:end)) = 0;

% Drawing skyplot
figure('Position',[300 100 700 480],'NumberTitle', 'off','Resize','off')
polarplot3d(flipud(Nsmt),'PlotType','surfn','RadialRange',[0 90],'PolarGrid',{6,12},...
                         'GridStyle',':','AxisLocation','surf');
view(90,-90)

% Set colormap and colorbar
colormap(flipud(hot))
if options.colorBarOn
    c = colorbar;
    c.Limits = options.colorBarLimits;
    c.Ticks = options.colorBarTicks;
    c.Position = [c.Position(1)*1.02, c.Position(2)*1.4, 0.8*c.Position(3), c.Position(4)*0.9];
    c.TickDirection = 'in';
    c.LineWidth = 1.1;
    c.FontSize = 10;
    caxis(options.colorBarLimits)
    ylabel(c,'Number of cycle-slips per bin','fontsize',10,'fontname','arial')
else
    caxis(options.colorBarLimits)
end

axis equal
axis tight
axis off
hold on
text(60,0,-100,'30','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')
text(30,0,-100,'60','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')

% Exporting figure
if saveFig == true
    [~, fileName, ~] = fileparts(xtrFileName);
    figName = fullfile(options.figSavePath, [fileName '_allGNSS_cycle-slips']);
    print(figName,'-dpng',sprintf('-r%s',options.figResolution))
end