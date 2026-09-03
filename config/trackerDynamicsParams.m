function dynamics = trackerDynamicsParams()
%TRACKERDYNAMICSPARAMS Phase 2A numerical and physical-stop parameters.
% Joint limits intentionally do not appear here. Every dynamics function reads
% them from model.joints.J1/J2 so future consumers have one authority.

dynamics.revision = "PHASE2A_1_0";
dynamics.gravity = 9.80665;
dynamics.upAxis_F0 = [0; 1; 0];
dynamics.massDerivativeStep = 1e-6;

dynamics.jointStops.defaultMode = "event";
dynamics.jointStops.physicalModelStatus = "UNRESOLVED_NOT_MODELED";
dynamics.jointStops.eventPolicy = "TERMINATE_ON_FIRST_OUTWARD_LIMIT_CROSSING";
end
