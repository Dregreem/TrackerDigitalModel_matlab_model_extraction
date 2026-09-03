function revision = compareCadRevision(model, cadExportFolder)
%COMPARECADREVISION Report identity/source/parent/configuration changes only.

cad = loadCadBridge(cadExportFolder);
old = model.components;
new = cad.components;
oldPaths = string({old.instance_path});
newPaths = string({new.instance_path});
revision.added = setdiff(newPaths, oldPaths, "stable");
revision.removed = setdiff(oldPaths, newPaths, "stable");
revision.changedSource = compareField(old, new, oldPaths, newPaths, "source_file");
revision.changedConfiguration = compareField(old, new, oldPaths, newPaths, "referenced_configuration");
revision.changedParent = compareField(old, new, oldPaths, newPaths, "parent_instance_path");
revision.changedTransform = compareNumericField(old, new, oldPaths, newPaths, ...
    "component_to_assembly_root_native_array", 1e-12);
revision.changedMass = compareMass(old, new, oldPaths, newPaths);
revision.changedGeometryTriangleCount = compareNumericField(old, new, oldPaths, newPaths, ...
    "triangle_count", 0);
revision.renamedOrUnmatched = union(revision.added, revision.removed, "stable");
revision.changedMateEvidence = compareJointMates(model.source.mateDocument.mates, cad.mates);
revision.requiresExplicitClassification = ~isempty(revision.added);
end

function changed = compareField(old, new, oldPaths, newPaths, fieldName)
common = intersect(oldPaths, newPaths, "stable");
changed = strings(0,1);
for k = 1:numel(common)
    oldIndex = find(oldPaths == common(k), 1);
    newIndex = find(newPaths == common(k), 1);
    if string(old(oldIndex).(fieldName)) ~= string(new(newIndex).(fieldName))
        changed(end+1,1) = common(k); %#ok<AGROW>
    end
end
end

function changed = compareNumericField(old, new, oldPaths, newPaths, fieldName, tolerance)
common = intersect(oldPaths, newPaths, "stable");
changed = strings(0,1);
for k = 1:numel(common)
    oldIndex = find(oldPaths == common(k), 1);
    newIndex = find(newPaths == common(k), 1);
    oldValue = double(old(oldIndex).(fieldName));
    newValue = double(new(newIndex).(fieldName));
    if ~isequal(size(oldValue), size(newValue)) || ...
            any(abs(oldValue(:) - newValue(:)) > tolerance)
        changed(end+1,1) = common(k); %#ok<AGROW>
    end
end
end

function changed = compareMass(old, new, oldPaths, newPaths)
common = intersect(oldPaths, newPaths, "stable");
changed = strings(0,1);
for k = 1:numel(common)
    oldIndex = find(oldPaths == common(k), 1);
    newIndex = find(newPaths == common(k), 1);
    oldMass = double(old(oldIndex).mass_properties_assembly_root.mass_kg);
    newMass = double(new(newIndex).mass_properties_assembly_root.mass_kg);
    if abs(oldMass - newMass) > 1e-12
        changed(end+1,1) = common(k); %#ok<AGROW>
    end
end
end

function changed = compareJointMates(oldMates, newMates)
jointNames = ["Concentric120", "Concentric99"];
changed = strings(0,1);
for jointName = jointNames
    oldMatch = oldMates(string({oldMates.feature_name}) == jointName);
    newMatch = newMates(string({newMates.feature_name}) == jointName);
    if numel(oldMatch) ~= 1 || numel(newMatch) ~= 1 || ...
            string(jsonencode(oldMatch)) ~= string(jsonencode(newMatch))
        changed(end+1,1) = jointName; %#ok<AGROW>
    end
end
end
