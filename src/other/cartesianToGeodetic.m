function [fi,la,h] = cartesianToGeodetic(X,Y,Z,ellipsoidData,angleUnits)
validateattributes(X,{'double'},{'size',[nan,1]},1);
validateattributes(Y,{'double'},{'size',[nan,1]},2);
validateattributes(Z,{'double'},{'size',[nan,1]},3);
validateattributes(ellipsoidData,{'double'},{'size',[1,2]},4);

if nargin < 5
    angleUnits = 'radians';
end

switch angleUnits
    case 'radians'
        isDegrees = false;
    case 'degrees'
        isDegrees = true;
    otherwise
        error('Unknown option "%s"! Only strings "radians" and "degrees" are allowed!',units);
end

% Unpack ellipsoid constants (major axis and eccentricity)
aEllipsoid = ellipsoidData(1);
eEllipsoid = ellipsoidData(2);

la = atan2(Y,X);
la(la < 0) = la(la < 0) + 2*pi;
p = sqrt(X.^2 + Y.^2);

% Get initial value of fi
fi = atan2(Z./p,1-eEllipsoid^2);
h = zeros(size(fi));

% Formula for osculating radius
N = @(a,e,phi) a./sqrt(1-(e*sin(phi)).^2);
diff_fi = 1;
diff_h = 1;

while true
    fiPrevious = fi;
    hPrevious = h;
    Ni = N(aEllipsoid,eEllipsoid,fi);
    h = p./cos(fi) - Ni;
    fi = atan2(Z./p,1-(Ni/(Ni+h))*eEllipsoid^2);
    diff_fi = max(abs(fi - fiPrevious));
    diff_h = max(abs(h - hPrevious));
    
    if diff_fi < 1.4544e-10 && diff_h < 0.001
        break
    end
end

% Conversion to degrees if required
if isDegrees
    la = rad2deg(la);
    fi = rad2deg(fi);
end
