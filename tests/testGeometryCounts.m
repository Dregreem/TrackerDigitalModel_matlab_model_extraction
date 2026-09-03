classdef testGeometryCounts < matlab.unittest.TestCase
    methods (Test)
        function baselineAndPerComponentCountsMatch(testCase)
            model = trackerTestModel();
            expected = double([model.components.triangle_count]).';
            actual = double([model.geometry.components.triangleCount]).';
            testCase.verifyEqual(size(model.geometry.triangles_F0, 1), 120724);
            testCase.verifyEqual(actual, expected);
            testCase.verifyEqual(sum(actual), 120724);
        end

        function everyGeometryIndexResolves(testCase)
            model = trackerTestModel();
            actual = unique(model.geometry.componentIndex);
            expected = sort(double([model.components.component_index]).');
            testCase.verifyEqual(sort(actual), expected);
        end
    end
end
