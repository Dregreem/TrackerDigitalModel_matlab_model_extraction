function figureHandle = showTracker(model, q, options)
%SHOWTRACKER Display the CAD geometry at a requested Phase 1 pose.
% q is in radians by default. Use Units="degrees" explicitly for degrees.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal} = [0 0]
    options.Units (1,1) string {mustBeMember(options.Units,["radians","degrees"])} = "radians"
    options.AllowLimitOverride (1,1) logical = false
    options.Interactive (1,1) logical = true
    options.ShowJointAxes (1,1) logical = true
    options.GroundAligned (1,1) logical = true
    options.ShowBelts (1,1) logical = false
end
if options.Units == "degrees"
    q = deg2rad(q);
end
state = trackerKinematics(model, q, AllowLimitOverride=options.AllowLimitOverride);
if any(abs(state.q) > 1e-14)
    warning("TrackerModel:AuxDriveUnresolved", "%s", model.status);
end

figureHandle = figure("Name", "Tracker Model Builder Phase 1", "Color", "w");
axesHandle = axes(figureHandle);
axesHandle.Position = [0.08 0.20 0.88 0.74];
hold(axesHandle, "on");
axis(axesHandle, "equal");
grid(axesHandle, "on");
xlabel(axesHandle, "X_0 (m)"); ylabel(axesHandle, "Y_0 (m)"); zlabel(axesHandle, "Z_0 (m)");
view(axesHandle, 3);

if options.GroundAligned
    HDisplay = trackerDisplayTransform(model);
else
    HDisplay = eye(4);
end
displayRoot = hgtransform("Parent", axesHandle, "Matrix", HDisplay, ...
    "Tag", "TrackerDisplayRoot");
transforms.B0 = hgtransform("Parent", displayRoot, "Matrix", state.H_B0);
transforms.B1 = hgtransform("Parent", displayRoot, "Matrix", state.H_B1);
transforms.B2 = hgtransform("Parent", displayRoot, "Matrix", state.H_B2);
transforms.AUX_DRIVE = hgtransform("Parent", displayRoot, "Matrix", eye(4));
transforms.B0.Tag = "TrackerTransform_B0";
transforms.B1.Tag = "TrackerTransform_B1";
transforms.B2.Tag = "TrackerTransform_B2";
transforms.AUX_DRIVE.Tag = "TrackerTransform_AUX_DRIVE";
colors.B0 = [0.55 0.58 0.62];
colors.B1 = [0.20 0.55 0.85];
colors.B2 = [0.95 0.55 0.15];
colors.AUX_DRIVE = [0.75 0.25 0.25];

for k = 1:numel(model.geometry.components)
    geometry = model.geometry.components(k);
    groupName = string(model.components(k).semantic_group);
    if ~options.ShowBelts && ismember(geometry.instancePath, model.display.hiddenBelts)
        continue
    end
    renderParent = transforms.(groupName);
    if groupName == "AUX_DRIVE"
        carrierGroup = string(model.components(k).carrier_group);
        if any(carrierGroup == ["B0","B1","B2"])
            renderParent = transforms.(carrierGroup);
        end
    end
    patch("Parent", renderParent, "Faces", geometry.faces, ...
        "Vertices", geometry.vertices_F0, "FaceColor", colors.(groupName), ...
        "EdgeColor", "none", "FaceLighting", "gouraud", ...
        "DisplayName", geometry.instancePath);
end
if options.ShowJointAxes
    axisHalfLength = 0.08;
    j1Points = model.joints.J1.origin_F0 + ...
        model.joints.J1.axis_F0 * [-axisHalfLength axisHalfLength];
    j2Points = model.joints.J2.origin_F0 + ...
        model.joints.J2.axis_F0 * [-axisHalfLength axisHalfLength];
    line("Parent", transforms.B0, "XData", j1Points(1,:), "YData", j1Points(2,:), ...
        "ZData", j1Points(3,:), "Color", [0.55 0 0.75], "LineWidth", 2.5, ...
        "LineStyle", "--", "Tag", "TrackerJointAxis_J1", "DisplayName", "J1 axis");
    line("Parent", transforms.B1, "XData", j2Points(1,:), "YData", j2Points(2,:), ...
        "ZData", j2Points(3,:), "Color", [0 0.55 0.20], "LineWidth", 2.5, ...
        "LineStyle", "--", "Tag", "TrackerJointAxis_J2", "DisplayName", "J2 axis");
end
camlight(axesHandle, "headlight");
material(axesHandle, "dull");
title(axesHandle, sprintf("Tracker pose: q_1=%.2f deg, q_2=%.2f deg", ...
    rad2deg(state.q(1)), rad2deg(state.q(2))));
if options.GroundAligned
    xlabel(axesHandle, "X_{display} (m)");
    ylabel(axesHandle, "Y_{display} (m)");
    zlabel(axesHandle, "Z_{up} (m)");
end

if options.Interactive
    qDegrees = rad2deg(state.q);
    q1LimitsDeg = rad2deg([model.joints.J1.qMin,model.joints.J1.qMax]);
    q2LimitsDeg = rad2deg([model.joints.J2.qMin,model.joints.J2.qMax]);
    q1Slider = uicontrol(figureHandle, "Style", "slider", "Units", "normalized", ...
        "Position", [0.20 0.105 0.68 0.035], ...
        "Min", q1LimitsDeg(1), "Max", q1LimitsDeg(2), ...
        "Value", qDegrees(1), "Tag", "TrackerSlider_J1");
    q2Slider = uicontrol(figureHandle, "Style", "slider", "Units", "normalized", ...
        "Position", [0.20 0.050 0.68 0.035], ...
        "Min", q2LimitsDeg(1), "Max", q2LimitsDeg(2), ...
        "Value", qDegrees(2), "Tag", "TrackerSlider_J2");
    q1Label = uicontrol(figureHandle, "Style", "text", "Units", "normalized", ...
        "BackgroundColor", "w", "HorizontalAlignment", "left", ...
        "Position", [0.03 0.102 0.16 0.040]);
    q2Label = uicontrol(figureHandle, "Style", "text", "Units", "normalized", ...
        "BackgroundColor", "w", "HorizontalAlignment", "left", ...
        "Position", [0.03 0.047 0.16 0.040]);
    q1Slider.Callback = @updatePose;
    q2Slider.Callback = @updatePose;
    updatePose([], []);
end

    function updatePose(~, ~)
        qNowDegrees = [q1Slider.Value; q2Slider.Value];
        pose = trackerKinematics(model, deg2rad(qNowDegrees));
        transforms.B0.Matrix = pose.H_B0;
        transforms.B1.Matrix = pose.H_B1;
        transforms.B2.Matrix = pose.H_B2;
        transforms.AUX_DRIVE.Matrix = eye(4);
        q1Label.String = sprintf("J1: %.2f deg", qNowDegrees(1));
        q2Label.String = sprintf("J2: %.2f deg", qNowDegrees(2));
        title(axesHandle, sprintf("Tracker pose: q_1=%.2f deg, q_2=%.2f deg", ...
            qNowDegrees(1), qNowDegrees(2)));
        drawnow limitrate;
    end
end
