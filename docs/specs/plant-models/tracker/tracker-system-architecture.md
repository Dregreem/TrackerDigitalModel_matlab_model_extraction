# Tracker plant system and architecture specification

## Scope and evidence

This specification covers the two-degree-of-freedom rigid-body physics core in
Phase 2A. The accepted Phase 1 model and `TRACKER_PHASE2_DYNAMICS_CONTRACT.md`
are the local design authorities. The CAD Bridge V2 export remains geometry and
topology truth; no new topology is inferred here.

The analytical fidelity level is a lumped rigid-body model:

- B0 is fixed.
- B1 rotates about validated J1.
- B2 is carried by B1 and rotates about validated J2.
- Flexible belts, pulley spin, backlash, friction, motor electrical dynamics,
  structural compliance, and measured stop properties are not modeled.

## Boundary and interfaces

| Class | Quantity | Shape | Unit | Meaning |
|---|---|---:|---|---|
| input `u` | `tauActuator` | 2x1 | N m | J1/J2 applied actuator torque |
| disturbance `w` | `tauDisturbance` | 2x1 | N m | external generalized torque |
| state | `q` | 2x1 | rad | joint position |
| state | `qdot` | 2x1 | rad/s | joint velocity |
| truth output `z` | `qdd` | 2x1 | rad/s^2 | joint acceleration |
| truth output `z` | `M,C,G` | matrices/vectors | SI | equation terms |
| truth output `z` | energy/power | scalar fields | J/W | audit quantities |
| measured output `y` | none | - | - | sensor modeling is not in Phase 2A |

The model is continuous-time. It has no controller sample time and no discrete
state in Phase 2A.

## Equations and conventions

```text
M(q) qdd + C(q,qdot) qdot + G(q)
    = tauActuator + tauDisturbance
```

F0 `+Y` is the upward direction. Gravitational potential is
`Vg = sum(m_i*g*y_i)`, and therefore `G = dVg/dq`. The mass matrix is assembled
from translational and rotational Jacobians of the frozen B1/B2 aggregate
properties. `C` is assembled from Christoffel coefficients computed from
central numerical derivatives of `M`.

Joint-limit handling is event based. Integration terminates on the first
outward limit crossing. This is numerical workspace enforcement, not a model of
impact, compliance, damping, or bounce. No position clamp is permitted.

## Architecture

```text
validated TrackerModel
  |- joints: axes, origins, qMin/qMax
  |- frames: R01_0, R02_0
  |- physics: aggregate B1/B2 mass properties
  `- dynamics: gravity, differentiation, stop assumptions
                    |
                    v
           rigid-body state/Jacobians
             |       |        |
             v       v        v
            M(q)   C(q,qd)    G(q)
             \       |        /
              \      |       /
               forward/inverse dynamics
                         |
                  energy + power audit
```

## Traceability and open items

| Item | Source/status |
|---|---|
| q1/q2 limits | frozen in Phase 1 and read only from `model.joints` |
| mass/COM/inertia | frozen `trackerPhysicalParams` v1.1 frame re-expression |
| gravity | conventional standard value 9.80665 m/s^2 |
| stop stiffness/damping | unresolved; not modeled |
| motor/friction/backlash | unresolved and excluded |
| AUX_DRIVE | pulley carriers resolved (`GT2_16T-1→B1`, `GT2_16T-2→B0`); local spin/belts unresolved and excluded from analytical inertia |

Standard gravity is documented by NIST at
https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b8.
