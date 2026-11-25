# MMC Per-Arm Control: Experimental Validation

A **single-phase grid-connected Modular Multilevel Converter (MMC)** with independent upper/lower arm leaders, local neighbor-based capacitor-voltage balancing, and phase-shifted PWM.

![MMC base experiments — overview](experiments/base/figures/grid_all_cases.png)

**[View the illustrated 11-case experiment gallery](docs/EXPERIMENT_GALLERY.md)** · **[Corrected capacitor tolerance](experiments/capacitance_samepattern/README.md)** · **[Gain sweep and convergence](experiments/gain_sweep/README.md)** · **[Aligned-delay figures: nine methods and measured outcomes](experiments/aligned/figures/README.md)** · **[Base figures: 13 test methods](experiments/base/figures/README.md)** · **[Historical plots: five methods](experiments/base/source_notes/nvb/README.md)** · **[Browse all 27 original figures](docs/FIGURE_CATALOG.md)** · **[Control architecture](docs/CONTROL_ARCHITECTURE.md)** · **[Measured results](docs/VALIDATION_2026.md)**

## Control architecture

```text
                      Grid / PCC measurements
                       P*, Q*, Vdc, currents
                               |
                  +------------+------------+
                  |                         |
             Upper arm leader         Lower arm leader
             PLL, P/Q, energy,       PLL, P/Q, energy,
              inner current           inner current
                  |     <-- W_arm -->        |
                  |      (100 us)           |
                  v                         v
             8 local SMs                8 local SMs
           Neighbor balancing        Neighbor balancing
                + PS-PWM                  + PS-PWM
                  |                         |
              Gate signals              Gate signals
```

Two arm leaders independently compute their modulation references. Each SM uses neighbor capacitor-voltage differences to adjust its own PWM duty. The **Simulink neighbor vector** is a simulation abstraction, not demonstrated packet-level communication; therefore this is *distributed per-arm control with local balancing*, not proven fully decentralized hardware.

## Nominal model

| Parameter | Value |
|---|---:|
| DC link / nominal SM capacitor | 800 V / 100 V |
| Submodules | 8 per arm, 16 total |
| SM capacitance | 2.2 mF |
| Arm inductance / resistance | 5 mH / 0.5 Ω |
| Grid | 230 V RMS, 50 Hz |
| Carrier per SM | 1,250 Hz |
| Simulation / arm control | 10 µs / 100 µs |
| Baseline P* / Q* | 1,500 W / 0 var |

## Experiment groups

