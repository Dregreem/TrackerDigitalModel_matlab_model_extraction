function [qdd, terms] = trackerDynamics(model, q, qdot, tau, options)
%TRACKERDYNAMICS Compact Phase 2A forward-dynamics entry point.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    qdot {mustBeNumeric, mustBeReal}
    tau {mustBeNumeric, mustBeReal}
    options.DisturbanceTorque {mustBeNumeric, mustBeReal} = zeros(2,1)
    options.StopModel (1,1) string = "default"
    options.AllowDiagnosticOverride (1,1) logical = false
end

[qdd, terms] = trackerForwardDynamics(model, q, qdot, tau, ...
    DisturbanceTorque=options.DisturbanceTorque, ...
    StopModel=options.StopModel, ...
    AllowDiagnosticOverride=options.AllowDiagnosticOverride);
end

