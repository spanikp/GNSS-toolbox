classdef SNRMultipathDetectorTest < matlab.unittest.TestCase
    properties
        obsrnx
        obsrnxSatpos
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'))
            %opt = OBSRNX.getDefaults();
            %opt.filtergnss = 'G';
            %obj.obsrnx = OBSRNX('../data/JAB1080M.19o',opt);
            %obj.obsrnxSatpos = obj.obsrnx.computeSatPosition('broadcast','../data/brdc');
            
            % Export loaded files to MAT 
            %obj.obsrnx.saveToMAT('../data/JAB1080M.mat');
            %obj.obsrnxSatpos.saveToMAT('../data/JAB1080MSatpos.mat');
            
            % Loading from MAT (use for test development))
            obj.obsrnx = OBSRNX.loadFromMAT('../data/JAB1080M.mat');
            obj.obsrnxSatpos = OBSRNX.loadFromMAT('../data/JAB1080MSatpos.mat');
        end
    end
    methods (Test)
        function testInvalidInputs(obj)
            obj.verifyError(@()SNRMultipathDetector(obj.obsrnx,'G',{'S1C','S2W','S5X'}),'invalidInput:noSattelitePositions');
        end
        function testSNRMultipathDetectorConstructor(obj)
            snrDetector = SNRMultipathDetector(obj.obsrnxSatpos,'G',{'S1C','S2W','S5X'});
        end
    end
end