classdef testWorkspaceKinematics < matlab.unittest.TestCase
    %TESTWORKSPACEKINEMATICS P1 critical-pose kinematic invariants.
    %
    % This is intentionally NOT the dense P2 sweep and NOT a collision test.
    % It validates the rigid-body motion logic at 25 critical configurations.

    methods (Test)
        function criticalGridProducesProperRigidTransforms(testCase)
            model = trackerTestModel();
            [q1Deg, q2Deg] = testWorkspaceKinematics.criticalAngles();

            for q1 = q1Deg
                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    transforms = {state.H_B0, state.H_B1, state.H_B2};

                    for k = 1:numel(transforms)
                        H = transforms{k};
                        R = H(1:3,1:3);

                        testCase.verifyTrue(all(isfinite(H), "all"), ...
                            sprintf("Non-finite transform at q1=%g deg, q2=%g deg.", q1, q2));
                        testCase.verifyEqual(H(4,:), [0 0 0 1], AbsTol=1e-14);
                        testCase.verifyEqual(R.'*R, eye(3), AbsTol=2e-12);
                        testCase.verifyEqual(det(R), 1, AbsTol=2e-12);
                    end
                end
            end
        end

        function baseRemainsFixedAcrossCriticalGrid(testCase)
            model = trackerTestModel();
            [q1Deg, q2Deg] = testWorkspaceKinematics.criticalAngles();

            for q1 = q1Deg
                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    testCase.verifyEqual(state.H_B0, eye(4), AbsTol=0);
                end
            end
        end

        function b1DependsOnlyOnQ1(testCase)
            model = trackerTestModel();
            [q1Deg, q2Deg] = testWorkspaceKinematics.criticalAngles();

            for q1 = q1Deg
                reference = trackerKinematics(model, deg2rad([q1;0]));
                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    testCase.verifyEqual(state.H_B1, reference.H_B1, AbsTol=1e-12);
                end
            end
        end

        function b2AtZeroQ2FollowsB1Exactly(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];

            for q1 = q1Deg
                state = trackerKinematics(model, deg2rad([q1;0]));
                testCase.verifyEqual(state.H_B2, state.H_B1, AbsTol=1e-12);
            end
        end

        function representativeB1PointKeepsDistanceToJ1Axis(testCase)
            model = trackerTestModel();
            p0 = testWorkspaceKinematics.farthestGroupVertexFromAxis( ...
                model, "B1", model.joints.J1.origin_F0, model.joints.J1.axis_F0);
            d0 = testWorkspaceKinematics.pointLineDistance( ...
                p0, model.joints.J1.origin_F0, model.joints.J1.axis_F0);
            testCase.verifyGreaterThan(d0, 1e-5);

            q1Deg = [-100 -50 0 50 100];
            for q1 = q1Deg
                state = trackerKinematics(model, deg2rad([q1;0]));
                p = testWorkspaceKinematics.applyPoint(state.H_B1, p0);
                d = testWorkspaceKinematics.pointLineDistance( ...
                    p, state.O1, state.e1);
                testCase.verifyEqual(d, d0, AbsTol=5e-12);
            end
        end

        function representativeB2PointKeepsDistanceToCurrentJ2Axis(testCase)
            model = trackerTestModel();
            p0 = testWorkspaceKinematics.farthestGroupVertexFromAxis( ...
                model, "B2", model.joints.J2.origin_F0, model.joints.J2.axis_F0);
            [q1Deg, q2Deg] = testWorkspaceKinematics.criticalAngles();

            for q1 = q1Deg
                reference = trackerKinematics(model, deg2rad([q1;0]));
                pReference = testWorkspaceKinematics.applyPoint(reference.H_B2, p0);
                dReference = testWorkspaceKinematics.pointLineDistance( ...
                    pReference, reference.O2, reference.e2);
                testCase.verifyGreaterThan(dReference, 1e-5);

                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    p = testWorkspaceKinematics.applyPoint(state.H_B2, p0);
                    d = testWorkspaceKinematics.pointLineDistance(p, state.O2, state.e2);
                    testCase.verifyEqual(d, dReference, AbsTol=5e-12);
                end
            end
        end

        function q2Minus180AndPlus180AreGeometricallyClosed(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];

            for q1 = q1Deg
                negative = trackerKinematics(model, deg2rad([q1;-180]));
                positive = trackerKinematics(model, deg2rad([q1;180]));

                testCase.verifyEqual(negative.H_B2, positive.H_B2, AbsTol=2e-12);
                testCase.verifyEqual(negative.O2, positive.O2, AbsTol=1e-12);
                testCase.verifyEqual(negative.e2, positive.e2, AbsTol=1e-12);
            end
        end
    end

    methods (Static, Access=private)
        function [q1Deg, q2Deg] = criticalAngles()
            q1Deg = [-100 -50 0 50 100];
            q2Deg = [-180 -90 0 90 180];
        end

        function p = farthestGroupVertexFromAxis(model, groupName, origin, axis)
            groupNames = string({model.components.semantic_group});
            indices = find(groupNames == groupName);
            if isempty(indices)
                error("TrackerPreControl:MissingGroupGeometry", ...
                    "No components found for rigid group %s.", groupName);
            end

            bestDistance = -inf;
            p = [];
            for idx = indices
                vertices = model.geometry.components(idx).vertices_F0;
                if isempty(vertices)
                    continue
                end
                delta = vertices - origin(:).';
                axisUnit = axis(:) / norm(axis);
                axial = delta * axisUnit;
                radial = delta - axial * axisUnit.';
                distances = vecnorm(radial, 2, 2);
                [candidateDistance, localIndex] = max(distances);
                if candidateDistance > bestDistance
                    bestDistance = candidateDistance;
                    p = vertices(localIndex,:).';
                end
            end

            if isempty(p)
                error("TrackerPreControl:MissingGroupGeometry", ...
                    "No vertices found for rigid group %s.", groupName);
            end
        end

        function d = pointLineDistance(point, origin, axis)
            axis = axis(:) / norm(axis);
            delta = point(:) - origin(:);
            radial = delta - dot(delta, axis) * axis;
            d = norm(radial);
        end

        function point = applyPoint(H, point)
            value = H * [point(:);1];
            point = value(1:3);
        end
    end
end
