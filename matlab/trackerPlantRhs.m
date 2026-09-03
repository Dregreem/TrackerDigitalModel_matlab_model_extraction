function [xdot, terms] = trackerPlantRhs(t, x, model, tauInput, options)
%TRACKERPLANTRHS ODE right-hand side without trajectory or controller logic.

arguments
    t (1,1) double {mustBeFinite}
    x {mustBeNumeric, mustBeReal}
    model (1,1) struct
    tauInput
    options.DisturbanceTorque = zeros(2,1)
    options.StopModel (1,1) string = "default"
    options.AllowDiagnosticOverride (1,1) logical = false
end

x = double(x(:));
if numel(x) ~= 4 || any(~isfinite(x))
    error("TrackerDynamics:InvalidOdeState", ...
        "ODE state must be [q1;q2;q1dot;q2dot] with finite values.");
end
tau = evaluateInput(tauInput, t, x, "tauInput");
tauDisturbance = evaluateInput(options.DisturbanceTorque, t, x, ...
    "DisturbanceTorque");
[qdd, terms] = trackerDynamics(model, x(1:2), x(3:4), tau, ...
    DisturbanceTorque=tauDisturbance, StopModel=options.StopModel, ...
    AllowDiagnosticOverride=options.AllowDiagnosticOverride);
xdot = [x(3:4); qdd];
end

function value = evaluateInput(input, t, x, name)
if isa(input, "function_handle")
    value = input(t, x);
else
    value = input;
end
value = double(value(:));
if numel(value) ~= 2 || any(~isfinite(value))
    error("TrackerDynamics:InvalidInput", ...
        "%s must return two finite real values.", name);
end
end

