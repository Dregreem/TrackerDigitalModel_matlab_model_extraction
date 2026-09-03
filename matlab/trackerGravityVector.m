function G = trackerGravityVector(model, q, options)
%TRACKERGRAVITYVECTOR Return dVg/dq for physical F0 +Y upward.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    options.AllowLimitOverride (1,1) logical = false
end

body = trackerRigidBodyState(model, q, ...
    AllowLimitOverride=options.AllowLimitOverride);
up = model.dynamics.upAxis_F0(:);
g = model.dynamics.gravity;
G = body.B1.mass * g * body.B1.Jv.' * up + ...
    body.B2.mass * g * body.B2.Jv.' * up;
end

