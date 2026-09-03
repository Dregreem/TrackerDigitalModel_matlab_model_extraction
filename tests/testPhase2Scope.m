classdef testPhase2Scope < matlab.unittest.TestCase
    methods (Test)
        function noSimulinkModelExists(testCase)
            root = trackerTestRoot();
            artifacts = [dir(fullfile(root,"**","*.slx")); ...
                dir(fullfile(root,"**","*.mdl"))];
            testCase.verifyEmpty(artifacts);
        end

        function phase2BArtifactsAreNotPresent(testCase)
            root = trackerTestRoot();
            deferred = ["trackerTrajectory.m","trackerController.m", ...
                "simulateTracker.m","animateTrackerTrajectory.m"];
            for name = deferred
                testCase.verifyFalse(isfile(fullfile(root,"matlab",name)));
            end
        end
    end
end
