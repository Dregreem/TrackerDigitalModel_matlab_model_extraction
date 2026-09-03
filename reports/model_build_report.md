# Tracker Model Builder Phase 1 — Build Report

**Build date:** 2026-09-03  
**MATLAB:** R2025b  
**Contract:** `TRACKER_MODEL_BUILDER_CONTRACT.md` Version 1.3 (corrected frame + carrier/limit policy)  
**CAD source of truth:** `TRACKER_CAD_BRIDGE_V2_20260903_153150` / `S0_ZERO` / `Default`  
**Overall result:** **PASS**

## Scope result

Model Builder Phase 1 was implemented as a MATLAB project. No Simulink model, Simscape Multibody dependency, CAD re-export, topology invention, automatic component classification, or automatic replacement of frozen B1/B2 analytical parameters was introduced.

The model exposes `meta`, `frames`, `components`, `geometry`, `groups`, `joints`, `cadMass`, `physics`, and `validation`. Geometry is loaded once from the root-frame triangle CSV and converted once to F0. The default viewer applies one display-only parent transform to ground-align the complete system and renders 38 patches because the two retained belt meshes are hidden.

## Off-axis correction audit

The first v1.0 implementation reproduced zero pose but separated the rigid groups at nonzero q. The transform anchor and B2 multiplication order were already correct; the failure was an inconsistent frame contract.

| Finding | Before correction | Corrected v1.1 |
|---|---:|---:|
| CAD datum interpretation | `Coordinate System1 = F0` | Coordinate System1 is `C0`; explicit `C0 → F0` rotation |
| Missing alignment | identity | `31.2239055789 deg` about +Y |
| J1 CAD-to-final-axis mismatch | `19.771516°` | `0°` |
| J1 CAD-to-final-line distance | `21.82–23.51 mm` | `6.06e-12 mm` |
| J2 CAD-to-final-axis mismatch | `31.223906°` | `0°` |
| J2 CAD-to-final-line distance | `29.06–34.24 mm` | `7.26e-11 mm` |
| J1 frozen-value correction | — | direction `0.172027 deg`; origin projection `0.211249 mm` |
| J2 origin projection | — | `0.001706 mm` |

The corrected F0 transform retains the manifest Coordinate System1 origin and adds the missing orientation. B1/B2 aggregate COM vectors and inertia tensors were re-expressed in the corrected body frames; their F0 COM and F0 inertia values remain unchanged to numerical precision.

## Contract-gate validation

| Gate | Result | Evidence |
|---|---:|---|
| TrackerModel public structure | PASS | All required public fields present |
| CAD Bridge V2 schemas | PASS | Manifest `TRACKER_CAD_BRIDGE_EXPORT 2.0.0`; components `TRACKER_CAD_BRIDGE_COMPONENTS 2.0.0`; mates `TRACKER_CAD_BRIDGE_MATES 2.0.0` |
| S0_ZERO baseline counts | PASS | 40 components; 120724 triangles; 194 root mates; 0 mass-property failures |
| Component scope | PASS | Every exported component is visible, unsuppressed, and included in both declared scopes |
| Component coverage | PASS | B0=17; B1=15; B2=4; AUX_DRIVE=4; duplicates=0; unclassified=0 |
| Geometry/component-index integrity | PASS | 120724 reported and imported triangles; each index resolves exactly once; all per-component counts agree |
| Component transforms | PASS | Maximum orthogonality error `2.12e-15`; maximum determinant error `8.88e-16` |
| Root to F0 | PASS | Inverse error `1.24e-16`; corrected full-matrix reference error `2.82e-17` |
| J1 / Concentric120 | PASS | CAD line transformed into F0: angular mismatch `0 deg`; line distance `6.05808755e-12 mm` |
| J2 / Concentric99 | PASS | CAD line transformed into F0: angular mismatch `0 deg`; line distance `7.26069897e-11 mm` |
| Zero pose | PASS | Maximum B0/B1/B2 transform error `0`; imported S0 F0 geometry is unchanged |
| Motion hierarchy | PASS | B0 fixed; B1 responds only to J1; B2 responds to J1 and J2; J2 axis is carried by B1 |
| Frozen rotation convention | PASS | Numerical pose agrees with frozen `R01(0)`, `R12(0)`, and right-hand `Rz(q)` convention |
| Joint limits | PASS | q1 `[-100,100] deg`; q2 `[-180,180] deg`; out-of-range commands rejected unless explicit diagnostic override is used |
| CAD mass / physics separation | PASS | CAD values remain references; corrected body-frame parameter expressions preserve the original F0 COM/inertia |
| AUX_DRIVE carrier policy | PASS | `GT2_16T-1→B1` via `Concentric180`; `GT2_16T-2→B0` via `Concentric187`; local spin/belt motion unresolved |
| Ground-aligned display | PASS | Physical F0 +Y maps to display +Z; minimum B0 vertex `Y0=-0.0002 m` maps exactly to `Z_display=0` |
| Belt visibility policy | PASS | 40 components remain in the model; default viewer renders 38 patches and 0 belt meshes; `ShowBelts=true` restores both |
| Viewer smoke test | PASS | Ground-aligned rendering at `[-53.80,-180] deg`; 38 patches, two sliders, two displayed joint axes |
| Simulink / Simscape exclusion | PASS | No `.slx`/`.mdl` artifact and no Simulink or Simscape dependency |

## Automated tests

Current combined Phase 1 + Phase 2A command result: **45 passed, 0 failed, 0 incomplete**. MATLAB Code Analyzer result: **0 issues**. The table below preserves the original Phase 1 test inventory; Phase 2A additions are listed in `phase2a_build_report.md`.

