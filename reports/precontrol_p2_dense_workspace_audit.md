# Pre-Control P2 Dense Workspace Sweep

**Date:** 2026-09-03  
**Branch:** `dev/precontrol-validation`  
**Result:** **PASS**

## Scope

P2 extends the accepted P1 kinematic invariants from the critical-pose set to the complete configured rectangular joint workspace using a deterministic 5-degree grid.

This phase does **not** perform collision/interference certification and therefore does **not** freeze the final safe mechanical operating envelope.

## Dense grid

```text
J1 = -100:5:+100 deg   -> 41 values
J2 = -180:5:+180 deg   -> 73 values
Total                   -> 2993 poses
```

## Validation result

```text
workspaceReport.pass            = 1
workspaceReport.failedPoseCount = 0
collisionStatus                  = PENDING_P3_COLLISION_INTERFERENCE_AUDIT
```

Therefore:

```text
2993 / 2993 kinematic poses passed
0 failed poses
```

## Maximum numerical errors

```text
allTransformsFinite              = 1
maxRotationOrthogonalityError    = 1.2163e-15
maxRotationDeterminantError      = 8.8818e-16
maxHomogeneousBottomRowError     = 0

maxB0Error                       = 0
maxB1Q2DependencyError           = 0
maxB2AtZeroQ2Error               = 0

maxJ1OriginError                 = 0
maxJ1AxisError                   = 0

maxJ2OriginTransportError        = 0
maxJ2AxisTransportError          = 2.7195e-16
maxJ2Q2OriginError               = 0
maxJ2Q2AxisError                 = 0

maxB1AxisRadiusError             = 5.5511e-17
maxB2AxisRadiusError             = 1.8041e-16

maxMovingPulleyCarrierError      = 0
maxFixedPulleyCarrierError       = 0

maxQ2EndpointTransformError      = 4.7184e-16
maxQ2EndpointOriginError         = 0
maxQ2EndpointAxisError           = 0

geometryVertexCountsUnchanged    = 1
displayTransformDriftError       = 0
```

The observed residuals are at or near floating-point numerical precision and are comfortably below the P2 acceptance tolerances.

## Full regression suite

Command:

```matlab
results = runAllTrackerTests();
```

Result:

```text
64 Passed
0 Failed
0 Incomplete
5.8934 s
```

## P2 acceptance

All P2 gates pass:

- [x] deterministic 2993-pose grid covers the configured J1/J2 limits;
- [x] all transforms remain finite;
- [x] all rotation matrices remain proper;
- [x] B0 remains fixed;
- [x] B1 remains independent of q2;
- [x] B2 hierarchy remains valid;
- [x] J1 origin/axis invariants remain valid;
- [x] J2 origin/axis transport remains valid;
- [x] q2 does not move the J2 axis/origin;
- [x] B1/J1 and B2/J2 axis-radius invariants remain valid;
- [x] pulley carrier assignments remain valid;
- [x] q2 ±180 degree endpoint closure remains valid;
- [x] geometry vertex counts remain unchanged;
- [x] display transform remains stable;
- [x] full regression suite passes 64/64.

**P2 — Dense Workspace Sweep: ACCEPTED**

## Important limitation

P2 proves:

> The implemented rigid-body kinematics are numerically consistent across all 2993 configured joint poses.

P2 does **not** prove:

> All 2993 poses are collision-free or mechanically safe.

Therefore:

```text
safeOperatingEnvelopeFrozen = false
collisionStatus = PENDING_P3_COLLISION_INTERFERENCE_AUDIT
```

## Next phase

**P3 — Rigid Collision / Interference Audit**

Required rigid collision scope:

```text
B0 <-> B1
B0 <-> B2
B1 <-> B2
rigid AUX pulley geometry <-> relevant rigid bodies
```

Flexible-belt deformation/collision remains unresolved and outside the rigid collision claim unless separately modeled or audited.
