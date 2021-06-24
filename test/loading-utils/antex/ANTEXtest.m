classdef ANTEXtest < matlab.unittest.TestCase
    properties
        atx
    end
    properties (TestParameter)
        ts = {... %ts - test scenario
            {'G',1,[  0,  0],'PCV',  3.04*1e-3};...
            {'G',1,[ 50,  5],'PCV', -2.12*1e-3};...
            {'G',1,[ 50,  5],'PCV', -2.12*1e-3};...
            {'G',2,[2.5,  5],'PCV', mean([3.54 7.05])*1e-3};...
            {'R',1,[ 70, 10],'PCV', -0.76*1e-3};...
            {'R',2,[ 65, 55],'PCV', -2.25*1e-3};...
            {'R',2,[  0,355],'PCV',  5.79*1e-3};...
            {'R',2,[  0,357.5],'PCV', mean([5.84 5.79])*1e-3};...
        };
    end
    methods (TestClassSetup)
        function setupPath(obj)
			addpath(genpath('../../../src'));
            obj.atx = ANTEX('../../data/JABO_TRM55971.00_NONE_1440932194.atx');
        end
    end
    methods (Test)
        function testConstructor(obj)
            obj.verifyEqual(obj.atx.version,'1.3');
            obj.verifyEqual(obj.atx.antennaType,'TRM57971.00_____NONE');
            obj.verifyEqual(obj.atx.serialnumber,'1440932194');
            obj.verifyEqual(obj.atx.azi,0:5:360);
            obj.verifyEqual(obj.atx.zen,0:5:90);
        end
        function testAntennaCorrectionOutOfElevationRange(obj)
        	% When request correction out of elevation range - nan is given
            corr = obj.atx.getCorrection('G',1,[-1,15],'PCV');
            obj.verifyEqual(corr,nan)
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testLoadedValues(obj,ts)
            corr = obj.atx.getCorrection(ts{1},ts{2},ts{3},ts{4});
            obj.verifyEqual(corr,ts{5},'AbsTol',1e-5)
        end
    end
end