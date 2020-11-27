classdef loadRINEXNavigationTest < matlab.unittest.TestCase
    properties
        tmpFolder
    end
    properties (TestParameter)
        gnss = {'G','R','E','C'};
        ext = {'n','g','l','c'};        
    end
    methods (TestClassSetup)
        function setupPath(obj)
			addpath(genpath('../../../src'));
            current_dir = fileparts(mfilename('fullpath'));
            obj.tmpFolder = fullfile(current_dir,'tmpNavMessage');
            if ~exist(obj.tmpFolder,'dir'), mkdir(obj.tmpFolder); end
        end
    end
    methods(TestClassTeardown)
        function removeArtifacts(obj)
            rmdir(obj.tmpFolder,'s');
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testLoadEphemerisFromRINEXNavMessage(obj,gnss,ext)
            ephFolder = '../../data/brdc';
            brdc = loadRINEXNavigation(gnss,ephFolder,sprintf('brdc0800.19%s',ext));
            obj.verifyEqual(brdc.gnss,gnss);
        end
        function testDownloadNavMessage(obj,gnss)
            downloadBroadcastMessage(gnss,datenum([2020 11 20]),obj.tmpFolder,true);
        end
	end
end