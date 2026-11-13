# Three-case model construction, revision 2 — historical engineering notes

**Date:** 11 November 2026.

**Starting point:** `MMC_Per_arm_outer_v5_G2_tests.slx` was the user's working source model. Revision 2 superseded the first trial versions of `case1_kv0`, `case2_imbalance`, and `case3_base`. Use the **corrected** models and `three_cases_results.mat`, not the invalid earlier exports.

## 1. Why the first trial set failed

The initial case variants diverged at t=0, even before active-power ramp-up near t=0.15 s. Their arm-current traces were therefore inconsistent with the source model's working behavior. That first trial introduced a rate-limiter block in the P* signal path, a MinMax spread scope, higher current/power limits and altered logging rates. A plausible diagnosis was inherited signal sample timing: the outer and inner MATLAB Function controllers used `Ts=100 µs` for integrators/resonant states but might have been evaluated at the plant's `10 µs` rate, effectively scaling integration dynamics by a factor of ten.

**Important qualification:** this was an engineering hypothesis based on archive comparison, **not a proven root cause from a MATLAB execution trace**. Revision 2 removed the additional rate limiter and moved the slew logic inside the controller where its sample interval is defined.

## 2. What changed in revision 2

Each case is based on the working `_tests` model with minimal differences.

| Change | Cases | Exact modification |
|---|---|---|
| Current and power limits | All three | `I_max: 15→17 A`; `P_max: 3000→2500 W`, in both arm leaders |
| Internal P reference slew | All three | `P_SLEW = 5000 W/s`; persistent `P_lim` approaches P* by at most `P_SLEW*Ts_ctrl` each controller update |
| Disable local balancing | A1 | Set `k_v=0` in all 16 local SM control functions |
| Introduce capacitor mismatch | A2 | Upper SM3/SM6 initial-voltage parameters `Vc0_u3=110`; `Vc0_u6=90` |
| P reference selection | A1 and A2 | Set manual P-switch to a constant P* instead of staircase |
| Disable load switching during shorter runs | A1 and A2 | `t_load1=10`; `t_load2=[10 11]` (outside simulation interval) |
| Simulation stop time | A1 and A2 | 3.2→2 s |

Archive comparison reported 21 changed entries for A1 (including the 16 SM controllers and root/config/callback edits), five for A2, and three for A3 (two arm leaders and callbacks). The aim was to preserve the model topology, not to restructure the circuit.

## 3. How to execute the corrected cases

1. Place `MMC_Per_arm_outer_v5_G2_case1_kv0.slx`, `MMC_Per_arm_outer_v5_G2_case2_imbalance.slx`, `MMC_Per_arm_outer_v5_G2_case3_base.slx`, `run_three_cases.m` (revision 2), and `export_all_results.m` in a single MATLAB working directory.
2. Open `case3_base.slx` and run it separately before batch processing. It should follow the original working `_tests` baseline up to ~0.6 s, with each later +250 W reference change occurring over ~50 ms.
3. Run `run_three_cases` then `export_all_results`. Recorded signal rates are inherited from the source timeseries, with a factor-of-ten decimation for nominal 10 µs signals in the archived results.
4. Keep original raw output files and compare derived plots by timestamp and metric definition before replacing them.

## 4. Expected behavior at the design stage (predictions, not measured results)

At the time revision 2 was prepared, the initial expectations were:

- A1: capacitor-voltage dispersion might drift at several volts per second without balancing while P regulation stays stable.
- A2: 20 V initial mismatch would remain until the AC current starts near 0.17 s, then settle to <1 V after ~0.26 s.
- A3: <1% steady power error through 2,500 W, <25 W overshoot per +250 W step, and estimated PCC grid powers +1500→+500→-500→+500 W.

**These were design expectations and are not authoritative recorded values.** In particular, the later measured A2 had a rapid initial drop below 1 V at ~46 ms followed by a separate startup recovery; measured A3 overshoot was **29–43 W**, not the predicted <25 W. For final measured results, use [the corrected case analysis](grid_base_results.md), [measurements](three_cases_metrics.txt) and [the figure-by-figure protocol](../figures/README.md).

## Limitations

No additional MATLAB or HIL simulation was run for this translation. The documented source code is inside the Simulink model; these notes do not validate real-time, embedded, communication or hardware safety performance.