classdef testEnergyPower < matlab.unittest.TestCase
    methods (Test)
        function kineticEnergyUsesMassMatrix(testCase)
            model = trackerTestModel();
            q = [-0.4;0.7];
            qdot = [0.8;-0.5];
            energy = trackerEnergy(model,q,qdot,StopModel="none");
            expected = 0.5*qdot.'*trackerMassMatrix(model,q)*qdot;
            testCase.verifyEqual(energy.kinetic,expected,AbsTol=1e-14);
        end

        function mechanicalEnergyRateMatchesInputPower(testCase)
            model = trackerTestModel();
            q = [0.31;-0.42];
            qdot = [0.27;-0.19];
            tau = [0.2;-0.1];
            disturbance = [0.01;-0.02];
            residual = testEnergyPower.energyPowerResidual(...
                model,q,qdot,tau,disturbance);
            testCase.verifyEqual(residual,0,AbsTol=2e-5);
        end

        function odeRhsContainsNoControllerLogic(testCase)
            model = trackerTestModel();
            x = [0.1;-0.2;0.3;-0.4];
            [xdot,terms] = trackerPlantRhs(0,x,model,[0.2;-0.1], ...
                StopModel="none");
            testCase.verifyEqual(xdot(1:2),x(3:4),AbsTol=0);
            testCase.verifyEqual(xdot(3:4),terms.M\terms.rhs,AbsTol=1e-14);
        end
    end

    methods (Static, Access=private)
        function residual = energyPowerResidual(model,q,qdot,tau,disturbance)
            qdd = trackerDynamics(model,q,qdot,tau, ...
                DisturbanceTorque=disturbance,StopModel="none");
            direction = [qdot;qdd];
            x = [q;qdot];
            h = 1e-6;
            plus = trackerEnergy(model,x(1:2)+h*direction(1:2), ...
                x(3:4)+h*direction(3:4),StopModel="none");
            minus = trackerEnergy(model,x(1:2)-h*direction(1:2), ...
                x(3:4)-h*direction(3:4),StopModel="none");
            energyRate = (plus.mechanical-minus.mechanical)/(2*h);
            power = trackerPower(model,q,qdot,tau, ...
                DisturbanceTorque=disturbance,StopModel="none");
            residual = energyRate-power.mechanicalEnergyRate;
        end
    end
end

