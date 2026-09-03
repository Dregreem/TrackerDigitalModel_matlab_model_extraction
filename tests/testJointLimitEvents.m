classdef testJointLimitEvents < matlab.unittest.TestCase
    methods (Test)
        function eventSurfacesComeFromModelLimits(testCase)
            model = trackerTestModel();
            x = [model.joints.J1.qMin;model.joints.J2.qMax;0;0];
            [value,isterminal,direction] = trackerJointLimitEvents(model,0,x);
            testCase.verifyEqual(value([1,4]),[0;0],AbsTol=0);
            testCase.verifyGreaterThan(value(2),0);
            testCase.verifyGreaterThan(value(3),0);
            testCase.verifyEqual(isterminal,ones(4,1));
            testCase.verifyEqual(direction,-ones(4,1));
        end

        function eventModeRejectsOutOfRangeStateWithoutClamp(testCase)
            model = trackerTestModel();
            q = [model.joints.J1.qMax+1e-6;0];
            testCase.verifyError(@() trackerDynamics(model,q,[0;0],[0;0], ...
                StopModel="event"),"TrackerModel:JointLimit");
        end

        function physicalStopParametersAreNotInvented(testCase)
            model = trackerTestModel();
            fields = string(fieldnames(model.dynamics.jointStops));
            testCase.verifyFalse(any(ismember(fields, ...
                ["stiffness","damping","restitution","impact"])));
            testCase.verifyEqual(model.dynamics.jointStops.physicalModelStatus, ...
                "UNRESOLVED_NOT_MODELED");
        end

        function diagnosticOverrideDoesNotClampState(testCase)
            model = trackerTestModel();
            q = [model.joints.J1.qMax+1e-3;0];
            [~,terms] = trackerDynamics(model,q,[0;0],[0;0], ...
                StopModel="none",AllowDiagnosticOverride=true);
            testCase.verifyEqual(terms.q,q,AbsTol=0);
        end

        function ode45TerminatesAtUpperLimit(testCase)
            model = trackerTestModel();
            x0 = [deg2rad(99);0;deg2rad(2);0];
            options = odeset("Events",@(t,x) trackerJointLimitEvents(model,t,x));
            [~,~,te,ye,ie] = ode45(@testJointLimitEvents.constantVelocityRhs, ...
                [0,2],x0,options);
            testCase.verifyNotEmpty(te);
            testCase.verifyEqual(ie(end),2);
            testCase.verifyEqual(ye(end,1),model.joints.J1.qMax,AbsTol=1e-9);
        end
    end

    methods (Static, Access=private)
        function xdot = constantVelocityRhs(~,x)
            xdot = [x(3:4);0;0];
        end
    end
end
