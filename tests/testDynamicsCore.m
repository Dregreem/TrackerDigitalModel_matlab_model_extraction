classdef testDynamicsCore < matlab.unittest.TestCase
    methods (Test)
        function limitsHaveOneAuthority(testCase)
            model = trackerTestModel();
            testCase.verifyEqual(model.joints.J1.qMin, deg2rad(-100), AbsTol=0);
            testCase.verifyEqual(model.joints.J1.qMax, deg2rad(100), AbsTol=0);
            testCase.verifyEqual(model.joints.J2.qMin, deg2rad(-180), AbsTol=0);
            testCase.verifyEqual(model.joints.J2.qMax, deg2rad(180), AbsTol=0);
            testCase.verifyFalse(any(ismember(string(fieldnames(model.dynamics)), ...
                ["qMin","qMax","limits","jointLimits"])));
        end

        function massMatrixIsSymmetricPositiveDefinite(testCase)
            model = trackerTestModel();
            points = testDynamicsCore.auditGrid(model);
            for k = 1:size(points,2)
                M = trackerMassMatrix(model, points(:,k));
                testCase.verifyEqual(M, M.', AbsTol=1e-12);
                testCase.verifyGreaterThan(min(eig(M)), 0);
            end
        end

        function gravityMatchesPotentialGradient(testCase)
            model = trackerTestModel();
            q = [0.31;-0.42];
            gradient = testDynamicsCore.potentialGradient(model, q);
            testCase.verifyEqual(trackerGravityVector(model,q), gradient, AbsTol=1e-7);
        end

        function coriolisSatisfiesSkewPowerIdentity(testCase)
            model = trackerTestModel();
            q = [0.31;-0.42];
            qdot = [0.27;-0.19];
            C = trackerCoriolisMatrix(model,q,qdot);
            Mdot = testDynamicsCore.massDirectionalDerivative(model,q,qdot);
            residual = qdot.'*(Mdot-2*C)*qdot;
            testCase.verifyEqual(residual, 0, AbsTol=1e-8);
        end

        function forwardInverseRoundTripCloses(testCase)
            model = trackerTestModel();
            q = [0.31;-0.42];
            qdot = [0.27;-0.19];
            qdd = [-0.13;0.22];
            disturbance = [0.01;-0.02];
            tau = trackerInverseDynamics(model,q,qdot,qdd, ...
                DisturbanceTorque=disturbance,StopModel="none");
            result = trackerForwardDynamics(model,q,qdot,tau, ...
                DisturbanceTorque=disturbance,StopModel="none");
            testCase.verifyEqual(result,qdd,AbsTol=1e-10);
        end

        function gravityTorqueHoldsStaticPose(testCase)
            model = trackerTestModel();
            q = [0.2;-0.3];
            G = trackerGravityVector(model,q);
            qdd = trackerDynamics(model,q,[0;0],G,StopModel="none");
            testCase.verifyEqual(qdd,zeros(2,1),AbsTol=1e-12);
        end
    end

    methods (Static, Access=private)
        function points = auditGrid(model)
            q1 = linspace(model.joints.J1.qMin,model.joints.J1.qMax,5);
            q2 = linspace(model.joints.J2.qMin,model.joints.J2.qMax,5);
            [Q1,Q2] = ndgrid(q1,q2);
            points = [Q1(:).';Q2(:).'];
        end

        function gradient = potentialGradient(model,q)
            h = 1e-6;
            gradient = zeros(2,1);
            for k = 1:2
                step = zeros(2,1);
                step(k) = h;
                plus = trackerEnergy(model,q+step,[0;0],StopModel="none");
                minus = trackerEnergy(model,q-step,[0;0],StopModel="none");
                gradient(k) = (plus.gravitationalPotential - ...
                    minus.gravitationalPotential)/(2*h);
            end
        end

        function Mdot = massDirectionalDerivative(model,q,qdot)
            h = model.dynamics.massDerivativeStep;
            Mdot = zeros(2,2);
            for k = 1:2
                step = zeros(2,1);
                step(k) = h;
                derivative = (trackerMassMatrix(model,q+step,AllowLimitOverride=true) - ...
                    trackerMassMatrix(model,q-step,AllowLimitOverride=true))/(2*h);
                Mdot = Mdot + derivative*qdot(k);
            end
        end
    end
end
