# Results and measurement definitions

All numbers below come from the uploaded `grid_base_results.md`, `three_cases_metrics.txt`, `aligned_delay_results.md` and `aligned_metrics.txt`, which are archived with the original files. They have not been re-simulated during repository assembly.

## Base experiments

- At `k_v=0`, the upper-arm capacitor-voltage spread reaches **2.07 V at 2 s** in the `three_cases_metrics.txt` instant-spread calculation; lower-arm mean-smoothed deviation can also drift. This is a **2-second ideal-capacitor simulation**, not a long-horizon limit.
- With balancing enabled (`k_v=0.2`), the steady 20 ms-averaged inter-SM offset is approximately **0.02–0.05 V** in the documented runs, while the instantaneous spread is larger due to normal PWM ripple. Do not interchange these metrics.
- From an upper-arm ±10 V initial mismatch, the unbounded original controller can have a rapid drop in mismatch but a large transient; the follow-up clipped-correction case is preferable for comparisons of safe response.
- During the power staircase, reported measured steady active power is **1506, 1754, 2003, 2250 and 2502 W** at setpoints **1500, 1750, 2000, 2250 and 2500 W**, respectively. The falling 2500 → 1500 W step is **slew-limited** and needs a distinct transient window.
- The documented PCC load steps preserve the converter power near 1500 W while exchanging surplus/deficit with the grid.

## Communication delay comparison

The same research result is best described with two independent dimensions: sample alignment and delay magnitude.

| Condition | Outcome in supplied recordings | Current THD, harmonics 2–20 |
| --- | --- | ---: |
| `k_v=0.2`, no delay, balanced start | Stable | 3.7% |
| 0.2 ms, fresh own sample | Stable but distorted | 21.1% |
| 0.2 ms, aligned own sample | Stable | 5.1% |
| 1.0 ms, fresh own sample | Unstable / runaway current | Not meaningful as steady-state |
| 1.0 ms, aligned own sample | Stable | 5.0% |
| ±10 V, clip, 1.4 ms aligned | Settles below 1 V spread by ~284 ms | 4.54% |
| ±10 V, clip, 5.5 ms aligned | Bounded, ~26 Hz oscillation and no persistent <1 V settling | 4.40% |

Note that a low current THD at 5.5 ms does **not** mean the local capacitor balancing is stable: the voltage-spread and oscillatory-mode metrics expose the problem.

## Definitions

Instantaneous arm spread, at sample k:

`spread(k) = max_i Vc_i(k) - min_i Vc_i(k)`

To separate PWM-induced capacitor ripple from inter-SM DC offsets, calculate the spread **after** a 20 ms moving average per capacitor. With the stored 100 µs dataset: `N=200` samples for one grid cycle.

- **Convergence time:** first time after which spread remains below a chosen threshold for the rest of the window. This is stricter than a first threshold crossing.
- **THD:** `100 * sqrt(sum(A_h^2, h=2:20)) / A_1`, computed from stored AC current with time-window and spectral leakage assumptions in the original MATLAB script. Since signals were downsampled, this is **low-order harmonic THD**, not switching-harmonic THD.
- **Power-tracking error:** `P_measured - P_reference` averaged over declared steady-state windows.
- **Circulating-current proxy:** from arm currents after confirming the original sign convention; identify DC and 100 Hz components separately instead of assuming no circulating current from power balance alone.
- **Arm voltage ripple:** peak-to-peak of mean SM capacitor voltage, not max-to-min across SMs.

## Validity notes

The original source notes contain both early expectations and later measured values. Results in this document cite the **recorded later measurements**, and potentially conflicting numbers in historical notes must be interpreted by their exact metric/window. No new high-frequency resimulation or oscilloscope validation was performed. HIL/embedded verification and formal statistical robustness tests remain outstanding.