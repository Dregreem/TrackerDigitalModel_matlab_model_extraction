classdef testCadSchema < matlab.unittest.TestCase
    methods (Test)
        function expectedV2DocumentsLoad(testCase)
            root = trackerTestRoot();
            addpath(fullfile(root, "config"), fullfile(root, "matlab"));
            cad = loadCadBridge(fullfile(root, "TRACKER_CAD_BRIDGE_V2_20260903_153150"));
            actual = [string(cad.manifest.schema_name), string(cad.manifest.schema_version); ...
                string(cad.componentDocument.schema_name), string(cad.componentDocument.schema_version); ...
                string(cad.mateDocument.schema_name), string(cad.mateDocument.schema_version)];
            expected = ["TRACKER_CAD_BRIDGE_EXPORT", "2.0.0"; ...
                "TRACKER_CAD_BRIDGE_COMPONENTS", "2.0.0"; ...
                "TRACKER_CAD_BRIDGE_MATES", "2.0.0"];
            testCase.verifyEqual(actual, expected);
        end
    end
end
