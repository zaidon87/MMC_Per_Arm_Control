# Experiment matrix and available artifacts

All stated results refer to uploaded simulations. `R` is a MATLAB struct array with 13 recorded signal fields and metadata (`name`, `grid`). Most cases run 2 seconds; the power/load staircase runs 3.2 seconds.

| Group | Dataset index | Case | Runtime model included? | Description |
| --- | ---: | --- | :---: | --- |
| Base | 1 | `case1_kv0` | Yes | `k_v=0`, 1500 W, balanced initial voltages, 2 s |
| Base | 2 | `case2_imbalance` | Yes | 110 V on upper SM3, 90 V on upper SM6, `k_v=0.2`, 2 s |
| Base | 3 | `case3_base` | Yes | Power staircase 1500 → 1750 → 2000 → 2250 → 2500 → 1500 W; PCC load steps; 3.2 s |
| Follow-up | 1 | `case2_clip` | **No** | ±10 V initial mismatch, `|k_v e| <= 0.1` |
| Follow-up | 2 | `case1b_kv02` | **No** | Neighbor balancing on, no link delay |
| Follow-up | 3 | `case1b_delay02` | **No** | Neighbors 0.2 ms old, own sample fresh |
| Follow-up | 4 | `case1b_delay1` | **No** | Neighbors 1.0 ms old, own sample fresh |
| Aligned | 1 | `case1b_delay1_aligned` | Yes | 1.0 ms delay, own sample delayed equally |
| Aligned | 2 | `case1b_delay02_aligned` | Yes | 0.2 ms delay, own sample delayed equally |
| Aligned | 3 | `case2_clip_delay1p4_aligned` | Yes | ±10 V mismatch, clipped correction, 1.4 ms aligned delay |
| Aligned | 4 | `case2_clip_delay5p5_aligned` | Yes | ±10 V mismatch, clipped correction, 5.5 ms aligned delay |

For the base models, the recorded script uses `I_max=17 A`, `P_max=2500 W`, `P_SLEW=5000 W/s` in the modified arm-leader controller. In the base run, a separate controller-sampling problem was identified in an obsolete earlier export, and the supplied v2 corrected the simulation workflow. Use the *included* v2 models and results; do not conflate archived notes with validated results.

### Power/load schedule — base case 3

| Time (s) | Event |
| ---: | --- |
| 0.6 | 1500 → 1750 W |
| 1.0 | 1750 → 2000 W |
| 1.4 | 2000 → 2250 W |
| 1.8 | 2250 → 2500 W |
| 2.2 | 2500 → 1500 W (slew-limited down-ramp) |
| 2.4 | First 1 kW PCC load connects |
| 2.7 | Second 1 kW PCC load connects |
| 3.0 | Second PCC load disconnects |

Only the first two delay values (0.2 and 1.0 ms) allow **matched aligned vs. unaligned** comparisons. The 1.4 and 5.5 ms tests have aligned implementations only.