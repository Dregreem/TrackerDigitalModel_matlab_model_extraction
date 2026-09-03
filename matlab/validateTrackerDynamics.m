function report = validateTrackerDynamics(model)
%VALIDATETRACKERDYNAMICS Execute deterministic Phase 2A validation gates.

checks = repmat(struct("name", "", "pass", false, "details", ""), 0, 1);
checks(end+1) = makeCheck("Phase 1 prerequisite", model.validation.pass, ...
    "Model Builder validation must remain PASS.");

dynamicsFields = string(fieldnames(model.dynamics));
stopFields = string(fieldnames(model.dynamics.jointStops));
limitNames = ["qMin","qMax","limits","jointLimits"];
singleSource = ~any(ismember(dynamicsFields, limitNames)) && ...
    ~any(ismember(stopFields, limitNames));
checks(end+1) = makeCheck("Joint-limit single source", singleSource, ...
    "Dynamics parameters contain no copied qMin/qMax values.");

projectRoot = fileparts(fileparts(mfilename("fullpath")));
simulinkFiles = [dir(fullfile(projectRoot,"**","*.slx")); ...
    dir(fullfile(projectRoot,"**","*.mdl"))];
checks(end+1) = makeCheck("Simulink/Simscape exclusion", isempty(simulinkFiles), ...
    "No .slx or .mdl artifact exists in the project.");

