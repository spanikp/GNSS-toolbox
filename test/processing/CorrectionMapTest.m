classdef CorrectionMapTest < matlab.unittest.TestCase
    properties
        corrMap
    end
    properties (TestParameter)
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'));
            azi = (0:1:360)';
            elev = (0:1:90)';
            c = repmat(flipud(elev),[1 numel(azi)]);
            obj.corrMap = CorrectionMap('G','L1C',c,azi,elev);
        end
    end
    methods (Test)
        function testConstructor(obj)
            obj.verifyEqual(obj.corrMap.gnss,'G')
            obj.verifyEqual(obj.corrMap.obsType,'L1C')
		    obj.verifyEqual(obj.corrMap.elev,(0:1:90)')
            obj.verifyEqual(obj.corrMap.azi,(0:1:360)')
        end
        function testGetCorrectionOutOfSkyBounds(obj)
            querryOutOfSkyBounds = [...
                1.4, -0.1;
                1.5, 90.1;
                -0.1, 13;
                360.1, 13;
                -0.1, -0.1
            ];
            for i = 1:size(querryOutOfSkyBounds,1)
                a = querryOutOfSkyBounds(i,1);
                e = querryOutOfSkyBounds(i,2);
                obj.verifyError(@() obj.corrMap.getCorrection(a,e),'ValidationError:QuerryPointOutOfSkyBounds')
            end
        end
        function testGetCorrection(obj)
            elev = 0*ones(10,1);
            azi = linspace(10,20,10)';
            corrVals = obj.corrMap.getCorrection(azi,elev);
            obj.verifyEqual(corrVals,90*ones(10,1))    
        end
        function testPlot(obj)
            f1 = obj.corrMap.plot();
            close(f1);
            f2 = obj.corrMap.plot('regular');
            close(f2);
        end
    end
end