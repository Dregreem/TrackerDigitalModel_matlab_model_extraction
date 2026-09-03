# Tracker Phase 2A Physics Core — Build Report

**Build date:** 2026-09-03  
**MATLAB:** R2025b  
**Phase 2 contract:** `TRACKER_PHASE2_DYNAMICS_CONTRACT.md` Version 2A.1.1  
**Phase 1 prerequisite:** Model Builder v1.3 / CAD Bridge V2 `S0_ZERO` PASS  
**Overall result:** **PASS**

## Delivered scope

Phase 2A was implemented in the requested order. Its first binding item is
joint-limit ownership and solver stop handling. The frozen limits remain only
in the built model:

```text
q1 = [-100, +100] deg
q2 = [-180, +180] deg
```

The physics core provides:

- `trackerMassMatrix` for configuration-dependent rigid-body inertia;
- `trackerCoriolisMatrix` for velocity-dependent Coriolis/centrifugal coupling;
- `trackerGravityVector` for static gravitational holding torque;
- `trackerDynamics` / `trackerForwardDynamics` for resulting acceleration;
- `trackerInverseDynamics` for required ideal actuator torque;
- `trackerEnergy` and `trackerPower` for mechanical audits;
- `trackerPlantRhs` and `trackerJointLimitEvents` for later ODE integration;
- `validateTrackerDynamics` for the complete Phase 2A validation gate.

Controller, trajectory generation, gravity-compensation application logic,
motor sizing, full time-simulation workflow, CAD time animation, Simulink, and
Simscape were not created.

## Joint-limit and stop result

| Gate | Result | Evidence |
|---|---:|---|
| Limits stored in `model.joints` | PASS | Exact frozen q1/q2 values |
| Duplicated dynamics limit constants | PASS | No qMin/qMax fields in `model.dynamics` |
| Kinematics/viewer rejection | PASS | Existing strict check retained |
| Diagnostic override | PASS | Explicit only; returned q is not clamped |
| Dynamics out-of-range rejection | PASS | Default event policy rejects invalid states |
| `ode45` terminal event | PASS | Automated crossing test stopped at q1 = +100 deg |
| Physical impact parameters | OPEN | Stiffness, damping, impact, and bounce are unknown and not modeled |

## AUX_DRIVE carrier correction

| Component | Carrier | CAD evidence | Axis result | Relative motion |
|---|---|---|---:|---|
| `GT2_16T-1` | B1 / `Nima 17 40x42x5mm-1` | `Concentric180` | `0 deg`, line distance `1.03528077545721e-13 m` | local spin unresolved |
| `GT2_16T-2` | B0 / `Nima 17 40x42x5mm-2` | `Concentric187` | `0 deg`, line distance `9.45756534685202e-14 m` | local spin unresolved |

The pulleys remain semantically in `AUX_DRIVE`; only their known carrier parent
is resolved. The belts remain hidden by default and their deformation/motion is
unresolved.

The event is a numerical joint-limit stop, not a physical collision model. No
placeholder stop torque and no hidden angle clamp were introduced.

## Dynamics validation

| Gate | Result | Value |
|---|---:|---:|
| Mass-matrix symmetry | PASS | maximum error `0` |
| Mass-matrix positive definiteness | PASS | minimum eigenvalue `0.00153380797319206` |
| Mass-matrix determinant | PASS | minimum `2.61592646294479e-05` |
| Gravity vs. potential gradient | PASS | residual `4.22298473967686e-10 N m` |
| Coriolis skew-power identity | PASS | residual `2.11758236813575e-22 W` |
| Kinetic energy via `M(q)` | PASS | residual `0 J` |
| Forward/inverse round trip | PASS | residual `1.94289029309402e-16` |
| Mechanical energy/power balance | PASS | residual `7.84337594872397e-11 W` |
| Zero-pose gravity hold | PASS | `[0.353140721921649; -0.0161552496631221] N m` |
| Simulink/Simscape exclusion | PASS | no `.slx` or `.mdl` file |

