# AGENTS.md — Tracker Digital Model

## Architecture

SolidWorks -> Tracker CAD Bridge V2 -> MATLAB Model Builder -> MATLAB Physics Core -> optional later Simulink.

Simscape Multibody is not part of the architecture.

## Accepted state

### Phase 1 — ACCEPTED
- CAD Bridge V2 source validated.
- 40-component baseline mapped.
- F0/J1/J2 validated.
- B0/B1/B2 kinematics working.
- ground-aligned viewer working.

### Phase 2A — ACCEPTED
- M(q), C(q,qdot), G(q)
- forward/inverse dynamics
- mechanical energy/power
- numerical joint-limit events
- 45/45 automated tests in accepted report
- no Simulink/Simscape

## Current required work

**PRE-CONTROL MECHANICAL WORKSPACE & MOTION VALIDATION**

Do not begin controller or trajectory-control implementation until this gate passes.

Current configured limits:

```text
J1 = [-100 deg,+100 deg]
J2 = [-180 deg,+180 deg]
```

These are model limits, not yet proof of a collision-free mechanical workspace.

Follow `PRE_CONTROL_VALIDATION_CONTRACT.md`.

## Pre-control principles

- Validate the entire q1-q2 operating envelope, not only zero pose or a few screenshots.
- Check limits, corners, dense interior poses and continuity.
- B0 must remain fixed.
- B1 must respond only to J1.
- B2 must follow J1 and J2.
- J2 origin and axis must be carried by J1 and must not move merely because q2 changes.
- GT2 pulley carrier attachment must remain correct throughout motion.
- A viewer that looks correct is not proof of collision freedom.
- Collision/interference must be checked explicitly.
- If the rectangular q1-q2 range is not mechanically safe, reduce limits or define a coupled admissible workspace before control work.

## AUX_DRIVE

Known:
- GT2_16T-1 carrier = B1 motor
- GT2_16T-2 carrier = B0 motor

Unresolved:
- local pulley spin
- belt deformation/motion
- AUX_DRIVE analytical inertia

Do not invent unresolved drive motion.

## Phase 2A physics boundaries

Do NOT invent:
- friction
- backlash
- motor electrical dynamics
- transmission efficiencies
- driver losses
- physical stop stiffness/damping/restitution
- sensor noise
- wind/cable loads

## Engineering rules

- If uncertain, fail loudly or report explicitly.
- Do not silently reclassify CAD components.
- Do not silently overwrite aggregate dynamics with CAD per-component mass properties.
- Preserve actual CAD-derived joint axes.
- Internal angles are radians unless an API explicitly declares degrees.
- Joint limits have one source of truth in `model.joints`.
- A topology, axis, or DOF change requires contract revision.

## Collaboration workflow

- `main` = accepted/stable checkpoints.
- `dev/<task>` = local development.
- `chatgpt/<task>` = ChatGPT changes when GitHub write access is available.
- Merge through PRs where practical.
- Update `PROJECT_STATE.md` after every accepted checkpoint.
