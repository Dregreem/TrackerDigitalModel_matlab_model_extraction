# PRE_CONTROL_VALIDATION_CONTRACT.md
## Full Mechanical Workspace & Motion Validation Gate

**Status:** Required before trajectory/controller work  
**Input model:** accepted Phase 1 Model Builder + accepted Phase 2A rigid-body physics  
**Controller work:** BLOCKED until this contract passes

# 1. Purpose

Before building a controller, prove that the current kinematic model behaves correctly over the complete intended joint workspace and determine the actual safe operating envelope.

Current configured rectangular limits are:

\[
q_1 \in [-100^\circ,+100^\circ]
\]

\[
q_2 \in [-180^\circ,+180^\circ]
\]

These values are hypotheses/configured limits until geometric feasibility is validated.

# 2. What is already proven

Existing tests already prove important local/software properties:

- the viewer sliders use model-owned joint limits;
- B1 and B2 hierarchy transforms update;
- the moving GT2 pulley is parented to B1;
- the fixed GT2 pulley is parented to B0;
- zero pose and joint axes have dedicated tests;
- Phase 2A dynamics is numerically self-consistent;
- ODE joint-limit events exist and terminate.

This contract adds what those tests do **not** prove: full-range mechanical motion and interference safety.

# 3. Required validation layers

## 3.1 Boundary pose set

At minimum evaluate:

```text
q1 = -100, 0, +100 deg
q2 = -180, -90, 0, +90, +180 deg
```

including all four rectangular workspace corners.

Every pose must return finite proper rigid transforms.

## 3.2 Dense workspace sweep

Run a deterministic grid over the complete configured envelope.

Recommended first audit grid:

```text
q1: -100:5:+100 deg   -> 41 values
q2: -180:5:+180 deg  -> 73 values
total                 -> 2993 poses
```

If performance allows, use a finer secondary audit around any low-clearance region.

At every pose check:

- finite transforms;
- `R'R ~= I` within tolerance;
- `det(R) ~= +1`;
- no transform drift;
- geometry vertex counts unchanged.

## 3.3 Rigid-group motion invariants

For all audited poses:

### B0
\[
H_{B0}=I
\]

### B1
Depends on q1 only.

For fixed q1, changing q2 must not alter `H_B1`.

### B2
Depends on q1 and q2.

For q2=0:

\[
H_{B2}=H_{B1}
\]

under the current zero-pose geometry convention.

## 3.4 Joint-axis transport invariants

J1 origin and axis remain fixed in F0.

J2 must be carried by J1:

\[
O_2(q_1)=H_{J1}(q_1)O_2(0)
\]

\[
e_2(q_1)=R_{J1}(q_1)e_2(0)
\]

For fixed q1, changing q2 must not change J2 origin or J2 axis.

## 3.5 Distance-to-axis invariants

Select representative rigid-body reference points or vertices.

For B1, distance to the J1 axis must remain constant under q1 motion.

For B2, with q1 fixed, distance to the current J2 axis must remain constant under q2 motion.

This catches wrong pivot/frame/transform-order regressions.

## 3.6 AUX_DRIVE carrier invariants

- `GT2_16T-1` must follow the B1 carrier transform at every pose.
- `GT2_16T-2` must remain with B0.

Do not test or invent local pulley spin in this gate.

Belts remain excluded from motion claims unless shown explicitly for audit.

## 3.7 q2 endpoint continuity

Because -180 deg and +180 deg represent the same revolute orientation geometrically, compare the resulting B2 pose at:

```text
q2 = -180 deg
q2 = +180 deg
```

for fixed q1 values.

The rigid-body pose should agree to numerical tolerance.

If a future unwrapped coordinate representation intentionally distinguishes them, document that separately; geometry must still be continuous.

## 3.8 Ground/reference stability

The display transform may place the base on Z=0, but motion must not alter B0.

Check:

- B0 geometry does not move with q;
- display transform is constant;
- no unintended frame shift occurs during slider or programmatic pose changes.

# 4. Collision / interference validation

This is mandatory before the current rectangular q-limits are called a safe operating envelope.

A screenshot is insufficient.

## 4.1 Rigid collision scope

At minimum check rigid geometry among:

```text
B0 vs B1
B0 vs B2
B1 vs B2
```

and rigid AUX pulley geometry against relevant rigid bodies if it can create interference.

## 4.2 Flexible belt policy

Belts are not rigidly animated, so belt collision/deformation cannot be certified from the current viewer.

Report belt collision safety as:

```text
UNRESOLVED / OUT OF CURRENT RIGID-COLLISION SCOPE
```

unless a separate approved belt model or SolidWorks motion audit is performed.

## 4.3 Collision implementation options

Preferred engineering options:

1. implement explicit MATLAB mesh collision/interference testing using transformed component meshes, or
2. use an approved SolidWorks interference/motion study for the same q-grid / critical poses.

Do not infer no-collision from visual inspection alone.

## 4.4 Output

Produce:

```text
safeWorkspace(q1,q2)
minimumClearanceEstimate
collisionPairs
firstCollisionPose
```

where available.

If the workspace is not a full rectangle, represent the admissible set explicitly rather than forcing independent qMin/qMax values.

# 5. Limit-event verification

Existing numerical events must be rechecked for:

```text
J1 lower
J1 upper
J2 lower
J2 upper
```

Test both:

- outward crossing -> terminal event;
- inward motion from boundary -> no artificial extra clamp.

No physical impact model is added.

# 6. Visual acceptance evidence

Save representative images for:

- zero pose;
- J1 min/max with q2=0;
- J2 min/max with q1=0;
- four q1/q2 corners;
- any minimum-clearance pose;
- any collision/failure pose.

Visual evidence supplements numerical checks; it does not replace them.

# 7. Required deliverables

Recommended additions:

```text
matlab/validateTrackerWorkspace.m
matlab/trackerWorkspaceSweep.m
matlab/trackerCollisionAudit.m       % if MATLAB collision route is selected
tests/testWorkspaceKinematics.m
tests/testWorkspaceLimits.m
tests/testAuxCarrierWorkspace.m
tests/testWorkspaceCollision.m       % when collision checker exists
reports/precontrol_workspace_report.md
reports/precontrol_workspace_data.mat
reports/precontrol_images/
```

# 8. Acceptance conditions

The pre-control gate is PASS only if:

```text
[ ] all boundary/corner transforms are valid;
[ ] dense workspace transform sweep passes;
[ ] B0/B1/B2 invariants pass;
[ ] J2 transport invariants pass;
[ ] distance-to-axis invariants pass;
[ ] GT2 carrier invariants pass;
[ ] q2 endpoint continuity passes;
[ ] ground/reference stability passes;
[ ] all four limit-event directions pass;
[ ] rigid collision/interference audit is complete;
[ ] safe operating envelope is explicitly frozen;
[ ] unresolved belt-motion limitation is documented;
[ ] regression tests pass;
[ ] precontrol_workspace_report.md is produced.
```

If collision occurs inside the current rectangle:

- do not proceed to controller;
- identify the limiting geometry;
- reduce limits or define a coupled safe-workspace constraint;
- rerun the full validation.

# 9. Explicit non-goals

This gate does not introduce:

- controller;
- trajectory tracking;
- motor model;
- friction;
- backlash;
- transmission efficiency;
- physical hard-stop dynamics;
- Simulink.

The goal is solely to prove: **where the mechanism may safely move and whether the implemented kinematics reproduce that motion correctly.**
