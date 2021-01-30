function results = runAllTests()
import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.ToUniqueFile;
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.TAPPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat

addpath(genpath('../src'));
thisFolder = fileparts(mfilename('fullpath'));

% Create test suite
suite = TestSuite.fromFolder(pwd(),'IncludingSubfolders',true);

% Create JUnit plugin
xmlFile = fullfile(thisFolder,'junit_test_results.xml');
pluginJUnitTestOutput = XMLPlugin.producingJUnitFormat(xmlFile);

% Add JUnit plugin to create test report in XML format
runner = TestRunner.withNoPlugins;
runner.addPlugin(pluginJUnitTestOutput);

% Add plugin to generate code coverage report
reportFormat = CoberturaFormat(fullfile(thisFolder,'test_coverage_report.xml'));
pluginTestCoverage = CodeCoveragePlugin.forFolder('../src',...
    'IncludingSubfolders',true,'Producing',reportFormat);
runner.addPlugin(pluginTestCoverage);

% Running configured test suite
results = runner.run(suite)


