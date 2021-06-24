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
xr = stateVector(1)/r;
yr = stateVector(2)/r;
zr = stateVector(3)/r;

% Assign derivatives
stateDer = [stateVector(4);
            stateVector(5);
            stateVector(6);
            -mur*xr + (3/2)*const.C20*mur*xr*(rho^2)*(1 - 5*zr^2) + acc(1);
            -mur*yr + (3/2)*const.C20*mur*yr*(rho^2)*(1 - 5*zr^2) + acc(2);
            -mur*zr + (3/2)*const.C20*mur*zr*(rho^2)*(3 - 5*zr^2) + acc(3)];
