classdef testPhysicalParams < matlab.unittest.TestCase
    methods (Test)
        function frameReexpressionPreservesF0MassDistribution(testCase)
            model = trackerTestModel();
            comB1 = model.joints.J1.origin_F0 + ...
                model.frames.R01_0 * model.physics.B1.r_O1C1_F1;
            comB2 = model.joints.J2.origin_F0 + ...
                model.frames.R02_0 * model.physics.B2.r_O2C2_F2;
            inertiaB1 = model.frames.R01_0 * model.physics.B1.Ic_F1 * ...
                model.frames.R01_0.';
            inertiaB2 = model.frames.R02_0 * model.physics.B2.Ic_F2 * ...
                model.frames.R02_0.';
            testCase.verifyEqual(comB1, model.physics.invarianceReference.B1.com_F0, AbsTol=1e-12);
            testCase.verifyEqual(comB2, model.physics.invarianceReference.B2.com_F0, AbsTol=1e-12);
            testCase.verifyEqual(inertiaB1, model.physics.invarianceReference.B1.Ic_F0, AbsTol=1e-12);
            testCase.verifyEqual(inertiaB2, model.physics.invarianceReference.B2.Ic_F0, AbsTol=1e-12);
        end

        function correctedInertiasRemainSymmetricPositiveDefinite(testCase)
            model = trackerTestModel();
            eigenvaluesB1 = eig(model.physics.B1.Ic_F1);
            eigenvaluesB2 = eig(model.physics.B2.Ic_F2);
            testCase.verifyEqual(model.physics.B1.Ic_F1, model.physics.B1.Ic_F1.', AbsTol=1e-14);
            testCase.verifyEqual(model.physics.B2.Ic_F2, model.physics.B2.Ic_F2.', AbsTol=1e-14);
            testCase.verifyGreaterThan(min(eigenvaluesB1), 0);
            testCase.verifyGreaterThan(min(eigenvaluesB2), 0);
        end
    end
end
