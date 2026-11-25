# MMC simulation experiments — current source-of-truth

This folder separates the original converter/delay studies from the **new corrected robustness experiments**. The old Test 1 capacitance-randomization and harmonic/gain plots have been superseded; their obsolete files and links are removed rather than presented as competing versions.

| Study | Data | Figures and procedure |
|---|---|---|
| [Base operation](base/figures/README.md) | 3 original base cases | 13 PNGs with figure-specific scientific descriptions |
| [Follow-up and time alignment](aligned/figures/README.md) | 4 follow-up + 4 aligned cases | 9 aligned figures with method and results |
| [Independent Test 3 archive](test3/README.md) | Duplicate of the 3 base cases, no additional scientific scenarios | 18 archived plots |
| **[Matched-pattern capacitance tolerance](capacitance_samepattern/README.md)** | **8 saved simulations**, 4 C patterns × `k_v=0/0.2` | **4 corrected SVG figures**, A–D, derived from the newly supplied `ctol_results_samepattern.mat` |
| **[Neighbor-gain sweep](gain_sweep/README.md)** | **12 saved simulations** | **1 new three-panel SVG**, source CSV and convergence times |
| [Correction saturation](saturation/README.md) | 4 distinct archived saturation tests | Original clipping source, MAT report and method; does not replace the new tolerance/gain results |

**Scientific distinction:** A/B/C are the original 11 recorded cases. The matched-pattern and gain studies are additional, partially overlapping operating points. Never total their runs as independent random samples. All reported robustness figures are **simulations**, not power hardware or communication experiments.

**Figure provenance:** Updated SVG figures reconstruct the uploaded MATLAB results (some curves sampled every 50 ms for legibility); they are not the original PNG pixels. Numerical summary values are read from the full MAT/CSV files. The source archives contain the MATLAB PNG, FIG, SLX, MAT and runner files; those large binaries are not claimed as hosted within the new GitHub directories.

[Main README](../README.md) · [Figure catalog](../docs/FIGURE_CATALOG.md) · [Original 11-case gallery](../docs/EXPERIMENT_GALLERY.md).
