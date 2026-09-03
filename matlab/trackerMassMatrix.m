function M = trackerMassMatrix(model, q, options)
%TRACKERMASSMATRIX Assemble the 2-by-2 rigid-body mass matrix.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    options.AllowLimitOverride (1,1) logical = false
end

body = trackerRigidBodyState(model, q, ...
    AllowLimitOverride=options.AllowLimitOverride);
M = body.B1.mass * (body.B1.Jv.' * body.B1.Jv) + ...
    body.B1.Jw.' * body.B1.inertiaCom_F0 * body.B1.Jw + ...
    body.B2.mass * (body.B2.Jv.' * body.B2.Jv) + ...
    body.B2.Jw.' * body.B2.inertiaCom_F0 * body.B2.Jw;
M = (M + M.') / 2;
end

