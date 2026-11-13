# MMC research validation (13 November 2026)

**[Open the illustrated gallery of all 11 cases and 27 original figures](EXPERIMENT_GALLERY.md).**


This note documents **recorded simulation results**, not a new MATLAB/HIL execution. The plant is a grid-connected single-phase MMC: **8 half-bridge submodules per arm (16 total)**; Vdc=800 V; nominal Vc=100 V; Csm=2.2 mF; Larm=5 mH; Rarm=0.5 Ω; grid=230 V RMS, 50 Hz; carrier=1,250 Hz/SM; simulation step=10 µs; arm control step=100 µs.

## Architecture

Each upper/lower arm has its own leader for outer P/Q control, grid synchronization, energy balancing and arm-current regulation. Eight local submodule controllers per arm modify duty from neighbor capacitor-voltage measurements and phase-shifted PWM. Arm energy is shared between the leaders with a modeled 100 µs link delay. This is **distributed per-arm control with neighbor-based SM voltage balancing**, not a fully decentralized peer-to-peer plant controller.

## Experiments — eleven stored cases

| Data file | Number | Conditions |
|---|---:|---|
| `three_cases_results.mat` | 3 | No balancing (kv=0), ±10 V upper-arm initial mismatch, power-staircase and PCC-load events |
| `followup_results.mat` | 4 | Initial mismatch with clipped duty correction; no-delay kv=0.2; fresh-own-sample delay 0.2 and 1.0 ms |
| `aligned_results.mat` | 4 | Time-aligned 0.2 and 1.0 ms delay; clipped initial mismatch with aligned 1.4 and 5.5 ms delay |

For the base-case power staircase, 1500→1750→2000→2250→2500→1500 W is scheduled at 0.6, 1.0, 1.4, 1.8, 2.2 s. PCC loads switch at 2.4, 2.7, 3.0 s. Recorded case-3 controller changes include Imax=17 A, Pmax=2500 W and power-reference slew=5 kW/s.

## Representative recorded values

- With balancing disabled, instantaneous upper capacitor spread is approximately 2.07 V at 2 s.
- With local balancing on, steady spread **after 20 ms voltage averaging per SM** is approximately 0.02–0.05 V in the documented baseline. This metric is not the same as instantaneous switching spread.
- Measured steady P at 1500/1750/2000/2250/2500 W reference: 1506/1754/2003/2250/2502 W.
- A 0.2 ms fresh-own delay increases the reported *2nd–20th harmonic* current THD from 3.7% (no delay) to 21.1%. Aligned 0.2 ms gives ~5.1%.
- A fresh-own 1.0 ms delay yields an unstable/runaway simulation; time-aligned 1.0 ms remains bounded with reported ~5.0% low-order current THD.
- Aligned 1.4 ms and clipped ±10 V mismatch converge to <1 V instantaneous upper spread after roughly 284 ms. At aligned 5.5 ms the spread does not remain under 1 V and a bounded ~26 Hz oscillation appears.

## Caveats

All figures refer to the **supplied model, gains and finite analysis windows**, not experimental hardware. THD is based on recorded/downsampled current and harmonics 2–20; it is **not full-band switching THD**. The high-delay clipped oscillation is not refuted by its moderate current THD. Original follow-up .slx models and driver scripts are unavailable in the supplied zip inputs, although the full four-case MAT dataset is available separately. See [Delay study](DELAY_ALIGNMENT_STUDY.md) and [Reproduction](REPRODUCE_RECORDED_DATA.md).
