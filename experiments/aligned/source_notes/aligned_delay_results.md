# Time-aligned neighbour-link delay — results (13 Nov 2026, from `aligned_results.mat`)

Four runs, 2 s, P* = 1.5 kW fixed, 20001 samples at 100 µs. References: `followup_results.mat` (twin, 0.2 ms fresh, 1 ms fresh,
case 2 clip). Definitions as in the digest; "frozen offset" below = per-submodule 20 ms-averaged deviation from the arm mean.

## 1. Claim (i): the run-away and the 3rd harmonic were the misalignment, not the delay — confirmed

| | no delay | 0.2 ms fresh | 0.2 ms aligned | 1 ms fresh | **1 ms aligned** |
|---|---|---|---|---|---|
| Stable | yes | yes | yes | **no** (845 A, Vc → 3.8 kV) | **yes** |
| All 16 Vc, whole run | 96.4–104.0 V | 97.2–103.4 V | 96.3–104.1 V | — | 96.3–103.9 V |
| i_u, whole run | −3.31 … +7.07 A | −2.47 … +6.73 A | −3.35 … +7.45 A | — | −3.41 … +7.54 A |
| i_ac THD (2nd–20th), 1.5–2 s | 3.7 % | **21.1 %** | 5.1 % | — | 5.0 % |
| i_ac 150 Hz | 0.154 A | 1.841 A | 0.288 A | — | 0.295 A |
| Imbalance, mean 1–2 s, up / low | 0.042 / 0.042 V | 0.047 / 0.040 V | 0.186 / 0.199 V | — | 0.204 / 0.208 V |
| P mean t > 0.45 s | 1500.7 W | 1500.5 W | 1500.6 W | — | 1500.4 W |

Aligning the own sample removes 94 % of the added 3rd harmonic (1.69 A → 0.14 A excess) and the 1 ms case is stable with
currents inside the no-delay band. Residual cost of an aligned delay: THD 3.7 → 5.0 % and an imbalance of ≈ 0.2 V instead of
0.04 V (see §3 for why).

## 2. Claim (ii): the eq. (6) test from ±10 V with the bounded correction

κ = k_v·ī/C = 0.2 × 3.11 / 2.2e-3 = 283 s⁻¹ → π/(4κ) = 2.78 ms at 1.5 kW. Ring modes of the half-Laplacian: λ = 0.29, 1, 1.71, 2 →
individual bounds π/(2κλ) = 19.0, 5.55, 3.25, 2.78 ms.

| | clip, no delay | **clip + 1.4 ms aligned** (τκ = 0.40) | **clip + 5.5 ms aligned** (τκ = 1.56) |
|---|---|---|---|
| Spread_up < 5 V / < 1 V | 263 / 284 ms | 264 / 284 ms | 264 ms / **never** (above 1 V for 84 % of t > 0.5 s) |
| Spread_up, mean 1–2 s (inst.) | 0.16 V | 0.42 V | 1.67 V (max 3.54 V) |
| Imbalance (20 ms avg), mean 1–2 s | 0.041 V | 0.396 V | 1.07 V (0.34 … 1.8 V) |
| rms inter-SM deviation 0.4–0.6 → 1.8–2.0 s | 0.060 → 0.061 V | 0.164 → 0.186 V | 0.648 → 0.631 V (bounded, not growing) |
| Dominant non-ripple line, HB_u3 deviation 1–2 s | none (0.04 V) | none (0.09 V at 2 Hz) | **0.36 V at 26 Hz** (period ≈ 40 ms) |
| i_u t > 0.45 s / i_ac peak | −3.2 … +7.0 A / 9.9 A | −3.3 … +6.9 A / 10.0 A | −5.4 … +8.4 A / 12.4 A |
| P, t > 0.45 s | 1471 … 1524 W | 1485 … 1522 W | **1335 … 1661 W** |
| Arm-average ripple pk-pk | 4.99 V | 4.99 V | 5.72 V |

Reading: below the bound (1.4 ms) the consensus converges exactly as without delay (284 ms to 1 V), then settles on a static
offset (§3). Above the bound (5.5 ms, where the two fastest ring modes are unstable and the third is marginal) the consensus does
not settle: a bounded oscillation at ≈ 26 Hz with 20 ms-averaged imbalance 0.3–1.8 V, instantaneous spread 1.7 V mean / 3.5 V
peak, bounded by the clip and the dead-band (rms deviation flat at 0.63 V, no growth), and visible in the currents (i_ac 12.4 A
peak, P ± 160 W). This is the behaviour (6) predicts above its bound; (6) is therefore the right bound once the samples are
aligned. (The limit-cycle frequency is below the linear estimate 45–90 Hz because the clip and the dead-band reduce the
effective gain; the statement in the paper should be "oscillates", with the measured 26 Hz, not a predicted frequency.)

## 3. New finding: a dead-band "blind zone" sets the residual imbalance after any delayed transient

After convergence the 1.4 ms run keeps the pattern [+0.14 −0.07 −0.26 −0.30 −0.16 +0.11 +0.27 +0.27] V (HB_u1…u8): one
period around the ring = the slowest ring mode (λ = 1 − cos(π/4) = 0.29). For that mode e_i = −λ·v_i, so every error is below
the 0.1 V dead-band as soon as the mode amplitude is below 0.1/0.29 = 0.34 V (max − min up to 0.68 V) — the balancing switches
itself off there. Measured: all eight |e_i| ≤ 0.09 V in the frozen state. Without delay the transient leaves this mode almost
unexcited (0.04–0.10 V); with an aligned delay the more oscillatory convergence leaves 0.2–0.4 V in it, which the dead-band then
never removes. The digest's residual "0.10 V" is therefore where the dead-band happened to freeze the state, not a property of
the gain; a filtered error with a smaller dead-band (or a dead-band applied after a moving average) would lower it.

## 4. Digest text — final sentences

Delay paragraph (replaces the eq. (6) claim; ≈ 95 words):
*"Equation (6) assumes that each submodule compares its own voltage with neighbour values of the same instant. With the own sample
fresh and the neighbour values τ late, the common 100 Hz ripple enters every error as −τ dv̄/dt: at τ = 0.2 ms the grid-current
THD rose from 3.7 % to 21 % and at τ = 1 ms the arm current ran away within 3 ms, while the consensus itself stayed within 7 V.
With the own sample delayed by the same τ the 1 ms case is stable (THD 5.0 %), and from ±10 V the consensus converged in 284 ms
for τ = 1.4 ms and oscillated at 26 Hz with 1.7 V spread for τ = 5.5 ms, consistent with the bound of 2.8 ms from (6)."*

Conclusions: *"the neighbour links have no delay"* → *"a link delay is tolerated up to the bound (6) only if the own sample is
time-aligned with the neighbour values; the residual imbalance after a delayed transient is set by the dead-band (up to 0.34 V
amplitude in the slowest ring mode is not corrected)."*

Optional one-liner for the results section (if space): *"An aligned delay leaves an uncorrected offset of 0.2–0.4 V in the
slowest ring mode, inside the 0.1 V dead-band."*

## 5. Hardware implication (Twist)

Timestamp or buffer the own measurement so that the comparison uses three samples of the same instant; the admissible link
latency is then the (6) bound (2.8 ms at 1.5 kW, 1.6 ms at 2.5 kW), two orders of magnitude above the RS-485 message time
measured in E2 (6.1 µs per reply, 13.7 µs for a single exchange). Without alignment the budget is < 0.2 ms and the failure is a current run-away, not an imbalance.