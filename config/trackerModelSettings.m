function settings = trackerModelSettings()
%TRACKERMODELSETTINGS Frozen Model Builder Phase 1 contract settings.

settings.modelSchemaVersion = "TRACKER_MODEL_BUILDER 1.3.0";
settings.schemas.manifest = ["TRACKER_CAD_BRIDGE_EXPORT", "2.0.0"];
settings.schemas.components = ["TRACKER_CAD_BRIDGE_COMPONENTS", "2.0.0"];
settings.schemas.mates = ["TRACKER_CAD_BRIDGE_MATES", "2.0.0"];
settings.seedSchema = ["TRACKER_MODEL_BUILDER_SEED_GROUPS", "1.0.0"];
settings.requiredFiles = ["manifest.json", "components.json", "mates.json", ...
    "geometry_root_triangles.csv"];

settings.baseline.snapshot = "S0_ZERO";
settings.baseline.configuration = "Default";
settings.baseline.componentCount = 40;
settings.baseline.triangleCount = 120724;
settings.baseline.mateCount = 194;
settings.baseline.massPropertyFailures = 0;

settings.tolerance.rotationOrthogonality = 1e-9;
settings.tolerance.rotationDeterminant = 1e-9;
settings.tolerance.inverse = 1e-12;
settings.tolerance.zeroPose = 1e-12;
settings.tolerance.axisAngleDeg = 0.05;
settings.tolerance.axisLineDistanceM = 0.10e-3;

settings.frames.cadDatumName = "Coordinate System1";
% Contract v1.1 correction: Coordinate System1 supplies the F0 origin, but
% CAD-root vectors require this +Y-preserving alignment into analytical F0.
settings.frames.R_F0_from_CadDatum = [ ...
     0.855148048755737, 0,  0.518383848812109; ...
     0,                 1,  0; ...
    -0.518383848812109, 0,  0.855148048755737];
settings.frames.expectedH_F0_from_root = [ ...
     0.855148048755737, 0,  0.518383848812109, 0.00902595703219132; ...
     0,                 1,  0,                 0; ...
    -0.518383848812109, 0,  0.855148048755737, 0.034302134974173; ...
     0,                 0,  0,                 1];
settings.display.R_ground_from_F0 = [ ...
    1, 0,  0; ...
    0, 0, -1; ...
    0, 1,  0];
settings.display.hiddenBelts = [ ...
    "Belt6-1^Measurement_for_math-1"; ...
    "Belt5-22^Measurement_for_math-1"];
settings.frames.R01_0 = [ ...
     0.211323479646670, -0.961986986873070, -0.172983883749019; ...
    -0.642778340193559, -0.003452034841898, -0.766044443118977; ...
     0.736327639253095,  0.273073470960328, -0.619073894724727];
settings.frames.R02_0 = [ ...
    -0.206151147882596, -0.172987479249578, -0.963108008610439; ...
     0.642800970139369, -0.766033232169393,  0.000000000000117; ...
    -0.737772740764102, -0.619086762283761,  0.269115149611528];
settings.frames.r_O1O2_F1 = [ ...
    0.00138114404496322; -0.181104917286779; 0.00298792765545965];

settings.joints.J1.name = "J1";
settings.joints.J1.featureName = "Concentric120";
settings.joints.J1.componentPair = ["03_polemount_6801_v3-1", "6801^Measurement_for_math-1"];
settings.joints.J1.originF0 = [0.046774000133400; 0.206520796479004; 0.168166213948893];
settings.joints.J1.axisF0 = normalizeVector([ ...
    -0.172983883749019; -0.766044443118977; -0.619073894724727]);
settings.joints.J1.originRootReference = [0.005720756; 0.016843849; -0.019244126];
settings.joints.J1.axisRootReference = normalizeVector([-0.172991077592; 0.766044443119; 0.619071884550]);
settings.joints.J1.positiveAxisRoot = normalizeVector([ ...
     0.172991077592195; -0.766044443118977; -0.619071884549790]);
settings.joints.J1.qMin = deg2rad(-100);
settings.joints.J1.qMax = deg2rad(100);

settings.joints.J2.name = "J2";
settings.joints.J2.featureName = "Concentric99";
settings.joints.J2.componentPair = ["u3_drivedisc_DEC_unimount_v3-2", "6001^Measurement_for_math-1"];
settings.joints.J2.originF0 = [0.220769578657278; 0.203969322109821; 0.117878492100684];
settings.joints.J2.axisF0 = normalizeVector([ ...
    -0.963108008610439; 0.000000000000117; 0.269115149611528]);
settings.joints.J2.originRootReference = [-0.03699854; 0.20396932; 0.13240426];
settings.joints.J2.axisRootReference = normalizeVector([-0.963104881333; 0; -0.269126341244]);
settings.joints.J2.positiveAxisRoot = normalizeVector([ ...
    -0.963104881333511; 0.000000000000117; -0.269126341244338]);
settings.joints.J2.qMin = deg2rad(-180);
settings.joints.J2.qMax = deg2rad(180);

settings.auxDrive.carrierAssignments(1).component = "GT2_16T-1";
settings.auxDrive.carrierAssignments(1).carrierGroup = "B1";
settings.auxDrive.carrierAssignments(1).carrierComponent = "Nima 17 40x42x5mm-1";
settings.auxDrive.carrierAssignments(1).mateFeature = "Concentric180";
settings.auxDrive.carrierAssignments(2).component = "GT2_16T-2";
settings.auxDrive.carrierAssignments(2).carrierGroup = "B0";
settings.auxDrive.carrierAssignments(2).carrierComponent = "Nima 17 40x42x5mm-2";
settings.auxDrive.carrierAssignments(2).mateFeature = "Concentric187";
settings.auxDrive.localPulleyMotionPolicy = "unresolved_local_spin";
settings.auxDrive.beltMotionPolicy = "unresolved_belt_deformation";
end

function value = normalizeVector(value)
value = value / norm(value);
end
