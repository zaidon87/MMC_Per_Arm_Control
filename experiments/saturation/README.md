# D6 — Local duty-correction saturation (independent retained experiment)

This archived **four-run clipping experiment** is separate from the superseded original random-capacitance and gain-sweep reports. Its source MAT, model, runner and textual report were preserved when the outdated `test1/` folder was retired.

**Setup:** 8 SM/arm, Vdc 800 V, P*=1500 W, 2 s, balanced start; four conditions at `k_v=0.2 V⁻¹`: alternating physical C ±20%, unbounded local correction; the same with ±0.10 and ±0.05 correction bounds; identical C at ±0.05 bound. The bounds are placed on the local duty correction before final duty saturation. Analyze grid-current THD at harmonics 2–20 and the worst-arm inter-SM filtered spread.

| Study | THD(2–20) | Worst-arm 20 ms-mean spread | Maximum correction |
|---|---:|---:|---:|
| Alternating ±20%, no correction bound | 7.27% | 0.319 V | 0.185 |
| Alternating ±20%, ±0.10 bound | 4.17% | 0.336 V | 0.100 |
| Alternating ±20%, ±0.05 bound | 3.32% | 0.457 V | 0.050 |
| Identical SMs, ±0.05 bound | 3.25% | 0.096 V | 0.034 |

**Finding:** Tightening correction bounds improves low-order current harmonics in the alternating-C runs at the expense of larger residual voltage spread. Reconstructed clipping statistics arise from logged modulation/voltage/current signals, not directly measured PWM gate waveforms.

Reproduce from [runner](scripts/check_saturation.m), [source model](models/MMC_Per_arm_outer_v5_G2_tests.slx), [clipping variant](models/MMC_Per_arm_outer_v5_G2_tests_sat.slx), [recorded MAT](data/sat_check_results.mat), and [saved text report](reports/sat_check_report.txt). Archived simulation results only; no independent physical validation.
