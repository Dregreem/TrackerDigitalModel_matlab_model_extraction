# Pre-Control P1 Kinematic Motion Audit

**Date:** 2026-09-03  
**Branch:** `dev/precontrol-validation`  
**Result:** **PASS**

## Scope

P1 validates the critical-pose rigid-body motion logic before the dense workspace sweep and before collision/interference analysis.

No controller, trajectory logic, motor model, collision model, Simulink, friction, backlash, pulley local spin, or flexible-belt deformation model was added.

## Critical-pose tests

### `testWorkspaceKinematics.m`

Result:

```text
7 Passed
0 Failed
0 Incomplete
0.62576 s
```

Validated:

- finite homogeneous transforms;
- proper rotation matrices;
- `det(R) = +1`;
- B0 fixed across critical configurations;
- B1 depends only on q1;
- B2 follows B1 when q2 = 0;
- representative B1 point preserves distance to J1 axis;
- representative B2 point preserves distance to current J2 axis;
- q2 = -180 deg and q2 = +180 deg are geometrically closed.

### `testJointTransport.m`

Result:

```text
4 Passed
0 Failed
0 Incomplete
0.22125 s
```

Validated:

- J1 origin remains fixed in F0;
- J1 axis remains fixed in F0;
- J2 origin is carried by J1;
- J2 axis is carried by J1;
- q2 does not move the J2 origin or axis;
- J1/J2 included angle is preserved during J1 motion.

### `testAuxCarrierWorkspace.m`

Result:

```text
3 Passed
0 Failed
0 Incomplete
1.2458 s
```

Validated:

- `GT2_16T-1` remains assigned to the B1 carrier;
- `GT2_16T-2` remains assigned to the B0 carrier;
- critical viewer poses retain the correct transform parents;
- carrier motion remains independent of q2 where required.

The accepted limitation remains unchanged:

```text
local pulley spin: unresolved
flexible-belt motion/deformation: unresolved
```

## Full regression suite

Command:

```matlab
results = runAllTrackerTests();
```

Result:

```text
59 Passed
0 Failed
0 Incomplete
5.1172 s
```

The expected AUX_DRIVE unresolved-motion warning was emitted during the existing viewer test and is not a failure.

## P1 acceptance

All P1 gates pass:

- [x] critical joint configurations validated;
- [x] B0 rigid-base invariant validated;
- [x] B1 q1-only dependency validated;
- [x] B2 hierarchy validated;
- [x] J2 origin/axis transport validated;
- [x] distance-to-axis invariants validated;
- [x] q2 ±180 deg geometric closure validated;
- [x] AUX pulley carrier invariants validated;
- [x] complete regression suite passes with 59/59 tests;
- [x] accepted unresolved drive limitations remain explicit.

**P1 — Kinematic Motion Audit: ACCEPTED**

**P2 — Dense Workspace Sweep is authorized.**

## Next phase

P2 will extend the accepted invariants from the critical pose set to the complete configured joint rectangle using the deterministic first-pass grid:

```text
q1 = -100:5:+100 deg   -> 41 values
q2 = -180:5:+180 deg   -> 73 values
total                   -> 2993 poses
```

P2 remains a kinematic/workspace audit only. Collision/interference certification remains P3.
