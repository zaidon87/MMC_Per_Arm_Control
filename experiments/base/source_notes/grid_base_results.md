# Corrected grid-model results — 8 SMs per arm (reference dataset)

**Source:** corrected `three_cases_results.mat`, 11 November 2026 (evening). Three simulation cases, recorded with approximately 100 µs signal spacing after logging decimation.

**Plant:** single-phase grid-connected MMC; Vdc = 800 V, 8 SMs/arm, Csm = 2.2 mF, Larm = 5 mH, 230 V RMS / 50 Hz grid, 1,250 Hz carrier per SM, plant step Ts = 10 µs and arm-controller step Ts_ctrl = 100 µs.

**Shared updated limits:** I_max = 17 A, P_max = 2,500 W, active-power reference slew limit = 5 kW/s; startup ramp = 10 kW/s after t = 0.15 s.

| Case | Model name suffix | Operating procedure |
|---|---|---|
| A1 | `case1_kv0` | Set k_v = 0 in all 16 SMs; constant P* = 1,500 W; 2 s |
| A2 | `case2_imbalance` | Set upper SM3 = 110 V and upper SM6 = 90 V at t = 0; k_v = 0.2; P* = 1,500 W; 2 s |
| A3 | `case3_base` | P* steps 1,500/1,750/2,000/2,250/2,500/1,500 W at 0.6/1.0/1.4/1.8/2.2 s; PCC loads switch at 2.4/2.7/3.0 s; 3.2 s |

The corrected case A3 was reported sample-by-sample identical to the earlier working `grid_base.mat` simulation until t = 0.6004 s, i.e. before the first step affected by the new slew limit. This statement comes from the archived analysis, not a new simulation.

## A3 — steady-state active-power sweep (last 100 ms of each level)

| P* (W) | Measured P (W) | AC current peak (A) | Upper arm-mean Vc ripple (Vpp) | Lower arm-mean Vc ripple (Vpp) | Predicted ripple (Vpp) | Upper/lower prediction error | Max instantaneous upper/lower SM spread (V) |
|---:|---:|---:|---:|---:|---:|---|---|
| 1,500 | 1,506 | 9.22 | 4.98 | 5.13 | 5.08 | -1.9% / +1.0% | 0.37 / 0.36 |
| 1,750 | 1,754 | 10.73 | 5.78 | 5.81 | 5.90 | -2.1% / -1.6% | 0.45 / 0.42 |
| 2,000 | 2,003 | 12.23 | 6.58 | 6.64 | 6.73 | -2.2% / -1.3% | 0.46 / 0.46 |
| 2,250 | 2,250 | 13.76 | 7.47 | 7.44 | 7.57 | -1.4% / -1.7% | 0.54 / 0.53 |
| 2,500 | 2,502 | 15.29 | 8.32 | 8.27 | 8.41 | -1.1% / -1.7% | 0.58 / 0.59 |

**Definitions:** Vc ripple is the peak-to-peak excursion of the *arm-mean capacitor voltage*, averaged over five line cycles. It is not SM-to-SM spread. The analytical estimate uses the arm-energy power relation
`p_upper = (Vdc/2 - v_ac) * (i_ac/2 + P/Vdc)`, with measured P and measured grid-voltage amplitude.

- Maximum spread **between separately 20 ms-averaged SM voltages** after 0.35 s: 0.10 V upper, 0.12 V lower; mean ~0.04 V.
- Arm-mean capacitor voltage: 99.92–100.09 V; |Q| <= 5 var; modulation reference m_arm between 0.07 and 0.92.
- Circulating-current DC component: approximately P/Vdc, 1.89–3.17 A; 100 Hz component <= 0.02 A, in the original analysis sign convention.
- **Full-band current THD cannot be derived from the 100 µs logged case data** because frequencies approaching 10 kHz alias. The earlier, higher-sample-rate `grid_base.mat` run with I_max = 15 A reported converter-current THD of 5.17% at 1,500 W and 2.93% at 2,250 W. These are historical-run values, **not measurements of the corrected A3 dataset**.

## A3 — transient response

