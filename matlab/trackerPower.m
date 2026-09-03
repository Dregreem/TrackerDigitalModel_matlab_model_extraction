function power = trackerPower(model, q, qdot, tau, options)
%TRACKERPOWER Return Phase 2A generalized power accounting.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    qdot {mustBeNumeric, mustBeReal}
    tau {mustBeNumeric, mustBeReal}
    options.DisturbanceTorque {mustBeNumeric, mustBeReal} = zeros(2,1)
    options.StopModel (1,1) string = "default"
    options.AllowDiagnosticOverride (1,1) logical = false
end

q = validateVector(q, "q");
qdot = validateVector(qdot, "qdot");
tau = validateVector(tau, "tau");
tauDisturbance = validateVector(options.DisturbanceTorque, "DisturbanceTorque");
[~, terms] = trackerForwardDynamics(model, q, qdot, tau, ...
    DisturbanceTorque=tauDisturbance, StopModel=options.StopModel, ...
    AllowDiagnosticOverride=options.AllowDiagnosticOverride);

power.actuator = dot(qdot, tau);
power.disturbance = dot(qdot, tauDisturbance);
power.gravity = -dot(qdot, terms.G);
power.mechanicalEnergyRate = power.actuator + ...
    power.disturbance;
end

function value = validateVector(value, name)
value = double(value(:));
if numel(value) ~= 2 || any(~isfinite(value))
    error("TrackerDynamics:InvalidInput", ...
        "%s must contain two finite real values.", name);
end
end
