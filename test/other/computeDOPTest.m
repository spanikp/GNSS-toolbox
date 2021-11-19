classdef computeDOPTest < matlab.unittest.TestCase
    properties
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'))
        end
    end
    methods (Test)
        function test_computeDOP(obj)
            recPos = [4.066576555345881,1.321310819070842,4.717024959080501]*1e6;
            res = computeDOP('xyz.csv',recPos);
            writetable(res,'xyz_dop.csv','Delimiter',',');
        end
    end
end