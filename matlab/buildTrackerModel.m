function model = buildTrackerModel(cadExportFolder)
%BUILDTRACKERMODEL Build a validated Phase 1 TrackerModel from CAD Bridge V2.

arguments
    cadExportFolder (1,1) string
end
settings = trackerModelSettings();
cad = loadCadBridge(cadExportFolder);

projectRoot = fileparts(fileparts(mfilename("fullpath")));
seedFile = fullfile(projectRoot, "tracker_seed_groups.json");
[groups, components] = buildRigidGroups(cad.components, seedFile);
[groups, components] = buildAuxDriveCarrierMotion(groups, components, ...
    cad.mates, settings);

H_root_from_CadDatum = parseSolidWorksTransform(cad.manifest.F0.mathtransform_native_array);
if rcond(H_root_from_CadDatum) < 1e-12
    error("TrackerModel:F0Malformed", "CAD datum transform is singular or malformed.");
end
H_CadDatum_from_root = H_root_from_CadDatum \ eye(4);
H_F0_from_CadDatum = [settings.frames.R_F0_from_CadDatum, zeros(3,1); 0 0 0 1];
H_F0_from_root = H_F0_from_CadDatum * H_CadDatum_from_root;
H_root_from_F0 = H_F0_from_root \ eye(4);

componentTransforms = repmat(eye(4), 1, 1, numel(components));
for k = 1:numel(components)
    componentTransforms(:, :, k) = parseSolidWorksTransform( ...
        components(k).component_to_assembly_root_native_array);
end

triangleComponentIndex = double(cad.geometryTable.component_index);
triangleRoot = cad.geometryTable{:, 2:10};
knownIndices = double([components.component_index]);
unknownIndices = setdiff(unique(triangleComponentIndex), knownIndices);
if ~isempty(unknownIndices)
    error("TrackerModel:UnknownGeometryComponent", ...
        "Geometry references unknown component_index value(s): %s", ...
        strjoin(string(unknownIndices), ", "));
end

geometryComponents = repmat(struct("componentIndex", [], "instancePath", "", ...
    "vertices_F0", [], "faces", [], "triangleCount", 0), numel(components), 1);
trianglesF0 = convertGeometryRootToF0(triangleRoot, H_F0_from_root);
for k = 1:numel(components)
    componentIndex = double(components(k).component_index);
    selection = triangleComponentIndex == componentIndex;
    actualCount = nnz(selection);
    expectedCount = double(components(k).triangle_count);
    if actualCount ~= expectedCount
        error("TrackerModel:GeometryCountMismatch", ...
            "Component %s reports %d triangles but CSV contains %d.", ...
            string(components(k).instance_path), expectedCount, actualCount);
    end
    componentTriangles = trianglesF0(selection, :);
    geometryComponents(k).componentIndex = componentIndex;
    geometryComponents(k).instancePath = string(components(k).instance_path);
    geometryComponents(k).vertices_F0 = reshape(componentTriangles.', 3, []).';
    geometryComponents(k).faces = reshape(1:(3 * actualCount), 3, []).';
    geometryComponents(k).triangleCount = actualCount;
end

model.meta.schemaVersion = settings.modelSchemaVersion;
model.meta.cadSnapshot = string(cad.manifest.snapshot_label);
model.meta.cadConfiguration = string(cad.manifest.active_configuration);
model.meta.sourceFolder = string(cad.sourceFolder);
model.meta.buildTimestamp = string(datetime("now", "TimeZone", "local", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ssXXX"));
model.frames.H_root_from_F0 = H_root_from_F0;
model.frames.H_F0_from_root = H_F0_from_root;
model.frames.H_root_from_CadDatum = H_root_from_CadDatum;
model.frames.H_CadDatum_from_root = H_CadDatum_from_root;
model.frames.H_F0_from_CadDatum = H_F0_from_CadDatum;
model.frames.R01_0 = settings.frames.R01_0;
model.frames.R02_0 = settings.frames.R02_0;
model.frames.R12_0 = settings.frames.R01_0.' * settings.frames.R02_0;
model.frames.r_O1O2_F1 = settings.frames.r_O1O2_F1;
model.components = components;
model.componentTransforms.H_root_from_component = componentTransforms;
model.geometry.componentIndex = triangleComponentIndex;
model.geometry.triangles_F0 = trianglesF0;
model.geometry.components = geometryComponents;
model.groups = groups;
model.joints = buildJointModel(cad, settings, H_F0_from_root);
model.cadMass.components = extractCadMass(components);
model.cadMass.visibleAssemblyAggregate = cad.manifest.included_visible_part_set_mass_properties;
model.physics = trackerPhysicalParams();
model.dynamics = trackerDynamicsParams();
model.source.manifest = cad.manifest;
model.source.componentDocument = cad.componentDocument;
model.source.mateDocument = cad.mateDocument;
model.status = "WARNING: AUX_DRIVE carrier motion is resolved for GT2_16T-1 " + ...
    "with B1 and GT2_16T-2 with B0. Local pulley spin and flexible-belt " + ...
    "motion remain unresolved; belt meshes are hidden by default.";
model.display.hiddenBelts = settings.display.hiddenBelts;
model.display.framePolicy = "GROUND_ALIGNED_DISPLAY_ONLY";

validation = validateTrackerModel(model);
model.validation.report = validation;
model.validation.pass = validation.pass;
if ~validation.pass
    error("TrackerModel:ValidationFailed", "TrackerModel validation failed.");
end
end

function cadMass = extractCadMass(components)
cadMass = repmat(struct("instancePath", "", "properties", struct()), numel(components), 1);
for k = 1:numel(components)
    cadMass(k).instancePath = string(components(k).instance_path);
    cadMass(k).properties = components(k).mass_properties_assembly_root;
end
end
