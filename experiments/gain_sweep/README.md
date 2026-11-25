# D5 — Neighbor-gain sweep and initial-imbalance convergence

**Source archive:** `13 thadkv(1).zip`. This extends Test 1's local-gain and THD analysis with **12 archived simulations**. The uploaded MAT/SLX/FIG/PNG binary files are retained in the separate corrected research package; this page reports verified numbers and figure methods.

## Method

Single-phase MMC (8 SM per arm, nominal Vdc 800 V, Vc 100 V, C=2.2 mF), 1500 W reference, 2 s runs. All 16 local SM control blocks are tested with neighbor correction gains `k_v = [0.05, 0.10, 0.15, 0.20]` V^-1.

- **Part A (8 runs):** identical 2.2 mF C and alternating ±20% C (1.76/2.64 mF). Start all capacitors at 100 V. Measure the maximum worst-arm max–min spread of individually trailing-20-ms-averaged SM voltages over 0.5–2.0 s. THD is limited to the 50 Hz harmonics 2–20 during 1.8–2.0 s.
- **Part B (4 runs):** identical C, initial upper SM3=102 V and SM6=98 V. Measure when the **absolute** deviation of SM3's filtered voltage from the upper-arm average **stays** below 1 V and 0.5 V, and when upper-arm filtered spread stays below 0.5 V. This is simulated capacitor-voltage convergence, **not measured communication-consensus latency**.

## Part A — Captured results

| C pattern | k_v (V^-1) | Worst-arm filtered imbalance (V) | THD harmonics 2–20 |
|---|---:|---:|---:|
| Identical | 0.05 | 0.186 | 2.63% |
| Identical | 0.10 | 0.125 | 2.35% |
| Identical | 0.15 | 0.095 | 2.66% |
| Identical | 0.20 | 0.096 | 3.25% |
| Alternating ±20% | 0.05 | 0.329 | 1.93% |
| Alternating ±20% | 0.10 | 0.304 | 2.98% |
| Alternating ±20% | 0.15 | 0.249 | 3.87% |
| Alternating ±20% | 0.20 | 0.319 | 7.27% |

**Finding:** For alternating mismatch the lowest sampled filtered imbalance is at `k_v=0.15`, whereas the lowest sampled low-order THD is at `k_v=0.05`. Increasing `k_v` is **not monotonically beneficial**. These four choices do not prove a universal optimum.

## Part B — Settling times (s)

| k_v | SM3 deviation stays <1 V | SM3 deviation stays <0.5 V | Upper-arm spread stays <0.5 V |
|---|---:|---:|---:|
| 0.05 | 0.238 | 0.281 | 0.318 |
| 0.10 | 0.237 | 0.258 | 0.290 |
| 0.15 | 0.227 | 0.241 | 0.271 |
| 0.20 | 0.212 | 0.228 | 0.257 |

**Finding:** `k_v=0.20` settles fastest under this *particular ±2 V initial-condition test*, despite less favorable harmonic results in the alternating-capacitance Part A comparison. Do not mix these distinct test conditions.

## Figure — `kv_sweep.png` (three panels)

**Left — imbalance versus k_v:** Read the worst-arm 20 ms-filtered max–min voltage spread for both physical capacitance patterns. Alternating ±20% has a minimum of 0.249 V at 0.15.

**Middle — grid-current THD:** Evaluate harmonic orders 2–20 in the last 0.2 s and plot THD versus k_v. Alternating ±20% rises from 1.93% to 7.27% across the tested gain range; this is **not full-band switching THD**.

**Right — initial-condition convergence:** Plot **signed** SM3 filtered voltage minus the mean filtered upper-arm voltage for the four gains after SM3 and SM6 are initialized at +2 V and -2 V. Use **absolute** errors for threshold times. Fast initial-condition settling is not evidence of global dynamic optimality.

## Reproduce and evidence limits

Run `run_kv_sweep.m` with `MMC_Per_arm_outer_v5_G2_tests.slx` from Test 1 in MATLAB/Simulink R2024a. The script creates `_kv.slx` working copy, emits `kv_sweep_results.mat`, `kv_sweep_summary.csv`, `kv_sweep.png` and `kv_sweep.fig`. Part B's initial-voltage mask parameter must be identified; four Part B rows **are present** in the supplied CSV and MAT. These are saved simulations, not new reruns or HIL/hardware validations. The repeated settings overlap with earlier Test 1 and must not be counted as independent cases.
