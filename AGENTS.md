# AGENTS.md — Tracker Digital Model

## Architecture
SolidWorks -> Tracker CAD Bridge V2 -> MATLAB Model Builder -> MATLAB Physics Core -> optional later Simulink.

Simscape Multibody is not part of the architecture.

## Current accepted state
- Model Builder Phase 1 accepted.
- CAD Bridge V2 load/schema path validated.
- 40 visible + unsuppressed + active components mapped.
- F0, J1 and J2 corrected and validated against CAD mate evidence.
- B0/B1/B2 kinematic chain works.
- Base aligned to horizontal Z=0.
- Belts hidden by default.
- 27/27 automated Phase 1 tests passed.
- MATLAB Code Analyzer: 0 findings.
- AUX_DRIVE detailed pulley/belt relative motion remains intentionally unresolved.

## Immediate pending corrections
1. J1 operational range = [-100 deg, +100 deg].
2. J2 remains [-180 deg, +180 deg].
3. GT2_16T-1 inherits carrier/body motion from B1 / Nima 17 40x42x5mm-1.
4. GT2_16T-2 inherits carrier/body motion from B0 / Nima 17 40x42x5mm-2.
5. Pulley local spin and belt deformation remain unresolved until explicitly modeled.

## Phase 2A scope
Only validated rigid-body physics:
- frozen B1/B2 aggregate physical parameters
- M(q)
- C(q,qdot)
- G(q)
- inverse dynamics
- forward dynamics
- joint mechanical power
- kinetic / gravitational potential energy
- joint-angle validation
- solver events at joint limits

Do NOT invent:
- friction
- backlash
- motor electrical dynamics
- gearbox/belt efficiency
- driver losses
- physical hard-stop stiffness/damping
- sensor noise

## Engineering rules
- If uncertain, fail loudly or report explicitly.
- Do not silently reclassify new CAD components.
- Do not silently overwrite validated aggregate dynamics from CAD component mass properties.
- Preserve actual CAD-derived joint axes; do not idealize J2 to +Y1.
- Internal angle units are radians unless an API explicitly declares degrees.
- Joint limits must have one source of truth used by viewer, kinematics, dynamics, trajectories, solver events and tests.
- Any change to joint topology, joint-axis geometry or DOF count requires a model-contract revision.

## Collaboration workflow
- `main` = accepted/stable checkpoints only.
- `dev/<task>` = local/user/Codex development.
- `chatgpt/<task>` = ChatGPT GitHub changes once repository access is enabled.
- Merge changes through pull requests when practical.
- Update PROJECT_STATE.md at every accepted checkpoint.
