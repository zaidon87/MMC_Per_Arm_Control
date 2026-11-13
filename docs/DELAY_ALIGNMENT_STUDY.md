# Communication delay and timestamp alignment

## Two different feedback implementations

For submodule i, let Vc,i be its capacitor voltage and τ the latency of the two neighbor values.

**Own voltage sampled now, neighbors delayed:**

```text
e_i(t) = 0.5 * (Vc_{i-1}(t-τ) + Vc_{i+1}(t-τ)) - Vc_i(t)
```

**All three voltages from the same timestamp:**

```text
e_i(t) = 0.5 * (Vc_{i-1}(t-τ) + Vc_{i+1}(t-τ)) - Vc_i(t-τ)
```

The first case injects ordinary common-mode capacitor ripple into the balancing error because Vc_i and Vc_neighbors are observed at different times. The second removes this sampling mismatch, albeit with pure control delay. The source Simulink model obtains neighbors from an arm voltage vector, not a verified packet network; transport/timestamps must be implemented for hardware.

## Comparisons from the archived runs

| Delay | Fresh own sample | Aligned own sample |
|---|---|---|
| 0 ms | stable, THD(2–20)=3.7% | reference |
| 0.2 ms | stable but distorted, THD=21.1% | stable, THD≈5.1% |
| 1.0 ms | unstable, high arm current | stable, THD≈5.0% |
| 1.4 ms | not provided | clipped ±10 V initial mismatch: settles below 1 V spread at ~284 ms |
| 5.5 ms | not provided | clipped ±10 V mismatch: bounded ~26 Hz oscillation, no sustained <1 V settlement |

**Do not compare** 1.4/5.5 ms clipped initial-mismatch cases directly with 0.2/1.0 ms balanced-start cases without stating their different initial conditions.

## Conditional linear ring-consensus estimate

At 1.5 kW, a simplified half-Laplacian ring model uses κ=kv*mean(abs(iarm))/C ≈0.2*3.11/(2.2e-3)=283 s^-1 and τcrit≈π/(4κ)=2.78 ms for its worst mode. The ~1.4 ms aligned case lies below this estimate; the ~5.5 ms case above it. This is a **model-dependent stability interpretation**, not a proven maximum network latency. Deadband and a clipped duty term alter both the residual imbalance and the mode frequency.

The source analysis identifies a 0.1 V neighbor-error deadband. It can freeze a slow spatial ring mode with a finite (~0.2–0.4 V) residual offset even when large transients settle.

## Required follow-up for hardware claims

Timestamp or buffer the local Vc sample, characterize clock skew and packet jitter, inject missing/late messages and capacitor tolerance, and repeat high-frequency current THD with sufficient anti-aliased bandwidth. Validate circulating current and protection separately.
