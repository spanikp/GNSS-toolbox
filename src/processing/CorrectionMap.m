classdef CorrectionMap
    properties
        gnss(1,1) char
        obsType(1,3) char   % Observation identifier (as in RINEX)
        corr(:,:) double    % Correction values in cycles
        azi(:,1) double {}  % Correction map Azimuth in degrees
        elev(:,1) double {} % Correction map Elevation in degrees
    end
    methods
        function obj = CorrectionMap(gnss,obsType,correctionMap,azimuth,elevation)
            assert(ismember(gnss,{'G','R','E','C'}),'Not allowed GNSS system "%s"!',gnss)
            assert(obsType(1)=='L','Input observation type "%s" is not a valid phase identifier!',obsType)
            assert(size(correctionMap,1)==numel(elevation),'Correction map size does not agree with input elevations!')
            assert(size(correctionMap,2)==numel(azimuth),'Correction map size does not agree with input azimuths!')
            assert(all(azimuth>=0) & all(azimuth<=360),'Input azimuth has to be between 0 - 360 degrees!')
            assert(all(elevation>=0) & all(elevation<=90),'Input elevation has to be between 0 - 90 degrees!')
            
            obj.gnss = gnss;
            obj.obsType = obsType;
            obj.corr = correctionMap;
            obj.azi = azimuth;
            obj.elev = elevation;
        end
        function corrValues = getCorrection(obj,azimuth,elevation,interpolationMethod)
            validateattributes(azimuth,{'double'},{},1)
            validateattributes(elevation,{'double'},{},2)
            if nargin < 4
                interpolationMethod = 'linear';
            end
            assert(isequal(size(azimuth),size(elevation)),'Size of azimuth(%d x %d) does not agree with size of elevation (%d x %d)!',...
                size(azimuth,1),size(azimuth,2),size(elevation,1),size(elevation,2))
            validatestring(interpolationMethod,{'linear','quadratic','cubic'});
            assert(min(obj.azi)<=min(azimuth) & max(obj.azi)>=max(azimuth),'ValidationError:QuerryPointOutOfSkyBounds',...
                'Input azimuth out of correction specified area!')
            assert(min(obj.elev)<=min(elevation) & max(obj.elev)>=max(elevation),'ValidationError:QuerryPointOutOfSkyBounds',...
                'Input elevation out of correction specified area!')
            
            % Correction interpolation
            corrValues = interp2(obj.azi,obj.elev,obj.corr,azimuth,elevation,interpolationMethod);
        end
    end
end