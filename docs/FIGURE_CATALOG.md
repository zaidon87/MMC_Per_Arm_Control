# Original figure catalog — 33 unique images

This catalog includes **27 original earlier PNGs and 6 additional Test1 PNGs** (not counting the duplicated directory layout under `test3/`). The linked Markdown pages show each original image with a brief experiment setup, test method and result directly underneath. Click the image itself on the page to open the original PNG. The images below are **unchanged, byte-for-byte PNG exports** from the user's previously uploaded experiment archives. Their original basenames and relative folders are retained. The descriptions distinguish recorded simulation plots, supplemental analyses, and reduced-model *expectations*.

For a test method and conclusion **under every image**, see [base figure guide](../experiments/base/figures/README.md), [aligned-delay figure guide](../experiments/aligned/figures/README.md) and [historical/reduced-order figure guide](../experiments/base/source_notes/nvb/README.md). See [Illustrated experiment gallery](EXPERIMENT_GALLERY.md) for a short explanation beside a figure for **each of the 11 recorded experiments**. See [Aligned-delay figure methods](../experiments/aligned/figures/README.md) for step-by-step explanations of each aligned PNG.

| Group | Figure (opens illustrated explanation) | Content / purpose |
|---|---|---|
| Base | [`grid_case1_kv0.png`](../experiments/base/figures/grid_case1_kv0.md) | A1: no balancing, complete multi-panel scope |
| Base | [`grid_case2_imbalance.png`](../experiments/base/figures/grid_case2_imbalance.md) | A2: ±10 V initial SM mismatch, complete scope |
| Base | [`grid_case3_base.png`](../experiments/base/figures/grid_case3_base.md) | A3: power staircase/load tests, complete scope |
| Base | [`grid_all_cases.png`](../experiments/base/figures/grid_all_cases.md) | Three-case contact sheet |
| Base | [`FigA_balancing_on_off.png`](../experiments/base/figures/FigA_balancing_on_off.md) | Balancing on/off comparison for A1 and B2 context |
| Base | [`FigB_initial_imbalance.png`](../experiments/base/figures/FigB_initial_imbalance.md) | Initial-mismatch dynamics, A2 |
| Base | [`FigC_staircase_overview.png`](../experiments/base/figures/FigC_staircase_overview.md) | Detailed P/load staircase, A3 |
| Base | [`FigD_ripple_vs_P.png`](../experiments/base/figures/FigD_ripple_vs_P.md) | Capacitor ripple vs P, A3 |
| Base | [`fig1_spread_kv_on_vs_off.png`](../experiments/base/figures/fig1_spread_kv_on_vs_off.md) | Summary capacitor spread on/off |
| Base | [`fig2_case2_initial_imbalance.png`](../experiments/base/figures/fig2_case2_initial_imbalance.md) | Short transient summary, A2 |
| Base | [`fig3_case3_staircase.png`](../experiments/base/figures/fig3_case3_staircase.md) | Power reference and measurement, A3 |
| Base | [`fig4_case3_load_test.png`](../experiments/base/figures/fig4_case3_load_test.md) | PCC active-power flows, A3 |
| Base | [`fig5_case3_Vc_ripple_vs_P.png`](../experiments/base/figures/fig5_case3_Vc_ripple_vs_P.md) | SM capacitor voltage ripple, A3 |
| Base | [`Fig1_overview.png`](../experiments/base/source_notes/nvb/Fig1_overview.md) | Supplementary historical three-case overview |
| Base | [`Fig2_balancing.png`](../experiments/base/source_notes/nvb/Fig2_balancing.md) | Supplementary balancing analysis |
| Base | [`Fig3_ripple_vs_P.png`](../experiments/base/source_notes/nvb/Fig3_ripple_vs_P.md) | Supplementary analytical ripple plot |
| Base | [`Fig4_step_2p2s_diagnostic.png`](../experiments/base/source_notes/nvb/Fig4_step_2p2s_diagnostic.md) | Supplementary 2.2 s step diagnosis |
| Base | [`expected_cases_1_2_reduced_model.png`](../experiments/base/source_notes/nvb/expected_cases_1_2_reduced_model.md) | Reduced-model expectation, not measured performance |
| Aligned | [`grid_case1b_delay1_aligned.png`](../experiments/aligned/figures/grid_case1b_delay1_aligned.md) | C1: 1 ms aligned-delay scope |
| Aligned | [`grid_case1b_delay02_aligned.png`](../experiments/aligned/figures/grid_case1b_delay02_aligned.md) | C2: 0.2 ms aligned-delay scope |
| Aligned | [`grid_case2_clip_delay1p4_aligned.png`](../experiments/aligned/figures/grid_case2_clip_delay1p4_aligned.md) | C3: clipped mismatch, 1.4 ms |
| Aligned | [`grid_case2_clip_delay5p5_aligned.png`](../experiments/aligned/figures/grid_case2_clip_delay5p5_aligned.md) | C4: clipped mismatch, 5.5 ms |
| Aligned | [`grid_all_aligned.png`](../experiments/aligned/figures/grid_all_aligned.md) | Four-case aligned overview |
| Aligned | [`fig1_delay_fresh_vs_aligned.png`](../experiments/aligned/figures/fig1_delay_fresh_vs_aligned.md) | Aligned-only waveform and low-order THD panels in saved PNG (fresh reference absent) |
| Aligned | [`fig2_eq6_test.png`](../experiments/aligned/figures/fig2_eq6_test.md) | C3 vs C4 convergence comparison in saved PNG (no-delay reference absent) |
| Aligned | [`figC_aligned_delay.png`](../experiments/aligned/figures/figC_aligned_delay.md) | Fresh versus aligned delay and THD |
| Aligned | [`figD_deadband_frozen_pattern.png`](../experiments/aligned/figures/figD_deadband_frozen_pattern.md) | Residual deadband / frozen slow mode |

The follow-up `followup_results.mat` records four cases but does not come with four standalone source PNGs. Its relevant comparison figures are included in the **aligned** archive. The gallery identifies shared figures explicitly, rather than treating them as direct exports from a different case.

## Test 1 robustness figures (six additional originals)

| Group | Figure (with method and result) | Test |
|---|---|---|
| Test1 | [`ctol_A_comparison.png`](../experiments/test1/figures/ctol_A_comparison.md) | Capacitance tolerance: balancing OFF versus ON |
| Test1 | [`ctol_B_imbalance_vs_time.png`](../experiments/test1/figures/ctol_B_imbalance_vs_time.md) | Capacitance tolerance: voltage imbalance versus time |
| Test1 | [`ctol_C_mean_voltages_upper.png`](../experiments/test1/figures/ctol_C_mean_voltages_upper.md) | Upper-arm mean capacitor voltages — eight-panel comparison |
| Test1 | [`ctol_D_capacitance_vs_voltage.png`](../experiments/test1/figures/ctol_D_capacitance_vs_voltage.md) | Assigned SM capacitances versus final upper-arm mean voltages |
| Test1 | [`thd_check_spectrum.png`](../experiments/test1/figures/thd_check_spectrum.md) | Grid-current harmonic spectrum for alternating capacitor mismatch |
| Test1 | [`thd_check_vs_time.png`](../experiments/test1/figures/thd_check_vs_time.md) | Sliding-window grid-current THD over time |
