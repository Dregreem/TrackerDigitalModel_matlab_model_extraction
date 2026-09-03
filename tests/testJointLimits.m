classdef testJointLimits < matlab.unittest.TestCase
    methods (Test)
        function boundaryCommandsAreAccepted(testCase)
            model = trackerTestModel();
            lower = trackerKinematics(model, deg2rad([-100;-180]));
            upper = trackerKinematics(model, deg2rad([100;180]));
            testCase.verifyEqual(lower.q, deg2rad([-100;-180]), AbsTol=1e-12);
            testCase.verifyEqual(upper.q, deg2rad([100;180]), AbsTol=1e-12);
        end

        function q1BelowLimitIsRejected(testCase)
            model = trackerTestModel();
            testCase.verifyError(@() trackerKinematics(model, deg2rad([-100.1;0])), ...
                "TrackerModel:JointLimit");
        end

        function q1AboveLimitIsRejected(testCase)
            model = trackerTestModel();
            testCase.verifyError(@() trackerKinematics(model, deg2rad([100.1;0])), ...
                "TrackerModel:JointLimit");
        end

        function q2BelowLimitIsRejected(testCase)
            model = trackerTestModel();
            testCase.verifyError(@() trackerKinematics(model, deg2rad([0;-180.1])), ...
                "TrackerModel:JointLimit");
        end

        function q2AboveLimitIsRejected(testCase)
            model = trackerTestModel();
            testCase.verifyError(@() trackerKinematics(model, deg2rad([0;180.1])), ...
                "TrackerModel:JointLimit");
        end

        function explicitDiagnosticOverrideIsAccepted(testCase)
            model = trackerTestModel();
            state = trackerKinematics(model, deg2rad([150;190]), AllowLimitOverride=true);
            testCase.verifyEqual(state.q, deg2rad([150;190]), AbsTol=1e-12);
        end
    end
end
