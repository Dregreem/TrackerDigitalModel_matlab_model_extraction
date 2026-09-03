function body = trackerRigidBodyState(model, q, options)
%TRACKERRIGIDBODYSTATE Return Phase 2A body poses, COMs, and Jacobians.

arguments
    model (1,1) struct
    q {mustBeNumeric, mustBeReal}
    options.AllowLimitOverride (1,1) logical = false
end

state = trackerKinematics(model, q, ...
    AllowLimitOverride=options.AllowLimitOverride);
q = state.q;

O1 = state.O1;
O2 = state.O2;
e1 = state.e1;
e2 = state.e2;

C1zero = model.joints.J1.origin_F0 + ...
    model.frames.R01_0 * model.physics.B1.r_O1C1_F1;
C2zero = model.joints.J2.origin_F0 + ...
    model.frames.R02_0 * model.physics.B2.r_O2C2_F2;

C1 = applyPoint(state.H_B1, C1zero);
C2 = applyPoint(state.H_B2, C2zero);
R1 = state.H_B1(1:3,1:3) * model.frames.R01_0;
R2 = state.H_B2(1:3,1:3) * model.frames.R02_0;

body.q = q;
body.B1.mass = model.physics.B1.mass;
body.B1.com_F0 = C1;
body.B1.R_F0_from_F1 = R1;
body.B1.inertiaCom_F0 = R1 * model.physics.B1.Ic_F1 * R1.';
body.B1.Jv = [cross(e1, C1 - O1), zeros(3,1)];
body.B1.Jw = [e1, zeros(3,1)];

body.B2.mass = model.physics.B2.mass;
body.B2.com_F0 = C2;
body.B2.R_F0_from_F2 = R2;
body.B2.inertiaCom_F0 = R2 * model.physics.B2.Ic_F2 * R2.';
body.B2.Jv = [cross(e1, C2 - O1), cross(e2, C2 - O2)];
body.B2.Jw = [e1, e2];
body.kinematics = state;
end

function point = applyPoint(H, point)
value = H * [point(:); 1];
point = value(1:3);
end

