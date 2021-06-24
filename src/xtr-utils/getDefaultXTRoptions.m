function opt = getDefaultXTRoptions(plotType)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to provide default properties for MATLAB XTR plots
%
% Optional:
% plotType - one of 'MP', 'SNR' or 'CS'
%
% Output:
% opt - structure with the following plotting settings:
%      colorBarLimits - 1x2 array to set colorbar range
%      colorBarTicks - 1xn array of colorbar ticks
%      colorBarOn - set visibility of colorbar (default: true)
%      figResolution - resolution of output image (default 200)
%      figSavePath - path to current location of this function
%      getMaskFromData - derive terrain mask from available data
%      cutOffValue - set value of elevation cutoff on skyplots
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get default plot type
if nargin == 0
    plotType = 'MP';
end

% Validation
validateattributes(plotType,{'char'},{},1)
assert(ismember(plotType,{'MP','SNR','CS'}),'Input "plotType" has to be one of: MP, SNR, CS!');

% General options
opt = struct(...
    'colorBarLimits',[0, 120],...
	'colorBarTicks', 0:20:120,...
	'colorBarOn',true,...
	'figResolution','200',...
	'figSavePath',pwd(),...
	'getMaskFromData', true,...
	'cutOffValue',0);

% Option specific for MP/SNR/CS
switch plotType
    case 'SNR'
    	opt.colorBarLimits = [15,55];
        opt.colorBarTicks = 15:5:55;
    case 'CS'
        opt.colorBarLimits = [];
        opt.colorBarTicks = 0:2:10;
end

