function C = trackerCoriolisMatrix(model, q, qdot, options)
%TRACKERCORIOLISMATRIX Assemble C(q,qdot) from Christoffel coefficients.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    qdot {mustBeNumeric, mustBeReal}
    options.AllowLimitOverride (1,1) logical = false
end

q = validateVector(q, "q");
qdot = validateVector(qdot, "qdot");
trackerKinematics(model, q, AllowLimitOverride=options.AllowLimitOverride);

h = model.dynamics.massDerivativeStep;
dM = zeros(2,2,2);
for k = 1:2
    step = zeros(2,1);
    step(k) = h;
    plus = trackerMassMatrix(model, q + step, AllowLimitOverride=true);
    minus = trackerMassMatrix(model, q - step, AllowLimitOverride=true);
    dM(:,:,k) = (plus - minus) / (2*h);
end

C = zeros(2,2);
for i = 1:2
    for j = 1:2
        for k = 1:2
            C(i,j) = C(i,j) + 0.5 * (...
                dM(i,j,k) + dM(i,k,j) - dM(j,k,i)) * qdot(k);
        end
    end
end
end

function value = validateVector(value, name)
value = double(value(:));
if numel(value) ~= 2 || any(~isfinite(value))
    error("TrackerDynamics:InvalidState", ...
        "%s must contain two finite real values.", name);
end
end

