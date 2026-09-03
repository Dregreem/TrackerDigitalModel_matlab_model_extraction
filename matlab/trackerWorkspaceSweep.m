function sweep = trackerWorkspaceSweep(model, options)
%TRACKERWORKSPACESWEEP Deterministic P2 dense kinematic workspace audit.
%
% This function does NOT perform collision/interference detection and does
% NOT declare the configured joint rectangle mechanically safe.
%
% Default audit grid:
%   q1 = model J1 limits at 5 deg spacing  -> expected 41 values
%   q2 = model J2 limits at 5 deg spacing  -> expected 73 values
%
% Returned values are raw audit metrics. Use validateTrackerWorkspace to
% apply acceptance tolerances.

arguments
    model (1,1) struct
    options.StepDeg (1,1) double {mustBePositive,mustBeFinite} = 5
end

q1Deg = makeInclusiveGrid( ...
    rad2deg(model.joints.J1.qMin), rad2deg(model.joints.J1.qMax), options.StepDeg);
q2Deg = makeInclusiveGrid( ...
    rad2deg(model.joints.J2.qMin), rad2deg(model.joints.J2.qMax), options.StepDeg);

n1 = numel(q1Deg);
n2 = numel(q2Deg);
poseCount = n1 * n2;

pB1Zero = farthestGroupVertexFromAxis( ...
    model, "B1", model.joints.J1.origin_F0, model.joints.J1.axis_F0);
pB2Zero = farthestGroupVertexFromAxis( ...
    model, "B2", model.joints.J2.origin_F0, model.joints.J2.axis_F0);

b1RadiusZero = pointLineDistance( ...
    pB1Zero, model.joints.J1.origin_F0, model.joints.J1.axis_F0);

movingPulley = componentByPath(model, "GT2_16T-1");
fixedPulley = componentByPath(model, "GT2_16T-2");
movingPulleyMetadataPass = ...
    string(movingPulley.semantic_group) == "AUX_DRIVE" && ...
    string(movingPulley.carrier_group) == "B1" && ...
    string(movingPulley.relative_motion_policy) == "unresolved_local_spin";
fixedPulleyMetadataPass = ...
    string(fixedPulley.semantic_group) == "AUX_DRIVE" && ...
    string(fixedPulley.carrier_group) == "B0" && ...
    string(fixedPulley.relative_motion_policy) == "unresolved_local_spin";

vertexCountsBefore = geometryVertexCounts(model);
[displayTransformBefore, ~] = trackerDisplayTransform(model);

q1Column = zeros(poseCount,1);
q2Column = zeros(poseCount,1);
finiteTransformPass = false(poseCount,1);
rotationOrthogonalityError = zeros(poseCount,1);
rotationDeterminantError = zeros(poseCount,1);
homogeneousBottomRowError = zeros(poseCount,1);
b0Error = zeros(poseCount,1);
b1Q2DependencyError = zeros(poseCount,1);
b2AtZeroQ2Error = nan(poseCount,1);
j1OriginError = zeros(poseCount,1);
j1AxisError = zeros(poseCount,1);
j2OriginTransportError = zeros(poseCount,1);
j2AxisTransportError = zeros(poseCount,1);
j2Q2OriginError = zeros(poseCount,1);
j2Q2AxisError = zeros(poseCount,1);
b1AxisRadiusError = zeros(poseCount,1);
b2AxisRadiusError = zeros(poseCount,1);
movingPulleyCarrierError = zeros(poseCount,1);
fixedPulleyCarrierError = zeros(poseCount,1);

