classdef getEphReferenceEpochTest < matlab.unittest.TestCase
    properties
        t = (datenum(2020,1,1,1,0,0):(900/86400):datenum(2020,1,1,5,0,0))';
        tEph = [datenum(2020,1,1,2,0,0);datenum(2020,1,1,4,0,0)];
    end
    methods (TestClassSetup)
        function setupPath(obj)
            addpath(genpath('../../../src'));
        end
    end
    methods (Test)
        function test_forward(obj)
            [ephAge,ephIdx] = getEphReferenceEpoch('G',obj.t,obj.tEph,3/24,'forward');
            obj.assertEqual(ephAge*86400,[nan(4,1);(0:900:6300)';(0:900:3600)'],'absTol',1e-4);
            obj.assertEqual(ephIdx,[nan(4,1);ones(8,1);2*ones(5,1)]);
        end
        function test_backward(obj)
            [ephAge,ephIdx] = getEphReferenceEpoch('G',obj.t,obj.tEph,3/24,'backward');
            obj.assertEqual(ephAge*86400,[(-3600:900:0)';(-6300:900:0)';nan(4,1)],'absTol',1e-4);
            obj.assertEqual(ephIdx,[ones(5,1);2*ones(8,1);nan(4,1)]);
        end
        function test_both(obj)
            [ephAge,ephIdx] = getEphReferenceEpoch('G',obj.t,obj.tEph,3/24,'closest');
            obj.assertEqual(ephAge*86400,[(-3600:900:0)';(900:900:3600)';(-2700:900:3600)'],'absTol',1e-4);
            obj.assertEqual(ephIdx,[ones(9,1);2*ones(8,1)]);
        end
    end
end