# Time-aligned neighbour-link delay — the eq. (6) test (13 Nov 2026)

Why two kinds of run: "time-aligned samples restore (6)" contains two claims. (i) The 1 ms run-away and the 21 % THD at 0.2 ms
were caused by the misalignment (own sample fresh, neighbours τ old), not by the delay as such. (ii) With aligned samples the
consensus obeys the delayed-consensus bound τ < π/(4κ), κ = k_v·ī/C (2.77 ms at 1.5 kW). The balanced twin can test (i) but
not (ii): its consensus is idle (all errors below the dead-band), so no delay bound can show. (ii) needs an initial imbalance to
excite the consensus, with the bounded correction so that saturation does not confound the result.

| # | File | From | Edit (`get_neighbors`, 16 charts) | Tests |
|---|---|---|---|---|
| 1 | `MMC_Per_arm_outer_v5_G2_case1b_delay1_aligned.slx` | twin | Vc_i, Vc_prev, Vc_next all delayed by ND = 100 (1 ms) | (i): counterpart of the unstable run |
| 2 | `MMC_Per_arm_outer_v5_G2_case1b_delay02_aligned.slx` | twin | ND = 20 (0.2 ms) | (i): counterpart of the 21 % THD run |
| 3 | `MMC_Per_arm_outer_v5_G2_case2_clip_delay1p4_aligned.slx` | case 2 clip | ND = 140 (1.4 ms, τκ = 0.40 < π/4) | (ii): below the bound → should converge |
| 4 | `MMC_Per_arm_outer_v5_G2_case2_clip_delay5p5_aligned.slx` | case 2 clip | ND = 550 (5.5 ms, τκ = 1.56 > π/4) | (ii): above the bound → the consensus should oscillate once P reaches 1.5 kW |

The edit is the same circular-buffer code as before with a third buffer for the own sample, so the local controller compares three
values of the same instant t − τ (the Olfati-Saber/Murray form behind (6)). Buffers start filled with the first values.
Runner: `run_aligned_cases.m` (runs 1 always, 2–4 if present; same 13 fields; `aligned_results.mat`; references from
`followup_results.mat` if it is in the folder).

## What to read in `aligned_metrics.txt`

Claim (i):
- Run 1 must be stable: all Vc within ≈ 97–103 V after 0.45 s, i_u within ≈ −3.3…+7 A, i_ac THD back near 3.7 % (fresh-sample
  1 ms: 845 A, Vc → 3.8 kV; fresh 0.2 ms: THD 21 %). If run 2 also shows THD ≈ 3.7 % and 150 Hz ≈ 0.15 A, the 3rd harmonic is
  gone with the alignment — that closes the mechanism argument.

Claim (ii), from the two case-2-clip runs:
- Before 0.15 s nothing distinguishes them (κ ≈ 0, bound infinite); the clip closes the ±10 V to ≈ 0.5 V by ≈ 0.28 s in both.
- 1.4 ms: `spread_up < 1 V` at a time close to the no-delay 284 ms, rms inter-SM deviation decreasing or flat from 0.4 s on, no
  non-ripple spectral line.
- 5.5 ms: the fastest ring mode (λ_max = 2 for the half-Laplacian) has τ·2κ = 3.1 > π/2 → expected: the inter-SM deviation grows
  after 0.3 s and settles into a limit cycle bounded by the clip and the dead-band (amplitude of the order of 0.5–2 V), with a
  spectral line between 1/(4τ) = 45 Hz and 2κ/2π = 90 Hz in `HB_u3 deviation 1-2 s`. `spread_up` then never settles below 1 V.
  If instead it converges like the 1.4 ms run, (6) is conservative for this law (the tanh gating and the periodic κ(t) are not in
  the linear model) — also a publishable statement, but then the bound in the text must be presented as sufficient, not tight.

Either outcome answers the reviewer: the paper will state what was tested, at which τ, and what was observed.

## Sentence for the digest once the numbers are in (placeholders in brackets)

*"With the own sample delayed by the same τ the common ripple term cancels: at τ = 1 ms the run that was unstable with a fresh own
sample is stable and the grid-current THD returns to [3.7] %. Starting again from ±10 V with the bounded correction, the consensus
converged for τ = 1.4 ms ([x] ms to 1 V) and [oscillated at ≈ y Hz / still converged] for τ = 5.5 ms, [consistent with / more
tolerant than] the bound (6) of 2.8 ms."*