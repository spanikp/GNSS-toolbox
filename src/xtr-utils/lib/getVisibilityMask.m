function visMask = getVisibilityMask(azi,ele,binSize,maskValue)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function to get approximate visibility mask based on tracked satellite
% positions and binSize used for visualization. 
%
% Inputs:
% azi - array of satellite's azimuths (deg)
% ele - array of satellite's elevations (deg)
% binSize - [1x2] array of azimuthal and elevation binning (sampling of
%           meshgrid used for visualization)
% 
% Optional:
% maskValue - value of elevation mask (in deg)
%
% Output:
% visMask - [nxm] logical array, size is derived from binSize 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check for number of inputs
if nargin == 3
   maskValue = 0;
elseif nargin < 3 || nargin > 4
    error('Wrong number of inputs!');
end

% Initialize bin arrays
aziBins = 0:binSize(1):360;
eleBins = (0:binSize(2):90)';
visMask  = false(numel(eleBins),numel(aziBins));

% Looping through azimuthal bins and looking for smallest values
for i = 1:numel(aziBins)
    inAziBin = azi >= aziBins(i) & azi <= aziBins(i);
    minEle = min(ele(inAziBin));
    if isempty(minEle)
        minEle = maskValue;
    end
    inEleBin = eleBins >= minEle & eleBins > maskValue;
    visMask(:,i) = inEleBin;
end

% Filtering visibility matrix
visMaskFilt = visMask;
for i = 2:numel(aziBins)-1
    visMaskFilt(:,i) = visMask(:,i-1) | visMask(:,i) | visMask(:,i+1);
end
visMask = visMaskFilt;

% % Visually compare raw and filtered results
% figure
% subplot(1,2,1)
% imagesc(visMask)
% title('Original')
% 
% subplot(1,2,2)
% imagesc(visMaskFilt)
% title('Filtered')