- **Four +250 W commands, each slew-limited over 50 ms:** power overshoot 29–43 W (12–17% of each increment); return within 2% of target in 45–90 ms. Both arm-mean capacitor voltages dip around 0.7–0.9 V.
- **-1,000 W command at 2.2 s, slew-limited over 200 ms:** 49 W undershoot relative to the moving target (5% of the step). Maximum SM capacitor voltage: 104.4 V (upper) and 104.7 V (lower); maximum stored arm energy 96.5 J.
- **PCC load switching:** recorded converter powers ~1,501 / 1,502 / 1,504 W; load powers ~1,007 / 2,005 / 1,006 W; grid powers +487 / -509 / +491 W in the original sign convention.
- Entire A3 SM voltage envelope: 94.9–104.7 V.

Compared to the *earlier* unslewed 15 A run, recorded power overshoot was previously 44–57% of each increment, the lower-arm voltage reached 111.65 V at 2.2 s, and measured power at the 2,500 W setpoint was limited to 2,457 W.

## A1 versus enabled balancing — local neighbor rule

The figures below refer to the **spread among each SM's 20 ms moving-average voltages**, not instantaneous PWM ripple.

| t (s) | 0.5 | 1.0 | 1.5 | 2.0 |
|---|---:|---:|---:|---:|
| k_v = 0, upper spread (V) | 0.53 | 1.20 | 2.12 | 2.00 |
| k_v = 0, lower spread (V) | 0.69 | 1.32 | 1.70 | 2.46 |
| k_v = 0.2, upper spread (V) | 0.05 | 0.04 | 0.03 | 0.02 |
| k_v = 0.2, lower spread (V) | 0.04 | 0.03 | 0.04 | 0.04 |

- Approximate A1 spread drift slopes over the reported intervals: 1.6 V/s upper (0.4–1.6 s) and 0.9 V/s lower. The upper spread reached ~2.29 V at 1.57 s and declined to 2.00 V by 2 s; the lower trend was still rising at 2 s.
- Upper spread averaged over 0.5–2 s: ~1.50 V without balancing versus ~0.04 V with balancing.
- Active power and arm-mean voltage ripple were approximately unchanged by k_v (1,499.5 W and 5.01 V in both comparisons).
- Indicative upper-SM individual voltage drift rates (V/s): [+0.64, +0.23, +0.24, +0.64, -0.76, -0.53, -0.23, -0.22].
- Evidence limit: 2 s only, with ideally matched SM capacitances.

## A2 — initial ±10 V capacitor mismatch

- Initial spread: 20 V at t = 0, first falling below 5 V after ~11 ms, below 2 V after ~24 ms and below 1 V after ~46 ms. The initial apparent decay time constant was ~8 ms.
- The spread later remained near 0.7 V during the zero-current/startup interval until t ~0.15 s. It **remained below 0.5 V only after ~242 ms**; after 0.3 s the 20 ms-averaged SM spread was typically 0.02–0.05 V. Do not confuse the *first threshold crossing* with a *sustained-convergence time*.
- **Startup side effect:** upper-arm current reached -17.1 A near 2.9 ms (balanced-reference magnitude ~1.1 A); lower arm-mean Vc fell to 86.8 V at 34 ms (about -24.7% arm energy), upper mean reached 105.5 V, and P_measured ranged from -1,043 to +884 W during the transient.
- Mechanism: with k_v=0.2 and 10 V local mismatch, unbounded correction k_v*error reaches magnitude 2. Six SMs can saturate at modulation 0 or 1, breaking arm-voltage compensation even though **unsaturated** neighbor corrections sum to zero.

## Remaining verification needs

1. Clip |Δm| at the local SM controller and repeat A2.
2. Extend A1 to at least 10 s to characterize drift.
3. Sweep unequal capacitances and varied neighbor communication delay; switch local balancing on during operation.
4. Capture raw grid / converter currents and voltage at 10 µs or faster for appropriate switching-band THD.
5. TWIST/HIL work has not been validated by these recorded simulation results.

## Provenance and corrected model history

- `grid_base.mat`, 18:48: first working baseline, I_max=15 A.
- Early `three_cases_results.mat`, 19:55: **invalid simulation**; arm-controller code assumed Ts_ctrl=100 µs but executed every 10 µs, producing around -685 W and a spurious 510 Hz / 11.7 A current component.
- Later corrected `three_cases_results.mat`: reference for the three cases described above.

See [the original base figure guide](../figures/README.md) for a figure-by-figure experimental procedure and interpretation.