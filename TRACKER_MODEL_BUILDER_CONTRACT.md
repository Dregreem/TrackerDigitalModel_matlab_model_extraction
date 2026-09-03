# TRACKER MODEL BUILDER CONTRACT
## Version 1.3 — SolidWorks CAD Bridge V2 → MATLAB Digital Model

**Project:** Petal / dual-axis solar tracker  
**Current CAD reference state:** `S0_ZERO`  
**Primary implementation target:** MATLAB  
**Simscape Multibody:** Not part of this architecture  
**Simulink:** Not part of Model Builder Phase 1; optional later layer

**v1.1 correction (2026-09-03):** Runtime viewer evidence exposed an omitted
CAD-datum-to-analytical-F0 rotation in v1.0. Version 1.1 restores that explicit
alignment, projects the frozen joint origins onto the validated CAD mate lines,
corrects the J1 direction, and re-expresses the aggregate physical parameters in
the corrected body frames without changing their F0 mass distribution.

**v1.2 presentation revision (2026-09-03):** The engineering model remains in
F0 where +Y0 is physical up. The viewer applies one display-only rigid transform
that maps +Y0 to display +Z and translates B0's lowest point to the Z=0 ground
plane. Belt meshes remain loaded and classified but are hidden by default at the
user’s explicit request; `ShowBelts=true` restores them for audit viewing.

**v1.3 operational revision (2026-09-03):** J1 operational travel is revised
to `[-100 deg,+100 deg]`; J2 remains `[-180 deg,+180 deg]`. CAD mate evidence
resolves the carrier motion of `GT2_16T-1` with B1 via `Concentric180` and
`GT2_16T-2` with B0 via `Concentric187`. Pulley local spin and flexible-belt
motion remain unresolved.

---

# 1. Mission

Build a deterministic MATLAB **Tracker Model Builder** that converts one SolidWorks CAD Bridge export folder into one clean, validated `TrackerModel`.

The target pipeline is:

```text
SolidWorks Assembly
        ↓
Tracker CAD Bridge V2
        ↓
MATLAB Model Builder
        ↓
TrackerModel
        ├── CAD geometry
        ├── components
        ├── frames
        ├── semantic groups
        ├── J1 / J2
        ├── CAD mass-property reference data
        └── frozen analytical dynamics parameters
        ↓
MATLAB Viewer / Kinematics / Physics
        ↓
optional later Simulink
```

The Model Builder is an **engineering integration layer**. It must not invent missing physics, silently repair ambiguity, idealize axes, or overwrite validated dynamics.

---

# 2. Non-negotiable rules

## 2.1 CAD scope

For both visualization and the CAD-side dynamics/model data scope, the included SolidWorks component set is exactly:

\[
\boxed{
\text{ACTIVE CONFIGURATION}
\cap
\text{UNSUPPRESSED}
\cap
\text{VISIBLE}
}
\]

The same included component set is used for both scopes.

Therefore:

- hidden component → outside the current digital-model scope,
- suppressed component → outside the current digital-model scope,
- visible + unsuppressed component → inside the current digital-model scope.

Do not create a second hidden-component physics scope.

## 2.2 No B0/B1/B2 logic inside CAD export

SolidWorks remains the assembly source of truth.

The CAD exporter describes component instances, geometry, transforms, mates, visibility state and CAD mass properties.

Semantic grouping belongs to MATLAB.

## 2.3 No automatic replacement of the validated analytical dynamics

The current validated rigid-body dynamics remain authoritative until the user explicitly creates a **dynamics revision**.

CAD component masses / COMs / inertias are reference and revision-support data.

They must **not** automatically overwrite:

\[
m_1,\;r_{O_1C_1},\;I_{C_1},
\qquad
m_2,\;r_{O_2C_2},\;I_{C_2}.
\]

## 2.4 No axis idealization

Never replace a measured/CAD-derived axis by a convenient global or body-frame axis.

Example: J2 has a known small real misalignment relative to the nominal \(+Y_1\) direction. Preserve the actual axis.

## 2.5 Fail loudly on unknown topology

A normal CAD revision may add or remove components.

The builder must report:

```text
ADDED
REMOVED
UNCLASSIFIED
CHANGED SOURCE
CHANGED CONFIGURATION
CHANGED PARENT
```

It must not silently assign an unknown component to B0/B1/B2.

## 2.6 No Simulink or Simscape Multibody work in Phase 1

Phase 1 ends when the MATLAB `TrackerModel`, viewer, pose kinematics and validation tests pass.

---

# 3. Source-of-truth precedence

When two data sources appear to conflict, use this precedence.

## 3.1 Geometry / component existence / visibility / CAD assembly relations

**Source of truth:** current `Tracker CAD Bridge V2` export.

## 3.2 Joint topology and real joint axes

Use CAD evidence plus already validated motion-identification results.

A mate by itself is **evidence**, not automatically the final joint definition.

The joint must remain consistent with:

