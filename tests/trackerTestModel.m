function model = trackerTestModel()
%TRACKERTESTMODEL Build the reference model once per MATLAB process.
persistent cachedModel
if isempty(cachedModel)
    root = trackerTestRoot();
    addpath(fullfile(root, "config"), fullfile(root, "matlab"));
    cachedModel = buildTrackerModel(fullfile(root, "TRACKER_CAD_BRIDGE_V2_20260903_153150"));
end
model = cachedModel;
end
