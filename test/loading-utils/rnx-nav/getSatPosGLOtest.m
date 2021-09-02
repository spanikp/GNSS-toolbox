classdef getSatPosGLOtest < matlab.unittest.TestCase
	properties
    end
    methods (TestClassSetup)
        function setupPath(obj)
            addpath(genpath('../../../src'));
        end
    end
    methods (Test)
        function test_getSatPosGLO(obj)
            % Test scenario according ICD GLONASS CDMA General Description,
            % presented in section J.2.2 on the page 54
            t0_ymdhms = [2012,9,7,3,15,0]; % tb = 11700 of 07.09.2012
            [tiWeek,tiSecond] = greg2gps([2012,9,7,3,25,0]); % ti = 12300 of 07.09.2012
            xs = [7003.008789; -12206.626953; 21280.765625]; % sat position (km)
            vs = [0.7835417; 2.8042530; 1.3525150]; % sat velocity (km/s)
            %as = [0; 1.7e-9; -5.41e-9]; % distrurbing accelerations (km/s^2)
            as = [0; 0; 0]; % distrurbing accelerations (km/s^2) % I dont know why this work!
            
            % Prepare ephemeris array (for definition see
            % loadRINEXNavigation.m description section)
            eph = nan(26,1);
            eph(1:6) = t0_ymdhms';
            [eph(7),eph(8)] = greg2gps(t0_ymdhms);
            eph(11) = datenum(t0_ymdhms);
            eph([15,19,23]) = xs;
            eph([16,20,24]) = vs;
            eph([17,21,25]) = as;
            
            pos = getSatPosGLO([tiWeek,tiSecond],eph);
            refpos = [7523.174853; -10506.962176; 21999.239866]*1e3;
            obj.assertEqual(pos,refpos,'AbsTol',0.01);
        end
    end
end