classdef runAllTests
    methods
        function obj = runAllTests(obj)
            import matlab.unittest.TestSuite
            import matlab.unittest.TestRunner
            import matlab.unittest.plugins.ToUniqueFile;
            import matlab.unittest.plugins.TAPPlugin
            import matlab.unittest.plugins.CodeCoveragePlugin
            import matlab.unittest.plugins.codecoverage.CoberturaFormat
            
            addpath(genpath('../src'))
            
            % Create test suite
            suite = TestSuite.fromFolder(pwd(),'IncludingSubfolders',true);
            
            % Run without test report
            % run(suite)
            
            % Add plugin to create test report
            runner = TestRunner.withTextOutput();
            stream = ToUniqueFile('.','WithPrefix','testResultsReport','WithExtension','.tap');
            pluginTestOutput = TAPPlugin.producingVersion13(stream);
            runner.addPlugin(pluginTestOutput);
            
            % Add plugin to generate code coverage report
            reportFormat = CoberturaFormat('testCoverageReport.xml');
            pluginTestCoverage = CodeCoveragePlugin.forFolder('../src',...
                'IncludingSubfolders',true,'Producing',reportFormat);
            runner.addPlugin(pluginTestCoverage);
            
            runner.run(suite)
        end
    end
end