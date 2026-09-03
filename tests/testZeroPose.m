classdef testZeroPose < matlab.unittest.TestCase
    methods (Test)
        function zeroPoseLeavesImportedGeometryUnchanged(testCase)
            model = trackerTestModel();
            state = trackerKinematics(model, [0;0]);
            testCase.verifyEqual(state.H_B0, eye(4), AbsTol=1e-12);
            testCase.verifyEqual(state.H_B1, eye(4), AbsTol=1e-12);
            testCase.verifyEqual(state.H_B2, eye(4), AbsTol=1e-12);
        end

        function rigidBodyHierarchyIsCorrect(testCase)
            model = trackerTestModel();
            j1Only = trackerKinematics(model, [0.2;0]);
            both = trackerKinematics(model, [0.2;0.3]);
            j2Only = trackerKinematics(model, [0;0.3]);
            testCase.verifyEqual(j1Only.H_B0, eye(4));
            testCase.verifyEqual(j1Only.H_B1, both.H_B1, AbsTol=1e-12);
            testCase.verifyNotEqual(j1Only.H_B1, eye(4));
            testCase.verifyEqual(j2Only.H_B1, eye(4), AbsTol=1e-12);
            testCase.verifyNotEqual(j2Only.H_B2, eye(4));
        end


        function poseMatchesFrozenRotationConvention(testCase)
            model = trackerTestModel();
            q = [0.17;-0.23];
            state = trackerKinematics(model, q);
            Rz1 = [cos(q(1)) -sin(q(1)) 0; sin(q(1)) cos(q(1)) 0; 0 0 1];
            Rz2 = [cos(q(2)) -sin(q(2)) 0; sin(q(2)) cos(q(2)) 0; 0 0 1];
            expectedR01 = model.frames.R01_0 * Rz1;
            expectedR02 = expectedR01 * model.frames.R12_0 * Rz2;
            actualR01 = state.H_B1(1:3,1:3) * model.frames.R01_0;
            actualR02 = state.H_B2(1:3,1:3) * model.frames.R02_0;
            testCase.verifyEqual(actualR01, expectedR01, AbsTol=2e-8);
            testCase.verifyEqual(actualR02, expectedR02, AbsTol=3e-8);
        end
    end
end
