function [groups, components] = buildRigidGroups(components, seedFile)
%BUILDRIGIDGROUPS Apply the explicit seed mapping; never infer classifications.

arguments
    components
    seedFile (1,1) string
end
if ~isfile(seedFile)
    error("TrackerModel:MissingSeedMapping", "Seed mapping file is missing: %s", seedFile);
end
seed = jsondecode(fileread(seedFile));
settings = trackerModelSettings();
if string(seed.schema_name) ~= settings.seedSchema(1) || ...
        string(seed.schema_version) ~= settings.seedSchema(2)
    error("TrackerModel:SeedSchemaMismatch", "Seed mapping schema/version is not accepted.");
end

groupNames = ["B0", "B1", "B2", "AUX_DRIVE"];
allMapped = strings(0, 1);
for groupName = groupNames
    source = seed.groups.(groupName);
    members = string(source.components(:));
    groups.(groupName).instancePaths = members;
    groups.(groupName).motionPolicy = string(source.motion_policy);
    allMapped = [allMapped; members]; %#ok<AGROW>
end

if numel(unique(allMapped)) ~= numel(allMapped)
    [uniqueMembers, ~, memberIds] = unique(allMapped);
    memberCounts = accumarray(memberIds, 1);
    duplicates = uniqueMembers(memberCounts > 1);
    error("TrackerModel:DuplicateClassification", ...
        "Components occur in more than one semantic group: %s", strjoin(unique(duplicates), ", "));
end

cadPaths = string({components.instance_path}).';
if numel(unique(cadPaths)) ~= numel(cadPaths)
    error("TrackerModel:DuplicateComponentIdentity", "CAD instance_path values are not unique.");
end
unclassified = setdiff(cadPaths, allMapped, "stable");
removed = setdiff(allMapped, cadPaths, "stable");
if ~isempty(unclassified)
    error("TrackerModel:UnclassifiedComponent", ...
        "Unclassified visible component(s): %s", strjoin(unclassified, ", "));
end
if ~isempty(removed)
    error("TrackerModel:RemovedComponent", ...
        "Seed component(s) absent from CAD export: %s", strjoin(removed, ", "));
end

for groupName = groupNames
    [found, locations] = ismember(groups.(groupName).instancePaths, cadPaths);
    if ~all(found)
        error("TrackerModel:ComponentCoverage", "Semantic group %s is incomplete.", groupName);
    end
    groups.(groupName).componentIndices = double([components(locations).component_index]).';
end

for k = 1:numel(components)
    componentPath = string(components(k).instance_path);
    for groupName = groupNames
        if ismember(componentPath, groups.(groupName).instancePaths)
            components(k).semantic_group = char(groupName);
            components(k).motion_policy = char(groups.(groupName).motionPolicy);
        end
    end
end
end
