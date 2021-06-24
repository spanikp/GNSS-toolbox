classdef TestCoordinateConversion < matlab.unittest.TestCase
    properties
        R = 6378137
        ecc = sqrt(0.00669438002290)
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'))
        end
    end
    methods (Test)
        function testCartesianToGeodetic(obj)
            pos = [4071156.8034,1261249.1173,4729379.4099];
            
            %[fi,la,h] = ecef2geodetic(pos(1),pos(2),pos(3),[obj.R,obj.ecc]); % Matlab geodetic toolbox as reference
            %[fiD,laD,hD] = ecef2geodetic(pos(1),pos(2),pos(3),[obj.R,obj.ecc],'degrees'); % Matlab geodetic toolbox as reference
            [fi,la,h] = cartesianToGeodetic(pos(1),pos(2),pos(3),[obj.R,obj.ecc]);
            [fiD,laD,hD] = cartesianToGeodetic(pos(1),pos(2),pos(3),[obj.R,obj.ecc],'degrees');
            obj.verifyEqual(fi,deg2rad(48.166587156346012),'AbsTol',1e-7);
            obj.verifyEqual(la,deg2rad(17.213041981478732),'AbsTol',1e-7);
            obj.verifyEqual(h,1.727349057942629e+02,'AbsTol',1e-7);
            obj.verifyEqual(fiD,48.166587156346012,'AbsTol',1e-7);
            obj.verifyEqual(laD,17.213041981478732,'AbsTol',1e-7);
            obj.verifyEqual(hD,1.727349057942629e+02,'AbsTol',1e-7);

        end
        function testCartesianToLocalVertical(obj)
            posSat = [14328028.425,-3906949.120,21838721.102];
            fi0 = 48;
            la0 = 17;
            h0 = 200;
            
            %[de,dn,du] = ecef2lv(posSat(1),posSat(2),posSat(3),deg2rad(fi0),deg2rad(la0),h0,[obj.R,obj.ecc]); % Matlab geodetic toolbox as reference
            %[de,dn,du] = ecef2enu(posSat(1),posSat(2),posSat(3),fi0,la0,h0,[obj.R,obj.ecc]);
            [de,dn,du] = cartesianToLocalVertical(posSat(1),posSat(2),posSat(3),fi0,la0,h0,[obj.R,obj.ecc]);
            [de2,dn2,du2] = cartesianToLocalVertical(posSat(1),posSat(2),posSat(3),deg2rad(fi0),deg2rad(la0),h0,[obj.R,obj.ecc],'radians');
            obj.verifyEqual(de,-0.792534412069468e+07,'AbsTol',1e-4);
            obj.verifyEqual(dn,0.530056647221096e+07,'AbsTol',1e-4);
            obj.verifyEqual(du,1.826686322779114e+07,'AbsTol',1e-4);
            obj.verifyEqual(de2,-0.792534412069468e+07,'AbsTol',1e-4);
            obj.verifyEqual(dn2,0.530056647221096e+07,'AbsTol',1e-4);
            obj.verifyEqual(du2,1.826686322779114e+07,'AbsTol',1e-4);
        end
    end
end
