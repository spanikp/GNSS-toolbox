classdef BaselineHandlerTest < matlab.unittest.TestCase
    properties
        oBase
        oRover
        bh
    end
    properties (TestParameter)
        ts = {...
            {'G', 6,'C1C',  1, 25083226.133,' 6'};...
        };
        gnss = {'G','R','E','C'};
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
		    
        end
    end
end