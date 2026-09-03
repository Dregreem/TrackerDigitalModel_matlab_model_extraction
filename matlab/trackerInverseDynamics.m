function [tau, terms] = trackerInverseDynamics(model, q, qdot, qdd, options)
%TRACKERINVERSEDYNAMICS Return actuator torque for a requested acceleration.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    qdot {mustBeNumeric, mustBeReal}
    qdd {mustBeNumeric, mustBeReal}
    options.DisturbanceTorque {mustBeNumeric, mustBeReal} = zeros(2,1)
    options.StopModel (1,1) string = "default"
    options.AllowDiagnosticOverride (1,1) logical = false
end

q = validateVector(q, "q");
qdot = validateVector(qdot, "qdot");
qdd = validateVector(qdd, "qdd");
tauDisturbance = validateVector(options.DisturbanceTorque, "DisturbanceTorque");

% A zero actuator call obtains exactly the same equation terms and stop policy
% as forward dynamics; the actuator result is then solved algebraically.
[~, base] = trackerForwardDynamics(model, q, qdot, zeros(2,1), ...
    DisturbanceTorque=tauDisturbance, StopModel=options.StopModel, ...
    AllowDiagnosticOverride=options.AllowDiagnosticOverride);
tau = base.M*qdd + base.C*qdot + base.G - ...
    tauDisturbance;
terms = base;
terms.tauActuator = tau;
terms.rhs = tau + tauDisturbance - ...
    terms.C*qdot - terms.G;
terms.residual = terms.M*qdd + terms.C*qdot + terms.G - ...
    tau - tauDisturbance;
end

function value = validateVector(value, name)
value = double(value(:));
if numel(value) ~= 2 || any(~isfinite(value))
    error("TrackerDynamics:InvalidInput", ...
        "%s must contain two finite real values.", name);
end
end
