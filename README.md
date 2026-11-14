# MMC Per-Arm Control: Experimental Validation

A **single-phase grid-connected Modular Multilevel Converter (MMC)** with independent upper/lower arm leaders, local neighbor-based capacitor-voltage balancing, and phase-shifted PWM.

![MMC base experiments — overview](experiments/base/figures/grid_all_cases.png)

**[View the illustrated 11-case experiment gallery](docs/EXPERIMENT_GALLERY.md)** · **[Capacitance tolerance, saturation and THD tests](experiments/test1/README.md)** · **[Aligned-delay figures: nine methods and measured outcomes](experiments/aligned/figures/README.md)** · **[Base figures: 13 test methods](experiments/base/figures/README.md)** · **[Historical plots: five methods](experiments/base/source_notes/nvb/README.md)** · **[Browse all 27 original figures](docs/FIGURE_CATALOG.md)** · **[Control architecture](docs/CONTROL_ARCHITECTURE.md)** · **[Measured results](docs/VALIDATION_2026.md)**

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

## Capacitance-tolerance robustness: Balancing OFF versus ON

![Upper-arm 20 ms mean capacitor voltages under identical, random and alternating capacitances with local balancing OFF and ON](experiments/test1/figures/ctol_C_mean_voltages_upper.png)

**Test:** Four SM capacitance patterns (identical, random ±10%, random ±20%, alternating ±20%) were each simulated for 2 s at P*=1,500 W, with local neighbor balancing disabled (`k_v=0`) and enabled (`k_v=0.2`). Each of the eight submodule voltages in the upper arm was separately averaged over 20 ms.

**Recorded result:** The balancing correction strongly reduces inter-SM mean-voltage divergence: worst-arm spread improves by **26.6×, 19.0×, 10.2× and 9.6×** across the four patterns. **Trade-off:** for alternating ±20% capacitors, the reported low-order grid-current THD rises to **7.27%** at `k_v=0.2`; subsequent clipping and gain-sensitivity tests reduce the distortion, with a balancing-error trade-off.

**[Complete Test 1: models, data, all six original figures and per-image methods](experiments/test1/README.md)** · [Explain this comparison figure](experiments/test1/figures/ctol_C_mean_voltages_upper.md).

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

The new `experiments/test1/` robustness study includes its **four original Simulink models, six PNGs, scripts and MAT/CSV results online**. Earlier A/B/C model variants and datasets have a separate historical import status described above.

## Interpretation and research limitations

The displayed figures are original saved simulation artifacts, not fresh runs. Instantaneous SM spread and **20 ms-averaged** voltage offset measure different behaviors. THD values here summarize harmonics **2–20** of the stored current, not full switching-frequency THD. No physical communication network, TWIST/STM32 embedded controller, OPAL-RT HIL, protection, or experimental validation is claimed.

## License

MIT License — see [LICENSE](LICENSE). Existing repository files and license have been preserved.
