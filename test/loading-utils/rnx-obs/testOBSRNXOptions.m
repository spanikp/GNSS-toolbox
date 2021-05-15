classdef testOBSRNXOptions < matlab.unittest.TestCase
    methods (TestClassSetup)
        function obj = setupPath(obj)
			addpath(genpath('../../../src'));
        end
    end
    methods (Test)
        function testFromStruct(obj)
            s = struct('filtergnss','E','samplingDecimation',5,'parseQualityIndicator',true);
            p = OBSRNXOptions.fromStruct(s);
            obj.verifyEqual(p.filtergnss,s.filtergnss);
            obj.verifyEqual(p.samplingDecimation,s.samplingDecimation);
            obj.verifyEqual(p.parseQualityIndicator,s.parseQualityIndicator);
        end
        function testFromStructWithWarning(obj)
            s = struct('parseQualityIndicator',true,'samplingDecimation',5);
            p = OBSRNXOptions.fromStruct(s);
            obj.verifyEqual(p.samplingDecimation,s.samplingDecimation);
            obj.verifyEqual(p.parseQualityIndicator,s.parseQualityIndicator);
        end
    end
end