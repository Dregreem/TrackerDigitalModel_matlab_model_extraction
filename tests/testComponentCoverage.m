classdef testComponentCoverage < matlab.unittest.TestCase
    methods (Test)
        function everyComponentMappedExactlyOnce(testCase)
            model = trackerTestModel();
            mapped = [model.groups.B0.instancePaths; model.groups.B1.instancePaths; ...
                model.groups.B2.instancePaths; model.groups.AUX_DRIVE.instancePaths];
            cad = string({model.components.instance_path}).';
            testCase.verifyEqual(numel(mapped), 40);
            testCase.verifyEqual(numel(unique(mapped)), 40);
            testCase.verifyEmpty(setxor(mapped, cad));
            testCase.verifyEqual([numel(model.groups.B0.instancePaths), ...
                numel(model.groups.B1.instancePaths), numel(model.groups.B2.instancePaths), ...
                numel(model.groups.AUX_DRIVE.instancePaths)], [17 15 4 4]);
        end

        function auxiliaryDriveStatusIsExplicit(testCase)
            model = trackerTestModel();
            testCase.verifyEqual(string(model.groups.AUX_DRIVE.motionPolicy), ...
                "carrier_resolved_relative_drive_unresolved");
            testCase.verifySubstring(model.status, "Local pulley spin");
        end

        function pulleyCarrierMotionHasCadMateEvidence(testCase)
            model = trackerTestModel();
            carrier = model.groups.AUX_DRIVE.carrierMotion;
            testCase.verifyEqual(string({carrier.component}), ...
                ["GT2_16T-1","GT2_16T-2"]);
            testCase.verifyEqual(string({carrier.carrierGroup}),["B1","B0"]);
            testCase.verifyEqual(string({carrier.carrierComponent}), ...
                ["Nima 17 40x42x5mm-1","Nima 17 40x42x5mm-2"]);
            testCase.verifyEqual(string({carrier.mateFeature}), ...
                ["Concentric180","Concentric187"]);
            testCase.verifyLessThanOrEqual(max([carrier.maxAxisAngleDeg]),0.05);
            testCase.verifyLessThanOrEqual(max([carrier.axisLineDistanceM]),0.10e-3);
        end
    end
end