row = 0;
for i = 1:n1
    q1 = q1Deg(i);
    q1Rad = deg2rad(q1);

    q1Reference = trackerKinematics(model, [q1Rad;0]);
    pB2Reference = applyPoint(q1Reference.H_B2, pB2Zero);
    b2RadiusReference = pointLineDistance( ...
        pB2Reference, q1Reference.O2, q1Reference.e2);

    expectedJ2Origin = applyPoint( ...
        q1Reference.H_B1, model.joints.J2.origin_F0);
    expectedJ2Axis = q1Reference.H_B1(1:3,1:3) * model.joints.J2.axis_F0;
    expectedJ2Axis = expectedJ2Axis / norm(expectedJ2Axis);

    for j = 1:n2
        q2 = q2Deg(j);
        row = row + 1;

        state = trackerKinematics(model, deg2rad([q1;q2]));
        transforms = {state.H_B0, state.H_B1, state.H_B2};

        q1Column(row) = q1;
        q2Column(row) = q2;

        finiteTransformPass(row) = all(cellfun( ...
            @(H) all(isfinite(H),"all"), transforms));

        [orthError, detError, bottomError] = rigidTransformErrors(transforms);
        rotationOrthogonalityError(row) = orthError;
        rotationDeterminantError(row) = detError;
        homogeneousBottomRowError(row) = bottomError;

        b0Error(row) = norm(state.H_B0 - eye(4), "fro");
        b1Q2DependencyError(row) = norm( ...
            state.H_B1 - q1Reference.H_B1, "fro");

        if abs(q2) < 1e-12
            b2AtZeroQ2Error(row) = norm( ...
                state.H_B2 - state.H_B1, "fro");
        end

        j1OriginError(row) = norm( ...
            state.O1 - model.joints.J1.origin_F0);
        j1AxisError(row) = norm( ...
            state.e1 - model.joints.J1.axis_F0);

        j2OriginTransportError(row) = norm( ...
            state.O2 - expectedJ2Origin);
        j2AxisTransportError(row) = norm( ...
            state.e2 - expectedJ2Axis);

        j2Q2OriginError(row) = norm( ...
            state.O2 - q1Reference.O2);
        j2Q2AxisError(row) = norm( ...
            state.e2 - q1Reference.e2);

        pB1 = applyPoint(state.H_B1, pB1Zero);
        b1AxisRadius = pointLineDistance(pB1, state.O1, state.e1);
        b1AxisRadiusError(row) = abs(b1AxisRadius - b1RadiusZero);

        pB2 = applyPoint(state.H_B2, pB2Zero);
        b2AxisRadius = pointLineDistance(pB2, state.O2, state.e2);
        b2AxisRadiusError(row) = abs(b2AxisRadius - b2RadiusReference);

        if movingPulleyMetadataPass
            movingCarrier = carrierTransform(state, string(movingPulley.carrier_group));
            movingPulleyCarrierError(row) = norm( ...
                movingCarrier - state.H_B1, "fro");
        else
            movingPulleyCarrierError(row) = inf;
        end

        if fixedPulleyMetadataPass
            fixedCarrier = carrierTransform(state, string(fixedPulley.carrier_group));
            fixedPulleyCarrierError(row) = norm( ...
                fixedCarrier - state.H_B0, "fro");
        else
            fixedPulleyCarrierError(row) = inf;
        end
    end
end

endpointQ1 = q1Deg(:);
endpointTransformError = zeros(n1,1);
endpointOriginError = zeros(n1,1);
endpointAxisError = zeros(n1,1);
for i = 1:n1
    negative = trackerKinematics(model, deg2rad([q1Deg(i);q2Deg(1)]));
    positive = trackerKinematics(model, deg2rad([q1Deg(i);q2Deg(end)]));
    endpointTransformError(i) = norm(negative.H_B2 - positive.H_B2, "fro");
    endpointOriginError(i) = norm(negative.O2 - positive.O2);
    endpointAxisError(i) = norm(negative.e2 - positive.e2);
end

vertexCountsAfter = geometryVertexCounts(model);
[displayTransformAfter, ~] = trackerDisplayTransform(model);

sweep.scope = "P2_DENSE_KINEMATIC_WORKSPACE_ONLY";
sweep.grid.stepDeg = options.StepDeg;
sweep.grid.q1Deg = q1Deg;
sweep.grid.q2Deg = q2Deg;
sweep.grid.q1Count = n1;
sweep.grid.q2Count = n2;
sweep.grid.poseCount = poseCount;

