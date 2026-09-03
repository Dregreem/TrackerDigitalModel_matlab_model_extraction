classdef testViewer < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function hideFigures(testCase)
            oldVisibility = get(groot, "defaultFigureVisible");
            testCase.addTeardown(@() set(groot, "defaultFigureVisible", oldVisibility));
            set(groot, "defaultFigureVisible", "off");
        end
    end

    methods (Test)
        function viewerCreatesGeometryControlsAndJointAxes(testCase)
            model = trackerTestModel();
            figureHandle = showTracker(model, [0 0]);
            testCase.addTeardown(@() close(figureHandle));
            testCase.verifyEqual(numel(findall(figureHandle, "Type", "patch")), 38);
            testCase.verifyEqual(numel(findall(figureHandle, "Style", "slider")), 2);
            j1Slider = findall(figureHandle, "Tag", "TrackerSlider_J1");
            j2Slider = findall(figureHandle, "Tag", "TrackerSlider_J2");
            testCase.verifyEqual([j1Slider.Min,j1Slider.Max], ...
                rad2deg([model.joints.J1.qMin,model.joints.J1.qMax]),AbsTol=0);
            testCase.verifyEqual([j2Slider.Min,j2Slider.Max], ...
                rad2deg([model.joints.J2.qMin,model.joints.J2.qMax]),AbsTol=0);
            testCase.verifyEqual(numel(findall(figureHandle, "Tag", "TrackerJointAxis_J1")), 1);
            testCase.verifyEqual(numel(findall(figureHandle, "Tag", "TrackerJointAxis_J2")), 1);
            testCase.verifyEmpty(findall(figureHandle, "DisplayName", ...
                "Belt6-1^Measurement_for_math-1"));
            testCase.verifyEmpty(findall(figureHandle, "DisplayName", ...
                "Belt5-22^Measurement_for_math-1"));
        end


        function optionalBeltAuditViewRestoresBothMeshes(testCase)
            model = trackerTestModel();
            figureHandle = showTracker(model, [0 0], ShowBelts=true);
            testCase.addTeardown(@() close(figureHandle));
            testCase.verifyEqual(numel(findall(figureHandle, "Type", "patch")), 40);
            testCase.verifyEqual(numel(findall(figureHandle, "DisplayName", ...
                "Belt6-1^Measurement_for_math-1")), 1);
            testCase.verifyEqual(numel(findall(figureHandle, "DisplayName", ...
                "Belt5-22^Measurement_for_math-1")), 1);
        end

        function displayFramePlacesB0OnHorizontalGround(testCase)
            model = trackerTestModel();
            [transform, info] = trackerDisplayTransform(model);
            groundPoint = transform * [0; info.minimumB0HeightF0; 0; 1];
            testCase.verifyEqual(info.upAxisDisplay, [0;0;1], AbsTol=1e-12);
            testCase.verifyEqual(groundPoint(3), 0, AbsTol=1e-12);
            testCase.verifyEqual(transform(1:3,1:3).' * ...
                transform(1:3,1:3), eye(3), AbsTol=1e-12);
            testCase.verifyEqual(det(transform(1:3,1:3)), 1, AbsTol=1e-12);
        end

        function sliderCallbacksUpdateHierarchy(testCase)
            model = trackerTestModel();
            figureHandle = showTracker(model, [0 0]);
            testCase.addTeardown(@() close(figureHandle));
            j1Slider = findall(figureHandle, "Tag", "TrackerSlider_J1");
            j2Slider = findall(figureHandle, "Tag", "TrackerSlider_J2");
            b1Transform = findall(figureHandle, "Tag", "TrackerTransform_B1");
            b2Transform = findall(figureHandle, "Tag", "TrackerTransform_B2");
            j1Slider.Value = 25;
            j1Slider.Callback(j1Slider, []);
            b1AfterJ1 = b1Transform.Matrix;
            j2Slider.Value = -45;
            j2Slider.Callback(j2Slider, []);
            testCase.verifyNotEqual(b1AfterJ1, eye(4));
            testCase.verifyEqual(b1Transform.Matrix, b1AfterJ1, AbsTol=1e-12);
            testCase.verifyNotEqual(b2Transform.Matrix, b1Transform.Matrix);
        end

        function pulleyPatchesUseResolvedCarrierParents(testCase)
            model = trackerTestModel();
            figureHandle = showTracker(model,deg2rad([20;0]));
            testCase.addTeardown(@() close(figureHandle));
            movingPulley = findall(figureHandle,"DisplayName","GT2_16T-1");
            fixedPulley = findall(figureHandle,"DisplayName","GT2_16T-2");
            testCase.verifyEqual(string(movingPulley.Parent.Tag),"TrackerTransform_B1");
            testCase.verifyEqual(string(fixedPulley.Parent.Tag),"TrackerTransform_B0");
            testCase.verifyNotEqual(movingPulley.Parent.Matrix,eye(4));
            testCase.verifyEqual(fixedPulley.Parent.Matrix,eye(4),AbsTol=0);
        end
    end
end
