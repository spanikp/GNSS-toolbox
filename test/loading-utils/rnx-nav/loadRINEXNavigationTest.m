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
            if ~exist(obj.tmpFolder,'dir')
                mkdir(obj.tmpFolder);
            end
        end
    end
    methods(TestClassTeardown)
        function removeArtifacts(obj)
            if exist(obj.tmpFolder,'dir')
                d = dir(obj.tmpFolder);
                for i = 1:length(d)
                    if ~d(i).isdir
                        delete(fullfile(d(i).folder,d(i).name))
                    end
                end
                %rmdir(obj.tmpFolder); % Failing for unknown reason!
            end
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testLoadEphemerisFromRINEXNavMessage(obj,gnss,ext)
            ephFolder = '../../data/brdc';
            brdc = loadRINEXNavigation(gnss,ephFolder,sprintf('brdc0800.19%s',ext));
            obj.verifyEqual(brdc.gnss,gnss);
        end
        function testDownloadNavMessages(obj,gnss)
            try
                downloadBroadcastMessage(gnss,datenum([2020 11 20]),obj.tmpFolder,true);
            catch 'MATLAB:io:ftp:ftp:FileUnavailable'
                warning('Broadcast message not available at server for "%s" system!\n',gnss);
                obj.assumeTrue(false); % This will mark test as incomplete
            end
        end
    end
end