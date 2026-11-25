# D4 — Matched-pattern capacitance-tolerance experiment

**Source archive:** `12(1).zip`. This is a controlled correction/extension of [Test 1](../test1/README.md), not a replacement of its original measurements. The original MAT/SLX/FIG/PNG binary files are provided in the separately prepared research package and **are not embedded in this GitHub documentation page**.

## What changed, and why it matters

The original Test 1 random ±10% and random ±20% cases used **different** random draws. Therefore the difference between the two results conflated *capacitance-tolerance magnitude* with *random pattern*. This updated runner uses the same seeded (`rng(1)`) 8-element upper and lower random patterns for both cases, scaling every deviation from 2.2 mF by exactly 2. Each capacitance distribution is also held fixed between the balancing-OFF and ON runs.

The **historical random ±20% results (2.248 V OFF, 0.221 V ON)** remain correct as *results of the original different random realization*; they must not be silently combined with the new matched-pattern plots.

## Method

Single-phase grid-connected MMC, 8 SM per arm, nominal Vdc=800 V, nominal SM voltage=100 V, C=2.2 mF. Four distributions (identical, matched random ±10%, matched random ±20%, alternating ±20%) × two gains (`k_v=0` and `k_v=0.2 V^-1`) = **8 saved simulations**. Run for 2 s at P*=1500 W with initially balanced 100 V SM capacitors. The 20 ms trailing mean is computed separately for every SM. The imbalance is the **maximum across t=0.5–2.0 s** of the max–min of those filtered SM voltages; report the worse arm. THD is computed from 50 Hz harmonic orders 2–20 on logged grid current during t=1.8–2.0 s. The arm-leader energy estimator retains nominal 2.2 mF despite physical C variation.

## Figures and numerical data available in GitHub

![Matched-pattern 20 ms-mean voltage spread: balancing OFF versus ON](figures/matched_pattern_voltage_spread.svg)

**Figure method:** For each fixed physical capacitance distribution, run matched OFF (`k_v=0`) and ON (`k_v=0.2 V^-1`) cases. Filter each SM capacitor voltage individually using a trailing 20 ms window; find per-arm max–min spread, then the maximum across 0.5–2.0 s and both arms.

**Recorded result:** The matched ±20% random pattern yields **3.097 V without correction and 0.171 V with correction**. The prior Test 1 random ±20% values (2.248/0.221 V) remain separate because their random draws differ. This SVG was reconstructed from the uploaded numeric summary, **not copied from the original MATLAB PNG**.

[Download the numeric comparison CSV](data/verified_summary.csv). The original four MATLAB PNG figures, SLX, MAT, FIG and runner are **not yet committed to GitHub**. Figure-specific test methods for A–D are recorded below, but their original PNGs can only be viewed in the supplied source archive.

## Verified saved results

| Capacitance case | Filtered imbalance OFF (V) | ON (V) | OFF/ON improvement | THD OFF | THD ON |
|---|---:|---:|---:|---:|---:|
| Identical | 2.550 | 0.096 | 26.6× | 3.18% | 3.25% |
| Matched random ±10% | 2.565 | 0.135 | 19.0× | 3.10% | 3.47% |
| Matched random ±20% | 3.097 | 0.171 | 18.1× | 3.11% | 3.32% |
| Alternating ±20% | 3.050 | 0.319 | 9.6× | 3.26% | 7.27% |

These values were independently read from uploaded `ctol_results_samepattern.mat`; **MATLAB was not rerun**.

## Figure-by-figure methods and findings (original figures in the source archive)

**Figure A — `ctol_A_comparison_samepattern.png`:** For each pattern, juxtapose OFF/ON bars for worst-arm 20 ms-filtered SM voltage spread, instantaneous SM spread and low-order current THD. *Finding:* strong voltage equalization in all four pairs, with a harmonic penalty for alternating ±20% at `k_v=0.2`.

**Figure B — `ctol_B_imbalance_vs_time_samepattern.png`:** Compute max–min across individually trailing-20-ms-averaged SM voltages for both arms, for both gains, and observe the t=0.5–2.0 s interval. *Finding:* OFF traces progressively separate; ON traces are bounded, and matched random ±20% reaches 0.171 V worst-arm spread.

**Figure C — `ctol_C_mean_voltages_upper_samepattern.png`:** Eight upper-arm **individual SM moving means**, four capacitance columns, OFF first row and ON second row, shared y axis. *Finding:* the matched-pattern ±20% panel preserves tight grouping with local correction; these are not instantaneous ripple curves or arm-average voltage.

**Figure D — `ctol_D_capacitance_vs_voltage_samepattern.png`:** For ON cases, plot assigned physical upper-arm C (mF) and each SM's final 20 ms-averaged Vc (V). *Finding:* voltage equalization survives unequal C; it does not imply equal energy, because `E=0.5*C*V^2`.

## Reproduce

Original script: `run_capacitance_tolerance_samepattern.m`, using `MMC_Per_arm_outer_v5_G2_tests.slx` from [Test 1](../test1/README.md). It generates `_Ctol.slx` as a working copy and outputs `ctol_results_samepattern.mat` and four `*_samepattern.png` figures. Preserve the previous Test 1 runner/results; no overwrite is scientifically justified. Simulated behavior only: not TWIST, hardware/HIL or verified packet-level communications.
