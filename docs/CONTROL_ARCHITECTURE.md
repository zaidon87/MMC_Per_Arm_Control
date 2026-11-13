# Control architecture

## Plant and organization

This system is a **single-phase grid-connected MMC** with two arms and eight half-bridge submodules per arm. The common DC link is 800 V; every SM capacitor nominally stores 0.5 × 2.2 mF × (100 V)^2 = **11 J**, giving 88 J nominal capacitor energy per arm. Arm inductance is 5 mH and resistance is 0.5 Ω. Grid connection is modeled as 230 V RMS, 50 Hz.

```text
                        Grid / PCC measurements
                                   |
                  +----------------+----------------+
                  |                                 |
          Upper-arm leader                   Lower-arm leader
          SOGI/PLL, P-Q loop                 SOGI/PLL, P-Q loop
          Arm energy / current               Arm energy / current
                  |     exchange W_arm (delayed)    |
                  +-----------<----->--------------+
                  |                                 |
                m_upper                           m_lower
                  |                                 |
          8 local HB controllers            8 local HB controllers
          neighbors in arm ring              neighbors in arm ring
          local duty + PS PWM                local duty + PS PWM
                  |                                 |
             Half-bridge gates                Half-bridge gates
```

## Local voltage balancing

A local controller can use the neighbor-average error

\[e_i = \tfrac12 (V_{c,i-1}+V_{c,i+1}) - V_{c,i}.\]

Voltage-based duty correction is modulated by the arm-current direction so that an undercharged capacitor is inserted for charging and an overcharged capacitor is preferentially bypassed (the exact sign convention depends on the arm and switch definition in the MATLAB Function block). The tested gain is `k_v=0.2`, and later experiments cap the local correction at `|delta m_i| <= 0.1` with a deadband; see the embedded controller implementation for exact expressions.

Under the initially unbounded correction, a 20 V mismatch can produce large controller demands and duty saturation, perturbing arm voltage/current. The clipped variants reduce this problem.

## Time alignment and link latency

**Fresh-own-sample comparison:**

\[e_i(t) = \tfrac12 [V_{c,i-1}(t-	au)+V_{c,i+1}(t-	au)]-V_{c,i}(t).\]

**Time-aligned comparison:**

\[e_i(t) = \tfrac12 [V_{c,i-1}(t-	au)+V_{c,i+1}(t-	au)]-V_{c,i}(t-	au).\]

The first expression mixes timestamps and can turn common-mode capacitor ripple into spurious balancing commands. The second compares values from the same time instant. The 1 ms fresh-own run was unstable; the 1 ms aligned run remained bounded in the supplied 2-second tests.

## Linearized consensus interpretation

Under simplifying assumptions with effective gain `kappa = k_v * mean_abs_arm_current / C`, ring modes of the half-Laplacian give a worst-case delay criterion `tau < pi/(4*kappa)` for a fully delayed comparison. With `k_v=0.2`, representative current `3.11 A`, and `C=2.2 mF`, `kappa≈283 s^-1` and `tau_crit≈2.78 ms`. This estimate is **conditional**: clipping, deadband, modulation, variable current and measurement filtering invalidate a direct universal stability guarantee. The 1.4 ms and 5.5 ms aligned runs are supportive numerical examples, not a proof for every operating point.

## Boundary of decentralization

Each arm retains a leader for outer/inner control. In the provided Simulink environment, neighbor samples are read from the arm capacitor-voltage vector; the physical message transport is not separately demonstrated. A real distributed implementation must implement timestamping, buffering, packet validity, synchronization, communication loss behavior and safe local gate limits.