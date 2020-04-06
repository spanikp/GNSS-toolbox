classdef BaselineHandlerTest < matlab.unittest.TestCase
    properties
        oBase
        oRover
        bh
    end
    properties (TestParameter)
        ts = {...
            {1,10,{'L1C'}, 106377941.101, 128712465.729, 106377734.694, 128711924.194};... %epoch,slaveSat,obsType,baseRef,baseSlave,roverRef,roverSlave
            {1,10,{'L2W'},  82891926.559, 100295458.132,  82891788.043, 100295081.531};...
            {1, 6,{'L1C'}, 106377941.101, 131813231.844, 106377734.694, 131813681.019};...
            {1, 6,{'L2W'},  82891926.559,           nan,  82891788.043, 102711948.435};...
            {1, 6,{'L2W','L1C'}, [82891926.559,106377941.101], [nan,131813231.844], [82891788.043,106377734.694], [102711948.435,131813681.019]};...
        }
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'));
            obj.oBase = OBSRNX('../data/base080G_30s_15min.19o');
            obj.oBase = obj.oBase.computeSatPosition('broadcast','../data/brdc');
            obj.oRover = OBSRNX('../data/rover080G_30s_15min.19o');
            obj.oRover = obj.oRover.computeSatPosition('broadcast','../data/brdc');
            obj.bh = BaselineHandler([obj.oBase; obj.oRover],'G');
        end
    end
    methods (Test)
        function testConstructorFail(obj)
            o1 = OBSRNX('../data/base080G_30s_15min.19o');
            o2 = OBSRNX('../data/rover080G_30s_15min.19o');
		    obj.verifyError(@() BaselineHandler([o1; o2],'G'),'ValidationError:NotValidObservationStruct')
        end
        function testGetDD(obj)
            epochNo = 1;
            slaveSat = 10;
            obsType = {'L1C'};
            oBaseRef = 106377941.101;
            oRoverRef = 106377734.694;
            oBaseSlave = 128712465.729;
            oRoverSlave = 128711924.194;
            
            valRef = (oRoverSlave - oBaseSlave) - (oRoverRef - oBaseRef);
            dd1 = obj.bh.getDD(obsType);
            valActualCycles = cellfun(@(x) x(epochNo,slaveSat),dd1);
            obj.verifyEqual(valActualCycles,valRef,'AbsTol',1e-7)
            
            dd2 = obj.bh.getDD(obsType,'meters');
            valActualMeters = cellfun(@(x) x(epochNo,slaveSat),dd2);
            f = cellfun(@(x) getWavelength('G',str2double(x(2))),obsType);
            obj.verifyEqual(valActualMeters,valRef.*f,'AbsTol',1e-5)
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testGetDDMoreTypes(obj,ts)
            epochNo = ts{1};
            slaveSat = ts{2};
            obsType = ts{3};
            oBaseRef = ts{4};
            oRoverRef = ts{6};
            oBaseSlave = ts{5};
            oRoverSlave = ts{7};
            
            valRef = (oRoverSlave - oBaseSlave) - (oRoverRef - oBaseRef);
            dd1 = obj.bh.getDD(obsType);
            valActualCycles = cellfun(@(x) x(epochNo,slaveSat),dd1);
            obj.verifyEqual(valActualCycles,valRef,'AbsTol',1e-7)
            
            dd2 = obj.bh.getDD(obsType,'meters');
            valActualMeters = cellfun(@(x) x(epochNo,slaveSat),dd2);
            f = cellfun(@(x) getWavelength('G',str2double(x(2))),obsType);
            obj.verifyEqual(valActualMeters,valRef.*f,'AbsTol',1e-5)
        end
    end
end