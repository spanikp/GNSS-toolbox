classdef runAllTests
    methods
        function obj = runAllTests(obj)
            import matlab.unittest.TestSuite
            import matlab.unittest.TestRunner
            import matlab.unittest.plugins.ToUniqueFile;
            import matlab.unittest.plugins.TAPPlugin
			addpath(genpath('../src'))
            
            % Create test suite
            suite = TestSuite.fromFolder(pwd,'IncludingSubfolders',true);
            
            % Run without test report
            run(suite)
            
            % % Run with Runner object to create test report
            %runner = TestRunner.withTextOutput();
            %stream = ToUniqueFile('.','WithPrefix','testReport','WithExtension','.tap');
            %plugin = TAPPlugin.producingVersion13(stream);
            %runner.addPlugin(plugin);
            %runner.run(suite)
        end
    end
end