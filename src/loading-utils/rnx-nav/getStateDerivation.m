function stateDer = getStateDerivation(const, stateVector, acc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to get numeric derivative of state vector. Function simply put 
% input velocity in state vector pos_vel and compute acceleration using
% sun-moon forces (SM) and input acc vector.
%
% State vector = [  X;     Y;     Z;    vX;    vY;    vZ ]
%
%                   |      |      |      |      |      |
%                   v      v      v      v      v      v
%
% Derivative   = [ vX;    vY;    vZ;   aX+SM; aY+SM; aZ+SM ]
% 
%     where: SM - sun-moon disturbing accelerations
%            SM = function(X,Y,Z)
%
% Input:  const - [6 x 1] vector of constants with fields (wE,GM,a,C20)
%         stateVector - state vector consisting of concatenated position
%                 and velocity in inertial frame [pos; vel]
%         acc   - acceleration of disturbing luni-solar forces in inertial 
%                 frame 
%
% Output: stateDer - [6 x 1] vector of derivative of stateVector 
%
% Peter Spanik, 18.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Auxiliary variables
r2 = sum(stateVector(1:3).^2);
r = sqrt(r2);
mur = const.GM/r2;
rho = const.a/r;
we = const.wE;
x = stateVector(1);
y = stateVector(2);
z = stateVector(3);
xr = x/r;
yr = y/r;
zr = z/r;
vx = stateVector(4);
vy = stateVector(5);
vz = stateVector(6);

% Assign derivatives
stateDer = [vx;
            vy;
            vz;
            -mur*xr + (3/2)*const.C20*mur*xr*(rho^2)*(1 - 5*zr^2) + (x*we^2 + 2*we*vy) + acc(1);
            -mur*yr + (3/2)*const.C20*mur*yr*(rho^2)*(1 - 5*zr^2) + (y*we^2 - 2*we*vx) + acc(2);
            -mur*zr + (3/2)*const.C20*mur*zr*(rho^2)*(3 - 5*zr^2) + acc(3)];


