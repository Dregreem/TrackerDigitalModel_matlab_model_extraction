# Tracker Phase 2 Dynamics Contract

**Version:** 2A.1.1  
**Status:** Frozen implementation contract for Phase 2A  
**Source model:** validated `TrackerModel` produced from `TRACKER_CAD_BRIDGE_V2_20260903_153150`

This contract extends the accepted Model Builder Phase 1 result. It does not
change the CAD source, F0, J1, J2, component classification, or aggregate B1/B2
physical parameters. A failed Phase 1 validation blocks Phase 2A construction.

## 1. Phase 2A Task 0 = Joint Limits + Stop Handling

This is the first and binding Phase 2 requirement. It precedes trajectory
generation and control.

The only joint-limit source is the built model:

```matlab
model.joints.J1.qMin = deg2rad(-100);
model.joints.J1.qMax = deg2rad(+100);
model.joints.J2.qMin = deg2rad(-180);
model.joints.J2.qMax = deg2rad(+180);
```

No Phase 2 function, future controller, or future Simulink model may copy these
four values into an independent parameter set.

- `trackerKinematics` and the viewer reject limit violations unless the caller
  explicitly requests a diagnostic override.
- The dynamics core never clamps `q`.
- Event mode exposes terminal zero crossings at all four limits and is the
  Phase 2A stop policy.
- Stop stiffness, damping, impact, and restitution are unknown. Phase 2A must
  not invent them and therefore must not claim a physical collision model.
- The event is a numerical joint-limit stop: integration terminates at the
  boundary; there is no penetration and no position clamp.

## 2. Phase 2A equation and sign convention

The analytical plant is

```text
M(q) qdd + C(q,qdot) qdot + G(q)
    = tauActuator + tauDisturbance
```

Angles are radians, angular rates are radians/second, torque is N m, mass is kg,
length is m, and energy is J. Physical F0 `+Y` is up. Positive joint motion is
the right-hand rotation about the validated positive J1/J2 axes.

## 3. Phase 2A required public functions

```text
trackerDynamics
trackerMassMatrix
trackerCoriolisMatrix
trackerGravityVector
trackerForwardDynamics
trackerInverseDynamics
trackerJointLimitEvents
trackerEnergy
trackerPower
trackerPlantRhs
validateTrackerDynamics
```

`trackerDynamics(model,q,qdot,tau)` remains the compact normal entry point.

## 4. Model boundary

- Input `u`: two actuator torques `[tau1;tau2]`.
- Disturbance `w`: optional two-element external generalized torque.
- State: `[q1;q2;q1dot;q2dot]`.
- Phase 2A outputs: acceleration, equation terms, stop status, energy, and power.
- Sensors, estimation, trajectory generation, controller, torque sizing, full
  time-simulation workflow, CAD time animation, Simulink, and Simscape are out
  of Phase 2A scope.

## 5. Parameter authority

- Geometry, frames, joint axes, origins, and limits: built `TrackerModel`.
- Aggregate masses, COM offsets, and inertia tensors: `trackerPhysicalParams`.
- Standard gravity and numerical dynamics settings: `trackerDynamicsParams`.
- Physical-stop stiffness, damping, impact, and restitution: unresolved and not
  modeled. Event surfaces use `model.joints` limits directly.

CAD per-component mass properties remain reference data and do not silently
replace the frozen aggregate analytical parameters.

## 6. Required validation gates

1. Phase 1 validation remains PASS.
2. Limits are read from `model.joints` and not duplicated in dynamics settings.
3. `M(q)` is symmetric positive definite over the test grid.
4. `G(q)` agrees with the finite-difference gradient of gravitational potential.
5. `qdot'*(Mdot-2*C)*qdot` is numerically zero.
6. Forward and inverse dynamics round-trip within tolerance.
7. Static holding torque equals `G(q)` away from a stop.
8. Event surfaces use the model limits and terminate on outward crossings.
9. Dynamics reject out-of-range state unless an explicit diagnostic override
   is used; no clamp exists.
10. Mechanical-energy derivative agrees with actuator and disturbance power
    within numerical tolerance.
11. No `.slx`/`.mdl`, Simulink, or Simscape dependency is introduced.

## 7. Frozen historical-reference policy

The Phase 1 contract records v1.0 dynamics numbers that predate the corrected
v1.1 J1 line. They remain historical only. Phase 2A must publish newly computed
v1.1 regression values alongside them; it must not modify the old numbers or
present them as current acceptance gates.

## 8. Phase order

```text
Phase 2A
|- Task 0: joint limits contract + numerical stop events
|- trackerDynamics
|- M(q), C(q,qdot), G(q)
|- forward dynamics
|- inverse dynamics
|- energy and power
`- regression tests

Phase 2B (not authorized by this contract)
|- trajectory
|- controller
|- gravity compensation
|- torque requirement
`- time simulation + CAD animation
```
