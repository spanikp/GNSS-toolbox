function [de,dn,du] = cartesianToLocalVertical(X,Y,Z,fi0,la0,h0,ellipsoidData,angleUnits)
validateattributes(X,{'double'},{'size',[nan,1]},1);
validateattributes(Y,{'double'},{'size',[nan,1]},2);
validateattributes(Z,{'double'},{'size',[nan,1]},3);
validateattributes(fi0,{'double'},{'size',[1,1]},4);
validateattributes(la0,{'double'},{'size',[1,1]},5);
validateattributes(h0,{'double'},{'size',[1,1]},6);
validateattributes(ellipsoidData,{'double'},{'size',[1,2]},4);

if nargin < 8
    angleUnits = 'degrees';
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

if isDegrees
    fi0 = deg2rad(fi0);
    la0 = deg2rad(la0);
end
N0 = aEllipsoid/sqrt(1-(eEllipsoid*sin(fi0)).^2);
X0 = (N0 + h0)*cos(fi0)*cos(la0);
Y0 = (N0 + h0)*cos(fi0)*sin(la0);
Z0 = ((1-eEllipsoid^2)*N0 + h0)*sin(fi0);

% Definition of rotation to local system
R(1,:) = [         -sin(la0),               cos(la0),              0];
R(2,:) = [-cos(la0)*sin(fi0),     -sin(la0)*sin(fi0),       cos(fi0)];
R(3,:) = [ cos(la0)*cos(fi0),      sin(la0)*cos(fi0),       sin(fi0)];

for i = 1:length(X)
    dXYZ = [X(i);Y(i);Z(i)] - [X0;Y0;Z0];
    dENU(:,i) = R*dXYZ;
end
dENU = dENU';

de = dENU(:,1);
dn = dENU(:,2);
du = dENU(:,3);

