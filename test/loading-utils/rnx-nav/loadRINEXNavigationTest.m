classdef loadRINEXNavigationTest < matlab.unittest.TestCase
    properties (TestParameter)
        gnss = {'G','R','E','C'};
        ext = {'n','g','l','c'};        
    end
    methods (TestClassSetup)
        function setupPath(obj)
			addpath(genpath('../../../src'));
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testLoadEphemerisFromRINEXNavMessage(obj,gnss,ext)
            ephFolder = '../../data/brdc';
            brdc = loadRINEXNavigation(gnss,ephFolder,sprintf('brdc0800.19%s',ext));
            obj.verifyEqual(brdc.gnss,gnss);
        end
	end
end