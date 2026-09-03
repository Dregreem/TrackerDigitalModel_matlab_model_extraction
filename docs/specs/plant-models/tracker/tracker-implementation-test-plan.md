# Tracker Phase 2A implementation and test plan

## Implementation order

1. Make joint limits and stop policy the first Phase 2A contract item.
2. Add dynamics parameters without duplicating joint limits or inventing stop coefficients.
3. Build rigid-body COM, inertia, and Jacobian state from Phase 1 kinematics.
4. Implement `M`, `C`, and `G`.
5. Implement forward and inverse dynamics.
6. Implement terminal event surfaces; leave physical impact parameters unresolved.
7. Implement energy, power, and ODE right-hand-side interfaces.
8. Run automated regression and source-scope gates.

## Numerical design

- `M` uses analytical rigid-body Jacobian assembly.
- `C` uses a configurable central-difference step on `M`.
- Linear solves use MATLAB matrix division; no explicit inverse is formed.
- Event surfaces are positive inside the legal range and cross zero in the
  negative direction when a bound is exceeded.
- There is no `min(max(q,...))` state clamp and no compliant-stop placeholder.
- `ode45` event integration is supported through `trackerJointLimitEvents` and
  `trackerPlantRhs`. MATLAB documents event functions through the `Events`
  option at https://www.mathworks.com/help/matlab/ref/ode45.html.

## Automated tests

| Requirement | Test evidence |
|---|---|
| immutable limits | exact model values; dynamics config has no limit fields |
| input validation | sizes, finiteness, limit and penetration errors |
| mass matrix | symmetry, Cholesky factorization, frozen grid minima |
| gravity | potential-energy finite difference |
| Coriolis | skew/power identity |
| forward/inverse | deterministic state/torque round trip |
| static hold | `tau=G` gives zero acceleration |
| event mode | values, terminal flags, crossing directions from model limits |
| energy/power | directional derivative equals actuator plus disturbance power |
| scope | no Simulink/Simscape files or source references |
| regression | v1.1 zero-pose and grid values generated and frozen in report |

## Acceptance tolerances

| Check | Tolerance |
|---|---:|
| mass symmetry | 1e-12 Frobenius norm |
| forward/inverse residual | 1e-10 N m |
| gravity finite difference | 1e-7 N m |
| skew power identity | 1e-8 W |
| energy/power directional balance | 2e-5 W |

## Deferred to Phase 2B

Trajectory generation, feedback/feedforward control, gravity-compensation
application logic, torque sizing, full scenario simulation, CAD time animation,
Simulink, and Simscape remain excluded.
