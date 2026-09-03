classdef testCadRevision < matlab.unittest.TestCase
    methods (Test)
        function acceptedExportHasNoRevisionDifferences(testCase)
            model = trackerTestModel();
            revision = compareCadRevision(model, model.meta.sourceFolder);
            testCase.verifyEmpty(revision.added);
            testCase.verifyEmpty(revision.removed);
            testCase.verifyEmpty(revision.changedSource);
            testCase.verifyEmpty(revision.changedConfiguration);
            testCase.verifyEmpty(revision.changedParent);
            testCase.verifyEmpty(revision.changedTransform);
            testCase.verifyEmpty(revision.changedMass);
            testCase.verifyEmpty(revision.changedGeometryTriangleCount);
            testCase.verifyEmpty(revision.changedMateEvidence);
            testCase.verifyFalse(revision.requiresExplicitClassification);
        end
    end
end
