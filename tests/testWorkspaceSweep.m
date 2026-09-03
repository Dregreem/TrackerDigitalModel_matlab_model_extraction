classdef testWorkspaceSweep < matlab.unittest.TestCase
    %TESTWORKSPACESWEEP P2 deterministic 2993-pose dense workspace audit.

    properties
        Model
        Sweep
        Report
    end

    methods (TestClassSetup)
        function buildDenseSweep(testCase)
            testCase.Model = trackerTestModel();
            testCase.Sweep = trackerWorkspaceSweep(testCase.Model);
            testCase.Report = validateTrackerWorkspace(testCase.Model);
        end
    end

    methods (Test)
        function defaultGridCoversConfiguredLimitsExactly(testCase)
            sweep = testCase.Sweep;
            model = testCase.Model;

            testCase.verifyEqual(sweep.grid.stepDeg, 5, AbsTol=0);
            testCase.verifyEqual(sweep.grid.q1Count, 41);
            testCase.verifyEqual(sweep.grid.q2Count, 73);
            testCase.verifyEqual(sweep.grid.poseCount, 2993);

            testCase.verifyEqual(sweep.grid.q1Deg(1), ...
                rad2deg(model.joints.J1.qMin), AbsTol=1e-12);
            testCase.verifyEqual(sweep.grid.q1Deg(end), ...
                rad2deg(model.joints.J1.qMax), AbsTol=1e-12);
            testCase.verifyEqual(sweep.grid.q2Deg(1), ...
                rad2deg(model.joints.J2.qMin), AbsTol=1e-12);
            testCase.verifyEqual(sweep.grid.q2Deg(end), ...
                rad2deg(model.joints.J2.qMax), AbsTol=1e-12);
        end

        function everyDensePosePassesKinematicAcceptance(testCase)
            report = testCase.Report;

            testCase.verifyTrue(report.pass);
            testCase.verifyEqual(report.failedPoseCount, 0);
            testCase.verifyEqual(height(report.sweep.pose), 2993);
            testCase.verifyTrue(all(report.sweep.pose.pass));
        end

        function denseSweepPreservesRigidMotionInvariants(testCase)
            s = testCase.Report.summary;
            tol = testCase.Report.tolerances;

            testCase.verifyTrue(s.allTransformsFinite);
            testCase.verifyLessThanOrEqual( ...
                s.maxRotationOrthogonalityError, tol.rotationOrthogonality);
            testCase.verifyLessThanOrEqual( ...
                s.maxRotationDeterminantError, tol.rotationDeterminant);
            testCase.verifyLessThanOrEqual(s.maxB0Error, tol.rigidBase);
            testCase.verifyLessThanOrEqual( ...
                s.maxB1Q2DependencyError, tol.hierarchy);
            testCase.verifyLessThanOrEqual( ...
                s.maxB2AtZeroQ2Error, tol.hierarchy);
            testCase.verifyLessThanOrEqual( ...
                s.maxJ2OriginTransportError, tol.jointTransport);
            testCase.verifyLessThanOrEqual( ...
                s.maxJ2AxisTransportError, tol.jointTransport);
            testCase.verifyLessThanOrEqual( ...
                s.maxB1AxisRadiusError, tol.axisRadius);
            testCase.verifyLessThanOrEqual( ...
                s.maxB2AxisRadiusError, tol.axisRadius);
        end

        function endpointAndCarrierInvariantsPassAcrossGrid(testCase)
            report = testCase.Report;
            s = report.summary;
            tol = report.tolerances;

            testCase.verifyTrue(report.sweep.auxDrive.movingPulleyMetadataPass);
            testCase.verifyTrue(report.sweep.auxDrive.fixedPulleyMetadataPass);
            testCase.verifyLessThanOrEqual( ...
                s.maxMovingPulleyCarrierError, tol.carrier);
            testCase.verifyLessThanOrEqual( ...
                s.maxFixedPulleyCarrierError, tol.carrier);
            testCase.verifyLessThanOrEqual( ...
                s.maxQ2EndpointTransformError, tol.endpointClosure);
            testCase.verifyLessThanOrEqual( ...
                s.maxQ2EndpointOriginError, tol.endpointClosure);
            testCase.verifyLessThanOrEqual( ...
                s.maxQ2EndpointAxisError, tol.endpointClosure);
        end

        function p2CannotFreezeMechanicalSafeWorkspace(testCase)
            report = testCase.Report;

            testCase.verifyFalse(report.preControlGatePass);
            testCase.verifyFalse(report.safeOperatingEnvelopeFrozen);
            testCase.verifyEqual(report.collisionStatus, ...
                "PENDING_P3_COLLISION_INTERFERENCE_AUDIT");
            testCase.verifyEqual(report.nextRequiredPhase, ...
                "P3_COLLISION_INTERFERENCE_AUDIT");
            testCase.verifyEqual( ...
                report.sweep.auxDrive.localPulleySpinStatus, ...
                "UNRESOLVED_NOT_MODELED");
            testCase.verifyEqual( ...
                report.sweep.auxDrive.flexibleBeltMotionStatus, ...
                "UNRESOLVED_NOT_MODELED");
        end
    end
end