1. SolidWorks mate geometry,
2. prior rigid-motion snapshot identification,
3. the frozen mathematical q-sign/frame convention.

## 3.3 Dynamic equations and validated aggregate body parameters

**Source of truth:** frozen validated rigid-body mathematical model.

Current CAD component mass properties are not allowed to silently redefine it.

## 3.4 Explicit user edit

If the user intentionally edits aggregate body parameters in the dedicated physics parameter file, that edit becomes the active dynamics revision.

---

# 4. Required CAD Bridge V2 input

The Model Builder takes one folder:

```text
TRACKER_CAD_BRIDGE_V2_YYYYMMDD_HHMMSS/
├── manifest.json
├── components.json
├── mates.json
├── geometry_root_triangles.csv
├── component_tree.txt
└── export_log.txt
```

Required files for programmatic loading:

```text
manifest.json
components.json
mates.json
geometry_root_triangles.csv
```

`component_tree.txt` and `export_log.txt` are audit/support files.

---

# 5. Current S0_ZERO baseline

The current accepted CAD Bridge V2 reference export has:

```text
active configuration           = Default
snapshot                       = S0_ZERO
included component nodes       = 40
included part nodes            = 40
included subassemblies         = 0
geometry components            = 40
triangles                      = 120724
root-assembly mates            = 194
mass properties unavailable    = 0
ignored suppressed             = 5
ignored hidden                 = 58
unreadable state count         = 0
```

These counts are a **baseline regression reference**, not permanent design constraints.

A future revision is allowed to change them, but the builder must report the change.

The complete currently included visible part set has a CAD-reported aggregate reference:

```text
mass = 1.51241641347696 kg
COM_root =
[-0.0278190013280925
  0.118212031084222
  0.159884765402555] m
```

This full-assembly aggregate is **not** the B1/B2 analytical-dynamics parameter set.

---

# 6. Component identity

Primary component identity:

```text
instance_path
```

Current exports also contain:

```text
component_index
component_id
name
source_file
referenced_configuration
parent_instance_path
tree_level
document_type
component_to_assembly_root_native_array
mass_properties_assembly_root
```

Do not use `component_index` as a persistent cross-revision identity. It is local to one export.

For revision comparison, compare at minimum:

```text
instance_path
source_file
referenced_configuration
parent_instance_path
```

and separately report transform/geometry changes.

---

# 7. Coordinate-frame contract

## 7.1 Frames

### Assembly root

SolidWorks-exported geometry, component transforms, mate entity points and CAD mass-property COMs are expressed in:

```text
assembly_root
```

### CAD datum C0 and analytical F0

`Coordinate System1` supplies the physical origin of the analytical frame, but
its exported CAD axes are an intermediate datum called `C0`. The analytical
model frame is `F0`; `C0` and `F0` share an origin but not an orientation.

The mathematical origin is:

\[
{}^{0}O_0 =
\begin{bmatrix}
0\\0\\0
\end{bmatrix}
\]

and \(+Y_0\) is global up.

## 7.2 SolidWorks native transform representation

The SolidWorks native transform array is interpreted using the row-vector convention:

\[
T_{\rm SW}=
\begin{bmatrix}
a&b&c&0\\
d&e&f&0\\
g&h&i&0\\
j&k&l&m
\end{bmatrix}
\]

with:

