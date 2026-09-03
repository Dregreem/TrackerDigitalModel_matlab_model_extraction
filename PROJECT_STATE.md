# PROJECT_STATE.md

## Repository checkpoint

**Phase 1 Model Builder: ACCEPTED**  
**Phase 2A MATLAB rigid-body physics core: ACCEPTED**  
**Next required gate: PRE-CONTROL MECHANICAL WORKSPACE & MOTION VALIDATION**

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

Current accepted regression result from `reports/phase2a_build_report.md`:

- 45 passed, 0 failed, 0 incomplete
- MATLAB Code Analyzer: 0 issues
- zero-pose gravity hold = `[0.353140721921649; -0.0161552496631221] N m`
- minimum mass-matrix eigenvalue = `0.00153380797319206`
- minimum mass-matrix determinant = `2.61592646294479e-05`
- gravity/potential residual = `4.22298473967686e-10 N m`
- forward/inverse round-trip residual = `1.94289029309402e-16`

## Joint limits — current configured values, not yet declared collision-free workspace

Single source of truth:

```text
J1 = [-100 deg, +100 deg]
J2 = [-180 deg, +180 deg]
```

These values are wired into the model, viewer and numerical ODE events.

**Important:** numerical limit enforcement does not prove that every pose inside this rectangle is mechanically feasible or collision-free. The safe operating envelope is not frozen until the pre-control workspace audit passes.

## AUX_DRIVE

Resolved carrier motion:

- `GT2_16T-1` carrier = B1 / moving motor `Nima 17 40x42x5mm-1`
- `GT2_16T-2` carrier = B0 / fixed motor `Nima 17 40x42x5mm-2`

Still intentionally unresolved:

- local pulley spin
- belt deformation / belt motion
- analytical AUX_DRIVE inertia contribution

## Mandatory next gate — Pre-Control Mechanical Workspace & Motion Validation

No controller development starts until this gate is accepted.

Required checks are defined in:

```text
PRE_CONTROL_VALIDATION_CONTRACT.md
```

At minimum the gate must validate:

1. all boundary and corner poses;
2. dense q1-q2 workspace motion;
3. B0/B1/B2 motion invariants;
4. J2 axis/origin carriage by B1;
5. pulley carrier attachment over the full range;
6. q2 ±180-degree endpoint continuity;
7. ground/reference-frame stability;
8. collision/interference across the allowed workspace;
9. all four numerical joint-limit event directions;
10. representative visual evidence and a PASS/FAIL report.

### Acceptance rule

Only after this validation do we freeze the **safe operating envelope**.

If collision/interference or geometric infeasibility is found, the joint limits must be reduced or a coupled q1-q2 admissible-workspace rule must be introduced **before** trajectory/controller development.

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
PRE-CONTROL    Workspace/motion/interference audit   NEXT / REQUIRED
Phase 2B       Trajectory + ideal closed-loop        BLOCKED
Actuator       Motor/driver/transmission model       LATER, with real parameters
Simulink       System/control integration            LATER
```

## Continuity rule

Update this file at every accepted checkpoint. GitHub is the project handoff source; do not rely on chat history for project state.
