function out = xtr2SNRskyplot(xtrFileName, SNRcode, saveFig, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to read Gnut-Anubis XTR output file and make SNR skyplot graphs.
% Process iterates through all available satellite systems (it will
% detect automatically) and try to plot given SNR values.
%
% Input:
% xtrFileName - name of XTR file
% SNRcode - 2-char representation of MP code combination to plot
%        - values corresponding to RINEX v2/v3 SNR measurements
%
% Optional:
% saveFig - true/false flag to export plots to PNG file (default: true)
% options - structure of plot settings (see getDefaultXTRoptions.m)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validateattributes(xtrFileName,{'char'},{},1)

% Default options
opt = getDefaultXTRoptions('SNR');

% Check input values
if nargin == 2
   saveFig = true;
   options = opt;
   if ~ischar(xtrFileName) || ~ischar(SNRcode)
      error('Inputs "xtrFileName" and "SNRcode" have to be strings!') 
   end
   
elseif nargin == 3
    saveFig = logical(saveFig);
   if ~ischar(xtrFileName) || ~ischar(SNRcode) || numel(saveFig) ~= 1 
      error('Inputs "xtrFileName","SNRcode" have to be strings and "saveFig" has to be single value!') 
   end
   options = opt;

elseif nargin == 4
   if numel(options) ~= numel(opt)
      error('Wrong number of elements in "options" (%d elements allowed)!',numel(opt)) 
   end
else
   error('Only 2, 3 or 4 input values are allowed!') 
end

% File loading
finp = fopen(xtrFileName,'r');
raw = textscan(finp,'%s','Delimiter','\n','Whitespace','');
data = raw{1,1};

% Find empty lines in XTR file and remove them
data = data(~cellfun(@(c) isempty(c), data));

% Get from which RINEX version we create XTR file
RNXVER_line = data{cellfun(@(x) strcmp('=RNXVER',x(1:7)),data)};
RNXVER = [str2double(RNXVER_line(29)), str2double(RNXVER_line(31:32))]; % 2-element array: [MajorVersion, MinorVersion]
checkGivenObservationType(RNXVER(1),'S',SNRcode);

% Find indices of Main Chapters (#)
GNScell = findGNSTypes(data);

% Set custom colormap -> empty bin = white
myColorMap = colormap(jet); close; % Command colormap open figure!
myColorMap = [[1,1,1]; myColorMap];

% Get approximate position
approxPositionSel = cellfun(@(x) strcmp('=XYZAPR',x(1:7)),data);
if nnz(approxPositionSel) == 1
    s = data(approxPositionSel);
    approxPosition = sscanf(s{1}(30:80),'%f')';
else
    error('Cannot read approximate position from XTR file! No element "=XYZAPR", please rerun anubis with different configuration!');
end 

% Satellite's data loading
pos = struct();
allGNSSSatPos.azi = [];
allGNSSSatPos.ele = [];
for i = 1:length(GNScell)
    % Find position estimate
    selpos = cellfun(@(c) strcmp(['=XYZ', GNScell{i}],c(1:7)), data);
    if nnz(selpos) == 1
        postext = char(data(selpos));
        pos.(GNScell{i}) = str2num(postext(30:76));
    else
        pos.(GNScell{i}) = nan(1,3);
    end
    
    % Elevation loading
    selELE_GNS = cellfun(@(c) strcmp([GNScell{i}, 'ELE'],c(2:7)), data);
    dataCell = data(selELE_GNS);
    [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell);
    ELE.(GNScell{i}).time = timeStamp;
    ELE.(GNScell{i}).mean3Vals = meanVal;
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
       
       % Add satellites position to all GNSS positions
       allGNSSSatPos.azi = [allGNSSSatPos.azi; AZI.(GNScell{i}).vals];
       allGNSSSatPos.ele = [allGNSSSatPos.ele; ELE.(GNScell{i}).vals];
    else
       error('Reading ELE and AZI failed, not equal number of ELE and AZI epochs!')
    end
    
    % Multipath loading
    selSNR_GNS = cellfun(@(c) strcmp([' ', GNScell{i}, 'S', SNRcode(end-1:end)], c(1:7)), data);
    if nnz(selSNR_GNS) == 0
        warning('For %s system SNR %s not available!',GNScell{i},SNRcode)
        AZI.(GNScell{i}).vector = [];
        ELE.(GNScell{i}).vector = [];
        continue
    end
    dataCell = data(selSNR_GNS);
    [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell);
    SNR.(GNScell{i}).time = timeStamp;
    SNR.(GNScell{i}).meanVals = meanVal;
    if size(dataMatrix,1) ~= size(sel1,1)
        % Find indices logical indices of not missing values
        idxNotMissing = ismember(timeStampsUni,timeStamp);
        
        % Alocate new array of values with correct dimensions
        newdataMatrix = nan(numel(timeStampsUni),size(dataMatrix,2));
        
        % Assign not missing values from old array to new one
        newdataMatrix(idxNotMissing,:) = dataMatrix;
        dataMatrix = newdataMatrix;
    end
    
    SNR.(GNScell{i}).vals = dataMatrix;
    sel3 = ~isnan(dataMatrix);

    sel = sel1 & sel2 & sel3;
    ELE.(GNScell{i}).vector = ELE.(GNScell{i}).vals(sel);
    AZI.(GNScell{i}).vector = AZI.(GNScell{i}).vals(sel);
    SNR.(GNScell{i}).vector = SNR.(GNScell{i}).vals(sel);
end

% Put output together
out.AZI = AZI;
out.ELE = ELE;

% Check if SNR struct exist (if not then input file not contain required data)
if exist('SNR','var')
    out.SNR = SNR;
else
    error('Input XTR file "%s" does not contain SNR information for "%s" signal!',...
        xtrFileName,SNRcode);
end

allGNSSSatPos.azi = allGNSSSatPos.azi(:);
allGNSSSatPos.ele = allGNSSSatPos.ele(:);
selNotNan = ~isnan(allGNSSSatPos.azi) & ~isnan(allGNSSSatPos.ele);
allGNSSSatPos.azi = allGNSSSatPos.azi(selNotNan);
allGNSSSatPos.ele = allGNSSSatPos.ele(selNotNan);

% Loop for plotting when data are loaded
for i = 1:length(GNScell)
    % Check if data are available
    if isempty(AZI.(GNScell{i}).vector)
        continue
    end
    
    % Interpolate to regular grid
    aziBins = 0:3:360;
    eleBins = 0:3:90;
    [azig, eleg] = meshgrid(aziBins, eleBins);
    warning('off');
    F = scatteredInterpolant(AZI.(GNScell{i}).vector,ELE.(GNScell{i}).vector,SNR.(GNScell{i}).vector,'linear','none');
    warning('on');
    mpg = F(azig,eleg);
    mpg(isnan(mpg)) = -1;
    
    % Check for useDataMasking settings
    if options.getMaskFromData
        visibleBins = getVisibilityMask(allGNSSSatPos.azi,allGNSSSatPos.ele,[3, 3],options.cutOffValue);
        %visibleBins = getVisibilityMask(AZI.(GNScell{i}).vector,ELE.(GNScell{i}).vector,[3, 3],options.cutOffValue);
        mpg(~visibleBins) = -1;
    end
    
    % Determine noSatZone bins
    [x_edge,y_edge] = getNoSatZone(GNScell{i},approxPosition);
    xq = (90 - eleg).*sind(azig);
    yq = (90 - eleg).*cosd(azig);
    in = inpolygon(xq,yq,x_edge,y_edge);
    mpg(in) = -1;
    
    % Create figure
    figure('Position',[300 100 700 480],'NumberTitle', 'off','Resize','off')
    polarplot3d(flipud(mpg),'PlotType','surfn','RadialRange',[0 90],'PolarGrid',{6,12},...
                              'GridStyle',':','AxisLocation','surf','TickSpacing',15);
    view(90,-90)
    
    % Set colormap and control colorbar
    colormap(myColorMap)
    if options.colorBarOn
        c = colorbar;
        colLimits = options.colorBarLimits;
        colLimits(1) = colLimits(1) + 5;
        c.Limits = colLimits;
        c.Ticks = options.colorBarTicks;
        c.Position = [c.Position(1)*1.02, c.Position(2)*1.4, 0.8*c.Position(3), c.Position(4)*0.9];
        c.TickDirection = 'in';
        c.LineWidth = 1.1;
        c.FontSize = 10;
        caxis(options.colorBarLimits)
        ylabel(c,sprintf('Mean %s SNR %s value (dBHz)',GNScell{i},SNRcode),'fontsize',10,'fontname','arial')
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
        figName = fullfile(options.figSavePath, [fileName '_', GNScell{i}, '_SNR', SNRcode]);
        print(figName,'-dpng',sprintf('-r%s',options.figResolution))
    end
end