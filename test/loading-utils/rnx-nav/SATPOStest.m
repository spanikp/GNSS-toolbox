classdef SATPOStest < matlab.unittest.TestCase
    properties (TestParameter)
        gnss = {'G','R','E','C'};
        ephRefSats = {1,1,1,6};
        ephRefPos = {...
             [ 21205.926710  11935.849328  10843.520838]*1e3,...
             [ 15869.795086 -19561.833554  -3964.297825]*1e3,...
             [ 15082.943039  13716.981791 -21463.750213]*1e3,...
             [-23389.162333  26622.342618  22879.979580]*1e3};          
    end
    methods (TestClassSetup)
        function setupPath(obj)
			addpath(genpath('../../../src'));
        end
    end
    methods (Test)
        function testConstructorBroadcast(obj)
            ephType = 'broadcast';
            ephFolder = '../../data/brdc';
            [GPS1w,GPS1s] = greg2gps([2019,3,21,2,15,18]);
            [GPS2w,GPS2s] = greg2gps([2019,3,21,4,15,18]);
            GPSTimeFrame = [GPS1w,GPS1s; GPS2w,GPS2s];
            [gpsWeek,gpsSecond] = getGPSTimeBetween(GPSTimeFrame,1800);
            satpos = SATPOS('R',1,ephType,ephFolder,[gpsWeek,gpsSecond]);
            obj.verifyEqual(satpos.ECEF{1}(1,:),[0.159713886719e+5, -0.198657680664e+5, -0.715209960938e+3]*1e3);
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testConstructorPrecise(obj,gnss,ephRefSats,ephRefPos)
            ephType = 'precise';
            ephFolder = '../../data/eph';
            [GPS1w,GPS1s] = greg2gps([2019,3,21,2,0,0]);
            [GPS2w,GPS2s] = greg2gps([2019,3,21,4,0,0]);
            GPSTimeFrame = [GPS1w,GPS1s; GPS2w,GPS2s];
            [gpsWeek,gpsSecond] = getGPSTimeBetween(GPSTimeFrame,100);
            satpos = SATPOS(gnss,ephRefSats,ephType,ephFolder,[gpsWeek,gpsSecond]);
            obj.verifyEqual(satpos.ECEF{1}(1,:),ephRefPos);
        end
	end
end