# MMC Per-Arm Control — Experimental Validation

A **single-phase grid-connected Modular Multilevel Converter (MMC)** with independent upper/lower arm leaders, local neighbor-based capacitor-voltage balancing, and phase-shifted PWM.

![MMC base experiments — overview](experiments/base/figures/grid_all_cases.png)

**[View the illustrated 11-case experiment gallery](docs/EXPERIMENT_GALLERY.md)** · **[Read the method for each of the 9 aligned-delay figures](experiments/aligned/figures/README.md)** · **[Browse all 27 original figures](docs/FIGURE_CATALOG.md)** · **[Control architecture](docs/CONTROL_ARCHITECTURE.md)** · **[Measured results](docs/VALIDATION_2026.md)**

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

![Matched fresh-versus-aligned delay comparison](experiments/aligned/figures/figC_aligned_delay.png)

**Central finding:** unaligned neighbor measurements at 0.2 ms yield **~21.1%** low-order current THD; an aligned 0.2 ms version gives **~5.1%**. At 1.0 ms the unaligned case diverges while the aligned version stays bounded (THD **~5.0%**). A clipped initial-mismatch case at 1.4 ms aligned delay converges, while 5.5 ms exhibits a bounded ~26 Hz oscillation. These results apply to the archived simulations and analysis windows, not verified hardware.

**[Browse the separate Test 3 archive (repeat of base cases)](experiments/test3/README.md)** — 18 original figures and figure-by-figure test methods; the upload is identical to the base archive and does not increase the 11 unique case count.

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

## Interpretation and research limitations

The displayed figures are original saved simulation artifacts, not fresh runs. Instantaneous SM spread and **20 ms-averaged** voltage offset measure different behaviors. THD values here summarize harmonics **2–20** of the stored current, not full switching-frequency THD. No physical communication network, TWIST/STM32 embedded controller, OPAL-RT HIL, protection, or experimental validation is claimed.

## License

MIT License — see [LICENSE](LICENSE). Existing repository files and license have been preserved.
