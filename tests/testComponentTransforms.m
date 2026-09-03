classdef testComponentTransforms < matlab.unittest.TestCase
    methods (Test)
        function transformsAreProperRigidTransforms(testCase)
            model = trackerTestModel();
            transforms = model.componentTransforms.H_root_from_component;
            errors = arrayfun(@(k) norm(transforms(1:3,1:3,k).' * ...
                transforms(1:3,1:3,k) - eye(3), "fro"), 1:size(transforms,3));
            determinants = arrayfun(@(k) det(transforms(1:3,1:3,k)), 1:size(transforms,3));
            testCase.verifyLessThanOrEqual(max(errors), 1e-9);
            testCase.verifyEqual(determinants, ones(size(determinants)), AbsTol=1e-9);
        end
    end
end
