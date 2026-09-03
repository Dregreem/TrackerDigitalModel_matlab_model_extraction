classdef testJ2Axis < matlab.unittest.TestCase
    methods (Test)
        function concentric99ValidatesWithoutIdealization(testCase)
            model = trackerTestModel();
            evidence = model.joints.J2.cadEvidence;
            nominalY1 = [0;1;0];
            testCase.verifyTrue(model.joints.J2.validated);
            testCase.verifyEqual(evidence.featureName, "Concentric99");
            testCase.verifyLessThanOrEqual(evidence.maxAngularMismatchDeg, 0.05);
            testCase.verifyLessThanOrEqual(evidence.maxLineDistanceM, 0.10e-3);
            testCase.verifyLessThanOrEqual(evidence.maxF0AngularMismatchDeg, 0.05);
            testCase.verifyLessThanOrEqual(evidence.maxF0LineDistanceM, 0.10e-3);
            testCase.verifyGreaterThan(norm(model.frames.R01_0.' * model.joints.J2.axis_F0 - nominalY1), 1e-4);
        end

        function carriedJ2PivotIsSharedByB1AndB2(testCase)
            model = trackerTestModel();
            pose = trackerKinematics(model, [0.4;-0.8]);
            zeroPivot = [model.joints.J2.origin_F0;1];
            pivotOnB1 = pose.H_B1 * zeroPivot;
            pivotOnB2 = pose.H_B2 * zeroPivot;
            testCase.verifyEqual(pivotOnB2, pivotOnB1, AbsTol=1e-12);
            testCase.verifyEqual(pose.O2, pivotOnB1(1:3), AbsTol=1e-12);
        end
    end
end
