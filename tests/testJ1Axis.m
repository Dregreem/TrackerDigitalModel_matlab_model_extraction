classdef testJ1Axis < matlab.unittest.TestCase
    methods (Test)
        function concentric120Validates(testCase)
            model = trackerTestModel();
            evidence = model.joints.J1.cadEvidence;
            testCase.verifyTrue(model.joints.J1.validated);
            testCase.verifyEqual(evidence.featureName, "Concentric120");
            testCase.verifyLessThanOrEqual(evidence.maxAngularMismatchDeg, 0.05);
            testCase.verifyLessThanOrEqual(evidence.maxLineDistanceM, 0.10e-3);
            testCase.verifyLessThanOrEqual(evidence.maxF0AngularMismatchDeg, 0.05);
            testCase.verifyLessThanOrEqual(evidence.maxF0LineDistanceM, 0.10e-3);
        end

        function j1PivotIsFixedByB1Motion(testCase)
            model = trackerTestModel();
            pose = trackerKinematics(model, [0.7;0]);
            pivot = pose.H_B1 * [model.joints.J1.origin_F0;1];
            testCase.verifyEqual(pivot(1:3), model.joints.J1.origin_F0, AbsTol=1e-12);
        end
    end
end
