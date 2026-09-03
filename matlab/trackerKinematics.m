function state = trackerKinematics(model, q, options)
%TRACKERKINEMATICS Return Phase 1 pose transforms using radians.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    options.AllowLimitOverride (1,1) logical = false
end
q = double(q(:));
if numel(q) ~= 2 || any(~isfinite(q))
    error("TrackerModel:InvalidJointState", "q must contain two finite angles in radians.");
end
limits = [model.joints.J1.qMin, model.joints.J1.qMax; ...
          model.joints.J2.qMin, model.joints.J2.qMax];
if ~options.AllowLimitOverride && any(q < limits(:,1) | q > limits(:,2))
    limitsDeg = rad2deg(limits);
    error("TrackerModel:JointLimit", ...
        "Joint command is outside q1=[%.12g,%.12g] deg or q2=[%.12g,%.12g] deg.", ...
        limitsDeg(1,1),limitsDeg(1,2),limitsDeg(2,1),limitsDeg(2,2));
end

H_J1 = axisRotationAboutPoint(model.joints.J1.axis_F0, model.joints.J1.origin_F0, q(1));
H_J2_zero = axisRotationAboutPoint(model.joints.J2.axis_F0, model.joints.J2.origin_F0, q(2));

state.q = q;
state.H_B0 = eye(4);
state.H_B1 = H_J1;
state.H_B2 = H_J1 * H_J2_zero;
state.O1 = model.joints.J1.origin_F0;
state.e1 = model.joints.J1.axis_F0;
state.O2 = applyPoint(H_J1, model.joints.J2.origin_F0);
state.e2 = H_J1(1:3,1:3) * model.joints.J2.axis_F0;
state.auxDriveMotionResolved = false;
end

function H = axisRotationAboutPoint(axis, origin, angle)
axis = axis(:) / norm(axis);
K = [0, -axis(3), axis(2); axis(3), 0, -axis(1); -axis(2), axis(1), 0];
R = eye(3) + sin(angle) * K + (1 - cos(angle)) * (K * K);
H = [R, origin(:) - R * origin(:); 0 0 0 1];
end

function point = applyPoint(H, point)
value = H * [point(:); 1];
point = value(1:3);
end
