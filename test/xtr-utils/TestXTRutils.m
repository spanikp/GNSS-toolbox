classdef TestXTRutils < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'))
        end
    end
    methods (TestMethodTeardown)
        function closeFigures(obj)
            close all
        end
    end
    methods (Test)
        function test_xtr2MPskyplotTestBasic(obj)
            xtr2MPskyplot('../../example/xtr-utils/GANP.xtr','C1C')
        end
        function test_xtr2SNRskyplotTestBasic(obj)
            xtr2SNRskyplot('../../example/xtr-utils/GANP.xtr','S1C')
        end
        function test_xtr2CSskyplotTestBasic(obj)
            xtr2CSskyplot('../../example/xtr-utils/GANP.xtr',true)
        end
    end
end