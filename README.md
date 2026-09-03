# TrackerDigitalModel

MATLAB digital model for the dual-axis solar tracker.

## Architecture

```text
SolidWorks
  -> Tracker CAD Bridge V2
  -> MATLAB Model Builder
  -> MATLAB Physics Core
  -> pre-control workspace validation
  -> later trajectory/controller
  -> optional later Simulink
```

Simscape Multibody is not used.

## Current status

- Phase 1 Model Builder: **ACCEPTED**
- Phase 2A ideal rigid-body physics: **ACCEPTED**
- Pre-control full workspace/motion/interference validation: **NEXT**
- Controller/trajectory: **BLOCKED until pre-control PASS**
- Simulink: not started
- local pulley spin / belt deformation: intentionally unresolved

Current configured joint ranges:

```text
J1 = [-100,+100] deg
J2 = [-180,+180] deg
```

These are not yet declared the final mechanically safe envelope. See:

- `PROJECT_STATE.md`
- `PRE_CONTROL_VALIDATION_CONTRACT.md`
- `AGENTS.md`
- `TRACKER_PHASE2_DYNAMICS_CONTRACT.md`
- `reports/phase2a_build_report.md`

## Key rule

A successful viewer pose and successful rigid-body dynamics tests do not by themselves prove collision-free motion across the full joint workspace. The safe operating envelope must be explicitly validated before controller development.