sweep.referencePoints.B1_F0 = pB1Zero;
sweep.referencePoints.B2_F0 = pB2Zero;
sweep.referencePoints.B1RadiusToJ1 = b1RadiusZero;

sweep.pose = table( ...
    q1Column, q2Column, finiteTransformPass, ...
    rotationOrthogonalityError, rotationDeterminantError, ...
    homogeneousBottomRowError, b0Error, b1Q2DependencyError, ...
    b2AtZeroQ2Error, j1OriginError, j1AxisError, ...
    j2OriginTransportError, j2AxisTransportError, ...
    j2Q2OriginError, j2Q2AxisError, ...
    b1AxisRadiusError, b2AxisRadiusError, ...
    movingPulleyCarrierError, fixedPulleyCarrierError, ...
    'VariableNames', { ...
    'q1Deg','q2Deg','finiteTransformPass', ...
    'rotationOrthogonalityError','rotationDeterminantError', ...
    'homogeneousBottomRowError','b0Error','b1Q2DependencyError', ...
    'b2AtZeroQ2Error','j1OriginError','j1AxisError', ...
    'j2OriginTransportError','j2AxisTransportError', ...
    'j2Q2OriginError','j2Q2AxisError', ...
    'b1AxisRadiusError','b2AxisRadiusError', ...
    'movingPulleyCarrierError','fixedPulleyCarrierError'});

sweep.endpointClosure = table( ...
    endpointQ1, endpointTransformError, endpointOriginError, endpointAxisError, ...
    'VariableNames', {'q1Deg','transformError','originError','axisError'});

sweep.auxDrive.movingPulley = "GT2_16T-1";
sweep.auxDrive.movingPulleyExpectedCarrier = "B1";
sweep.auxDrive.movingPulleyMetadataPass = movingPulleyMetadataPass;
sweep.auxDrive.fixedPulley = "GT2_16T-2";
sweep.auxDrive.fixedPulleyExpectedCarrier = "B0";
sweep.auxDrive.fixedPulleyMetadataPass = fixedPulleyMetadataPass;
sweep.auxDrive.localPulleySpinStatus = "UNRESOLVED_NOT_MODELED";
sweep.auxDrive.flexibleBeltMotionStatus = "UNRESOLVED_NOT_MODELED";

sweep.geometry.vertexCountsBefore = vertexCountsBefore;
sweep.geometry.vertexCountsAfter = vertexCountsAfter;
sweep.geometry.vertexCountsUnchanged = isequal(vertexCountsBefore, vertexCountsAfter);

sweep.display.transformBefore = displayTransformBefore;
sweep.display.transformAfter = displayTransformAfter;
sweep.display.transformDriftError = norm( ...
    displayTransformAfter - displayTransformBefore, "fro");

sweep.summary.allTransformsFinite = all(finiteTransformPass);
sweep.summary.maxRotationOrthogonalityError = max(rotationOrthogonalityError);
sweep.summary.maxRotationDeterminantError = max(rotationDeterminantError);
sweep.summary.maxHomogeneousBottomRowError = max(homogeneousBottomRowError);
sweep.summary.maxB0Error = max(b0Error);
sweep.summary.maxB1Q2DependencyError = max(b1Q2DependencyError);
sweep.summary.maxB2AtZeroQ2Error = finiteMax(b2AtZeroQ2Error);
sweep.summary.maxJ1OriginError = max(j1OriginError);
sweep.summary.maxJ1AxisError = max(j1AxisError);
sweep.summary.maxJ2OriginTransportError = max(j2OriginTransportError);
sweep.summary.maxJ2AxisTransportError = max(j2AxisTransportError);
sweep.summary.maxJ2Q2OriginError = max(j2Q2OriginError);
sweep.summary.maxJ2Q2AxisError = max(j2Q2AxisError);
sweep.summary.maxB1AxisRadiusError = max(b1AxisRadiusError);
sweep.summary.maxB2AxisRadiusError = max(b2AxisRadiusError);
sweep.summary.maxMovingPulleyCarrierError = max(movingPulleyCarrierError);
sweep.summary.maxFixedPulleyCarrierError = max(fixedPulleyCarrierError);
sweep.summary.maxQ2EndpointTransformError = max(endpointTransformError);
sweep.summary.maxQ2EndpointOriginError = max(endpointOriginError);
sweep.summary.maxQ2EndpointAxisError = max(endpointAxisError);
sweep.summary.geometryVertexCountsUnchanged = sweep.geometry.vertexCountsUnchanged;
sweep.summary.displayTransformDriftError = sweep.display.transformDriftError;

