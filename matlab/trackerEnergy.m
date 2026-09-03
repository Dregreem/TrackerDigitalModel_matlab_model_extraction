function energy = trackerEnergy(model, q, qdot, options)
%TRACKERENERGY Return kinetic, gravitational, stop, and total energy.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    qdot {mustBeNumeric, mustBeReal}
    options.StopModel (1,1) string = "default"
    options.AllowDiagnosticOverride (1,1) logical = false
end

q = validateVector(q, "q");
qdot = validateVector(qdot, "qdot");
resolveStopModel(model, options.StopModel);
trackerKinematics(model, q, ...
    AllowLimitOverride=options.AllowDiagnosticOverride);

body = trackerRigidBodyState(model, q, AllowLimitOverride=true);
M = trackerMassMatrix(model, q, AllowLimitOverride=true);
up = model.dynamics.upAxis_F0(:);
g = model.dynamics.gravity;
v1 = body.B1.Jv*qdot;
w1 = body.B1.Jw*qdot;
v2 = body.B2.Jv*qdot;
w2 = body.B2.Jw*qdot;
energy.kinetic = 0.5*body.B1.mass*dot(v1,v1) + ...
    0.5*w1.'*body.B1.inertiaCom_F0*w1 + ...
    0.5*body.B2.mass*dot(v2,v2) + ...
    0.5*w2.'*body.B2.inertiaCom_F0*w2;
energy.kineticViaMassMatrix = 0.5 * qdot.' * M * qdot;
energy.gravitationalPotential = g * (...
    body.B1.mass * dot(up, body.B1.com_F0) + ...
    body.B2.mass * dot(up, body.B2.com_F0));
energy.mechanical = energy.kinetic + energy.gravitationalPotential;
end

function stopModel = resolveStopModel(model, stopModel)
if stopModel == "default"
    stopModel = string(model.dynamics.jointStops.defaultMode);
end
if ~any(stopModel == ["event","none"])
    error("TrackerDynamics:InvalidStopModel", "Invalid StopModel value.");
end
end

function value = validateVector(value, name)
value = double(value(:));
if numel(value) ~= 2 || any(~isfinite(value))
    error("TrackerDynamics:InvalidInput", ...
        "%s must contain two finite real values.", name);
end
end
