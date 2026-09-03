function cad = loadCadBridge(cadExportFolder)
%LOADCADBRIDGE Load and hard-validate one Tracker CAD Bridge V2 export.

arguments
    cadExportFolder (1,1) string
end
settings = trackerModelSettings();
if ~isfolder(cadExportFolder)
    error("TrackerModel:MissingCadFolder", "CAD export folder does not exist: %s", cadExportFolder);
end
for fileName = settings.requiredFiles
    filePath = fullfile(cadExportFolder, fileName);
    if ~isfile(filePath)
        error("TrackerModel:MissingCadFile", "Required CAD Bridge file is missing: %s", filePath);
    end
end

cad.sourceFolder = char(java.io.File(cadExportFolder).getCanonicalPath());
cad.manifest = jsondecode(fileread(fullfile(cadExportFolder, "manifest.json")));
cad.componentDocument = jsondecode(fileread(fullfile(cadExportFolder, "components.json")));
cad.mateDocument = jsondecode(fileread(fullfile(cadExportFolder, "mates.json")));

requireFields(cad.manifest, ["schema_name","schema_version","active_configuration", ...
    "snapshot_label","scope_contract","geometry","assembly_relations","F0","counts", ...
    "included_visible_part_set_mass_properties"], "manifest");
requireFields(cad.componentDocument, ["schema_name","schema_version","primary_identity_key", ...
    "transform_convention","components"], "components");
requireFields(cad.mateDocument, ["schema_name","schema_version","assembly_level", ...
    "active_configuration","entity_parameter_frame","mates"], "mates");
validateSchema(cad.manifest, settings.schemas.manifest, "manifest");
validateSchema(cad.componentDocument, settings.schemas.components, "components");
validateSchema(cad.mateDocument, settings.schemas.mates, "mates");

if string(cad.componentDocument.primary_identity_key) ~= "instance_path"
    error("TrackerModel:SchemaMismatch", "components primary identity must be instance_path.");
end
if string(cad.manifest.F0.name) ~= settings.frames.cadDatumName
    error("TrackerModel:F0Mismatch", "Expected CAD datum = Coordinate System1.");
end

components = cad.componentDocument.components;
componentRequired = ["component_index","instance_path","name","source_file", ...
    "referenced_configuration","parent_instance_path","included_in_visualization", ...
    "included_in_dynamics_scope","is_suppressed","is_hidden","triangle_count", ...
    "component_to_assembly_root_native_array","mass_properties_assembly_root"];
for k = 1:numel(components)
    requireFields(components(k), componentRequired, "component");
end
componentIndices = double([components.component_index]);
if numel(unique(componentIndices)) ~= numel(componentIndices)
    error("TrackerModel:DuplicateComponentIndex", ...
        "component_index must resolve to exactly one component within an export.");
end
insideScope = arrayfun(@(x) logical(x.included_in_visualization) && ...
    logical(x.included_in_dynamics_scope) && ~logical(x.is_suppressed) && ...
    ~logical(x.is_hidden), components);
if ~all(insideScope)
    error("TrackerModel:ScopeMismatch", ...
        "Every exported component must be visible, unsuppressed, and included in both declared scopes.");
end

mates = cad.mateDocument.mates;
for k = 1:numel(mates)
    requireFields(mates(k), ["mate_index","feature_name","mate_type_name", ...
        "entity_count","entities"], "mate");
end

opts = detectImportOptions(fullfile(cadExportFolder, "geometry_root_triangles.csv"), ...
    "FileType", "text");
opts.VariableNamingRule = "preserve";
cad.geometryTable = readtable(fullfile(cadExportFolder, "geometry_root_triangles.csv"), opts);
expectedColumns = ["component_index","x1","y1","z1","x2","y2","z2","x3","y3","z3"];
if ~isequal(string(cad.geometryTable.Properties.VariableNames), expectedColumns)
    error("TrackerModel:SchemaMismatch", "Geometry CSV columns do not match the V2 schema.");
end
cad.components = components;
cad.mates = mates;
end

function validateSchema(document, expected, label)
if string(document.schema_name) ~= expected(1) || string(document.schema_version) ~= expected(2)
    error("TrackerModel:SchemaMismatch", ...
        "%s schema must be %s %s; found %s %s.", label, expected(1), expected(2), ...
        string(document.schema_name), string(document.schema_version));
end
end

function requireFields(value, names, label)
present = string(fieldnames(value));
missing = names(~ismember(names, present));
if ~isempty(missing)
    error("TrackerModel:SchemaMismatch", "%s is missing required field(s): %s", ...
        label, strjoin(missing, ", "));
end
end
