# Pre-Control P0 Baseline Freeze

**Date:** 2026-09-03  
**Branch:** `dev/phase2a`  
**Commit:** `3a2259f299e563c8fbe1119c85fc3ceed14f2753`  
**Result:** **PASS**

## Repository state

- Working tree: clean
- Branch: `dev/phase2a`
- Remote branch checkpoint verified at commit `3a2259f299e563c8fbe1119c85fc3ceed14f2753`

## Automated regression baseline

MATLAB command:

```matlab
results = runAllTrackerTests();
```

Result:

```text
45 Passed
0 Failed
0 Incomplete
7.4698 s
```

## Dynamics validation baseline

MATLAB commands:

```matlab
dynamicsReport = validateTrackerDynamics(model);
assert(dynamicsReport.pass);
```

Result:

```text
dynamicsReport.pass = 1
```

## Viewer / AUX_DRIVE warning

The viewer emitted the expected informational warning:

```text
AUX_DRIVE carrier motion is resolved for GT2_16T-1 with B1 and GT2_16T-2 with B0.
Local pulley spin and flexible-belt motion remain unresolved; belt meshes are hidden by default.
```

This warning is consistent with the accepted model contract and is not a test failure.

## Frozen configured joint ranges entering Pre-Control validation

```text
J1 = [-100,+100] deg
J2 = [-180,+180] deg
```

These remain configured limits only. They are not yet declared the final collision-free safe operating envelope.

## Known unresolved items entering P1

- local pulley spin
- flexible-belt deformation/motion
- AUX_DRIVE analytical inertia contribution
- rigid-body collision/interference across the full q1-q2 workspace
- final safe operating envelope

## P0 acceptance

All P0 baseline gates pass:

- [x] clean repository checkpoint
- [x] 45/45 regression tests pass
- [x] dynamics validation passes
- [x] existing viewer tests pass
- [x] expected AUX_DRIVE limitation remains explicit
- [x] no new controller, motor, or Simulink logic introduced

**P1 — Kinematic Motion Audit is authorized.**
