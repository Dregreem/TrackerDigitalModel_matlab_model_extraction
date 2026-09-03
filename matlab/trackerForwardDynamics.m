function [qdd, terms] = trackerForwardDynamics(model, q, qdot, tau, options)
%TRACKERFORWARDDYNAMICS Solve the Phase 2A rigid-body equation for qdd.

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
stopModel = resolveStopModel(model, options.StopModel);

trackerKinematics(model, q, ...
    AllowLimitOverride=options.AllowDiagnosticOverride);
M = trackerMassMatrix(model, q, AllowLimitOverride=true);
C = trackerCoriolisMatrix(model, q, qdot, AllowLimitOverride=true);
G = trackerGravityVector(model, q, AllowLimitOverride=true);
rhs = tau + tauDisturbance - C*qdot - G;
qdd = M \ rhs;

terms.M = M;
terms.C = C;
terms.G = G;
terms.coriolisTorque = C*qdot;
terms.tauActuator = tau;
terms.tauDisturbance = tauDisturbance;
terms.q = q;
terms.stop.status = model.dynamics.jointStops.physicalModelStatus;
terms.stop.eventPolicy = model.dynamics.jointStops.eventPolicy;
terms.rhs = rhs;
terms.residual = M*qdd + C*qdot + G - ...
    tau - tauDisturbance;
terms.stopModel = stopModel;
end

function stopModel = resolveStopModel(model, stopModel)
if stopModel == "default"
    stopModel = string(model.dynamics.jointStops.defaultMode);
end
if ~any(stopModel == ["event","none"])
    error("TrackerDynamics:InvalidStopModel", ...
        "StopModel must be event, none, or default.");
end
end

function value = validateVector(value, name)
value = double(value(:));
if numel(value) ~= 2 || any(~isfinite(value))
    error("TrackerDynamics:InvalidInput", ...
        "%s must contain two finite real values.", name);
end
end
