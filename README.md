# TrackerDigitalModel

Shared MATLAB digital model for the dual-axis solar tracker.

## Architecture

```text
SolidWorks
  -> Tracker CAD Bridge V2
  -> MATLAB Model Builder
  -> MATLAB Physics Core
  -> optional later Simulink
```

Simscape Multibody is not used.

## Current status

- Phase 1 Model Builder: accepted
- Phase 2A MATLAB rigid-body physics: in progress
- Simulink: not started
- Detailed belt/pulley relative motion: intentionally unresolved

See:
- `PROJECT_STATE.md` for the live checkpoint
- `AGENTS.md` for engineering rules
- `CONTRACT/` for model contracts

## Recommended repository content

```text
TrackerDigitalModel/
├── AGENTS.md
├── PROJECT_STATE.md
├── README.md
├── .gitignore
├── CONTRACT/
├── cad/
│   └── baseline/
│       └── S0_ZERO/
├── config/
├── matlab/
├── tests/
├── reports/
└── TrackerDigitalModel.prj
```

The accepted `S0_ZERO` CAD Bridge export should be committed under
`cad/baseline/S0_ZERO/` so another machine/session can reconstruct the model.