q1Grid = linspace(model.joints.J1.qMin, model.joints.J1.qMax, 9);
q2Grid = linspace(model.joints.J2.qMin, model.joints.J2.qMax, 9);
minEigenvalue = inf;
minDeterminant = inf;
maxSymmetryError = 0;
for q1 = q1Grid
    for q2 = q2Grid
        M = trackerMassMatrix(model, [q1;q2]);
        minEigenvalue = min(minEigenvalue, min(eig(M)));
        minDeterminant = min(minDeterminant, det(M));
        maxSymmetryError = max(maxSymmetryError, norm(M-M.', "fro"));
    end
end
massPass = minEigenvalue > 0 && minDeterminant > 0 && ...
    maxSymmetryError <= 1e-12;
checks(end+1) = makeCheck("Mass matrix", massPass, sprintf(...
    "min eigenvalue=%.15g, min determinant=%.15g, max symmetry error=%.3g", ...
    minEigenvalue, minDeterminant, maxSymmetryError));

auditQ = [0.31;-0.42];
auditQdot = [0.27;-0.19];
auditQdd = [-0.13;0.22];
auditDisturbance = [0.01;-0.02];
h = 1e-6;
gradientV = zeros(2,1);
for k = 1:2
    step = zeros(2,1);
    step(k) = h;
    plus = trackerEnergy(model, auditQ+step, zeros(2,1), StopModel="none");
    minus = trackerEnergy(model, auditQ-step, zeros(2,1), StopModel="none");
    gradientV(k) = (plus.gravitationalPotential - ...
        minus.gravitationalPotential)/(2*h);
end
G = trackerGravityVector(model, auditQ);
gravityResidual = norm(G-gradientV, inf);
checks(end+1) = makeCheck("Gravity/potential consistency", ...
    gravityResidual <= 1e-7, sprintf("residual=%.15g N m", gravityResidual));

C = trackerCoriolisMatrix(model, auditQ, auditQdot);
Mdot = massDirectionalDerivative(model, auditQ, auditQdot, h);
skewPowerResidual = abs(auditQdot.'*(Mdot-2*C)*auditQdot);
checks(end+1) = makeCheck("Coriolis skew-power identity", ...
    skewPowerResidual <= 1e-8, sprintf("residual=%.15g W", skewPowerResidual));

auditEnergy = trackerEnergy(model,auditQ,auditQdot,StopModel="none");
kineticEnergyResidual = abs(auditEnergy.kinetic - ...
    auditEnergy.kineticViaMassMatrix);
checks(end+1) = makeCheck("Kinetic energy via mass matrix", ...
    kineticEnergyResidual <= 1e-14, sprintf("residual=%.15g J", ...
    kineticEnergyResidual));

[tau, inverseTerms] = trackerInverseDynamics(model, auditQ, auditQdot, ...
    auditQdd, DisturbanceTorque=auditDisturbance, StopModel="none");
[roundTripQdd, forwardTerms] = trackerForwardDynamics(model, auditQ, ...
    auditQdot, tau, DisturbanceTorque=auditDisturbance, StopModel="none");
roundTripResidual = norm(roundTripQdd-auditQdd, inf);
equationResidual = max(norm(inverseTerms.residual,inf), ...
    norm(forwardTerms.residual,inf));
checks(end+1) = makeCheck("Forward/inverse round trip", ...
    roundTripResidual <= 1e-10 && equationResidual <= 1e-10, sprintf(...
    "qdd residual=%.15g, equation residual=%.15g N m", ...
    roundTripResidual, equationResidual));

G0 = trackerGravityVector(model, [0;0]);
[staticQdd, ~] = trackerForwardDynamics(model, [0;0], [0;0], G0, ...
    StopModel="none");
checks(end+1) = makeCheck("Static gravity hold", norm(staticQdd,inf) <= 1e-12, ...
    sprintf("G0=[%.15g; %.15g] N m", G0(1), G0(2)));

[eventValue, isterminal, direction] = trackerJointLimitEvents(model, 0, ...
    [model.joints.J1.qMin;model.joints.J2.qMax;0;0]);
eventPass = eventValue(1) == 0 && eventValue(4) == 0 && ...
    all(isterminal == 1) && all(direction == -1);
checks(end+1) = makeCheck("Numerical joint-limit events", eventPass, ...
    "Four terminal surfaces read qMin/qMax directly from model.joints.");

energyPowerResidual = energyPowerAudit(model, auditQ, auditQdot, tau, ...
    auditDisturbance);
checks(end+1) = makeCheck("Mechanical energy/power balance", ...
    energyPowerResidual <= 2e-5, sprintf("residual=%.15g W", energyPowerResidual));

report.pass = all([checks.pass]);
report.checks = checks;
report.currentRegression.zeroPoseHoldingTorque = G0;
report.currentRegression.minimumMassMatrixEigenvalue = minEigenvalue;
report.currentRegression.minimumMassMatrixDeterminant = minDeterminant;
report.currentRegression.gravityFiniteDifferenceResidual = gravityResidual;
report.currentRegression.skewPowerResidual = skewPowerResidual;
report.currentRegression.kineticEnergyViaMassResidual = kineticEnergyResidual;
report.currentRegression.forwardInverseResidual = roundTripResidual;
report.currentRegression.energyPowerResidual = energyPowerResidual;
report.historicalV1_0.zeroPoseHoldingTorque = ...
    [0.353421363899;-0.016165481861];
report.historicalV1_0.status = "HISTORICAL_ONLY_PRE_V1_1_J1_CORRECTION";
report.assumptions = [ ...
    "B1 and B2 are ideal rigid aggregate bodies."; ...
    "Physical F0 +Y is vertical up and standard gravity is used."; ...
    "Friction, backlash, drive elasticity, and AUX_DRIVE inertia are excluded."];
report.unresolvedItems = [ ...
    "Physical-stop stiffness, damping, impact, and restitution require hardware identification."; ...
    "Motor, gearbox, friction, backlash, cable, and AUX_DRIVE dynamics remain unresolved."; ...
    "Phase 2B trajectory, controller, sizing, time workflow, and CAD animation are not implemented."];
report.generatedAt = string(datetime("now", "TimeZone", "local", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ssXXX"));
end

function Mdot = massDirectionalDerivative(model, q, qdot, h)
Mdot = zeros(2,2);
for k = 1:2
    step = zeros(2,1);
    step(k) = h;
    derivative = (trackerMassMatrix(model,q+step,AllowLimitOverride=true) - ...
        trackerMassMatrix(model,q-step,AllowLimitOverride=true))/(2*h);
    Mdot = Mdot + derivative*qdot(k);
end
end

function residual = energyPowerAudit(model, q, qdot, tau, disturbance)
[qdd, ~] = trackerForwardDynamics(model, q, qdot, tau, ...
    DisturbanceTorque=disturbance, StopModel="none");
direction = [qdot;qdd];
x = [q;qdot];
h = 1e-6;
plus = trackerEnergy(model, x(1:2)+h*direction(1:2), ...
    x(3:4)+h*direction(3:4), StopModel="none");
minus = trackerEnergy(model, x(1:2)-h*direction(1:2), ...
    x(3:4)-h*direction(3:4), StopModel="none");
energyRate = (plus.mechanical-minus.mechanical)/(2*h);
power = trackerPower(model, q, qdot, tau, ...
    DisturbanceTorque=disturbance, StopModel="none");
residual = abs(energyRate-power.mechanicalEnergyRate);
end

function check = makeCheck(name, pass, details)
check.name = string(name);
check.pass = logical(pass);
check.details = string(details);
end
