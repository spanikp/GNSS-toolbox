classdef SNRMultipathDetectorTest < matlab.unittest.TestCase
    properties
        obsrnx
        obsrnxSatpos
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'))
            opt = OBSRNX.getDefaults();
            opt.filtergnss = 'G';
            %obj.obsrnx = OBSRNX('../data/JAB1080M.19o',opt);
            %obj.obsrnxSatpos = obj.obsrnx.computeSatPosition('broadcast','../data/brdc');
            obj.obsrnx = OBSRNX.loadFromMAT('../data/JAB1080M.mat');
            obj.obsrnxSatpos = OBSRNX.loadFromMAT('../data/JAB1080MSatpos.mat');
            
            % Export and load files from MAT (useful for local debug)
            %obj.obsrnx.saveToMAT('../data/JAB1080M.mat');
            %obj.obsrnxSatpos.saveToMAT('../data/JAB1080MSatpos.mat');
        end
    end
    methods (Test)
        function testInvalidInputs(obj)
            obj.verifyError(@()SNRMultipathDetector(obj.obsrnx),'invalidInput:noSattelitePositions');
        end
        function testSNRMultipathDetectorConstructor_2frequencies(obj)
            opts = SNRMultipathDetectorOptions();
            opts.snrIdentifiers = {'S1C','S2W'};
            SNRMultipathDetector(obj.obsrnxSatpos,opts);
        end
        function testSNRMultipathDetectorConstructor_2frequencies_customFuncs(obj)
            opts = SNRMultipathDetectorOptions();
            opts.snrIdentifiers = {'S1C','S2W'};
            opts.verbosity = 1;
            opts.fitByOptimization = true;
            opts.funcs = {@(x,p) piecewiseConstant(x,[p(1),p(2),p(3),p(4)]), @(x,p)0, @(x,p) piecewiseConstant(x,[p(1),p(2),p(3),p(4)])};
            %opts.funcs = {@(x,p) piecewiseLinear(x,[p(1),p(2),p(3),p(4)]), @(x,p)0, @(x,p) piecewiseLinear(x,[p(1),p(2),p(3),p(4)])};
            SNRMultipathDetector(obj.obsrnxSatpos,opts);
        end
        function testSNRMultipathDetectorConstructor_3frequencies(obj)
            opts = SNRMultipathDetectorOptions();
            opts.verbosity = 2;
            opts.fitByOptimization = true;
            snrDetector = SNRMultipathDetector(obj.obsrnxSatpos,opts);
            %snrDetector
        end
    end
end