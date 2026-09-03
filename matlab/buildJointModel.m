function joints = buildJointModel(cad, settings, H_F0_from_root)
%BUILDJOINTMODEL Build frozen J1/J2 definitions after CAD evidence validates.

joints.J1 = buildOneJoint(cad.mates, settings.joints.J1, ...
    settings.tolerance, H_F0_from_root);
joints.J2 = buildOneJoint(cad.mates, settings.joints.J2, ...
    settings.tolerance, H_F0_from_root);
end

function joint = buildOneJoint(mates, reference, tolerance, H_F0_from_root)
mateNames = string({mates.feature_name});
match = find(mateNames == reference.featureName);
if numel(match) ~= 1
    error("TrackerModel:JointEvidenceMissing", ...
        "%s requires exactly one mate named %s; found %d.", ...
        reference.name, reference.featureName, numel(match));
end
mate = mates(match);
if string(mate.mate_type_name) ~= "CONCENTRIC" || numel(mate.entities) ~= 2
    error("TrackerModel:JointEvidenceInvalid", ...
        "%s evidence must be a two-entity CONCENTRIC mate.", reference.name);
end

entityNames = string({mate.entities.reference_component_name});
if ~isequal(sort(entityNames), sort(reference.componentPair))
    error("TrackerModel:JointEvidenceInvalid", ...
        "%s mate connects an unexpected component pair.", reference.name);
end

angles = zeros(1, numel(mate.entities));
distances = zeros(1, numel(mate.entities));
f0Angles = zeros(1, numel(mate.entities));
f0Distances = zeros(1, numel(mate.entities));
for k = 1:numel(mate.entities)
    entity = mate.entities(k);
    direction = double(entity.direction_assembly_root(:));
    point = double(entity.point_assembly_root_m(:));
    if numel(direction) ~= 3 || numel(point) ~= 3 || norm(direction) < eps
        error("TrackerModel:JointEvidenceInvalid", "%s mate entity has malformed line data.", reference.name);
    end
    direction = direction / norm(direction);
    cosine = min(1, max(0, abs(dot(direction, reference.axisRootReference))));
    angles(k) = rad2deg(acos(cosine));
    distances(k) = norm(cross(point - reference.originRootReference, reference.axisRootReference));
    pointF0 = H_F0_from_root * [point; 1];
    directionF0 = H_F0_from_root(1:3,1:3) * direction;
    directionF0 = directionF0 / norm(directionF0);
    f0Cosine = min(1, max(0, abs(dot(directionF0, reference.axisF0))));
    f0Angles(k) = rad2deg(acos(f0Cosine));
    f0Distances(k) = norm(cross(pointF0(1:3) - reference.originF0, reference.axisF0));
end

maxAngle = max(angles);
maxDistance = max(distances);
if maxAngle > tolerance.axisAngleDeg
    error("TrackerModel:JointAxisMismatch", ...
        "%s CAD mate axis differs from the validated motion axis by %.9g deg.", reference.name, maxAngle);
end
if maxDistance > tolerance.axisLineDistanceM
    error("TrackerModel:JointLineMismatch", ...
        "%s CAD mate line differs from the validated motion line by %.9g mm.", ...
        reference.name, maxDistance * 1e3);
end
maxF0Angle = max(f0Angles);
maxF0Distance = max(f0Distances);
if maxF0Angle > tolerance.axisAngleDeg
    error("TrackerModel:JointAxisMismatch", ...
        "%s CAD mate axis transformed to F0 differs by %.9g deg.", reference.name, maxF0Angle);
end
if maxF0Distance > tolerance.axisLineDistanceM
    error("TrackerModel:JointLineMismatch", ...
        "%s CAD mate line transformed to F0 differs by %.9g mm.", ...
        reference.name, maxF0Distance * 1e3);
end

joint.origin_F0 = reference.originF0;
joint.axis_F0 = reference.axisF0;
joint.qMin = reference.qMin;
joint.qMax = reference.qMax;
joint.validated = true;
joint.cadEvidence.featureName = reference.featureName;
joint.cadEvidence.componentPair = reference.componentPair;
joint.cadEvidence.maxAngularMismatchDeg = maxAngle;
joint.cadEvidence.maxLineDistanceM = maxDistance;
joint.cadEvidence.maxF0AngularMismatchDeg = maxF0Angle;
joint.cadEvidence.maxF0LineDistanceM = maxF0Distance;
end
