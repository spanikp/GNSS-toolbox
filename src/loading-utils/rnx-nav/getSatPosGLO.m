function pos = getSatPosGLO(GLOtime,eph)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute position of GLONASS satellites using set of broadcast
% parameters using Runge-Kutta integration method of 4-th order. Both
% direction of computation are implemented - forward and backward. It is
% recommended by GLONASS ICD document to perform integration only in 15
% minutes interval, so select eph block of ephemeris carefully.
%
% Input:  GLOtime - [n x 2] matrix with fields [GLO week, GLO second-of-week]
%                 - time have to be expressed in UTC to be consistent with
%                   values from broadcast ephemeris !!!
%                 - before putting values into function correct time from
%                   observation RINEX (usually GPST) with appropriate
%                   number of leap seconds to get UTC time
%
%         eph     - [26 x 1] matrix of GLONASS ephemeris loaded by 
%
% Output: pos     - [3 x n] matrix of GLONASS satellite positions in PZ-90
%                   ECEC frame for given UTC moments in GLOtime. First row
%                   are X-coordinates, 2nd row is Y and 3rd is Z (all in m).
%
%
% Peter Spanik, 18.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize output
pos = zeros(3,size(GLOtime,1));

% Time step of Runge-Kutta integration method
step_RK = 1; 

% Loading constants for GLONASS system
const = getBroadcastConstants('R');

% Assigning eph values to variables
ymd  = eph(1:3)';    % Year-Month-Day vector
intday0 = eph(3);     % Starting day of integration
te   = eph(8);       % Time of ephemeris -> UTC second of the week
tff  = GLOtime(:,2); % Select only seconds of week
mTimee = eph(11);

% Broadcast position, velocity, lunisolar accelerations (in m, m/s, m/s2)
Xe   = eph(15)*1000;
Ye   = eph(19)*1000;
Ze   = eph(23)*1000;
re   = [Xe; Ye; Ze];

VXe  = eph(16)*1000;
VYe  = eph(20)*1000;
VZe  = eph(24)*1000;
ve   = [VXe; VYe; VZe];

AXe  = eph(17)*1000;
AYe  = eph(21)*1000;
AZe  = eph(25)*1000;
ae   = [AXe; AYe; AZe];

% Computation of Greenwich sidereal time in te epoch (reference epoch of ephemeris in UTC time scale)
ThetaG0 = getGMST(ymd);
ThetaGe = ThetaG0 + const.wE*rem(te,86400);
         
% Rotation matrix from Terestrial PZ-90 frame to inertial frame
R_ThetaGe = [cos(ThetaGe), -sin(ThetaGe), 0;
             sin(ThetaGe),  cos(ThetaGe), 0;
                        0,             0, 1];
                    
% State vector transformation to inertial system           
ra = R_ThetaGe*re; % position
va = R_ThetaGe*ve + const.wE*[-ra(2); ra(1); 0]; % velocity

% Switch processing into two part in case the data requires it
selDirections = [tff >= te, tff < te];

for processingParts = 1:2
    
    tf = tff(selDirections(:,processingParts));
    %mt = mTime(selDirections(:,processingParts));
    
    % Check if tf is non-empty
    if isempty(tf)
        continue;
    end
    
    % Time variable in loop, initialized with time of ephemeris (starting point
    % of forward or backward integration)
    ti = te;
    mti = mTimee;
    
    % Initial state of satellite position and velocity
    initialState = [ra; va];
    lengthIntegration = ceil((max(abs(te - [min(tf), max(tf)])) + 1)/step_RK);
    int_val = zeros(3,lengthIntegration);
    R_ThetaGi = R_ThetaGe;
    
    
    % Determine direction of integration
    if tf(end) > te
        processDirection = 1;  % Forward integration
        endOfIntegration = tf(end);
        intTimes = te:step_RK:tf(end);
        i = 1;
    else
        processDirection = -1; % Backward integration
        endOfIntegration = tf(1);
        intTimes = tf(1):step_RK:te;
        i = lengthIntegration;
    end
    
    % Performe Runge-Kutta numerical integration (forward/backward possible)
    while true
        
        % Integrated position transformed from inertial back to ECEF system
        int_val(:,i) = R_ThetaGi'*initialState(1:3);
        
        % Acceleration in inertial frame (due to lunar and solar gravity)
        aa = R_ThetaGi*ae; % J_xa_m + J_xa_s
                           % J_ya_m + J_ya_s
                           % J_za_m + J_za_s
        
        % Derivative computation k1 - k4
        k1 = getStateDerivation(const,initialState,aa);
        temp = initialState + processDirection*k1*(step_RK/2);
        
        k2 = getStateDerivation(const,temp,aa);
        temp = initialState + processDirection*k2*(step_RK/2);
        
        k3 = getStateDerivation(const,temp,aa);
        temp = initialState + processDirection*k3*step_RK;
        
        k4 = getStateDerivation(const,temp,aa);
        initialState = initialState + processDirection*step_RK*(k1 + 2*(k2 + k3) + k4)/6;
        
        % Make time and index step (forward or backward)
        ti = ti + processDirection*step_RK;
        mti = mti + (processDirection*step_RK)/86400;
        i = i + processDirection;
        
        % Compute new rotation matrix for updated time ti
        ymd = [year(mti), month(mti), day(mti)];
        ThetaG0 = getGMST(ymd);
        ThetaGi   = ThetaG0 + const.wE*rem(ti,86400);
        R_ThetaGi = [cos(ThetaGi), -sin(ThetaGi), 0;
                     sin(ThetaGi),  cos(ThetaGi), 0;
                                0,             0, 1];
        
        % End loop when ti reach endOfIntegration (index 1 or end, depend on processDirection)
        switch processDirection
            case 1
                if ti > endOfIntegration
                    break;
                end
            case -1
                if ti < endOfIntegration
                    break;
                end
        end
    end
    
    % Select only values defined in tf
    [~,outIdx,~] = intersect(intTimes,tf);
    pos(:,selDirections(:,processingParts)) = int_val(:,outIdx);
    
end