| Group | Cases | Primary purpose | Gallery |
|---|---:|---|---|
| **A: Base converter operation** | 3 | Balancing OFF, initial mismatch, power/load staircase | [A1–A3](docs/EXPERIMENT_GALLERY.md#a-base-model-and-converter-performance-3-cases) |
| **B: Local correction and fresh-own delay** | 4 | Clipped duty, no-delay reference, 0.2/1.0 ms unaligned delay | [B1–B4](docs/EXPERIMENT_GALLERY.md#b-balancing-correction-and-fresh-own-sample-delay-4-cases) |
| **C: Timestamp-aligned delay** | 4 | Aligned 0.2/1.0/1.4/5.5 ms, stability and deadband effects | [C1–C4](docs/EXPERIMENT_GALLERY.md#c-time-aligned-neighbor-voltage-delay-4-cases) |

## PCC load-switching validation

![PCC load-switching test — converter, load and grid active power](experiments/base/figures/fig4_case3_load_test.png)

**Test procedure:** Operate the MMC near **1,500 W** active power and connect a **1 kW PCC load at 2.4 s**. Connect a second **1 kW load at 2.7 s**, then disconnect the second load at **3.0 s**. Monitor converter power, total load power and grid power, using consistent sign conventions and a 20 ms averaging window.

**Recorded result:** Converter output remains near **1,501–1,504 W** while grid exchange changes with the loads: approximately **+487 W**, **−509 W**, then **+491 W**. The recorded power balance follows `P_converter ≈ P_load + P_grid` under the archived sign convention. These are simulation results, not HIL or hardware measurements.

[View the original figure with the experimental method and result](experiments/base/figures/fig4_case3_load_test.md). The **time-aligned communication delay** comparisons remain documented in the [aligned-delay experiment gallery](experiments/aligned/figures/README.md).

**[Browse the separate Test 3 archive (repeat of base cases)](experiments/test3/README.md)** — 18 original figures and figure-by-figure test methods; the upload is identical to the base archive and does not increase the 11 unique case count.

## Corrected capacitance-tolerance experiment

The **matched-pattern study supersedes the earlier random ±20% comparison**. Identical, random ±10%, random ±20% and alternating ±20% capacitance patterns were compared using **the same physical capacitances within each balancing OFF/ON pair**. Crucially, the ±10% and ±20% random vectors use **the same seeded pattern with doubled deviation**, instead of two different draws.

![Corrected upper-arm mean capacitor voltages — 8 SMs × four capacitance patterns, balancing OFF versus ON](experiments/capacitance_samepattern/figures/ctol_C_mean_voltages_upper_samepattern.svg)

**Figure C — Procedure:** Simulate eight cases at P*=1,500 W, Vdc=800 V, eight SMs per arm, Cnom=2.2 mF and 100 V initial SM voltages. Compute a *trailing 20 ms average separately for each upper-arm SM* and compare all eight traces from 0.5–2.0 s. The first row uses `k_v=0`; the second uses `k_v=0.2 V⁻¹`. **Result:** OFF cases exhibit widening mean-voltage separation, while the ON cases remain clustered near 100 V, including the corrected matched random ±20% case.

| Capacitance distribution | Balancing OFF, worst-arm spread | Balancing ON, worst-arm spread | Improvement |
|---|---:|---:|---:|
| Identical | 2.550 V | 0.096 V | 26.6× |
| Random ±10% | 2.565 V | 0.135 V | 19.0× |
| **Matched random ±20%** | **3.097 V** | **0.171 V** | **18.1×** |
| Alternating ±20% | 3.050 V | 0.319 V | 9.6× |

These values are the maximum of the *per-arm max–min difference of individually 20 ms-averaged SM voltages* over t=0.5–2.0 s, taking the worse arm. They are **not** instantaneous ripple metrics. For the alternating ±20% pattern, the low-order grid-current THD(2–20) rises from **3.26%** at `k_v=0` to **7.27%** at `k_v=0.2`.

![Corrected four-pattern comparison of filtered spread, instantaneous spread and THD](experiments/capacitance_samepattern/figures/ctol_A_comparison_samepattern.svg)

**Figure A — Procedure and result:** Under each fixed capacitance pattern, compare balancing OFF and ON using the worst-arm 20 ms-mean spread, worst-arm instantaneous spread and grid-current THD of 50 Hz harmonics 2–20 during the final 0.2 s. The corrected random ±20% run achieves **18.1×** filtered-spread improvement; the alternating ±20% condition exposes the THD penalty.

[Full four-figure experiment and numerical source summary](experiments/capacitance_samepattern/README.md).

## Neighbor-balancing gain: THD and convergence

![Gain sweep — mean-voltage spread, grid-current harmonics and initial-mismatch convergence](experiments/gain_sweep/figures/kv_sweep.svg)

**Gain-sweep procedure:** Twelve saved simulations: eight runs comparing identical and alternating ±20% physical capacitances at `k_v={0.05, 0.10, 0.15, 0.20}` V⁻¹, plus four initial-mismatch runs with upper SM3=102 V and SM6=98 V. **Results:** With alternating ±20% capacitances, the lowest sampled worst-arm filtered spread is **0.249 V at `k_v=0.15`**; the lowest sampled low-order THD is **1.93% at `k_v=0.05`**. Under the distinct ±2 V initial-mismatch test, upper-arm spread remains below 0.5 V from **0.257 s at `k_v=0.20`** versus **0.318 s at `k_v=0.05`**. Thus no single universal gain optimum is established.

[Gain-sweep dataset and full test methods](experiments/gain_sweep/README.md) · [Separate correction-saturation study](experiments/saturation/README.md).

*Provenance:* These five SVG plots are reconstructed from the **newly uploaded archived MATLAB/Simulink data**, with time-series downsampling for display; numerical tables use the full original MAT/CSV values. They are not pixel-identical copies of the original MATLAB PNGs. No additional Simulink run, physical network, TWIST or HIL validation is claimed.

## Files and reproduction

- `model/MMC_Per_arm_outer_v5_G2.slx` — original published model (preserved).
- `src/` — readable original MATLAB Function snapshots; editing snapshots does **not** modify blocks embedded inside a `.slx`.
- `docs/Arm_control.pptx` — original conceptual architecture presentation (preserved).
- `experiments/base/figures/` and `experiments/aligned/figures/` — original published PNG plots.
- `experiments/base/source_notes/nvb/` — supplementary published analysis plots.
- `docs/EXPERIMENT_GALLERY.md` — 11 visual case descriptions.
- `docs/FIGURE_CATALOG.md` — original image inventory.
- `scripts/` — validation/import checkers.
- **Large binary research supplements:** 8 new model variants, 3 archived MAT datasets and test runners are **not yet uploaded** here; see [import instructions](docs/IMPORT_BINARY_SUPPLEMENT.md) and [dataset schema](docs/REPRODUCE_RECORDED_DATA.md).

The previous overlapping Test 1 capacitance and harmonic figures/results have been superseded by the corrected matched-pattern and gain-sweep documentation. The independent saturation study is retained under `experiments/saturation/`. Original source archives supplied in this conversation are not reproduced byte-for-byte in GitHub; the displayed new figures are source-derived SVGs.

## Interpretation and research limitations

The original A/B/C figures are saved simulation artifacts. The updated robustness SVGs are source-derived redraws of saved MAT/CSV results, not fresh runs. Instantaneous SM spread and **20 ms-averaged** voltage offset measure different behaviors. THD values here summarize harmonics **2–20** of the stored current, not full switching-frequency THD. No physical communication network, TWIST/STM32 embedded controller, OPAL-RT HIL, protection, or experimental validation is claimed.

## License

MIT License — see [LICENSE](LICENSE). Existing repository files and license have been preserved.
