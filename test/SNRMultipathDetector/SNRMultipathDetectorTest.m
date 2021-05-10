classdef SNRMultipathDetectorTest < matlab.unittest.TestCase
    properties
        obsrnx
        obsrnxSatpos
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'))
            opt = OBSRNX.getDefaults();
            obj.obsrnx = OBSRNX('../data/JAB1080M.19o',opt);
            obj.obsrnxSatpos = obj.obsrnx.computeSatPosition('broadcast','../data/brdc');
            %obj.obsrnx = OBSRNX.loadFromMAT('../data/JAB1080M.mat');
            %obj.obsrnxSatpos = OBSRNX.loadFromMAT('../data/JAB1080MSatpos.mat');
            
            % Export and load files from MAT (useful for local debug)
            %obj.obsrnx.saveToMAT('../data/JAB1080M.mat');
            %obj.obsrnxSatpos.saveToMAT('../data/JAB1080MSatpos.mat');
        end
    end
    methods (TestMethodTeardown)
        function closeFigures(obj)
            close all
        end
    end
    methods (Test)
        function testInvalidInputs(obj)
            obj.verifyError(@()SNRMultipathDetector(obj.obsrnx),'invalidInput:noSattelitePositions');
        end
        function testSNRMultipathDetectorConstructor_2frequencies(obj)
            opts = SNRMultipathDetectorOptions();
            opts.snrIdentifiers = {'S1C','S2W'};
            opts.threshold_significancy = 0.9;
            opts.threshold_iteration_increment = 0.1;
            SNRMultipathDetector(obj.obsrnxSatpos,opts);
        end
        function testSNRMultipathDetectorConstructor_2frequencies_customFuncs(obj)
            opts = SNRMultipathDetectorOptions();
            opts.snrIdentifiers = {'S1C','S2W'};
            opts.verbosity = 2;
            opts.fitByOptimization = true;
            opts.funcs = {@(x,p) piecewiseConstant(x,[p(1),p(2),p(3),p(4),p(5),p(6)]), @(x,p)0, @(x,p) piecewiseConstant(x,[p(1),p(2),p(3),p(4)])};
            %opts.funcs = {@(x,p) piecewiseLinear(x,[p(1),p(2),p(3),p(4)]), @(x,p)0, @(x,p) piecewiseLinear(x,[p(1),p(2),p(3),p(4)])};
            SNRMultipathDetector(obj.obsrnxSatpos,opts);
            close all;
        end
        function testSNRMultipathDetectorConstructor_3frequencies(obj)
            opts = SNRMultipathDetectorOptions();
            opts.verbosity = 2;
            opts.fitByOptimization = true;
            snrDetector = SNRMultipathDetector(obj.obsrnxSatpos,opts);
        end
        function testSNRMultipathDetector_plotCalibrationFit(obj)
            try
                for i = 1:length(obj.obsrnxSatpos.gnss)
                    gnss = obj.obsrnxSatpos.gnss(i);
                    obsTypes = obj.obsrnxSatpos.obsTypes.(gnss);
                    availableSNR = obsTypes(cellfun(@(x) startsWith(x,'S'),obsTypes));

                    tmp = nchoosek(availableSNR,2);
                    snr2combs = cell(size(tmp,1),1);
                    for j = 1:size(tmp,1)
                        snr2combs{j} = tmp(j,:);
                    end
                    tmp = nchoosek(availableSNR,3);
                    snr3combs = cell(size(tmp,1),1);
                    for j = 1:size(tmp,1)
                        snr3combs{j} = tmp(j,:);
                    end
                    allCombsSNR = [snr2combs; snr3combs];
                    for j = 1:length(allCombsSNR)
                        opts = SNRMultipathDetectorOptions();
                        opts.threshold_iteration_increment = 0.01;
                        opts.gnss = gnss;
                        opts.snrIdentifiers = allCombsSNR{j};
                        snrDetector = SNRMultipathDetector(obj.obsrnxSatpos,opts);
                        snrDetector.plotCalibrationFit(SNRCalibrationMode.ALL);
                        snrDetector.plotCalibrationFit(SNRCalibrationMode.BLOCK);
                        snrDetector.plotCalibrationFit(SNRCalibrationMode.INDIVIDUAL);
                        close all;
                    end
                end
            catch ME
                fprintf('\nFAILING TEST: gnss=%s, combination=%s\n',gnss,strjoin(allCombsSNR{j},','));
                rethrow(ME);
            end
        end
        function testOBSRNX_detectMultipathViaSNR(obj)
            opts = SNRMultipathDetectorOptions();
            opts.snrIdentifiers = {'S1C','S2X'};
            %opts.fitByOptimization = true;
            %opts.funcs{3} = @(x,p) p(1) + p(2)*x;
            opts.threshold_function = @(x,S,s0,t) S(x) + s0*t*exp((90-x)./80);
            opts.threshold_iteration_increment = 0.01;
            snrDetector = SNRMultipathDetector(obj.obsrnxSatpos,opts);
            %snrDetector.plotCalibrationFit(SNRCalibrationMode.ALL);
            isMultipath = obj.obsrnxSatpos.detectMultipathViaSNR(snrDetector,SNRCalibrationMode.ALL,0.99);
            skyplot = obj.obsrnxSatpos.makeMultipathPlot(snrDetector.gnss,isMultipath);
        end
    end
end