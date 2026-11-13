# Original (historical) grid-model baseline — before the corrected three-case experiment

**Source:** `grid_base.mat`, 11 November 2026, 18:48; stop time 3.2 s, plant step 10 µs, arm controller step 100 µs, 19 logged `logsout` signals.

**Plant:** Vdc=800 V, 8 SMs/arm, Csm=2.2 mF, Larm=5 mH, 230 V RMS 50 Hz grid and 1,250 Hz SM switching carriers.

**Test:** ramp P* from 0 to 1,500 W, then request +250 W increments at 0.6/1.0/1.4/1.8 s; return to 1,500 W at 2.2 s; switch the first PCC load at 2.4 s and the second between 2.7 and 3.0 s.

**Important:** this older baseline had **k_v=0.2, all capacitors initialized to 100 V, I_max=15 A, and no reference slew limit after startup**. It does *not* include the disabled-balancing A1 or initial-mismatch A2 cases, and is *not* interchangeable with the corrected A3 dataset.

## Steady state — last 100 ms of each power level

| P* (W) | Measured P (W) | AC current peak (A) | Reported converter-current full-band THD (%) | Upper Vc arm-mean ripple (Vpp) | Lower Vc arm-mean ripple (Vpp) | Analytical ripple (Vpp) | Upper/lower analytical error | Max instantaneous upper/lower SM spread (V) |
|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1,500 | 1,505 | 9.21 | 5.17 | 4.98 | 5.13 | 5.07 | -1.8% / +1.2% | 0.39 / 0.40 |
| 1,750 | 1,748 | 10.69 | 4.29 | 5.79 | 5.81 | 5.89 | -1.7% / -1.3% | 0.45 / 0.47 |
| 2,000 | 2,001 | 12.23 | 3.54 | 6.64 | 6.61 | 6.73 | -1.3% / -1.8% | 0.51 / 0.51 |
| 2,250 | 2,248 | 13.74 | 2.93 | 7.43 | 7.44 | 7.56 | -1.8% / -1.6% | 0.54 / 0.52 |
| 2,500 | 2,457 (15 A limit) | 15.01 | 2.87 | 8.12 | 8.16 | 8.26 | -1.8% / -1.3% | 0.61 / 0.57 |

- Vc ripple = arm-mean capacitor voltage peak-to-peak, averaged over five fundamental cycles. Analytical model uses `p_upper = (Vdc/2 - v_ac) * (i_ac/2 + P/Vdc)`.
- The old-run THD was calculated from the high-rate **converter current before the filter capacitor**, covering frequencies up to 50 kHz; at 1,500 W the original notes report harmonics 2–40 = 3.5% (h3 2.1%, h9 2.0%, h5 1.4%), interharmonics below 2 kHz = 3.2%, and content around 10 kHz = 2.5%. These details cannot be inferred from the later 100 µs sampled dataset.
- Spread among SM voltages **after individual 20 ms moving averages** <= 0.10 V beyond 0.35 s, mean ~0.04 V. Distinguish this from instantaneous PWM ripple and arm-mean Vc ripple.
- Mean arm capacitor voltages 99.91–100.09 V; reported power factor ~1, |Q| <= 12 var.
- Circulating current DC component P/Vdc ~1.89–3.12 A, 100 Hz component <=0.02 A.
- Actual switching frequencies were reported ~1,253–1,256 Hz per SM; arm modulation reference 0.07–0.92.

## Transient response in the earlier run

- +250 W steps: power overshoot **44–57% of the 250 W change** around 25 ms after each transition, then within 2% of setpoint by about 34 ms. Lower arm-mean Vc dipped by 2.2–2.5 V, upper by 0.45–0.77 V.
- -1,000 W change at 2.2 s: measured P dipped to 1,023 W; lower arm capacitor voltage peaked at **111.65 V** (+11.6%) and energy reached **109.6 J** (+24.6%), while upper voltage remained <= 104.1 V. Total arm energy spanned roughly 176–200 J. Return to ±0.5 V after ~154 ms upper and ~271 ms lower.
- PCC load switching: converter power ~1,485–1,518 W; arm-mean capacitor voltage excursion <=0.25 V.
- During startup SM mean spread peaked ~0.50 V at 0.17 s and dropped below 0.1 V by 0.27 s. The spread between SM means stayed <=0.097 V during the 2.2 s event.

## Diagnosed problems in this old baseline

1. Current limit **I_max=15 A** was below the approximately 15.3 A needed at the 2,500 W target; measured power remained ~2,457 W.
2. Excessive 111.65 V transient: the DC-side feedforward in energy-control block B2 used a 20 ms averaged P_measured, lagging AC-side power by ~20 ms, with around 24 J energy surplus.
3. Power overshoot was aggravated by the same delayed measurement and unslewed P* reference.
4. `iacref_UPPER` and `iacref_LOWER` were numerically identical because the arm leaders read the same measurement in simulation; this is not proof of fault-tolerant independence.
5. Carrier f_sw was an exact 25× fundamental-frequency multiple, implying deterministic carrier/grid synchronism.

## Follow-up actions subsequently implemented

- Test `k_v=0` to isolate neighbor balancing.
- Apply ±10 V initial SM mismatch in A2.
- Raise I_max to 17 A and implement P-reference slew limiting in the corrected three-case models.

The corrected outputs are documented in [the revised grid results](../grid_base_results.md); do **not** cite this earlier baseline's 111.65 V transient as the behavior of the corrected A3 case.

See the [historical-figure guide](README.md) for descriptions of the five NVB supplementary plots.