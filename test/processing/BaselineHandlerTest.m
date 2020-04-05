classdef BaselineHandlerTest < matlab.unittest.TestCase
    properties
        oBase
        oRover
        bh
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../../src'));
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
    end
end