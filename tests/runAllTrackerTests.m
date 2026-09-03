function results = runAllTrackerTests()
%RUNALLTRACKERTESTS Run every class-based Tracker test and assert success.
root = trackerTestRoot();
addpath(fullfile(root, "config"), fullfile(root, "matlab"), fullfile(root, "tests"));
suite = matlab.unittest.TestSuite.fromFolder(fullfile(root, "tests"), ...
    IncludingSubfolders=true);
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);
assertSuccess(results);
end