## Corrected v1.1 regression references

The Phase 1 contract retains older dynamics numbers from before the corrected
J1 line. They were not overwritten.

| Quantity | Historical v1.0 only | Current v1.1 Phase 2A |
|---|---:|---:|
| zero-pose `G1` | `0.353421363899 N m` | `0.353140721921649 N m` |
| zero-pose `G2` | `-0.016165481861 N m` | `-0.0161552496631221 N m` |
| minimum `det(M)` | `2.6158999130629047e-05` | `2.61592646294479e-05` |
| minimum eigenvalue of `M` | `0.0015304556575007114` | `0.00153380797319206` |
| gravity finite-difference residual | about `4.08e-10 N m` | `4.22298473967686e-10 N m` |
| skew residual | about `1.7347e-18` | `2.11758236813575e-22` |

The new values are the accepted software regression references for the current
corrected model. They are not motor-selection or hardware-validation results.

## Automated test result

Final command result: **45 passed, 0 failed, 0 incomplete**. MATLAB Code
Analyzer result: **0 issues**. The tests cover all Phase 1 gates plus mass,
gravity, Coriolis, forward/inverse dynamics, energy/power, limit events,
diagnostic override behavior, ODE event termination, and Phase 2B exclusion.

## Detected assumptions

1. B1 and B2 are ideal rigid aggregate bodies using the frozen Phase 1 mass,
   COM, and inertia values.
2. Physical F0 `+Y` is vertical up. The conventional standard gravity value
   `9.80665 m/s^2` is used.
3. CAD component mass properties remain reference data; they do not replace the
   frozen aggregate physics values.
4. Friction, backlash, drive elasticity, belt/gear losses, motor electrical
   dynamics, and AUX_DRIVE inertia are excluded.
5. Joint-limit events enforce the known workspace but do not represent impact
   mechanics.

## Unresolved items

- Physical stop stiffness, damping, impact force, and restitution require
  measurement or an approved mechanical specification.
- Motor, gearbox, belt/gear losses, friction, backlash, cable loading, wind
  loading, and drive efficiency are not identified.
- AUX_DRIVE pulley carrier motion is resolved. Local pulley spin, belt
  deformation/motion, and analytical drive inertia remain unresolved.
- Phase 2B trajectory, controller, gravity compensation, torque sizing, full
  time simulation, and CAD animation have not started.

## Exact commands to try Phase 2A

Open and build the project:

```matlab
proj = openProject("C:\Users\Kerem Bayer\Desktop\KBStracker\Kerem_astro\Matlab_model_extraction\TrackerDigitalModel.prj");
model = buildTrackerModel(fullfile(proj.RootFolder,"TRACKER_CAD_BRIDGE_V2_20260903_153150"));
```

Inspect the mechanics at 30 deg / -20 deg:

```matlab
q = deg2rad([30;-20]);
qdot = deg2rad([1;0.5]);
M = trackerMassMatrix(model,q)
C = trackerCoriolisMatrix(model,q,qdot)
G = trackerGravityVector(model,q)
[qdd,terms] = trackerDynamics(model,q,qdot,[0.4;0.05])
tauRoundTrip = trackerInverseDynamics(model,q,qdot,qdd)
energy = trackerEnergy(model,q,qdot)
power = trackerPower(model,q,qdot,[0.4;0.05])
```

Open the existing ground-aligned viewer at the same pose:

```matlab
showTracker(model,[30 -20],Units="degrees");
```

Wire the numerical limit event into a future `ode45` call:

```matlab
eventOptions = odeset("Events",@(t,x) trackerJointLimitEvents(model,t,x));
rhs = @(t,x) trackerPlantRhs(t,x,model,[0;0],StopModel="event");
[t,x,te,xe,ie] = ode45(rhs,[0 2],[0;0;0;0],eventOptions);
```

Run the complete validation:

```matlab
results = runAllTrackerTests();
dynamicsReport = validateTrackerDynamics(model)
assert(dynamicsReport.pass)
```