\[
[x\ y\ z\ 1]_{\rm local}\,T_{\rm SW}
=
[x'\ y'\ z'\ 1]_{\rm root}.
\]

For MATLAB column-vector homogeneous transforms:

\[
H_{\rm root\leftarrow local}=T_{\rm SW}^{T}.
\]

## 7.3 F0 conversion

The `Coordinate System1` transform returned in the current manifest is treated
as **C0 → assembly_root**:

\[
H_{\rm root\leftarrow C0}=T_{C0,\rm SW}^{T}.
\]

The v1.0 assumption `C0 = F0` was incorrect. The accepted current alignment is
a +Y-preserving rotation:

\[
R_{F0\leftarrow C0}=
\begin{bmatrix}
 0.855148048755737&0& 0.518383848812109\\
 0&1&0\\
-0.518383848812109&0& 0.855148048755737
\end{bmatrix},
\]

equivalent to `31.2239055789 deg` about +Y under the active column-vector
convention. Therefore:

\[
\boxed{
H_{F0\leftarrow root}
=
H_{F0\leftarrow C0}
H_{C0\leftarrow root}
}
\]

All analytical/model-builder geometry must use:

\[
{}^{F0}p
=
H_{F0\leftarrow root}
{}^{root}p.
\]

Do not apply the native C0 transform in the forward direction, and do not omit
the explicit `C0 → F0` alignment.

Current S0 manifest native array:

```text
[1, 0, 0,
 0, 1, 0,
 0, 0, 1,
 0.0100631432061527,
 0,
 -0.03401231413688,
 1, 0, 0, 0]
```

For the current S0 reference this gives:

\[
H_{F0\leftarrow root}=
\begin{bmatrix}
 0.855148048755737&0& 0.518383848812109&0.00902595703219132\\
 0&1&0&0\\
-0.518383848812109&0& 0.855148048755737&0.034302134974173\\
 0&0&0&1
\end{bmatrix}.
\]

This full matrix, not a translation-only shortcut, is the current regression reference.

---

# 8. Current semantic-group seed mapping

This mapping is the accepted seed for the current `S0_ZERO` visible 40-component export.

It covers all 40 current components exactly once.

This seed is a MATLAB/model-layer contract, not a SolidWorks exporter rule.

## 8.1 B0 — fixed structural/base group

```text
sigma2020-200-1
M14_mount_left_2020base-1
sigma2020-300-1
M14_mount_right_2020base-1
b1_connector_right-4
b3_2020 adapter-1
02_angle_50deg_v4_2020base-1
04_rollmount left_50°_v6_2020base-1
04_rollmount right_50°_v6_2020base-1
sigma2020-300-3
b1_connector_left-3
6801^Measurement_for_math-1
M14_mount_rear_2020base_v4-1
6001^Measurement_for_math-4
6001^Measurement_for_math-3
Nima 17 40x42x5mm-2
Part26^Measurement_for_math-1
```

Current visible count:

```text
17
```

Motion policy:

```text
fixed
```

## 8.2 B1 — first moving rigid body

```text
u4_holder-2
05_pole_v5-1
03_polemount_6801_v3-1
06c_splitring_part3_v4-2
05.1_pole_v4-1
06a_splitring_part1_v4-1
11_DEC_motor_mount_v9_NEMA-2
06b_splitring_part2_v4-1
u4_holder-1
05.1_pole_v4-2
05_pole_v5-2
05.2_stabilizer-2
6001^Measurement_for_math-1
6001^Measurement_for_math-2
Nima 17 40x42x5mm-1
```

Current visible count:

```text
15
```

Motion policy:

```text
J1
```

## 8.3 B2 — second moving rigid body

```text
u3_drivedisc_DEC_unimount_v3-2
u2_bearing_holder-2
sigma2020-220-1
sigma2020-220-2
```

Current visible count:

```text
4
```

Motion policy:

```text
J1 + J2
```

Several historically identified B2 members are currently hidden and are therefore correctly outside the present model scope.

## 8.4 AUX_DRIVE — resolved carriers with unresolved relative drive motion

```text
Belt6-1^Measurement_for_math-1
GT2_16T-1
GT2_16T-2
Belt5-22^Measurement_for_math-1
```

Current visible count:

```text
4
```

These components remain inside the CAD/model scope.

Their carrier motion is known from CAD; detailed spin/flexible-belt motion is
**not** to be invented.

Use:

```text
motion_policy = carrier_resolved_relative_drive_unresolved
```

Phase-1 viewer behavior must be explicit:

- retain all four components correctly in the model at `S0_ZERO`,
- carry `GT2_16T-1` with B1 based on concentric mate `Concentric180`,
- carry `GT2_16T-2` with B0 based on concentric mate `Concentric187`,
- hide the two belt meshes by default in the viewer while retaining both pulleys,
- permit explicit belt audit display with `ShowBelts=true`,
- do not claim local pulley spin or flexible-belt animation at nonzero q,
- emit one non-fatal viewer/model status indicating unresolved auxiliary-drive motion.

Later a drivetrain model may assign pulley rotation and belt behavior.

## 8.5 Mapping invariant

For the current baseline:

```text
17 + 15 + 4 + 4 = 40
```

Every included component must be in exactly one semantic group.

No duplicates.

No silently unclassified components.

For a future revision, newly included components must be reported before the model is accepted.

---

# 9. Joint topology

The reduced mechanical topology is:

\[
\boxed{
B_0
\xrightarrow{J_1(q_1)}
B_1
\xrightarrow{J_2(q_2)}
B_2
}
\]

Both J1 and J2 are revolute.

No additional generalized coordinate may be introduced in Phase 1.

---

# 10. Frozen analytical joint convention

These values define the validated mathematical convention.

They are not to be replaced by visually convenient axes.

All distances below are converted to SI in code.

---

## 10.1 J1

In F0:

\[
{}^0O_1=
\begin{bmatrix}
46.7740001334\\
206.520796479\\
168.166213949
\end{bmatrix}\ {\rm mm}
\]

Reference point:

\[
{}^0P_1=
\begin{bmatrix}
13.6441865559\\
59.8082297208\\
49.6013957795
\end{bmatrix}\ {\rm mm}
\]

Axis:

\[
{}^0e_1=
\begin{bmatrix}
-0.172983883749\\
-0.766044443119\\
-0.619073894725
\end{bmatrix}
\]

Joint convention:

```text
q1 = 0        mechanical middle / validated zero convention
range         [-100°, +100°]
positive q1   right-hand rule about +e1
```

Current CAD/motion-derived root-axis reference:

```text
O1_root ≈
[ 0.005720756
  0.016843849
 -0.019244126 ] m

e1_root ≈
[-0.172991077592
 +0.766044443119
 +0.619071884550]
```

The vector above describes the unoriented root-frame line. The corrected
positive-q root direction is its opposite:

```text
[+0.172991077592,
 -0.766044443119,
 -0.619071884550]
```

The sign of an axis line extracted from CAD mate geometry is geometrically interchangeable until it is reconciled to the frozen positive-q convention.

---

## 10.2 J2

In F0:

\[
{}^0O_2=
\begin{bmatrix}
220.769578657\\
203.969322110\\
117.878492101
\end{bmatrix}\ {\rm mm}
\]

Reference point:

\[
{}^0P_2=
\begin{bmatrix}
146.509578612\\
203.969322110\\
138.628491938
\end{bmatrix}\ {\rm mm}
\]

Axis:

\[
{}^0e_2=
\begin{bmatrix}
-0.963108008610\\
0.000000000000\\
0.269115149612
\end{bmatrix}
\]

In F1 at the zero pose:

\[
{}^1e_2=
\begin{bmatrix}
-0.005370412855\\
0.999985579229\\
0.000000000000
\end{bmatrix}
\]

Its real misalignment from \(+Y_1\) is approximately:

\[
0.30770347^\circ
\]

Do not replace it by exactly \(+Y_1\).

Joint convention:

```text
q2 = 0        CAD / validated zero pose
range         [-180°, +180°] for visual/control model
positive q2   right-hand rule about +e2
```

Current CAD/motion-derived root-axis reference:

```text
O2_root ≈
[-0.03699854
  0.20396932
  0.13240426] m

e2_root ≈
[-0.963104881333
  0
 -0.269126341244]
```

Again, mate-axis sign may be reversed geometrically. The final sign must follow the frozen q convention.

---

# 11. Current CAD mate evidence for the joints

The builder must parse `mates.json`.

Do not search for a mate only by generic type and assume it is a joint. Use the explicit current reference evidence below and then validate its axis line.

## 11.1 J1 CAD evidence

Current reference mate:

```text
feature_name = Concentric120
mate_type    = CONCENTRIC
```

It connects:

```text
03_polemount_6801_v3-1
6801^Measurement_for_math-1
```

One current root-frame direction is:

```text
[-0.172991077592195,
 +0.766044443118977,
 +0.619071884549790]
```

which is the same geometric axis line as the previously identified J1 motion axis, up to sign.

## 11.2 J2 CAD evidence

Current reference mate:

```text
feature_name = Concentric99
mate_type    = CONCENTRIC
```

It connects:

```text
u3_drivedisc_DEC_unimount_v3-2
6001^Measurement_for_math-1
```

One current root-frame direction is:

```text
[-0.963104881333511,
 ~0,
 -0.269126341244338]
```

which agrees with the previously identified J2 motion axis.

## 11.3 Joint-line comparison

Axis direction equivalence must be sign-insensitive:

\[
\theta =
\cos^{-1}
\left(
\left|
e_a^T e_b
\right|
\right)
\]

For two axis lines:

\[
L_a:p_a+\lambda e_a,
\qquad
L_b:p_b+\mu e_b
\]

compare their shortest line distance.

Recommended current validation thresholds:

```text
axis angular mismatch      <= 0.05 deg
axis-line distance         <= 0.10 mm
```

If either current J1 or J2 evidence violates the tolerance:

```text
FAIL MODEL BUILD
```

Do not average two inconsistent axes and continue.

---

# 12. Rigid-body zero-pose frames

Frozen zero-pose F1 basis:

```text
X1 = [ 0.21132348, -0.64277834,  0.73632764]
Y1 = [-0.96198699, -0.00345203,  0.27307347]
Z1 = e1
```

\[
R_{01}(0)=
\begin{bmatrix}
0.211323479647 & -0.961986986873 & -0.172983883749\\
-0.642778340194 & -0.003452034842 & -0.766044443119\\
0.736327639253 & 0.273073470960 & -0.619073894725
\end{bmatrix}
\]

Frozen zero-pose F2 basis:

```text
x2 = [-0.20615115,  0.64280097, -0.73777274]
y2 = [-0.17298748, -0.76603323, -0.61908676]
z2 = e2
```

\[
R_{02}(0)=
\begin{bmatrix}
-0.206151147883 & -0.172987479250 & -0.963108008610\\
0.642800970139 & -0.766033232169 & 0\\
-0.737772740764 & -0.619086762284 & 0.269115149612
\end{bmatrix}
\]

\[
R_{12}(0)\approx
\begin{bmatrix}
-0.999985579077 & -0.000017440709 & -0.005370412855\\
-0.005370412854 & -0.000000093665 & 0.999985579229\\
-0.000017440960 & 0.999999999848 & 0
\end{bmatrix}
\]

and:

\[
{}^1r_{O_1O_2}
=
\begin{bmatrix}
1.381144045\\
-181.104917287\\
2.987927655
\end{bmatrix}\ {\rm mm}.
\]

These define the analytical body-frame convention.

---

# 13. Frozen kinematic convention

Use:

\[
R_z(q)=
\begin{bmatrix}
\cos q&-\sin q&0\\
\sin q&\cos q&0\\
0&0&1
\end{bmatrix}
\]

\[
R_{01}(q_1)
=
R_{01}(0)R_z(q_1)
\]

\[
R_{12}(q_2)
=
R_{12}(0)R_z(q_2)
\]

\[
R_{02}(q_1,q_2)
=
R_{01}(q_1)R_{12}(q_2).
\]

J2 origin motion:

\[
{}^0O_2(q_1)
=
{}^0O_1
+
R_{01}(q_1)\,{}^1r_{O_1O_2}.
\]

The Model Builder may use equivalent homogeneous-transform/Rodrigues implementations, but numerical output must match this convention.

---

# 14. Geometry animation contract

The imported triangle vertices are initially in `assembly_root`.

Convert them once to F0 during model build/cache generation.

Do not re-tessellate CAD during animation.

Do not redraw individual triangles every simulation step.

Preferred MATLAB rendering architecture:

```text
one/few patch objects per component
+
hgtransform / homogeneous transform matrices
```

or an equivalently efficient vectorized approach.

## 14.1 B0

At all q:

```text
H_B0 = I
```

## 14.2 B1

B1 follows J1 only.

## 14.3 B2

B2 follows J1 and J2.

The implementation must respect that the J2 axis itself is carried by B1.

At:

```text
q1 = 0
q2 = 0
```

all B0/B1/B2 geometry must reproduce the imported `S0_ZERO` geometry exactly within floating-point tolerance.

## 14.4 AUX_DRIVE

Retain correct S0 geometry in `TrackerModel`. The viewer hides the two belt
meshes by default per the explicit user presentation decision; this is not a
scope deletion or semantic reclassification. `ShowBelts=true` restores them.

Carry `GT2_16T-1` with B1 and `GT2_16T-2` with B0. Do not invent
relative pulley spin or flexible-belt motion.

## 14.5 Ground-aligned display frame

F0 remains the engineering frame and is not changed for presentation. MATLAB
graphics convention displays +Z vertically, while physical up is +Y0. The
default viewer therefore applies:

\[
R_{display\leftarrow F0}=
\begin{bmatrix}
1&0&0\\
0&0&-1\\
0&1&0
\end{bmatrix}
\]

to one parent graphics transform shared by every rigid group and joint-axis
overlay. A display-only Z translation then places the minimum B0 vertex at
`Z_display = 0`. This transform must never modify cached F0 geometry, joint
definitions, mass properties, physics parameters, or kinematic outputs.

---

# 15. Frozen analytical dynamics parameter interface

The Model Builder must create a dedicated, easy-to-edit aggregate physical parameter source.

Recommended file:

```text
config/trackerPhysicalParams.m
```

The user must be able to change the aggregate moving-body parameters without editing Model Builder internals.

The intended edit points are:

```text
B1.mass
B1.r_O1C1_F1
B1.Ic_F1

B2.mass
B2.r_O2C2_F2
B2.Ic_F2
```

---

## 15.1 B1 frozen current parameters

\[
m_1 = 0.60257\ {\rm kg}
\]

\[
{}^1r_{O_1C_1}
=
\begin{bmatrix}
0.008088478071\\
0.064232996416\\
0.061288824664
\end{bmatrix}
{\rm m}
\]

\[
{}^1I_{C_1}
\approx
\begin{bmatrix}
0.010536587499 & 0.001009114567 & 0.002189746100\\
0.001009114567 & 0.009905725572 & -0.001086140192\\
0.002189746100 & -0.001086140192 & 0.010870515897
\end{bmatrix}
{\rm kg\,m^2}.
\]

---

## 15.2 B2 frozen current parameters

\[
m_2 = 0.30680\ {\rm kg}
\]

\[
{}^2r_{O_2C_2}
=
\begin{bmatrix}
0.004235819400\\
0.003305484296\\
0.237641625357
\end{bmatrix}
{\rm m}
\]

\[
{}^2I_{C_2}
\approx
\begin{bmatrix}
0.003058245999 & -0.000287964999 & -0.000837678994\\
-0.000287964999 & 0.002727614984 & -0.000539219996\\
-0.000837678994 & -0.000539219996 & 0.001598525999
\end{bmatrix}
{\rm kg\,m^2}.
\]

The tensor convention above is the already corrected standard tensor convention.

Version 1.1 values are a rigid frame re-expression of the v1.0 aggregate
parameters. Mass is unchanged, and the F0 COM and F0 inertia tensors are
preserved to numerical precision; CAD component masses were not substituted.

Do not replace it with raw SolidWorks cross-term signs.

---

# 16. CAD mass-property data policy

`components.json` contains per-visible-part CAD mass properties in assembly root and raw SolidWorks moment/product terms.

Store these inside:

```matlab
model.cadMass
```

They are useful for:

- revision comparisons,
- checking new part mass,
- COM audits,
- future automatic aggregate-body updates,
- detecting major CAD/material changes.

They do not automatically overwrite:

```matlab
model.physics.B1
model.physics.B2
```

A future helper may combine component mass properties using the parallel-axis theorem, but applying those results to the validated dynamics must require an explicit user action/revision.

---

# 17. Current CAD-group mass audit reference

For the current visible seed mapping, CAD component data give approximately:

```text
B0 CAD visible mass  = 0.5732813706 kg

B1 CAD visible mass  = 0.6118198336 kg
B1 CAD COM_root      =
[-0.01421916,
  0.15490821,
  0.11989036] m

B2 CAD visible mass  = 0.3055888370 kg
B2 CAD COM_root      =
[ 0.00067394,
  0.20416424,
  0.14269012] m

AUX_DRIVE CAD mass   = 0.0217263723 kg
```

After the current root → F0 conversion:

```text
B1 CAD COM_F0 ≈
[-0.02428230,
  0.15490821,
  0.15390267] m

B2 CAD COM_F0 ≈
[-0.00938921,
  0.20416424,
  0.17670243] m
```

These are useful regression/audit values.

They are not permission to replace the frozen analytical aggregate parameters.

---

# 18. Required MATLAB TrackerModel structure

The exact internal implementation may vary, but the public model should expose at least:

```matlab
model.meta
model.frames
model.components
model.geometry
model.groups
model.joints
model.cadMass
model.physics
model.validation
```

Recommended semantics:

```matlab
model.meta.schemaVersion
model.meta.cadSnapshot
model.meta.cadConfiguration
model.meta.sourceFolder

model.frames.H_root_from_F0
model.frames.H_F0_from_root
model.frames.R01_0
model.frames.R12_0

model.components
model.geometry

model.groups.B0
model.groups.B1
model.groups.B2
model.groups.AUX_DRIVE

model.joints.J1.origin_F0
model.joints.J1.axis_F0
model.joints.J1.qMin
model.joints.J1.qMax
model.joints.J1.validated

model.joints.J2.origin_F0
model.joints.J2.axis_F0
model.joints.J2.qMin
model.joints.J2.qMax
model.joints.J2.validated

model.cadMass.components
model.cadMass.visibleAssemblyAggregate

model.physics.B1
model.physics.B2

model.validation.report
model.validation.pass
```

---

# 19. Public MATLAB API

Phase 1 should provide a simple user-facing API.

## Build

```matlab
model = buildTrackerModel(cadExportFolder);
```

## Validate

```matlab
report = validateTrackerModel(model);
```

## Display zero pose

```matlab
showTracker(model);
```

Equivalent to:

```matlab
showTracker(model,[0 0]);
```

## Display arbitrary pose

```matlab
showTracker(model,[q1 q2]);
```

Default presentation options are:

```matlab
showTracker(model,q,GroundAligned=true,ShowBelts=false,ShowJointAxes=true)
```

Use `GroundAligned=false` only to audit the raw engineering F0 orientation and
`ShowBelts=true` only to audit the retained belt meshes.

Angles at the public API should be clearly specified.

Recommended:

```text
internal computation = radians
viewer convenience   = optionally degrees through explicit option
```

Never silently mix degrees and radians.

## Kinematics

```matlab
state = trackerKinematics(model,q);
```

The returned state should expose at least:

```matlab
state.q
state.H_B0
state.H_B1
state.H_B2
state.O1
state.e1
state.O2
state.e2
```

---

# 20. Required project structure

Recommended agent output:

```text
TRACKER_DIGITAL_MODEL/
│
├── CONTRACT/
│   ├── TRACKER_MODEL_BUILDER_CONTRACT.md
│   └── tracker_seed_groups.json
│
├── config/
│   ├── trackerPhysicalParams.m
│   └── trackerModelSettings.m
│
├── matlab/
│   ├── buildTrackerModel.m
│   ├── loadCadBridge.m
│   ├── parseSolidWorksTransform.m
│   ├── convertGeometryRootToF0.m
│   ├── buildRigidGroups.m
│   ├── buildJointModel.m
│   ├── trackerKinematics.m
│   ├── showTracker.m
│   ├── validateTrackerModel.m
│   └── compareCadRevision.m
│
├── tests/
│   ├── testCadSchema.m
│   ├── testComponentCoverage.m
│   ├── testGeometryCounts.m
│   ├── testComponentTransforms.m
│   ├── testRootToF0.m
│   ├── testJ1Axis.m
│   ├── testJ2Axis.m
│   ├── testZeroPose.m
│   ├── testJointLimits.m
│   └── runAllTrackerTests.m
│
├── cache/
│   └── [generated cache only; never source of truth]
│
└── reports/
    └── model_build_report.md
```

The agent may improve file organization but must preserve the responsibility boundaries.

---

# 21. Required validation tests

No Model Builder is accepted without automated tests.

## 21.1 Schema test

Verify expected V2 schemas and required fields exist.

Current reference:

```text
manifest schema   = TRACKER_CAD_BRIDGE_EXPORT 2.0.0
components schema = TRACKER_CAD_BRIDGE_COMPONENTS 2.0.0
mates schema      = TRACKER_CAD_BRIDGE_MATES 2.0.0
```

## 21.2 Current baseline-count test

For the current `S0_ZERO` reference:

```text
40 included parts
120724 triangles
194 root mates
0 mass-property failures
```

For later revisions this becomes a change report, not automatically an error.

## 21.3 Component coverage test

Current seed mapping must satisfy:

```text
all current CAD components = union(B0,B1,B2,AUX_DRIVE)
intersection of any two groups = empty
unclassified current components = 0
```

## 21.4 Geometry/component-index integrity

Every triangle `component_index` must resolve to exactly one component.

Triangle counts per component must agree with `components.json`.

## 21.5 Component transform sanity

For every rigid transform rotation block:

```text
R'R ≈ I
det(R) ≈ +1
```

Reject malformed transforms.

## 21.6 Root → F0 test

For current S0:

```text
H_F0_from_root = inverse(H_root_from_F0)
```

must reproduce the complete v1.1 matrix in Section 7.3, including the
`C0 → F0` rotation and translation.

Do not repeat the earlier forward/inverse mistake.

## 21.7 J1 axis test

Validate current `Concentric120` axis against the stored root-line reference,
then transform the CAD line into F0 and validate it against the final J1 line.

Use sign-insensitive direction comparison and line-distance comparison.

## 21.8 J2 axis test

Validate current `Concentric99` axis against the stored root-line reference,
then transform the CAD line into F0 and validate it against the final J2 line.

## 21.9 Zero-pose geometry test

At:

```text
q = [0;0]
```

B0/B1/B2 transformed vertices in F0 must equal their imported S0 F0 vertices to numerical tolerance.

## 21.10 Joint-range test

Reject pose commands outside:

```text
q1 ∈ [-100°, +100°]
q2 ∈ [-180°, +180°]
```

unless an explicit override is requested for diagnostic use.

---

# 22. Later Phase-2 dynamics regression tests

These are not required to finish the basic Model Builder, but the architecture must preserve them.

Validated equation:

\[
M(q)\ddot q + C(q,\dot q)\dot q + G(q)=\tau.
\]

Known zero-pose static holding torques:

\[
\tau_1 = 0.353421363899\ {\rm N\,m}
\]

\[
\tau_2 = -0.016165481861\ {\rm N\,m}.
\]

Known numerical audit references include:

```text
max kinetic-energy-via-M error ≈ 2.78e-17 J
G finite-difference residual   ≈ 4.08e-10 N m
100k-state tau residual        ≈ 5.55e-17 N m
minimum det(M)                 ≈ 2.6158999130629047e-5
minimum eigenvalue(M)          ≈ 0.0015304556575007114
skew residual                  ≈ 1.7347e-18
```

When the MATLAB Physics Core is integrated later, these become regression tests.

Because v1.1 corrects the physical J1 line by `0.172027 deg` and `0.211249 mm`,
the v1.0 torque/dynamics audit numbers above are retained as historical
references only. They must be recomputed and explicitly accepted during Phase 2;
they are not Phase-1 acceptance gates.

The Model Builder must not silently weaken or redefine them; Phase 2 must record
both the v1.0 historical result and the accepted v1.1 replacement.

---

# 23. CAD revision workflow

For a future CAD export:

```text
new CAD export
      ↓
buildTrackerModel
      ↓
compare with previous accepted component registry
      ↓
revision report
```

The report must distinguish:

```text
ADDED COMPONENT
REMOVED COMPONENT
RENAMED/UNMATCHED COMPONENT
SOURCE FILE CHANGED
CONFIGURATION CHANGED
PARENT CHANGED
TRANSFORM CHANGED
MASS CHANGED
GEOMETRY/TRIANGLE COUNT CHANGED
MATE EVIDENCE CHANGED
```

## 23.1 If only geometry changes but topology/joints do not

Update CAD geometry after user acceptance.

Do not automatically change frozen dynamics.

## 23.2 If aggregate moving-body mass distribution changes

The user may update only:

```text
mass
COM offset
Ic
```

in `trackerPhysicalParams.m` after computing/choosing the new aggregate values.

If joint geometry is unchanged, the kinematic derivation does not need to be rewritten.

## 23.3 If J1/J2 geometry changes

This is a kinematic model revision.

Do not treat it as only a mass-property edit.

## 23.4 If a new degree of freedom appears

Stop.

This contract is a 2-DOF model contract and requires revision.

---

# 24. Agent permissions

The agent **may**:

- create MATLAB source files,
- create tests,
- create cache generation,
- create reports,
- parse JSON/CSV,
- vectorize geometry loading,
- use MATLAB graphics / `hgtransform`,
- create explicit helper functions,
- improve code organization,
- detect CAD revisions,
- produce clear diagnostics.

The agent **must**:

- use the exact current input schemas,
- preserve units,
- preserve frame labels,
- preserve q conventions,
- preserve the actual J1/J2 axes,
- keep CAD and analytical dynamics responsibilities separate,
- make unknown topology visible to the user,
- run automated tests after implementation.

---

# 25. Agent prohibitions

The agent must **not**:

- use Simscape Multibody,
- build Simulink in Phase 1,
- re-export or modify SolidWorks,
- hardcode B0/B1/B2 into the SolidWorks macro,
- replace J2 by exactly \(+Y_1\),
- reverse F0 transform direction again,
- silently infer a new component group,
- silently delete visible CAD components,
- automatically sum CAD masses into frozen B1/B2 dynamics,
- change inertia cross-term convention without an explicit conversion layer,
- change q signs/ranges because another convention looks easier,
- replace the validated analytical model with a new derivation,
- continue after a failed J1/J2 validation.

---

# 26. Error policy

Use:

```text
IF UNCERTAIN → FAIL LOUDLY OR FLAG EXPLICITLY
```

Examples:

```text
ERROR: Unclassified visible component: NewBracket-1

ERROR: J1 CAD mate axis differs from validated motion axis by 1.7 deg.

ERROR: F0 transform is singular or malformed.

ERROR: geometry_root_triangles.csv references unknown component_index 41.
```

For known non-critical Phase-1 limitations:

```text
WARNING: AUX_DRIVE carrier motion is resolved for both pulleys;
         local pulley spin and flexible-belt motion remain unresolved.
```

---

# 27. Performance requirements

The accepted CAD reference has approximately 120k triangles.

The builder/viewer should therefore:

- load geometry once,
- cache parsed geometry if useful,
- avoid repeated CSV parsing during slider movement,
- avoid recomputing SolidWorks tessellation,
- avoid one graphics object per triangle,
- update transforms rather than rebuilding geometry every frame.

Target behavior is interactive MATLAB slider motion on a normal engineering workstation.

Do not reduce geometry fidelity silently merely to gain speed.

Any optional decimation must be explicit and off by default.

---

# 28. Definition of Done — Model Builder Phase 1

Phase 1 is complete only when all of the following are true:

```text
[ ] CAD Bridge V2 folder loads with one command.
[ ] All 40 baseline visible components are recognized.
[ ] Every baseline component is mapped exactly once.
[ ] Root → F0 conversion passes.
[ ] J1 CAD/motion axis validation passes.
[ ] J2 CAD/motion axis validation passes.
[ ] q=[0,0] reproduces S0 geometry.
[ ] B1 moves only under J1.
[ ] B2 moves under J1 and J2.
[ ] B0 remains fixed.
[ ] J1/J2 limits are enforced.
[ ] AUX_DRIVE limitation is explicit, not hidden.
[ ] CAD mass properties are available as reference data.
[ ] Frozen physical parameters are stored separately.
[ ] Automated tests pass.
[ ] A model_build_report.md is generated.
[ ] No Simulink/Simscape dependency exists.
```

---

# 29. Phase order after Model Builder

Only after Phase 1 is accepted:

```text
PHASE 2
MATLAB Physics Core integration
    ↓
trackerDynamics(model,q,qdot,tau)
    ↓
regression against frozen dynamics audits
```

Then, only if useful:

```text
PHASE 3
Simulink system/control integration
```

Simulink must consume the MATLAB Physics Core.

It must not become a second independent mechanical truth.

---

# 30. Agent start instruction

Use the following instruction with the coding agent:

> Implement **Model Builder Phase 1 only** according to `TRACKER_MODEL_BUILDER_CONTRACT.md`. Treat the supplied Tracker CAD Bridge V2 export as the CAD source of truth and the frozen values in this contract as immutable validation references. Do not use Simscape Multibody and do not create Simulink yet. Do not invent missing topology or silently classify new components. Build the MATLAB project, run all automated tests, and produce `reports/model_build_report.md` containing pass/fail results, detected assumptions, unresolved items, and the exact commands needed for me to launch the viewer. Stop and report rather than changing the contract if J1/J2, F0, component coverage, or source schemas do not validate.

---

# 31. Intended user workflow after completion

Normal use should be approximately:

```matlab
model = buildTrackerModel("path\to\TRACKER_CAD_BRIDGE_V2_...");
report = validateTrackerModel(model);

showTracker(model);               % q1=0, q2=0
showTracker(model,[30 -20],"deg");
```

Later:

```matlab
state = trackerKinematics(model,[q1;q2]);
```

and, after Phase 2:

```matlab
qdd = trackerDynamics(model,q,qdot,tau);
```

The internal architecture can be sophisticated.

The user-facing workflow should remain simple.

---

**END OF CONTRACT**
