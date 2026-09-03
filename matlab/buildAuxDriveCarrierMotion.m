function [groups, components] = buildAuxDriveCarrierMotion(groups, components, mates, settings)
%BUILDAUXDRIVECARRIERMOTION Validate and attach known pulley carrier motion.
% Pulley spin and flexible-belt motion remain unresolved.

assignments = settings.auxDrive.carrierAssignments;
cadPaths = string({components.instance_path}).';
for k = 1:numel(components)
    groupName = string(components(k).semantic_group);
    if groupName == "AUX_DRIVE"
        components(k).carrier_group = 'S0';
        components(k).relative_motion_policy = char(settings.auxDrive.beltMotionPolicy);
    else
        components(k).carrier_group = char(groupName);
        components(k).relative_motion_policy = 'none';
    end
end

carrierMotion = repmat(struct("component", "", "carrierGroup", "", ...
    "carrierComponent", "", "mateFeature", "", "localMotionPolicy", "", ...
    "maxAxisAngleDeg", 0, "axisLineDistanceM", 0), numel(assignments), 1);
for k = 1:numel(assignments)
    assignment = assignments(k);
    component = string(assignment.component);
    carrierGroup = string(assignment.carrierGroup);
    carrierComponent = string(assignment.carrierComponent);
    mateFeature = string(assignment.mateFeature);

    requireMembership(component, groups.AUX_DRIVE.instancePaths, ...
        "assigned pulley", cadPaths);
    requireMembership(carrierComponent, groups.(carrierGroup).instancePaths, ...
        "carrier component", cadPaths);

    mateNames = string({mates.feature_name});
    match = find(mateNames == mateFeature);
    if numel(match) ~= 1
        error("TrackerModel:AuxCarrierEvidenceMissing", ...
            "%s requires exactly one mate named %s; found %d.", ...
            component, mateFeature, numel(match));
    end
    mate = mates(match);
    entityNames = string({mate.entities.reference_component_name});
    expectedPair = [component, carrierComponent];
    if string(mate.mate_type_name) ~= "CONCENTRIC" || ...
            numel(entityNames) ~= 2 || ...
            ~isequal(sort(entityNames), sort(expectedPair))
        error("TrackerModel:AuxCarrierEvidenceInvalid", ...
            "%s must be a two-entity CONCENTRIC mate between %s and %s.", ...
            mateFeature, component, carrierComponent);
    end

    [angleDeg, lineDistanceM] = lineAgreement(mate.entities);
    if angleDeg > settings.tolerance.axisAngleDeg || ...
            lineDistanceM > settings.tolerance.axisLineDistanceM
        error("TrackerModel:AuxCarrierAxisMismatch", ...
            "%s concentric-line mismatch is %.9g deg and %.9g mm.", ...
            mateFeature, angleDeg, lineDistanceM*1e3);
    end

    componentIndex = find(cadPaths == component);
    components(componentIndex).carrier_group = char(carrierGroup);
    components(componentIndex).relative_motion_policy = ...
        char(settings.auxDrive.localPulleyMotionPolicy);
    carrierMotion(k).component = component;
    carrierMotion(k).carrierGroup = carrierGroup;
    carrierMotion(k).carrierComponent = carrierComponent;
    carrierMotion(k).mateFeature = mateFeature;
    carrierMotion(k).localMotionPolicy = settings.auxDrive.localPulleyMotionPolicy;
    carrierMotion(k).maxAxisAngleDeg = angleDeg;
    carrierMotion(k).axisLineDistanceM = lineDistanceM;
end

groups.AUX_DRIVE.motionPolicy = "carrier_resolved_relative_drive_unresolved";
groups.AUX_DRIVE.carrierMotion = carrierMotion;
groups.AUX_DRIVE.beltMotionPolicy = settings.auxDrive.beltMotionPolicy;
end

function requireMembership(name, members, role, cadPaths)
if ~ismember(name, cadPaths) || ~ismember(name, members)
    error("TrackerModel:AuxCarrierClassificationMismatch", ...
        "%s %s is absent from its required explicit group.", role, name);
end
end

function [angleDeg, lineDistanceM] = lineAgreement(entities)
direction1 = double(entities(1).direction_assembly_root(:));
direction2 = double(entities(2).direction_assembly_root(:));
point1 = double(entities(1).point_assembly_root_m(:));
point2 = double(entities(2).point_assembly_root_m(:));
direction1 = direction1/norm(direction1);
direction2 = direction2/norm(direction2);
cosine = min(1,max(0,abs(dot(direction1,direction2))));
angleDeg = rad2deg(acos(cosine));
lineDistanceM = norm(cross(point2-point1,direction1));
end

