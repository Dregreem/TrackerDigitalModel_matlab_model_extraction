# PROJECT_STATE.md

## Repository checkpoint

**Phase 1 Model Builder: ACCEPTED**  
**Phase 2A MATLAB rigid-body physics core: ACCEPTED**  
**Pre-Control P0 Baseline Freeze: ACCEPTED**  
**Pre-Control P1 Kinematic Motion Audit: ACCEPTED**  
**Pre-Control P2 Dense Workspace Sweep: ACCEPTED**  
**Next required gate: P3 RIGID COLLISION / INTERFERENCE AUDIT**

Controller, trajectory-control logic, motor/driver modeling and Simulink are **not authorized yet**.

## Phase 1 accepted state

- Tracker CAD Bridge V2 import and schemas validated.
- 40-component baseline coverage validated.
- F0, J1 and J2 corrected and validated against CAD mate evidence.
- B0/B1/B2 kinematic chain works.
- Base display is aligned to horizontal Z=0.
- Belt meshes are hidden by default.
- No Simulink or Simscape Multibody dependency exists.

## Phase 2A accepted state

The ideal 2-DOF rigid-body plant is implemented:

```text
M(q) qdd + C(q,qdot) qdot + G(q)
    = tauActuator + tauDisturbance
```

Delivered and validated:

- `trackerMassMatrix`
- `trackerCoriolisMatrix`
- `trackerGravityVector`
- `trackerDynamics` / `trackerForwardDynamics`
- `trackerInverseDynamics`
- `trackerEnergy`
- `trackerPower`
- `trackerPlantRhs`
- `trackerJointLimitEvents`
- `validateTrackerDynamics`

Accepted Phase 2A regression:

```text
45 passed
0 failed
0 incomplete
```

## Pre-Control accepted checkpoints

### P0 — Baseline Freeze

Accepted:

- clean repository checkpoint
- Phase 1/2A regression baseline
- dynamics validation PASS
- accepted AUX_DRIVE limitations explicitly preserved

Report:

```text
reports/precontrol_p0_baseline.md
```

### P1 — Kinematic Motion Audit

Accepted critical-pose invariants:

- B0 fixed
- B1 depends only on q1
- B2 hierarchy correct
- J2 origin/axis transported by J1
- q2 does not move J2 origin/axis
- distance-to-axis invariants preserved
- q2 ±180 degree geometric closure preserved
- rigid pulley carrier relationships preserved

Regression after P1:

```text
59 passed
0 failed
0 incomplete
```

Report:

```text
reports/precontrol_p1_kinematic_audit.md
```

### P2 — Dense Workspace Sweep

Accepted deterministic configured-space sweep:

```text
J1 = -100:5:+100 deg   -> 41 values
J2 = -180:5:+180 deg   -> 73 values
Total                   -> 2993 poses
```

Result:

```text
2993 / 2993 poses passed
0 failed poses

workspaceReport.pass = 1
workspaceReport.failedPoseCount = 0
```

Maximum observed P2 errors:

```text
maxRotationOrthogonalityError = 1.2163e-15
maxRotationDeterminantError   = 8.8818e-16
maxJ2AxisTransportError       = 2.7195e-16
maxB1AxisRadiusError          = 5.5511e-17
maxB2AxisRadiusError          = 1.8041e-16
maxQ2EndpointTransformError   = 4.7184e-16
```

Full regression after P2:

```text
64 passed
0 failed
0 incomplete
```

Report:

```text
reports/precontrol_p2_dense_workspace_audit.md
```

## Joint limits — configured but not yet certified collision-free

Single source of truth:

```text
J1 = [-100 deg, +100 deg]
J2 = [-180 deg, +180 deg]
```

P2 proves the kinematic implementation is numerically consistent over this entire rectangle.

P2 does **not** prove this entire rectangle is mechanically collision-free.

Therefore:

```text
safeOperatingEnvelopeFrozen = false
collisionStatus = PENDING_P3_COLLISION_INTERFERENCE_AUDIT
```

## AUX_DRIVE

Resolved carrier motion:

- `GT2_16T-1` carrier = B1 / moving motor `Nima 17 40x42x5mm-1`
- `GT2_16T-2` carrier = B0 / fixed motor `Nima 17 40x42x5mm-2`

Still intentionally unresolved:

- local pulley spin
- belt deformation / belt motion
- analytical AUX_DRIVE inertia contribution

## Mandatory next gate — P3 Rigid Collision / Interference Audit

No controller development starts until P3 and final safe-workspace freeze are accepted.

Required rigid collision scope:

```text
B0 <-> B1
B0 <-> B2
B1 <-> B2
rigid AUX pulley geometry <-> relevant rigid bodies
```

P3 must use actual transformed CAD mesh geometry or an equivalently rigorous approved SolidWorks interference audit.

Visual inspection alone is insufficient.

P3 must determine, where available:

```text
collisionPairs
firstCollisionPose
safeWorkspace(q1,q2)
minimumClearanceEstimate
```

If collision/interference occurs inside the configured rectangle, reduce the independent limits or define a coupled admissible q1-q2 workspace before any trajectory/controller work.

Flexible-belt collision/deformation remains unresolved unless separately modeled or audited.

## Explicitly not modeled yet

Do not invent:

- friction
- backlash
- motor electrical dynamics
- gearbox/belt efficiency
- driver losses
- physical hard-stop stiffness/damping/restitution
- sensor noise
- wind/cable loads

## Phase order

```text
Phase 1        Model Builder                         ACCEPTED
Phase 2A       Ideal rigid-body physics core         ACCEPTED
P0             Baseline freeze                       ACCEPTED
P1             Critical-pose kinematic audit         ACCEPTED
P2             2993-pose dense workspace sweep       ACCEPTED
P3             Rigid collision/interference audit    NEXT / REQUIRED
P4             Safe workspace freeze                 BLOCKED BY P3
Phase 2B       Trajectory + ideal closed-loop        BLOCKED BY P4
Actuator       Motor/driver/transmission model       LATER
Simulink       System/control integration            LATER
```

## Continuity rule

Update this file at every accepted checkpoint. GitHub is the project handoff source; do not rely on chat history for project state.
