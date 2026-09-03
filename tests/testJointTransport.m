classdef testJointTransport < matlab.unittest.TestCase
    %TESTJOINTTRANSPORT Validate J1/J2 origin-axis transport invariants.

    methods (Test)
        function j1OriginAndAxisRemainFixedInF0(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];
            q2Deg = [-180 -90 0 90 180];

            for q1 = q1Deg
                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    testCase.verifyEqual(state.O1, model.joints.J1.origin_F0, AbsTol=0);
                    testCase.verifyEqual(state.e1, model.joints.J1.axis_F0, AbsTol=0);
                end
            end
        end

        function j2OriginAndAxisAreCarriedByJ1(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];

            for q1 = q1Deg
                state = trackerKinematics(model, deg2rad([q1;0]));

                expectedOrigin = testJointTransport.applyPoint( ...
                    state.H_B1, model.joints.J2.origin_F0);
                expectedAxis = state.H_B1(1:3,1:3) * model.joints.J2.axis_F0;
                expectedAxis = expectedAxis / norm(expectedAxis);

                testCase.verifyEqual(state.O2, expectedOrigin, AbsTol=2e-12);
                testCase.verifyEqual(state.e2, expectedAxis, AbsTol=2e-12);
                testCase.verifyEqual(norm(state.e2), 1, AbsTol=2e-12);
            end
        end

        function q2CannotMoveJ2OriginOrAxis(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];
            q2Deg = [-180 -90 0 90 180];

            for q1 = q1Deg
                reference = trackerKinematics(model, deg2rad([q1;0]));

                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    testCase.verifyEqual(state.O2, reference.O2, AbsTol=1e-12);
                    testCase.verifyEqual(state.e2, reference.e2, AbsTol=1e-12);
                end
            end
        end

        function transportedJ2AxisPreservesJ1J2IncludedAngle(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];

            zeroAngle = acos(max(-1,min(1, ...
                dot(model.joints.J1.axis_F0, model.joints.J2.axis_F0))));

            for q1 = q1Deg
                state = trackerKinematics(model, deg2rad([q1;0]));
                currentAngle = acos(max(-1,min(1, dot(state.e1, state.e2))));
                testCase.verifyEqual(currentAngle, zeroAngle, AbsTol=2e-12);
            end
        end
    end

    methods (Static, Access=private)
        function point = applyPoint(H, point)
            value = H * [point(:);1];
            point = value(1:3);
        end
    end
end
