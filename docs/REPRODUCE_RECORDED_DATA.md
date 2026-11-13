# Dataset schema, provenance and reproducibility

The uploaded MATLAB MAT files contain a variable named `R` with 3, 4 and 4 cases respectively. Each element has fields:

```
Vc_up, Vc_low, P_UP, Q_UP, Pstar_ref, v_ac, i_ac,
i_u, i_l, m_up, m_low, i_load, i_grid, name, grid
```

The signal fields are serialized MATLAB `timeseries`; access `.Time` and `.Data` **in MATLAB**. The voltage matrices have 8 SM columns per arm. The `name` and `grid` fields are labels. Original simulation logging inherited signal sample periods; most fast signals were downsampled to ~100 µs by a factor of ten. A generic Python SciPy `loadmat` may not reconstruct full MATLAB timeseries objects without MATLAB.

Example after importing the supplemental dataset:

```matlab
S = load('experiments/aligned/data/aligned_results.mat');
assert(numel(S.R) == 4);
t = S.R(1).Vc_up.Time;
v = S.R(1).Vc_up.Data;
spread = max(v,[],2) - min(v,[],2);
plot(t, spread); grid on;
xlabel('Time (s)'); ylabel('Upper-arm capacitor spread (V)');
```

**Availability:** The offline research supplement contains the base `*_tests.slx` model, 3 derived base cases and 4 aligned cases, the original `run_three_cases.m`, `run_aligned_cases.m`, and `export_all_results.m`, stored datasets, original figures and notes. The corresponding `followup_results.mat` is available, but its 4 original fresh-own-sample .slx variants were **not** present in the supplied archives and are not claimed to be fully simulation reproducible.

**No simulations were run during packaging.** Previous results are recorded outputs from the uploaded files. Validate exact Simulink dependencies for the installed MATLAB version (R2024a is the previous source version), and inspect each model before re-running. High-frequency THD, hardware control delays, and physical peer-to-peer messaging were not validated.
