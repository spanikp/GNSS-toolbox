classdef TestSatelliteInfo < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../src'))
        end
    end
    methods (Test)
        function testTestSatelliteInfoConstructor(obj)
            satInfo = SatelliteInfo();
            obj.verifyClass(satInfo,'SatelliteInfo');
        end
        function testTestSatelliteInfoGetBlockNumber(obj)
            satInfo = SatelliteInfo();
            gpsPRN1satBlockNo = satInfo.getSatelliteBlock(1,'G',datetime(2020,1,15));
            obj.verifyEqual(gpsPRN1satBlockNo,8);
        end
    end
end
