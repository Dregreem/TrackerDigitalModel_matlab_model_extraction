# PROJECT_STATE.md

## Checkpoint
**Phase 1: ACCEPTED**

### Verified
- Tracker CAD Bridge V2 import and schemas
- 40-component baseline coverage
- F0 transform
- J1/J2 CAD mate validation
- B0/B1/B2 kinematics
- horizontal base at Z=0
- belt meshes hidden by default
- 27/27 automated tests
- MATLAB Code Analyzer: 0 findings
- no Simulink
- no Simscape Multibody

### Intentional Phase 1 limitation
AUX_DRIVE detailed relative pulley/belt motion is not yet modeled.

## Phase 2A code already demonstrated locally
- trackerMassMatrix
- trackerCoriolisMatrix
- trackerGravityVector
- trackerDynamics
- trackerInverseDynamics
- trackerEnergy
- trackerPower

Observed example consistency:
`trackerInverseDynamics(..., trackerDynamics(...))` reproduced the commanded torque `[0.4; 0.05]`.

Observed zero-pose gravity:
- G1 = 0.353140721921649 N m
- G2 = -0.0161552496631221 N m

These are working-state observations; formal Phase 2A acceptance still requires the frozen regression suite.

## Immediate pending changes
- Change J1 limit to [-100 deg, +100 deg].
- Keep J2 at [-180 deg, +180 deg].
- Fix GT2_16T-1 carrier motion so it remains attached to the moving B1 motor.
- Keep GT2_16T-2 carrier motion with the fixed/base B0 motor.
- Pulley local spin and belt deformation remain explicitly unresolved.
- Complete/verify Phase 2A regression tests.
- Do not add unknown motor/friction/hard-stop physics.

## Continuity
This file is the repository-level handoff state. Update it whenever a checkpoint is accepted.
