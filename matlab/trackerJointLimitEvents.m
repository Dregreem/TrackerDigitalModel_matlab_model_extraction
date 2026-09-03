function [value, isterminal, direction] = trackerJointLimitEvents(model, ~, x)
%TRACKERJOINTLIMITEVENTS Terminal event surfaces for four model-owned limits.

arguments
    model (1,1) struct
    ~
    x {mustBeNumeric, mustBeReal}
end
x = double(x(:));
if numel(x) ~= 4 || any(~isfinite(x))
    error("TrackerDynamics:InvalidOdeState", ...
        "ODE state must be [q1;q2;q1dot;q2dot] with finite values.");
end
q = x(1:2);
limits = [model.joints.J1.qMin, model.joints.J1.qMax; ...
          model.joints.J2.qMin, model.joints.J2.qMax];
value = [q(1) - limits(1,1); limits(1,2) - q(1); ...
         q(2) - limits(2,1); limits(2,2) - q(2)];
isterminal = ones(4,1);
direction = -ones(4,1);
end

