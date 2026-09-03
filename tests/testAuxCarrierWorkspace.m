classdef testAuxCarrierWorkspace < matlab.unittest.TestCase
    %TESTAUXCARRIERWORKSPACE P1 verification of resolved pulley carrier motion.
    %
    % This tests carrier/body transport only. Local pulley spin and belt
    % deformation remain intentionally unresolved.

    methods (TestMethodSetup)
        function hideFiguresAndExpectedWarning(testCase)
            oldVisibility = get(groot, "defaultFigureVisible");
            testCase.addTeardown(@() set(groot, "defaultFigureVisible", oldVisibility));
            set(groot, "defaultFigureVisible", "off");

            oldWarning = warning("query", "TrackerModel:AuxDriveUnresolved");
            testCase.addTeardown(@() warning(oldWarning.state, oldWarning.identifier));
            warning("off", "TrackerModel:AuxDriveUnresolved");
        end
    end

    methods (Test)
        function carrierMetadataMatchesAcceptedEvidence(testCase)
            model = trackerTestModel();

            moving = testAuxCarrierWorkspace.component(model, "GT2_16T-1");
            fixed = testAuxCarrierWorkspace.component(model, "GT2_16T-2");

            testCase.verifyEqual(string(moving.semantic_group), "AUX_DRIVE");
            testCase.verifyEqual(string(fixed.semantic_group), "AUX_DRIVE");
            testCase.verifyEqual(string(moving.carrier_group), "B1");
            testCase.verifyEqual(string(fixed.carrier_group), "B0");
            testCase.verifyEqual(string(moving.relative_motion_policy), ...
                "unresolved_local_spin");
            testCase.verifyEqual(string(fixed.relative_motion_policy), ...
                "unresolved_local_spin");
        end

        function viewerKeepsPulleyParentsCorrectAtCriticalPoses(testCase)
            model = trackerTestModel();
            posesDeg = [ ...
                -100 -180; ...
                -100  180; ...
                   0 -180; ...
                   0    0; ...
                   0  180; ...
                 100 -180; ...
                 100  180];

            for k = 1:size(posesDeg,1)
                qDeg = posesDeg(k,:);
                figureHandle = showTracker(model, qDeg, Units="degrees", ...
                    Interactive=false, ShowJointAxes=false);
                cleanup = onCleanup(@() close(figureHandle));

                movingPulley = findall(figureHandle, "DisplayName", "GT2_16T-1");
                fixedPulley = findall(figureHandle, "DisplayName", "GT2_16T-2");
                state = trackerKinematics(model, deg2rad(qDeg(:)));

                testCase.verifyEqual(numel(movingPulley), 1);
                testCase.verifyEqual(numel(fixedPulley), 1);
                testCase.verifyEqual(string(movingPulley.Parent.Tag), ...
                    "TrackerTransform_B1");
                testCase.verifyEqual(string(fixedPulley.Parent.Tag), ...
                    "TrackerTransform_B0");
                testCase.verifyEqual(movingPulley.Parent.Matrix, ...
                    state.H_B1, AbsTol=1e-12);
                testCase.verifyEqual(fixedPulley.Parent.Matrix, ...
                    state.H_B0, AbsTol=0);

                clear cleanup
            end
        end

        function movingPulleyCarrierChangesOnlyWithQ1(testCase)
            model = trackerTestModel();
            q1Deg = [-100 -50 0 50 100];
            q2Deg = [-180 -90 0 90 180];

            for q1 = q1Deg
                reference = trackerKinematics(model, deg2rad([q1;0]));
                for q2 = q2Deg
                    state = trackerKinematics(model, deg2rad([q1;q2]));
                    testCase.verifyEqual(state.H_B1, reference.H_B1, AbsTol=1e-12);
                end
            end
        end
    end

    methods (Static, Access=private)
        function item = component(model, instancePath)
            paths = string({model.components.instance_path});
            index = find(paths == instancePath);
            if numel(index) ~= 1
                error("TrackerPreControl:ComponentLookup", ...
                    "Expected exactly one component named %s; found %d.", ...
                    instancePath, numel(index));
            end
            item = model.components(index);
        end
    end
end