| Test | Result |
|---|---:|
| `testCadRevision/acceptedExportHasNoRevisionDifferences` | PASS |
| `testCadSchema/expectedV2DocumentsLoad` | PASS |
| `testComponentCoverage/everyComponentMappedExactlyOnce` | PASS |
| `testComponentCoverage/auxiliaryDriveStatusIsExplicit` | PASS |
| `testComponentTransforms/transformsAreProperRigidTransforms` | PASS |
| `testGeometryCounts/baselineAndPerComponentCountsMatch` | PASS |
| `testGeometryCounts/everyGeometryIndexResolves` | PASS |
| `testJ1Axis/concentric120Validates` | PASS |
| `testJ1Axis/j1PivotIsFixedByB1Motion` | PASS |
| `testJ2Axis/concentric99ValidatesWithoutIdealization` | PASS |
| `testJ2Axis/carriedJ2PivotIsSharedByB1AndB2` | PASS |
| `testJointLimits/boundaryCommandsAreAccepted` | PASS |
| `testJointLimits/q1BelowLimitIsRejected` | PASS |
| `testJointLimits/q1AboveLimitIsRejected` | PASS |
| `testJointLimits/q2BelowLimitIsRejected` | PASS |
| `testJointLimits/q2AboveLimitIsRejected` | PASS |
| `testJointLimits/explicitDiagnosticOverrideIsAccepted` | PASS |
| `testPhysicalParams/frameReexpressionPreservesF0MassDistribution` | PASS |
| `testPhysicalParams/correctedInertiasRemainSymmetricPositiveDefinite` | PASS |
| `testRootToF0/inverseAndTranslationDirectionAreCorrect` | PASS |
| `testViewer/viewerCreatesGeometryControlsAndJointAxes` | PASS |
| `testViewer/optionalBeltAuditViewRestoresBothMeshes` | PASS |
| `testViewer/displayFramePlacesB0OnHorizontalGround` | PASS |
| `testViewer/sliderCallbacksUpdateHierarchy` | PASS |
| `testZeroPose/zeroPoseLeavesImportedGeometryUnchanged` | PASS |
| `testZeroPose/rigidBodyHierarchyIsCorrect` | PASS |
| `testZeroPose/poseMatchesFrozenRotationConvention` | PASS |

## Detected assumptions

1. The supplied `TRACKER_CAD_BRIDGE_V2_20260903_153150` folder is the accepted current `S0_ZERO` export. Its schema names, versions, snapshot, configuration, component scope, and frozen counts were validated rather than inferred.
2. Contract v1.1 treats `Coordinate System1` as CAD datum C0. Its origin is retained, while the explicit +Y-preserving `31.2239055789 deg` alignment maps C0 vectors into analytical F0.
3. `tracker_seed_groups.json` is the only semantic classification authority for the 40-component baseline. No name heuristics or fallback classification exists.
4. The triangle CSV is already in metres and assembly-root coordinates. The builder does not re-tessellate or alter geometry fidelity.
5. Public kinematic inputs are radians. Degrees are accepted only through the viewer's explicit `Units="degrees"` option.
6. Ground alignment is presentation-only: it maps F0 +Y to display +Z and translates the full graphics tree so B0 touches `Z=0`; model geometry and kinematic outputs remain in F0.
7. The two explicitly named belt meshes are hidden only in the default viewer. They remain loaded, classified, counted, and available with `ShowBelts=true`.

## Unresolved items

- **AUX_DRIVE relative motion remains intentionally unresolved.** `GT2_16T-1` is carried by B1 and `GT2_16T-2` by B0 using validated concentric-mate evidence. Local pulley spin and flexible-belt behavior are not claimed.
- The historical v1.0 Phase-2 torque/dynamics audit values require recomputation under the corrected J1 line before they can become v1.1 regression gates. This does not block Model Builder Phase 1.
- No other Phase 1 validation item is unresolved.

## Exact viewer launch commands

From the MATLAB Command Window:

```matlab
proj = openProject("C:\Users\Kerem Bayer\Desktop\KBStracker\Kerem_astro\Matlab_model_extraction\TrackerDigitalModel.prj");
model = buildTrackerModel(fullfile(proj.RootFolder,"TRACKER_CAD_BRIDGE_V2_20260903_153150"));
showTracker(model,[0 0]);
```

The viewer opens ground-aligned at zero pose with J1/J2 sliders and without the two belt meshes. Dashed purple and green lines display the validated J1 and carried J2 axes. To start at a pose specified explicitly in degrees:

```matlab
showTracker(model,[30 -20],Units="degrees");
```

Optional audit views:

```matlab
showTracker(model,[0 0],ShowBelts=true);       % restore both belt meshes
showTracker(model,[0 0],GroundAligned=false); % show raw engineering F0 orientation
```

To launch MATLAB and the zero-pose viewer directly from PowerShell:

```powershell
matlab -r "proj=openProject('C:\Users\Kerem Bayer\Desktop\KBStracker\Kerem_astro\Matlab_model_extraction\TrackerDigitalModel.prj'); model=buildTrackerModel(fullfile(proj.RootFolder,'TRACKER_CAD_BRIDGE_V2_20260903_153150')); showTracker(model,[0 0]);"
```

To rerun the complete automated suite from MATLAB:

```matlab
proj = openProject("C:\Users\Kerem Bayer\Desktop\KBStracker\Kerem_astro\Matlab_model_extraction\TrackerDigitalModel.prj");
results = runAllTrackerTests();
```