sweep.collision.status = "NOT_RUN_P3_REQUIRED";
sweep.collision.safeWorkspaceFrozen = false;
end

function grid = makeInclusiveGrid(minimumDeg, maximumDeg, stepDeg)
span = maximumDeg - minimumDeg;
intervalCount = round(span / stepDeg);
if intervalCount < 1 || abs(intervalCount * stepDeg - span) > 1e-9
    error("TrackerPreControl:WorkspaceGridNotDivisible", ...
        "Joint span %.12g deg is not divisible by StepDeg %.12g.", span, stepDeg);
end
grid = minimumDeg + (0:intervalCount) * stepDeg;
grid(1) = minimumDeg;
grid(end) = maximumDeg;
end

function [maxOrthError, maxDetError, maxBottomError] = rigidTransformErrors(transforms)
maxOrthError = 0;
maxDetError = 0;
maxBottomError = 0;
for k = 1:numel(transforms)
    H = transforms{k};
    R = H(1:3,1:3);
    maxOrthError = max(maxOrthError, norm(R.'*R - eye(3), "fro"));
    maxDetError = max(maxDetError, abs(det(R) - 1));
    maxBottomError = max(maxBottomError, norm(H(4,:) - [0 0 0 1]));
end
end

function p = farthestGroupVertexFromAxis(model, groupName, origin, axis)
componentIndices = model.groups.(char(groupName)).componentIndices(:);
axisUnit = axis(:) / norm(axis);
bestDistance = -inf;
p = [];

for componentIndex = componentIndices.'
    geometryIndex = find( ...
        [model.geometry.components.componentIndex] == componentIndex, 1);
    if isempty(geometryIndex)
        error("TrackerPreControl:MissingGroupGeometry", ...
            "No geometry found for component_index %g in group %s.", ...
            componentIndex, groupName);
    end

    vertices = model.geometry.components(geometryIndex).vertices_F0;
    if isempty(vertices)
        continue
    end

    delta = vertices - origin(:).';
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
        "No representative geometry vertex found for rigid group %s.", groupName);
end
end

function item = componentByPath(model, instancePath)
paths = string({model.components.instance_path});
index = find(paths == instancePath);
if numel(index) ~= 1
    error("TrackerPreControl:ComponentLookup", ...
        "Expected exactly one component named %s; found %d.", ...
        instancePath, numel(index));
end
item = model.components(index);
end

function H = carrierTransform(state, carrierGroup)
switch carrierGroup
    case "B0"
        H = state.H_B0;
    case "B1"
        H = state.H_B1;
    case "B2"
        H = state.H_B2;
    otherwise
        error("TrackerPreControl:UnsupportedCarrierGroup", ...
            "Unsupported resolved AUX_DRIVE carrier group: %s.", carrierGroup);
end
end

function counts = geometryVertexCounts(model)
counts = zeros(numel(model.geometry.components),1);
for k = 1:numel(model.geometry.components)
    counts(k) = size(model.geometry.components(k).vertices_F0,1);
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

function value = finiteMax(values)
values = values(isfinite(values));
if isempty(values)
    value = nan;
else
    value = max(values);
end
end
