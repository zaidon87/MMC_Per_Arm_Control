# Recorded MMC experiments

**[Aligned figure-by-figure test methods](aligned/figures/README.md)** · **[Illustrated experiment gallery](../docs/EXPERIMENT_GALLERY.md)** · **[27-original-figure catalog](../docs/FIGURE_CATALOG.md)** · **[Dataset and reproduction notes](../docs/REPRODUCE_RECORDED_DATA.md)**

| Folder | Cases | Assets online |
|---|---:|---|
| `base/` | 3 | 13 original PNG plots and 5 supplementary PNG plots under `base/source_notes/nvb/` |
| `followup/` | 4 | Comparative plots located in `aligned/figures/`; no dedicated PNG set in uploaded follow-up material |
| `aligned/` | 4 | 9 original PNG plots covering aligned cases and cross-case comparisons |
| [`test1/`](test1/README.md) | 8+4+5 runs (some overlapping) | **Complete** capacitance-tolerance, saturation and THD study; 6 original PNGs, 4 SLX models, 3 MAT files, original scripts and reports |
| [`test3/`](test3/README.md) | 0 additional | Separate archive of the same **3 base cases**, with 18 original figures and test-by-test instructions; byte-identical input ZIP |

**All 27 earlier original PNG figures plus the 6 new Test1 PNGs are now available in this GitHub repository.** The eight newly supplied `.slx` variants and three `.mat` datasets have been retained in the offline supplement; they must be imported separately before rerunning and before calling this a fully reproducible source checkout. The previous original `model/MMC_Per_arm_outer_v5_G2.slx` remains available.

The 11 recorded cases consist of three base tests, four follow-up tests, and four aligned tests. Match cases by the MATLAB `R` array indices documented in [the gallery](../docs/EXPERIMENT_GALLERY.md). The original source does not include the four follow-up standalone Simulink model variants. 

**Independent Test 3 archive:** [`experiments/test3/`](test3/README.md) keeps the repeated upload separate for navigation and provenance. It does not change the total of 11 distinct simulation cases.


## Corrected and extended robustness studies (25 November 2026)

| Folder | Recorded runs | Relationship to Test 1 |
|---|---:|---|
| [`capacitance_samepattern/`](capacitance_samepattern/README.md) | 8 | Fixes the comparison between random ±10% and ±20% by scaling the **same** random pattern; original Test 1 results remain separately valid for their old random realization |
| [`gain_sweep/`](gain_sweep/README.md) | 12 | Four `k_v` settings, identical versus alternating ±20% C, plus +2/-2 V upper-arm initial mismatch convergence |

Both folders currently contain **English documentation** of the supplied archive data. Their original FIG/PNG/MAT/SLX inputs are provided in a separately downloadable corrected package, rather than already committed to GitHub. Some operating points overlap with Test 1: these are not 20 statistically independent new physical experiments.

## Detailed procedures under every figure

- [Base: 13 original images](base/figures/README.md)
- [Aligned-delay: nine original images](aligned/figures/README.md)
- [Historical and reduced-order analysis: five original images](base/source_notes/nvb/README.md)
- [Separate test3 archival duplicate: 18 images](test3/figures/README.md)

- [Test1 robustness: 6 original figures with setup, method and result](test1/figures/README.md)

**Online provenance:** The Test1 SLX/MAT/PNG files have been uploaded as their original bytes, with Git blob hashes verified. This does **not** change the historical offline-only status of the earlier base/aligned supplemental models.
